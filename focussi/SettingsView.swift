import SwiftUI
#if SCREEN_TIME_ENABLED
import FamilyControls
#endif
import FocusCore

struct SettingsView: View {
  @EnvironmentObject private var model: AppModel
  @ObservedObject var services: FocusServices
  #if SCREEN_TIME_ENABLED
  @State private var showingPicker = false
  @State private var authorizing = false
  #endif
  @State private var requestingNotifications = false
  @Environment(\.openURL) private var openURL

  private var sessionActive: Bool { model.state.activeSession != nil }

  var body: some View {
    NavigationStack {
      Form {
        #if DEBUG
        Section {
          NavigationLink {
            IslandTestingView()
          } label: {
            Label("Island testing", systemImage: "hammer")
          }
        } footer: {
          Text("Test materials and rewards without waiting for a timer.")
        }
        .listRowBackground(IsleTheme.paper)
        #endif
        Section {
          Stepper("Focus · \(model.state.settings.focusMinutes) min", value: duration(\.focusMinutes), in: 15...120, step: 5)
          Stepper("Short break · \(model.state.settings.shortBreakMinutes) min", value: duration(\.shortBreakMinutes), in: 1...30)
          Stepper("Long break · \(model.state.settings.longBreakMinutes) min", value: duration(\.longBreakMinutes), in: 5...60, step: 5)
        } header: {
          menuHeading("Session lengths")
        } footer: {
          Text(sessionActive
            ? "Finish or end your session to change session lengths."
            : "A long break is suggested after four completed focus sessions. Sessions and breaks start manually.")
        }
        .disabled(sessionActive)
        .listRowBackground(IsleTheme.paper)

        #if SCREEN_TIME_ENABLED
        Section {
          LabeledContent("Screen Time access", value: permissionText)
          if services.authorizationStatus != .approved {
            Button {
              authorizing = true
              Task {
                do { try await services.authorize() }
                catch { model.error = error.localizedDescription }
                authorizing = false
              }
            } label: {
              HStack {
                Text(authorizing ? "Requesting access…" : "Allow Screen Time access")
                Spacer()
                if authorizing { ProgressView() }
              }
            }
            .disabled(authorizing)
          }
          Button { showingPicker = true } label: {
            HStack {
              Text("Choose distractions")
              Spacer()
              Text("\(services.selectedCount) selected").foregroundStyle(IsleTheme.secondary)
              Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(IsleTheme.secondary)
            }
          }
          .disabled(services.authorizationStatus != .approved)
        } header: {
          menuHeading("App blocking")
        } footer: {
          Text(sessionActive
            ? "Selected apps cannot be changed during a session."
            : "Selected apps, categories, and websites are blocked during focus sessions and unlocked during breaks. You can also use the timer without blocking. Focus sessions require at least 15 minutes for background unlocking.")
        }
        .disabled(sessionActive)
        .listRowBackground(IsleTheme.paper)
        #else
        Section {
          Text("App blocking is not included in this version.")
            .font(.subheadline).foregroundStyle(IsleTheme.secondary)
        } header: {
          menuHeading("App blocking")
        }
        .listRowBackground(IsleTheme.paper)
        #endif

        Section {
          LabeledContent("Session alerts", value: services.notificationsEnabled ? "Allowed" : "Not enabled")
          if !services.notificationsEnabled {
            Button {
              requestingNotifications = true
              Task {
                do { try await services.requestNotifications() }
                catch { model.error = error.localizedDescription }
                requestingNotifications = false
              }
            } label: {
              HStack {
                Text(requestingNotifications ? "Requesting access…" : "Enable notifications")
                Spacer()
                if requestingNotifications { ProgressView() }
              }
            }
            .disabled(requestingNotifications)
          }
          if services.notificationsEnabled && services.notificationError != nil {
            Text("The session alert could not be scheduled. Check notification access in iPhone settings.").font(.caption).foregroundStyle(.red)
          }
          Button("Open iPhone settings", systemImage: "arrow.up.right") {
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
          }
        } header: {
          menuHeading("Notifications")
        } footer: {
          Text("Receive an alert when a focus session or break ends. If access was denied, change it in iPhone settings.")
        }
        .listRowBackground(IsleTheme.paper)

        Section {
          LabeledContent("Progress storage", value: "On this device")
          LabeledContent("Version", value: "Beta 1.0")
        } header: {
          menuHeading("Your island")
        } footer: {
          Text("Materials, creatures, and decorations stay earned. Missing a day only resets your current streak.")
        }
        .listRowBackground(IsleTheme.paper)
      }
      .foregroundStyle(IsleTheme.ink)
      .scrollContentBackground(.hidden)
      .background(IsleTheme.background)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("SETTINGS").font(.system(.headline, design: .monospaced)).foregroundStyle(IsleTheme.ink)
        }
      }
      #if SCREEN_TIME_ENABLED
      .familyActivityPicker(isPresented: $showingPicker, selection: $services.selection)
      #endif
    }
  }

  #if SCREEN_TIME_ENABLED
  private var permissionText: String {
    if services.authorizationStatus == .approved { return "Allowed" }
    if services.authorizationStatus == .denied { return "Not allowed" }
    if services.authorizationStatus == .notDetermined { return "Not set up" }
    return "Unknown"
  }
  #endif

  private func duration(_ path: WritableKeyPath<FocusSettings, Int>) -> Binding<Int> {
    Binding(get: { model.state.settings[keyPath: path] }, set: { model.state.settings[keyPath: path] = $0; model.save() })
  }

  private func menuHeading(_ title: String) -> some View {
    Text(title.uppercased()).font(.system(.caption, design: .monospaced).weight(.bold)).foregroundStyle(IsleTheme.secondary)
  }
}

#if DEBUG
private struct IslandTestingView: View {
  @EnvironmentObject private var model: AppModel
  private var sessionActive: Bool { model.state.activeSession != nil }

  var body: some View {
    Form {
      Section {
        Button(model.isTesting ? "Return to main island" : "Enter test island") {
          model.setTesting(!model.isTesting)
        }.disabled(sessionActive)
      } footer: {
        Text(sessionActive
          ? "Finish or end the active timer before switching islands or using test controls."
          : "The test island has its own save. Your main island stays separate. Test progress is saved; re-enter here to resume after relaunch.")
      }
      .listRowBackground(IsleTheme.paper)

      if model.isTesting {
        Section {
          LabeledContent("Materials", value: "\(model.state.materials)")
          LabeledContent("Completed sessions", value: "\(model.state.totalSessions)")
          LabeledContent("Creatures", value: "\(model.state.discoveredCreatures.count) / 6")
        } header: { Text("Test progress") }
        .listRowBackground(IsleTheme.paper)

        Section {
          Button("Add 100 materials") { model.addTestMaterials() }
          Button("Simulate 1 focus session") { model.simulateFocusSessions(1) }
          Button("Simulate 4 focus sessions") { model.simulateFocusSessions(4) }
        } header: { Text("Instant rewards") }
        footer: { Text("Each simulated session gives 10 materials. Four sessions hatch a creature. Open Island to spend materials and place decorations. These actions do not block apps or schedule alerts.") }
        .disabled(sessionActive)
        .listRowBackground(IsleTheme.paper)
      }
    }
    .foregroundStyle(IsleTheme.ink)
    .scrollContentBackground(.hidden)
    .background(IsleTheme.background)
    .navigationTitle("Island testing")
    .navigationBarTitleDisplayMode(.inline)
  }
}
#endif
