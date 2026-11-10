# Final Wiring

## Buttons

The three momentary switches use the ESP32's internal pull-ups. Each switch closes its GPIO to ground when pressed.

| Control | GPIO | Input mode |
|---|---:|---|
| Player One | 12 | `INPUT_PULLUP` |
| Player Two | 13 | `INPUT_PULLUP` |
| Reset | 14 | `INPUT_PULLUP` |

```text
GPIO 12 ---- Player One switch ---- GND
GPIO 13 ---- Player Two switch ---- GND
GPIO 14 ---- Reset switch --------- GND
```

The illuminated button wiring uses the 5V/GND power rails separately from the switch contacts.

## HUB75 signal map

This is the explicit pin map used by the working firmware and should be treated as the source of truth for this build.

| HUB75 signal | ESP32-S3 GPIO |
|---|---:|
| R1 | 6 |
| G1 | 36 |
| B1 | 37 |
| R2 | 5 |
| G2 | 0 |
| B2 | 35 |
| A | 45 |
| B | 1 |
| C | 48 |
| D | 2 |
| E | 4 |
| LAT | 38 |
| OE | 21 |
| CLK | 47 |

The E address line is used because the final 64-pixel-high panel is a 1/32-scan HUB75/HUB75E module.

## Power

The display is a 5V load. The completed build routes power through the HUB75 adapter/power wiring and maintains a common ground between the ESP32 controller and matrix panel.

General rules retained from bring-up:

- Verify polarity before applying power.
- Keep the HUB75 ribbon disconnected while changing wiring.
- Do not hot-plug the HUB75 ribbon under power.
- Use adequately sized wiring for the panel's 5V current.

## Production power hardware

The completed scoreboard uses the following identified power/service components:

- **ADRESUNO 5V 10A 50W AC/DC adapter** — [Amazon B0D76F4W1C](https://www.amazon.com/dp/B0D76F4W1C)
- **SDTC Tech 5.5×2.5 mm 10A threaded panel-mount DC jack** — [Amazon B0B6FFN4V5](https://www.amazon.com/dp/B0B6FFN4V5)
- **LLidgermal ESP32/HUB75 adapter board** — [Amazon B0FVNMRRTB](https://www.amazon.com/dp/B0FVNMRRTB)
- **Poyiccot panel-mount USB-C extension** — [Amazon B086YBP5VW](https://www.amazon.com/dp/B086YBP5VW)

The 5V adapter feeds the enclosure through the panel-mount DC jack. The HUB75 adapter provides the physical interface/power-routing point for the ESP32-S3 and matrix. All logic and panel power share a common ground. The USB-C extension is for programming/service access; it is not documented as the primary matrix power source.
