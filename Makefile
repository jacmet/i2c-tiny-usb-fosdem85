# Name: Makefile
# Project: USB I2C
# Author: Christian Starkjohann, modified for I2C USB by Till Harbaum
# Creation Date: 2005-03-20
# Tabsize: 4
# Copyright: (c) 2005 by OBJECTIVE DEVELOPMENT Software GmbH
# License: Proprietary, free under certain conditions. See Documentation.
# This Revision: $Id: Makefile-avrusb.tiny45,v 1.3 2007/06/07 13:53:47 harbaum Exp $

# DEFINES += -DDEBUG
# DEFINES += -DDEBUG_LEVEL=1
DEFINES += -DF_CPU=16500000
COMPILE = avr-gcc -Wall -O2 -Iusbdrv -I. -mmcu=attiny85 $(DEFINES)

OBJECTS = usbdrv/usbdrv.o usbdrv/usbdrvasm.o usbdrv/oddebug.o main.o

# symbolic targets:
all:	firmware.hex

.c.o:
	$(COMPILE) -c $< -o $@

.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

.c.s:
	$(COMPILE) -S $< -o $@

# Fuse high byte:
# 0x5f = 0 1 0 1   1 1 1 1 <-- BODLEVEL0 (Brown out trigger level bit 0)
#        ^ ^ ^ ^   ^ ^ ^------ BODLEVEL1 (Brown out trigger level bit 1)
#        | | | |   | +-------- BODLEVEL2 (Brown out trigger level bit 2)
#        | | | |   + --------- EESAVE (don't preserve EEPROM over chip erase)
#        | | | +-------------- WDTON (WDT not always on)
#        | | +---------------- SPIEN (allow serial programming)
#        | +------------------ DWEN (ebug wire is enabled)
#        +-------------------- RSTDISBL (reset pin is disabled)
# Fuse low byte:
# 0xdf = 1 1 0 1   1 1 1 1
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL 3..0 (external >8M crystal)
#        | |  +--------------- SUT 1..0 (crystal osc, BOD enabled)
#        | +------------------ CKOUT (clock output enable)
#        +-------------------- CKDIV8 (divide clock by eight disabled)

clean:
	rm -f firmware.lst firmware.obj firmware.cof firmware.list firmware.map *.bin *.o */*.o *~ */*~ firmware.s usbdrv/oddebug.s usbdrv/usbdrv.s 

# file targets:
firmware.bin:	$(OBJECTS)
	$(COMPILE) -o firmware.bin $(OBJECTS)

firmware.hex:	firmware.bin
	rm -f firmware.hex firmware.eep.hex
	avr-objcopy -j .text -j .data -O ihex firmware.bin firmware.hex
	./checksize firmware.bin 4096 196
# do the checksize script as our last action to allow successful compilation
# on Windows with WinAVR where the Unix commands will fail.

program: firmware.hex
	micronucleus --run firmware.hex

disasm:	firmware.bin
	avr-objdump -d firmware.bin

cpp:
	$(COMPILE) -E main.c