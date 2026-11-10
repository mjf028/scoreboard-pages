# Scoreboard BLE firmware and iPhone test guide

Open [the BLE sketch](../firmware/scoreboard_ble/scoreboard_ble.ino) in Arduino IDE. Keep it in the matching `scoreboard_ble` folder. This is a separate sketch; do not paste it over the original.

The BLE sketch is based on the [panel bring-up sketch](../firmware/reference/panel_bringup/panel_bringup.ino).

## Preserved hardware and display

Panel: 128 x 64, one panel; ICN2038S driver; clkphase=false; latch_blanking=true; brightness=140. Font FreeSansBold9pt7b. The default PLAYER 2 label is green at baseline 26 and PLAYER 1 is blue at baseline 54. Margins 6; divider y=34.

| HUB75 signal | GPIO |
|---|---:|
| R1 / G1 / B1 | 6 / 36 / 37 |
| R2 / G2 / B2 | 5 / 0 / 35 |
| A / B / C / D / E | 45 / 1 / 48 / 2 / 4 |
| LAT / OE / CLK | 38 / 21 / 47 |

All buttons remain active LOW, INPUT_PULLUP. Actions occur on release; a long press is at least 600 ms. The original 20 ms release debounce remains.

| Button | Short release | Long release |
|---|---|---|
| GPIO12 / P1 / PLAYER 1 (`scorePlayerOne`) | +1 | -1, minimum zero |
| GPIO13 / P2 / PLAYER 2 (`scorePlayerTwo`) | +1 | -1, minimum zero |
| GPIO14 | No score change | Reset both |

GPIO12 controls P1 on the lower row. GPIO13 controls P2 on the upper row.

## BLE protocol

Device name: **Scoreboard**.

| Purpose | UUID | Properties |
|---|---|---|
| Service | `ea180001-7444-4d8e-b83c-3f0c0e473ee1` | Custom service |
| Command | `ea180002-7444-4d8e-b83c-3f0c0e473ee1` | Write with response |
| Score state | `ea180003-7444-4d8e-b83c-3f0c0e473ee1` | Read, Notify; CCCD 0x2902 |
| Saved names | `ea180004-7444-4d8e-b83c-3f0c0e473ee1` | Read, Notify; CCCD 0x2902 |
| Set names | `ea180005-7444-4d8e-b83c-3f0c0e473ee1` | Write with response |

Send one exact, case-sensitive UTF-8/ASCII command per write, without spaces, quotes, NUL, or line endings:

| Command | Hex bytes | Action |
|---|---|---|
| P1+ | 50 31 2B | PLAYER 1 +1 |
| P1- | 50 31 2D | PLAYER 1 -1, minimum zero |
| P2+ | 50 32 2B | PLAYER 2 +1 |
| P2- | 50 32 2D | PLAYER 2 -1, minimum zero |
| RESET | 52 45 53 45 54 | Both zero |

State is exactly 8 binary bytes: unsigned 32-bit little-endian P1, then unsigned 32-bit little-endian P2. Example P1=1, P2=2: `01 00 00 00 02 00 00 00`. This fits the default BLE notification payload without requiring an MTU change. Display state is initialized before advertising and updated after physical button releases and each processed BLE command. Notifications require subscription; use Read for the current state immediately after connecting or reconnecting.

Callbacks validate and enqueue commands into a 32-entry FreeRTOS queue; only loop() changes scores, draws, publishes state, and restarts advertising. It processes up to eight commands per loop pass so physical buttons continue to be polled. Disconnect requests advertising restart after 500 ms without blocking loop(). Scores survive BLE disconnects but reset on power restart, as in the original. Invalid/overflowed commands are ignored and counted in the 115200-baud serial log. A successful GATT Write response confirms receipt, not completed scoring: verify the state. Commands already queued still execute after disconnect. BLE increments guard against signed integer overflow; the original physical button logic is untouched.

## Player names on current firmware

The name characteristics are optional for clients that only use scoring. Names use the same ASCII payload for writes and saved state. Start with version character `1`, then send the bottom/blue P1 name, a literal `|`, and the top/green P2 name. For example, `1PLAYER 1|PLAYER 2`. Each name uses 1–8 uppercase ASCII letters, digits, spaces, or hyphens, with no leading or trailing spaces. The whole packet is at most 18 bytes. Send it as text without quotes or a line ending.

