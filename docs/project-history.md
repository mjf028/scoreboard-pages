# Project History and Lessons Learned

## Initial concept

The project began as a kid-friendly two-player scoreboard with three goals: physical controls that always work, a bright RGB display, and optional local phone control without depending on cloud services.

The initial hardware plan used an ESP32-S3, HUB75 adapter, 5V power supply and illuminated momentary buttons. The final production hardware is now identified more precisely: a LLidgermal ESP32/HUB75 adapter board, an ADRESUNO 5V 10A 50W power adapter, an SDTC Tech 5.5×2.5 mm panel-mount DC jack, and a Poyiccot panel-mount USB-C extension.

## First panel: P1.53 commercial-signage module

The first purchased panel was an LEDLightsWorld ID-S Series P1.53 module. Recorded project details were:

- 320×160 mm
- 208×104 pixels
- P1.53
- 1/52 scan
- 5V
- SMD1515
- Panel price: $58.95
- Shipping: $19.00

The important lesson was that a HUB75-family connector does not by itself guarantee easy compatibility with common ESP32 HUB75 DMA libraries. The unusual 208×104 geometry and 1/52 scan architecture were much closer to commercial receiving-card signage hardware than the common hobby 1/16 or 1/32-scan panels.

That panel therefore became prototype/sunk cost rather than part of the final scoreboard.

## Successful panel change

The project returned to direct ESP32 drive with a P2 module advertised as a standard HUB75 interface:

- 256×128 mm
- 128×64 pixels
- 1/32 scan
- HUB75/HUB75E
- Chipone 2038S-family driver

This geometry matches the type of panel supported much more naturally by the ESP32 HUB75 DMA library. The original P2 order came to $29.88 for the item and $46.05 delivered.

## Bring-up

Early on, the replacement P2 panel showed bright green horizontal rows while the sketch still used the old 208×104 dimensions. The project switched the configuration to the replacement panel’s 128×64 geometry. The visible rows alone did not identify the correct driver timing or wiring.

The ESP32-S3 was first validated independently, followed by the buttons. Panel bring-up then established the final custom GPIO map and the working display configuration:

```cpp
mxconfig.driver = HUB75_I2S_CFG::ICN2038S;
mxconfig.clkphase = false;
mxconfig.latch_blanking = true;
```

The production brightness is 140/255.

## Control simplification

The original plan considered dedicated + and − controls for each side. The finished design uses only three buttons by distinguishing short and long presses:

- Short player press: +1
- Long player press: −1
- Long reset press: reset both scores

The long-press threshold is 600 ms.

## Physical completion

The electronics were installed behind the matrix in a finished enclosure with top-mounted buttons, side I/O/power access and a removable rear service panel. See the [cabinet gallery](https://scoreboard.digitalmf.net/build.html#enclosure) and [installed wiring photos](https://scoreboard.digitalmf.net/wiring.html#inside). The front and rear photographs are in [`images/final/`](images/final/).

## Bluetooth and iPhone controller

The separate [BLE sketch](../firmware/scoreboard_ble/scoreboard_ble.ino) uses the same display and button wiring. The [iPhone controller](../ios/ScoreboardController/START-HERE.md) reads live scores, sends scoring commands, and can save player names to the panel with current BLE firmware.
