# Install focussi on iPhone

Beta 1.0 is supplied as source. Use Xcode on a Mac to build and sign your own copy for an iPhone running iOS 17 or newer. No signed IPA is included.

## Choose a scheme

- **focussi Personal** works with a free Apple Personal Team. It includes the timer, pixel-art island, rewards, collection, local progress, and notifications. App blocking is not included.
- **FocusIsle** is the full Screen Time build. It requires an Apple Developer Program team, Family Controls, a shared App Group, and the monitor extension.

Personal Team provisioning expires after seven days. Rebuild and reinstall using the same bundle identifier to renew it. Do not delete the app if you want to retain local progress.

## Configure your signing settings

1. Open `FocusIsle.xcodeproj` in Xcode 16 or newer.
2. In **Xcode → Settings → Apple Accounts**, add your own Apple Account.
3. Copy `Config/Signing.local.xcconfig.example` to `Config/Signing.local.xcconfig`. The local copy is ignored by Git; keep account-specific settings there.
4. In the local copy, set `DEVELOPMENT_TEAM` to your Apple team ID and `PRODUCT_BUNDLE_IDENTIFIER` to a unique Personal app identifier. The local configuration is wired to the Personal target; configure the full app and monitor identifiers in Xcode as described below.
5. In your chosen target's **Signing & Capabilities**, confirm **Automatically manage signing** is enabled and your own team is selected. For Personal, use target **FocussiPersonal**. For the full build, both **FocusIsle** and **FocusIsleMonitor** must use the same enrolled team.

Use your own identifiers, such as `com.example.focussi.personal` for Personal, `com.example.focussi` for the full app, and `com.example.focussi.monitor` for its extension. These are examples to replace, not identifiers registered for you. Personal and full builds use different identifiers and therefore separate app storage.

## Pair and run the Personal build

1. Connect your iPhone to the Mac with a USB data cable. Unlock it and approve the device's **Trust** prompt if shown.
2. Select the phone in Xcode's device tools to pair it.
3. On the phone, enable **Settings → Privacy & Security → Developer Mode**. Restart and confirm when prompted. This option appears after pairing is initiated.
4. Choose **focussi Personal** in Xcode's scheme chooser and your physical iPhone as the destination.
5. Press **⌘R**. This target does not need Family Controls, App Groups, or a monitor extension.
6. If iOS shows **Untrusted Developer**, open **Settings → General → VPN & Device Management → Developer App**, select your own developer account, and approve trust on the phone. Keep the phone online for verification, then open **focussi**.

Start a session normally. No Screen Time permission is requested in Personal. Enable session-end notifications in the app's Settings if desired. Simulator and physical-phone progress are stored separately.

## Configure the full Screen Time build

1. Choose the **FocusIsle** scheme and an Apple Developer Program team.
2. Confirm your unique app and monitor bundle identifiers and automatic signing for both targets.
3. Enable **Family Controls** and **App Groups** for both targets. Register one shared App Group under your team and select it for both.
4. Replace the default `group.com.focusisle.app` with that registered group in `FocusIsle/FocusIsle.entitlements`, `FocusIsleMonitor/FocusIsleMonitor.entitlements`, and `Shared/ScreenTimeConfiguration.swift`.
5. Keep the monitor extension embedded in the full app. Select your iPhone and press **⌘R**.
6. In focussi's Settings, allow Screen Time access and select distractions. Notification permission is separate.

Full Screen Time blocking is not yet verified on a physical iPhone. Complete the [Screen Time device checklist](SCREEN_TIME.md) before relying on it. Simulator behavior does not establish that shielding or background cleanup works on a phone. TestFlight or App Store distribution also requires Apple's Family Controls distribution approval for the relevant app and extension identifiers.

## Test rewards without waiting

With a **Debug** build, open **Settings → Island testing → Enter test island**. Add materials or simulate focus completions, then use Island to place items. The test island has a separate save; use **Exit test** to return to normal progress. Test controls are unavailable in Release builds.

## Apple references

- [Run an app on a device](https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html)
- [Enable Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
- [Configure Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)
- [Developer account and Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account)
