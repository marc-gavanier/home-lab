# Hardware

The boards and peripherals the lab runs on.

## Raspberry Pi 4 Model B

| Specification | Value                                                           |
|---------------|-----------------------------------------------------------------|
| Processor     | Broadcom BCM2711, quad-core Cortex-A72 (ARM v8) 64-bit @ 1.5GHz |
| RAM           | 8 GB LPDDR4-3200                                                |
| Storage       | MicroSD + USB 3.0                                               |
| Network       | Gigabit Ethernet, Wi-Fi 802.11ac                                |
| USB           | 2x USB 3.0, 2x USB 2.0                                          |
| Power         | USB-C 5V/3A                                                     |
| GPIO          | 40-pin header                                                   |

## Peripherals

| Component      | Details                         |
|----------------|---------------------------------|
| SD card        | 64 GB (OS + configs)            |
| External HDD   | 5 TB USB 3.0 (data + backups)   |
| Case           | With active fan                 |
| Power supply   | Included with the kit           |
| Ethernet cable | Direct connection to ISP router |

## Important Notes

- **USB power**: power the 5 TB HDD independently if possible, so it does not overload the Pi's USB bus.
- **Cooling**: the active fan is essential; the Cortex-A72 throttles at 80°C.
- **SD card**: use A2 class for IOPS and keep writes low (see [System](../02-system/README.md#sd-write-reduction)).
- **RAM**: this host has 8 GB. The original 4 GB board is now the offsite backup target (ADR-010), so "4 GB" in offsite docs and older ADRs is correct.
