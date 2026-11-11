# Bill of Materials and Project Cost

This is the hardware record for the completed scoreboard. Where an exact purchase price has not been recovered, the BOM identifies the item but does not invent a paid price. Amazon links use the product ASIN so the exact purchased/listed component can be found again even if the listing title changes.

## Final-build components

| Item | Product / specification | Qty used | Purchase reference | Documented price | Role / notes |
|---|---|---:|---|---:|---|
| RGB matrix panel | P2 indoor RGB HUB75/HUB75E, 256×128 mm, 128×64, 1/32 scan, SMD1515, Chipone 2038S-family driver | 1 | Original order | $29.88 item / $46.05 delivered | Production display |
| ESP32 controller | ESP32-S3-DevKitC-1 N16R8, 16 MB flash / 8 MB PSRAM | 1 | ESP32-S3 purchase | ≈$19 | Main controller; provides Wi-Fi/BLE capability for future expansion |
| HUB75 adapter | LLidgermal **ESP32 LED Matrix Adapter Board with Dual Power Input & HUB75 Interface** | 1 | [Amazon B0FVNMRRTB](https://www.amazon.com/dp/B0FVNMRRTB) | $24.80 Amazon listing / $26.78 with 8% tax | Connects the ESP32-S3 to the HUB75 panel and provides convenient power distribution; listing supports ESP32/ESP32-S3 |
| Production power supply | ADRESUNO **5V 10A 50W AC/DC power supply** | 1 | [Amazon B0D76F4W1C](https://www.amazon.com/dp/B0D76F4W1C) | $19.99 Amazon listing / $21.59 with 8% tax | **Final production PSU**; 100–240V AC input, regulated 5V DC / 10A output |
| Panel-mount DC connector | SDTC Tech **5.5×2.5 mm 10A threaded female DC power jack + male pigtail kit** | 1 set/component used | [Amazon B0B6FFN4V5](https://www.amazon.com/dp/B0B6FFN4V5) | $8.99 Amazon purchase price for three-set kit / $9.71 with 8% tax | Brings the 5V supply connection cleanly through the enclosure |
| Panel-mount USB-C extension | Poyiccot **USB 3.1 Type-C panel-mount extension cable**, 1 ft, male-to-female, 10 Gbps / 60W | 1 | [Amazon B086YBP5VW](https://www.amazon.com/dp/B086YBP5VW) | $9.89 Amazon listing / $10.68 with 8% tax | External USB-C access for programming/service without opening the enclosure |
| Decorative corner protectors | uxcell **Decorative Box Corner Cover / Metal Edge Guard with screws**, gold | 4 | [Amazon B0DBG9KCJX](https://www.amazon.com/dp/B0DBG9KCJX) | $9.89 Amazon listing / $10.68 with 8% tax (returned 33 mm selection) | Brass/gold-tone enclosure corner protection. Check the size against your enclosure. |
| Illuminated momentary buttons | 12 mm illuminated momentary push buttons | 3 | Button set | ≈$8/set | Player One, Player Two and Reset controls |
| Enclosure | Custom wood box / frame | 1 | Fabricated for project | Not recovered | Supports the panel, controls and electronics |
| Exterior finish | Mojotone Fender Style Smooth Brown Vinyl Tolex, 54″ × 36″ cut, item 7311003 | 1 cut | [Mojotone](https://mojotone.com/products/fender-style-smooth-brown-vinyl-tolex-54-width?variant=41689733595232) | $22.05 item + $9.95 shipping = $32.00 delivered | Cabinet wrap |
| Wiring / assembly hardware | Wire, HUB75 ribbon, connectors, fasteners, adhesive and miscellaneous consumables | — | Various | Not recovered | Internal assembly |

## Known production hardware

The production power path is no longer an unknown: the finished scoreboard uses the **ADRESUNO 5V 10A 50W supply (ASIN B0D76F4W1C)**. The enclosure also uses the **SDTC Tech 5.5×2.5 mm panel-mount DC connector**, while the **Poyiccot panel-mount USB-C extension** provides service/programming access. The ESP32-S3 connects to the matrix through the **LLidgermal HUB75 adapter board**.

The build estimate applies 8% sales tax to Amazon lines, rounded to the nearest cent per line. The panel and Tolex use their delivered costs. The partial estimate is **$173.81**, including **$5.09** Amazon tax and excluding the returned corner-protector selection. Listing figures are budget references.

The final P2 panel order was $29.88 for the item, $20.68 shipping, −$20.00 shipping discount, $10.59 import charges, and $4.90 sales tax, for a **$46.05 delivered cost**.

## Prototype / sunk cost

| Item | Cost | Outcome |
|---|---:|---|
| Original P1.53 LED panel | $58.95 | Not used in final scoreboard |
| Shipping for P1.53 panel | $19.00 | Original panel shipment |
| **P1.53 prototype subtotal** | **$77.95** | Sunk/prototype cost |

## Original acquisition estimate

Before the panel architecture changed, the project notes contained this estimate:

| Item | Approx. cost at the time |
|---|---:|
| P1.53 panel | $58.95 |
| Panel shipping | $19.00 |
| ESP32-S3 | ~$19 |
| HUB75 adapter | ~$18 initial estimate |
| 5V 10A power supply | ~$20 initial estimate |
| Button set | ~$8 |
| **Estimated initial total** | **~$142–145** |

This table is retained only as historical planning context. It is **not** the final reproduction cost: the P1.53 panel was replaced, and the exact final HUB75 adapter and production PSU are now identified above.

## Purchase records still worth recovering

To turn the BOM into an exact project-cost ledger, the remaining useful order details are:

1. Installed corner protector size and purchase price
2. Actual paid prices for the ESP32-S3, LLidgermal adapter, ADRESUNO PSU, USB-C extension, and button set
3. Cabinet wood, adhesive, and fastener costs
4. Miscellaneous connectors, wire and fasteners if consumables are to be included

The component identities are now documented; only the missing historical paid amounts prevent an exact final-build total.