Subscribe to Saved names, read the current pair, then write a new pair to Set names. The firmware saves both labels together in ESP32 Preferences, updates the panel, and publishes the saved pair. A GATT write response confirms receipt. Wait for the matching saved pair to confirm application. Invalid writes leave both names as they were. Wide rows use a compact font so both the label and the score fit. A score reset affects scores only. Power cycling preserves the names and resets scores. [Espressif Preferences API](https://docs.espressif.com/projects/arduino-esp32/en/latest/api/preferences.html)

For a manual test, save `1BLUE-1|GREEN 2` and confirm the lower blue and upper green rows, respectively. Try a malformed packet such as `1|GREEN 2` and read Saved names again to verify the valid pair remains. Disconnect and reconnect, then power-cycle and confirm the same pair. Restore the defaults with `1PLAYER 1|PLAYER 2` if desired. [iPhone test checklist](../ios/ScoreboardController/START-HERE.md#edit-player-names-on-the-panel)

## Arduino setup

Use ESP32S3 Dev Module and the installed Espressif ESP32 core 3.3.7. BLE headers come with that core; no separate NimBLE library is needed. The existing ESP32 HUB75 DMA and Adafruit GFX libraries are used. Keep the same working board, memory, flash, and USB settings as the original project. Select the serial port for your board in Arduino IDE. The sketch logs at 115200 baud.

## nRF Connect on iPhone: exact first test

1. Upload this separate sketch from Arduino IDE and wait for upload completion. Leave the panel powered. Allow nRF Connect Bluetooth access on the iPhone.
2. Open nRF Connect for Mobile, select Scanner, and scan. Find **Scoreboard**, stop scanning, then tap **Connect**. If there are multiple similarly named devices, power this board off/on to identify it.
3. In the connected device's Services view, expand custom service `ea180001-7444-4d8e-b83c-3f0c0e473ee1`. Identify its command characteristic ending `0002` and state characteristic ending `0003` by their complete UUIDs above.
4. On the state characteristic, tap Read (the read/down-arrow control). Select hexadecimal/raw bytes for its value. On a fresh boot it must be `00 00 00 00 00 00 00 00`.
5. Enable notifications using the state characteristic's Notify/subscribe control. Confirm subscription is enabled (CCCD 0x2902 notifications value 01 00). Button icons/labels can vary by app version; operate the control on the state characteristic, not on the command characteristic.
6. On the command characteristic, tap Write (up-arrow control). Choose **Write with response / Request**. Select **UTF-8/Text**, enter `P1+` exactly, and tap Write. If that editor only offers hexadecimal, choose Hex and enter `50312B` instead. Do not send the literal text `50312B` in Text mode.
7. PLAYER 1's bottom score should become 1. The state notification should be `01 00 00 00 00 00 00 00`. Read state again if needed; processing occurs shortly after the write response.
8. Write `P2+` the same way. PLAYER 2's top score should become 1; state: `01 00 00 00 01 00 00 00`.
9. Write `P1-`. PLAYER 1 returns to 0; state: `00 00 00 00 01 00 00 00`. Write `P1-` again: it stays zero.
10. Write `P2-`. Both are now zero. Increment each once, then write `RESET`: both return to zero. Send lowercase `reset`: it must have no effect.
11. Test GPIO12 and GPIO13 separately: short press/release adds one; hold at least 600 ms and release subtracts one. Confirm both display and notifications. Short GPIO14 release does not reset; hold it at least 600 ms and release to reset both.
12. Tap Disconnect. Wait at least one second, scan again, and reconnect to Scoreboard. Read state to confirm scores were retained. Re-enable notifications if necessary, then send another command. If the phone shows old services, disconnect and perform fresh service discovery/reconnect.

Do not send command strings through the iPhone Bluetooth Settings screen; use the writable GATT characteristic inside nRF Connect.

Official nRF Connect feature reference: https://www.nordicsemi.com/Products/Development-tools/nRF-Connect-for-mobile
Official iOS app project: https://github.com/nordicsemi/IOS-nRF-Connect
BLE API reference used: installed Arduino-ESP32 3.3.7 BLE UART example and BLE headers, with upstream example at https://github.com/espressif/arduino-esp32/blob/master/libraries/BLE/examples/UART/UART.ino
