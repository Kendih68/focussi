import DeviceActivity
import Foundation
import ManagedSettings

final class FocusMonitor: DeviceActivityMonitor {
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    try? ScreenTimeConfiguration.withLock {
      guard let session = ScreenTimeConfiguration.session(),
        session.activityName == activity,
        Date() >= session.deadline
      else { return }
      // The shared lock keeps this ID/deadline check atomic with app starts.
      // A delayed callback from an older session cannot clear new shields.
      ManagedSettingsStore(named: session.storeName).clearAllSettings()
      // The app owns the timer/rewards and removes metadata when it reconciles.
    }
  }
}
