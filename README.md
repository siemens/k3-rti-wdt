RTI Watchdog Firmware for TI K3 SoCs
====================================

This provides the required firmware for the Windowed Watchdog Timer of the
Real Time Interrupt (RTI) modules on the TI AM65x. One use case is the SIMATIC
IOT2050. It should work on the J721E as well, but here the hardware is capable
of issuing a reset on its own.

The watchdog firmware can be loaded via remoteproc into the R5 core 0 of the
MCU island, either by the bootloader (e.g. U-Boot) or the OS kernel (typically
Linux). On expiry of the watchdog, it then triggers a system reset.

During initialization, the firmware establishes some self-protection means. It
locks the R5 core it runs on via TISCI to prevent shutdown via remoteproc. And
it sets the Interconnect Firewall so that external access to the firmware
memory is denied until the next system reset.


Compilation
-----------

Make sure an ARMv7 cross compiler is available in the search path, then just
call `make`.

By default, the firmware supports RTI1 as this is known to work fine on the
AM65x. To build it for RTI0, compile it via `make RTI_MODULE=0`.

By default, the firmware also supports to save watchdog reset cause to RAM at
0xA2200000. To build it for other RAM locations, compile it via
`make PON_REASON_BASE_ADDR=<addr>`. To build without this feature, compile via
`make PON_REASON_BASE_ADDR=-1`.


Usage
-----

Load the firmware binary `k3-rti-wdt.fw` via remoteproc into MCU R5 core 0 of
the system before starting the watchdog.
