# Software

## Production firmware

The working firmware is stored at:

`firmware/scoreboard/scoreboard.ino`

The original working sketch was cleaned up for the repository so player-specific names exist only in the configuration block. Scoring logic, button names and comments use generic Player One / Player Two terminology.

## User configuration

```cpp
const char* PLAYER_ONE_NAME = "PLAYER 1";
const char* PLAYER_TWO_NAME = "PLAYER 2";
```

The corresponding scores are:

```cpp
int scorePlayerOne = 0;
int scorePlayerTwo = 0;
```

This separation is intentional: the future BLE controller can make the player names runtime values without changing the core scoring logic.

## Display configuration

| Setting | Final value |
|---|---|
| Resolution | 128×64 |
| Panel chain | 1 |
| Driver mode | `ICN2038S` |
| `clkphase` | `false` |
| `latch_blanking` | `true` |
| Brightness | 140 / 255 |
| Font | `FreeSansBold9pt7b` |
| Divider | Y=34 |
| Top row | Player Two, green |
| Bottom row | Player One, blue |

## Button behavior

The three buttons use `INPUT_PULLUP`, so a pressed switch reads LOW.

| GPIO | Logical control | Short press | Long press (≥600 ms) |
|---:|---|---|---|
| 12 | Player One | +1 | −1, floor at 0 |
| 13 | Player Two | +1 | −1, floor at 0 |
| 14 | Reset | No action | Both scores = 0 |

A 20 ms delay after release provides simple debounce.

## Dependencies

The sketch requires:

- ESP32 Arduino core
- `ESP32-HUB75-MatrixPanel-DMA`
- Adafruit GFX font support (`FreeSansBold9pt7b`)

## Tested BLE extension and iPhone controller

The production sketch above is unchanged. BLE is implemented in the separate [`firmware/scoreboard_ble/scoreboard_ble.ino`](../firmware/scoreboard_ble/scoreboard_ble.ino), derived directly from the verified local panel_bringup sketch and tested on the real scoreboard. The production file was subsequently located in this repository and inspected: it uses the same hardware configuration, row layout, brightness, and button behavior, with generic player names/variables.

The user verified all five BLE commands, physical buttons, and reconnection in the original BLE milestone, then verified live scoring in both directions with the native iPhone app. The current BLE sketch and iPhone app also support editing both player names on the panel. The ESP32 stores the pair across power cycles.

See [BLE protocol, GPIO map, and nRF Connect instructions](BLE-FIRMWARE-AND-NRF-CONNECT.md), and [iPhone installation](../ios/ScoreboardController/START-HERE.md).
