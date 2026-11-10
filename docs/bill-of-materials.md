# Bill of Materials and Project Cost

This is the hardware record for the completed scoreboard. Where an exact purchase price has not been recovered, the BOM identifies the item but does not invent a paid price. Amazon links use the product ASIN so the exact purchased/listed component can be found again even if the listing title changes.

## Final-build components

| Item | Product / specification | Qty used | Purchase reference | Documented price | Role / notes |
|---|---|---:|---|---:|---|
| RGB matrix panel | P2 indoor RGB HUB75/HUB75E, 256×128 mm, 128×64, 1/32 scan, SMD1515, Chipone 2038S-family driver | 1 | Final P2 panel listing | Not recovered | Production display |
| ESP32 controller | ESP32-S3-DevKitC-1 N16R8, 16 MB flash / 8 MB PSRAM | 1 | ESP32-S3 purchase | ≈$19 | Main controller; provides Wi-Fi/BLE capability for future expansion |
| HUB75 adapter | LLidgermal **ESP32 LED Matrix Adapter Board with Dual Power Input & HUB75 Interface** | 1 | [Amazon B0FVNMRRTB](https://www.amazon.com/dp/B0FVNMRRTB) | $24.80 current listing shown in project record | Connects the ESP32-S3 to the HUB75 panel and provides convenient power distribution; listing supports ESP32/ESP32-S3 |
| Production power supply | ADRESUNO **5V 10A 50W AC/DC power supply** | 1 | [Amazon B0D76F4W1C](https://www.amazon.com/dp/B0D76F4W1C) | Not recovered | **Final production PSU**; 100–240V AC input, regulated 5V DC / 10A output |
| Panel-mount DC connector | SDTC Tech **5.5×2.5 mm 10A threaded female DC power jack + male pigtail kit** | 1 set/component used | [Amazon B0B6FFN4V5](https://www.amazon.com/dp/B0B6FFN4V5) | Not recovered | Brings the 5V supply connection cleanly through the enclosure |
| Panel-mount USB-C extension | Poyiccot **USB 3.1 Type-C panel-mount extension cable**, 1 ft, male-to-female, 10 Gbps / 60W | 1 | [Amazon B086YBP5VW](https://www.amazon.com/dp/B086YBP5VW) | Not recovered | External USB-C access for programming/service without opening the enclosure |
| Decorative corner protectors | uxcell **Decorative Box Corner Cover / Metal Edge Guard with screws**, gold | 4 | [Amazon B0DBG9KCJX](https://www.amazon.com/dp/B0DBG9KCJX) | $9.89 current listing shown in project record | Brass/gold-tone enclosure corner protection. Check the size against your enclosure. |
| Illuminated momentary buttons | 12 mm illuminated momentary push buttons | 3 | Button set | ≈$8/set | Player One, Player Two and Reset controls |
| Enclosure | Custom wood box / frame | 1 | Fabricated for project | Not recovered | Supports the panel, controls and electronics |
| Exterior finish | Brown textured enclosure covering/finish | — | Build material | Not recovered | Final exterior finish |
| Wiring / assembly hardware | Wire, HUB75 ribbon, connectors, fasteners, adhesive and miscellaneous consumables | — | Various | Not recovered | Internal assembly |

## Known production hardware

The production power path is no longer an unknown: the finished scoreboard uses the **ADRESUNO 5V 10A 50W supply (ASIN B0D76F4W1C)**. The enclosure also uses the **SDTC Tech 5.5×2.5 mm panel-mount DC connector**, while the **Poyiccot panel-mount USB-C extension** provides service/programming access. The ESP32-S3 connects to the matrix through the **LLidgermal HUB75 adapter board**.

The exact *paid* prices for several of these items are still not present in the project records, so they are intentionally left as `Not recovered`. A current/listing price is only shown where a supplied project screenshot recorded it; it should not be interpreted as the historical purchase price.

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

1. Final P2 128×64 panel purchase price and shipping
2. Actual paid prices for the ESP32-S3, LLidgermal adapter, ADRESUNO PSU, DC jack, USB-C extension, corner protectors and button set
3. Enclosure wood/material and exterior finish cost
4. Miscellaneous connectors, wire and fasteners if consumables are to be included

The component identities are now documented; only the missing historical paid amounts prevent an exact final-build total.
