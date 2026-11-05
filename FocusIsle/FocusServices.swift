import Combine
#if SCREEN_TIME_ENABLED
import DeviceActivity
import FamilyControls
import ManagedSettings
#endif
import Foundation
import UserNotifications

@MainActor
final class FocusServices: ObservableObject {
  #if SCREEN_TIME_ENABLED
  @Published var selection: FamilyActivitySelection {
    didSet {
      if let data = try? JSONEncoder().encode(selection) {
        ScreenTimeConfiguration.defaults?.set(data, forKey: ScreenTimeConfiguration.selectionKey)
      }
    }
  }
  @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
  private var authorizationSubscription: AnyCancellable?
  private let center = DeviceActivityCenter()
  private let authorizationKey = "focus.wasAuthorized"
  #endif
  @Published private(set) var notificationsEnabled = false
  @Published private(set) var notificationError: String?
  private var notificationGeneration = UUID()
  private let notificationKey = "focus.pendingNotification"
  private let notificationDelegate = FocusNotificationDelegate()

  init() {
    #if SCREEN_TIME_ENABLED
    if let data = ScreenTimeConfiguration.defaults?.data(
      forKey: ScreenTimeConfiguration.selectionKey),
      let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    {
      selection = saved
    } else {
      selection = FamilyActivitySelection()
    }
    authorizationSubscription = AuthorizationCenter.shared.$authorizationStatus
      .receive(on: DispatchQueue.main)
      .sink { [weak self] status in
        guard let self else { return }
        self.authorizationStatus = status
        if status == .denied {
          UserDefaults.standard.set(false, forKey: self.authorizationKey)
          self.endFocus()
        }
      }
    #endif
    UNUserNotificationCenter.current().delegate = notificationDelegate
    refreshStatus()
    #if SCREEN_TIME_ENABLED
    if UserDefaults.standard.bool(forKey: authorizationKey) {
      Task {
        do { try await authorize() } catch {
          UserDefaults.standard.set(false, forKey: authorizationKey)
          refreshStatus()
        }
      }
    }
    #endif
  }

  var selectedCount: Int {
    #if SCREEN_TIME_ENABLED
    return selection.applicationTokens.count + selection.categoryTokens.count
      + selection.webDomainTokens.count
    #else
    return 0
    #endif
  }

  #if SCREEN_TIME_ENABLED
  func authorize() async throws {
    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    UserDefaults.standard.set(true, forKey: authorizationKey)
    refreshStatus()
  }
  #endif

  func refreshStatus() {
    #if SCREEN_TIME_ENABLED
    authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    #endif
    Task {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      notificationsEnabled =
        settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
  }

  func requestNotifications() async throws {
    notificationsEnabled = try await UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge])
  }

  /// Register automatic cleanup before applying any shields. A failure leaves apps unblocked.
  func beginFocus(until deadline: Date) throws {
    #if SCREEN_TIME_ENABLED
    guard authorizationStatus == .approved else { throw FocusServiceError.permissionRequired }
    guard
      FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: ScreenTimeConfiguration.appGroup) != nil
    else {
      throw FocusServiceError.appGroupUnavailable
    }
    guard selectedCount > 0 else { throw FocusServiceError.noSelection }
    guard selection.applicationTokens.count <= 50, selection.webDomainTokens.count <= 50 else {
      throw FocusServiceError.tooManySelections
    }
    // Apple requires a monitoring interval of at least 15 minutes. Starting
    // two seconds in the past avoids subsecond truncation at that boundary.
    guard deadline.timeIntervalSinceNow >= 15 * 60 - 1 else {
      throw FocusServiceError.intervalTooShort
    }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    let start = Date().addingTimeInterval(-2)
    let roundedEnd = Date(timeIntervalSince1970: ceil(deadline.timeIntervalSince1970))
    let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let schedule = DeviceActivitySchedule(
      intervalStart: calendar.dateComponents(components, from: start),
      intervalEnd: calendar.dateComponents(components, from: roundedEnd),
      repeats: false
    )
    try ScreenTimeConfiguration.withLock {
      let previous = ScreenTimeConfiguration.session()
      let session = ScreenTimeConfiguration.BlockingSession(
        activityID: "FocusIsle.\(UUID().uuidString)", deadline: deadline
      )
      try center.startMonitoring(session.activityName, during: schedule)
      do { try ScreenTimeConfiguration.saveSession(session) } catch {
        center.stopMonitoring([session.activityName])
        throw error
      }
      if let previous { center.stopMonitoring([previous.activityName]) }
      let store = ManagedSettingsStore(named: session.storeName)
      store.shield.applications =
        selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
      store.shield.applicationCategories =
        selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
      store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
      store.shield.webDomainCategories =
        selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
    }
    #else
    throw FocusServiceError.blockingUnavailable
    #endif
  }

  func endFocus() {
    #if SCREEN_TIME_ENABLED
    try? ScreenTimeConfiguration.withLock {
      if let session = ScreenTimeConfiguration.session() {
        ManagedSettingsStore(named: session.storeName).clearAllSettings()
        center.stopMonitoring([session.activityName])
      }
      ScreenTimeConfiguration.clearSession()
    }
    #endif
  }

  /// Call after restoring the saved timer and whenever the app becomes active.
  func reconcile(activeDeadline: Date?) {
    #if SCREEN_TIME_ENABLED
    guard let session = ScreenTimeConfiguration.session() else { return }
    guard let activeDeadline, activeDeadline > Date(),
      abs(activeDeadline.timeIntervalSince(session.deadline)) < 1
    else {
      endFocus()
      return
    }
    if authorizationStatus == .denied { endFocus() }
    #endif
  }

  func scheduleNotification(until deadline: Date, isFocus: Bool) {
    cancelNotification()
    let generation = UUID()
    notificationGeneration = generation
    let identifier = "FocusIsle.\(generation.uuidString)"
    UserDefaults.standard.set(identifier, forKey: notificationKey)
    let content = UNMutableNotificationContent()
    content.title =
      isFocus ? "A little more island, a little more you." : "Ready for a fresh start?"
    content.body =
      isFocus
      ? "Your focus session is complete. Come see what you earned."
      : "Your break is over. Start your next focus session when you’re ready."
    content.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    Task {
      do {
        try await UNUserNotificationCenter.current().add(request)
        if notificationGeneration != generation {
          UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
          ])
          return
        }
        notificationError = nil
      } catch {
        if notificationGeneration == generation { notificationError = error.localizedDescription }
      }
    }
  }

  func cancelNotification() {
    notificationGeneration = UUID()
    if let identifier = UserDefaults.standard.string(forKey: notificationKey) {
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
        identifier
      ])
    }
    UserDefaults.standard.removeObject(forKey: notificationKey)
  }
}

enum FocusServiceError: LocalizedError {
  case permissionRequired, appGroupUnavailable, noSelection, intervalTooShort, tooManySelections, blockingUnavailable
  var errorDescription: String? {
    switch self {
    case .permissionRequired:
      "Allow Screen Time access before starting a session with blocked apps."
    case .appGroupUnavailable:
      "Screen Time setup is incomplete. Enable the shared App Group for both app targets in Xcode."
    case .noSelection: "Choose at least one distracting app or category first."
    case .intervalTooShort: "App blocking needs a focus session of at least 15 minutes."
    case .tooManySelections:
      "Choose at most 50 individual apps and 50 websites. You can select categories to include more."
    case .blockingUnavailable:
      "App blocking is not included in this version."
    }
  }
}

private final class FocusNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
