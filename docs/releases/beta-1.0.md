# focussi Beta 1.0

**Tag:** `v1.0.0-beta.1`
**Platform:** iPhone, iOS 17 or newer
**Delivery:** source only; no signed IPA, TestFlight build, or App Store release is supplied.

Build and sign your own copy in Xcode. Start with the [iPhone installation guide](../INSTALL_IPHONE.md).

## Included

- Native SwiftUI focus and break timers with manual starts, saved deadlines, and early-end confirmation.
- Cozy pixel-art island, six purchasable decorations, six collectible creatures, and four streak keepsakes.
- Ten materials per completed focus session, a creature every four sessions, and progress carried across days.
- Daily and longest streaks, total focus time, completed-session history, and a monthly calendar.
- On-device progress storage and permission-based local session-end notifications.
- Debug-only test island with a separate save, instant materials, and simulated focus completions.

## Build variants and capabilities

| Scheme | Requirements | Included blocking support |
| --- | --- | --- |
| **focussi Personal** | Free Apple Personal Team for direct device installation | None; no Family Controls, App Group entitlement, or monitor extension |
| **focussi** | Apple Developer Program team; Family Controls and shared App Group configured for app and monitor | Managed Settings shields and Device Activity Monitor cleanup |

The full build's Screen Time APIs are compiled only with `SCREEN_TIME_ENABLED`. The Personal build retains notifications and all timer, reward, collection, and progress features. Family Controls distribution approval is required before distributing the full build through TestFlight or the App Store.

## Verification

- `swift run FocusCoreChecks`: **13 checks pass** in Debug.
- `swift run -c release FocusCoreChecks`: **12 checks pass** in Release.
- The additional Debug check covers material grants, normal completion rewards, creature hatching, and rejection of simulated completion while a timer is active.
- Release compilation excludes testing hooks and controls.

The core checks exercise saved deadlines, duplicate reward prevention, early endings, breaks, midnight, missed days, streak milestones, purchases, persistence, duration limits, non-Gregorian calendar preferences, and daylight saving transitions.

## Known beta limits

- **Fixed island placement:** purchased decorations occupy preset spots. Free placement and rearrangement are not included.
- **Local-only storage:** no accounts, cloud backup, or cross-device sync. Deleting the app removes its local progress. Different bundle identifiers and simulator installations have separate saves.
- **Personal signing:** free Personal Team provisioning expires after seven days. Rebuild and reinstall with the same identifier to renew it while keeping the app's stored progress.
- **Full blocking unverified:** physical-device shielding, background cleanup, and notification delivery still need the [device checklist](../SCREEN_TIME.md). The full build requires its capabilities and permission setup; blocking remains voluntary and can be bypassed by revoking access.
- **Background timing:** iOS may delay monitor callbacks or notifications. The app does not promise second-perfect background unlocking. Rewards settle when the app next processes the saved deadline.
- **Finish-day timezone:** credit uses the session's deadline and the local timezone at completion reconciliation. If the timezone changes while the app is closed, that timezone is used for the unsettled session. Already recorded day credit stays fixed.
- **Small starter catalog:** six creatures and six decorations. After all creatures are discovered, the four-session hatch cycle repeats.
- **Session lengths:** focus settings range from 15–120 minutes; the minimum accommodates the full build's background monitoring requirement.

There are no purchases, social features, leaderboards, or cloud services in this beta.

## Artwork

In-app pixel sprites are drawn locally in SwiftUI Canvas. The app icon's [source artwork](../branding/focussi-icon-source.png) and [generation prompt](../branding/focussi-icon-prompt.md) are included for reference.
