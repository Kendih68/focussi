import Darwin
import DeviceActivity
import Foundation
import ManagedSettings

/// Keep the app group identical in both targets and in their entitlements.
enum ScreenTimeConfiguration {
  static let appGroup = "group.com.focusisle.app"
  static let selectionKey = "focus.selection"

  struct BlockingSession: Codable {
    let activityID: String
    let deadline: Date
    var activityName: DeviceActivityName { DeviceActivityName(activityID) }
    var storeName: ManagedSettingsStore.Name { ManagedSettingsStore.Name("FocusIsle.focus") }
  }

  static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

  static var sessionURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
      .appendingPathComponent("blocking-session.json")
  }

  static func session() -> BlockingSession? {
    guard let url = sessionURL, let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(BlockingSession.self, from: data)
  }

  static func saveSession(_ session: BlockingSession) throws {
    guard let url = sessionURL else { throw CoordinationError.unavailable }
    try JSONEncoder().encode(session).write(
      to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  static func clearSession() {
    if let url = sessionURL { try? FileManager.default.removeItem(at: url) }
  }
}

extension ScreenTimeConfiguration {
  enum CoordinationError: Error { case unavailable }

  /// Serialize the app and extension so an old callback cannot race a new shield.
  static func withLock<T>(_ operation: () throws -> T) throws -> T {
    guard
      let directory = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroup)
    else {
      throw CoordinationError.unavailable
    }
    let descriptor = open(
      directory.appendingPathComponent("blocking.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard descriptor >= 0 else { throw CoordinationError.unavailable }
    defer { close(descriptor) }
    guard flock(descriptor, LOCK_EX) == 0 else { throw CoordinationError.unavailable }
    defer { flock(descriptor, LOCK_UN) }
    return try operation()
  }
}
