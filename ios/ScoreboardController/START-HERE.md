# Scoreboard — iPhone controller

A native SwiftUI app for the ESP32-S3 BLE firmware already tested on your panel. Requires iOS 16 or later. Scoring also works with the earlier BLE sketch. Editing panel names requires the current BLE sketch. The app has no third-party packages.

By default, PLAYER 2 appears first in green and PLAYER 1 appears below in blue, matching the panel. Each player has large minus and plus buttons. Scores come from the panel, including changes from the physical buttons. Reset asks for confirmation.

See the [iOS bring-up history](IOS-BRINGUP.md) for the original upload, Bluetooth tests, signing and trust troubleshooting, and the working iPhone screenshots.

## Install using your Mac

1. Transfer this entire extracted `ScoreboardController` folder to your Mac. Open `ScoreboardController.xcodeproj` in Xcode. Use a current Xcode version that supports your iPhone's iOS version.
2. In Xcode Settings → Apple Accounts (called Accounts in some versions), add your Apple Account if needed.
3. Select the blue project icon in Xcode's left sidebar. Under TARGETS, select **ScoreboardController**. Open **Signing & Capabilities**, leave **Automatically manage signing** checked, and choose your Team. A personal team can be used for testing on your own phone; Xcode may require you to renew the installation later. If Xcode says the bundle identifier is unavailable, replace `org.example.ScoreboardController` with a unique identifier such as `com.yourname.ScoreboardController`.
4. Plug your iPhone into the Mac, unlock it, and accept Trust prompts. If Xcode requests Developer Mode, enable it in iPhone Settings → Privacy & Security → Developer Mode, restart, and confirm it.
5. Choose **ScoreboardController** as the scheme and your physical iPhone as the run destination at the top of Xcode. Click the triangular **Run** button. Let Xcode finish building and installing. If iOS asks you to trust your developer identity, follow the device's instructions in Settings → General → VPN & Device Management.
6. When Scoreboard opens, allow Bluetooth access. Keep the panel powered and nearby. In nRF Connect, disconnect from Scoreboard so it is available to this app.
7. Tap **Find scoreboard**, then **Connect** beside the detected scoreboard. Once the status says **Connected · Live scores**, the scoring controls become available.

There is no App Store or TestFlight installation in this package. It contains source and an Xcode project, not a signed IPA. Xcode's simulator can show the screen and run protocol tests; a real iPhone is required for the panel connection.

## First on-panel test

- Confirm both rows show the same scores as the panel before pressing anything.
- Tap + and − in the top card and verify the top panel row follows. Repeat for the bottom card and row.
- Press each physical scoring button: the app should update without tapping refresh.
- Tap Reset both scores, choose Cancel, and verify scores remain. Repeat and confirm Reset; both scores should become zero.
- Tap Disconnect: score values become dashes and controls disable. Find and connect again: current panel scores should return.
- Turn the panel off while connected, then back on within about 20 seconds. The app should reconnect to the same panel. If discovery times out, use Find scoreboard again.
- Tap +, immediately switch to another app, and return. Confirm the controller refreshes the score, then try a second score change to verify the buttons are available again. This release is for use with the app in the foreground; it does not request background Bluetooth operation.
- Try a large text setting and VoiceOver. Controls have player-specific spoken labels and at least 80-point-tall scoring buttons; the screen scrolls on small phones.

If you have multiple Scoreboard devices nearby, the picker shows a short device identifier. Power the intended board off/on to identify it before connecting.

## Edit player names on the panel

