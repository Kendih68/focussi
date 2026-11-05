# Screen Time setup and device verification

The full focussi build uses the native Family Controls picker, Managed Settings shields, and a Device Activity Monitor extension. No app names or browsing history are collected. Selecting no apps runs a timer without blocking.

## Before running on iPhone

1. Install full Xcode and select a development team for both targets.
2. Replace the example bundle identifiers with identifiers registered to that team.
3. Enable Family Controls for both app and monitor targets.
4. Register an App Group. Replace `group.com.focusisle.app` in both entitlements and `Shared/ScreenTimeConfiguration.swift` with that exact group identifier.
5. Keep `ScreenTimeConfiguration.swift` in both targets. Embed `FocusIsleMonitor.appex` in the app.
6. Run on a physical iPhone. Grant Screen Time access from Settings inside focussi, and choose apps with Apple's picker.
7. Request Family Controls distribution approval for both identifiers before TestFlight/App Store distribution.

## Behavior and limits

- Focus sessions with blocking require at least 15 minutes because Apple's monitoring API rejects shorter intervals. Breaks do not block apps.
- The app registers a one-time monitoring interval before applying shields. If registration fails, starting the protected session fails and no new shields are applied.
- The monitor releases shields at the deadline even while the app is closed. iOS schedules extension execution; callbacks and notifications may arrive late. This mechanism cannot promise an exact second of background unlocking. Returning to focussi also reconciles expired shields.
- A single named settings store avoids the platform's store limit. The app and extension use a shared file lock and check a unique activity ID plus the deadline to keep stale callbacks from unlocking a newer session.
- Ending early clears shields, stops monitoring, and cancels the pending notification. Rewards and streaks are managed by the app's persisted domain state, independently of notification delivery.
- A successful authorization is remembered, and the app refreshes it on a later launch. Apple silently refreshes an existing individual grant. If access was revoked, the system may require authorization again; the app does not promise blocking without permission.
- Individual authorization is voluntary. Users can revoke it in iOS Settings, and the app cannot guarantee they cannot bypass blocking.
- Notification permission is independent of Screen Time permission. Foreground notifications show a banner and play a sound when allowed. A unique identifier prevents canceled asynchronous notification requests from reappearing.

## Physical-device checklist

- [ ] Grant permission and select a test app. It becomes shielded only during focus.
- [ ] Start a 15-minute session, lock the phone, and verify automatic unlock at the end.
- [ ] Repeat with focussi terminated; verify monitor cleanup and exactly one reward on return.
- [ ] End early; verify immediate unlock and no reward/streak credit.
- [ ] End early and immediately start another session. Verify no old notification or callback ends the new session.
- [ ] Reopen midway through a session; verify the deadline and shields remain in effect.
- [ ] Revoke Screen Time access in system Settings; verify the UI reports the permission change.
- [ ] Test notification authorization denied and enabled, both foreground and background.
- [ ] Cross local midnight; verify completion is counted on its finish date.
- [ ] Verify settings and app selection persist across process termination.

## Verification status in this workspace

On November 5, 2026, Xcode 27.2 successfully completed a clean Debug simulator build of the app, FocusCore package, and monitor extension. The app launched on the iPhone 18 Pro simulator, and the Focus screen was visually inspected. Physical-device signing, shields, background cleanup, and notification delivery remain unverified. This checklist remains required before claiming working device blocking.

## Apple references

- [Individual authorization](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:))
- [Minimum monitoring interval](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror/intervaltooshort)
- [Screen Time APIs and named stores](https://developer.apple.com/videos/play/wwdc2022/110336/)
- [Distribution entitlement requests](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement)