1. Upload the current [BLE sketch](../../firmware/scoreboard_ble/scoreboard_ble.ino) to the ESP32-S3 with your working board and port settings. Build and run the updated iPhone app from Xcode.
2. Connect to the scoreboard and tap **Edit player names**. The editor shows the green top row first and the blue bottom row second.
3. Enter 1–8 letters (A–Z), digits, spaces, or hyphens per name and tap **Save**. The app trims surrounding whitespace and sends uppercase names. Wait for the updated labels on the phone and panel. If a save cannot be confirmed, check the panel and reconnect before retrying.
4. Press each physical score button and each app plus/minus control. Verify the corresponding row on both screens. Reset should clear only the scores. Disconnect and reconnect, then power-cycle the panel and reconnect. The names should survive both. The scores should return to zero after a panel power cycle.

If **Edit player names** is unavailable, confirm the new BLE sketch was uploaded and reconnect to the board. The app reports a separate error if it cannot read the names or subscribe to their updates. With the older firmware, scoring still works and the app shows the default labels.

## Troubleshooting

**No scoreboard found:** verify the panel is powered and nearby; disconnect nRF Connect or another phone; retry Find scoreboard. On the iPhone, check Bluetooth and the Scoreboard app's Bluetooth permission.

**Connection needs attention:** the inline message explains the failure. Reconnect. If a command was interrupted, inspect the panel before repeating it: the app never automatically replays scoring commands.

**A signing error in Xcode:** select your Team and a unique bundle identifier. Physical-device unit tests also need the ScoreboardControllerTests target assigned to the same Team; simulator tests do not require a team.

## Implementation and verified protocol

- Service: `ea180001-7444-4d8e-b83c-3f0c0e473ee1`
- Write-with-response command: `ea180002-7444-4d8e-b83c-3f0c0e473ee1`
- Read/notify score state: `ea180003-7444-4d8e-b83c-3f0c0e473ee1`
- PLAYER 1 +/− sends exactly `P1+` / `P1-`; PLAYER 2 +/− sends `P2+` / `P2-`; reset sends `RESET`. No terminators are appended.
- Score state is exactly eight bytes: unsigned little-endian uint32 PLAYER 1, then uint32 PLAYER 2. Parsing uses explicit byte shifts, with no alignment assumptions.
- Discovery filters by the scoreboard service. The user chooses a device; unexpected disconnection searches for that same identifier. Explicit Disconnect stops reconnection.
- Controls require successful characteristic discovery, enabled notifications, and a valid state packet. Old scores are cleared on disconnection and refreshed when returning to the foreground.
- Writes use GATT responses, allow one outstanding write, and include a short cooldown plus a follow-up read. UI scores are never changed optimistically. The firmware does not provide application-level command acknowledgments; receipt of a GATT write is not proof that the score was applied. Observe the live score/panel.
- Connection, service discovery, and write timeouts expose recoverable messages. Commands are never queued for reconnection. Reset is sent once after confirmation.
- Bluetooth callbacks run on the main queue. No location access, account, server, or internet connection is used. This app uses the existing firmware's BLE access behavior.

## Validation and Mac checks

Build and test on a Mac, then verify the Home Screen icon and repeat the on-panel checks above.

The included XCTest cases cover score decoding, exact score commands, and valid and malformed player-name packets. Run them on the Mac with Product → Test using an installed iPhone simulator. Use the device checklist above to verify the new firmware and app together.

Optional Terminal build check, run inside this folder:

```sh
xcodebuild -project ScoreboardController.xcodeproj -scheme ScoreboardController -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

To run tests from Terminal, first list simulator destinations:

```sh
xcodebuild -project ScoreboardController.xcodeproj -scheme ScoreboardController -showdestinations
```

Then use an available simulator's ID:

```sh
xcodebuild -project ScoreboardController.xcodeproj -scheme ScoreboardController -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' CODE_SIGNING_ALLOWED=NO test
```

Apple references: [Run an app on a device](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices), [Core Bluetooth](https://developer.apple.com/documentation/corebluetooth), [Characteristic notifications](https://developer.apple.com/documentation/corebluetooth/cbperipheral/setnotifyvalue(_:for:)), [Write characteristic values](https://developer.apple.com/documentation/corebluetooth/cbperipheral/writevalue(_:for:type:)).
