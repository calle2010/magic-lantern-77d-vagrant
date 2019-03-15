# Notes about Ghidra

Can Ghidra be used as an alternative to IDA?

## Installation

Download from https://ghidra-sre.org

Install it on the host machine. Java 11 is required.

Change MAXMEM setting in ghidraRun command (shell script or .bat) to 4G or more.
2GB (default on 8GB machine) can result in OutOfMemory errors.

## Get the ROM files

Follow the instructions here https://www.magiclantern.fm/forum/index.php?topic=6785.msg187436#msg187436
to create the copied ROM files:

```./run_canon_fw.sh 77D,firmware="boot=0" -d romcpy```

Stop the emulator with Ctrl-C. A file ```77D/romcpy.sh``` will be created
which can be used to create the copies of the ROM0.BIN file.

## Start Ghirda and create first project

- Execute ```ghidrarun```
- Create new project "77D"
- Run the CodeBrowser tool
- Import ROM0.BIN
  - Format is "RAW Binary"
  - Select language "ARM v7 little endian", and compiler "default"
  - In options enter name ```rom0``` and base address ```0xe0000000```
  - _Important_ Do not run the analyzer yet!
- Right click in the ROM0.BIN listing, select Processor Options and enter ```1``` for TMode.
  This will set the disassembler to Thumb mode by default. It is still possible to disassemble
  ARM (see below). This setting is not persistent. In the next Ghidra session it will be
  default again.
- Add the copied ROMs to their respective base addresses:
  - ```77D.0x4000.bin``` as ```rom0x4000``` to base address 0x4000 etc
  - ```77D.0x40100000.bin```
  - ```77D.0xDF000000.bin```
  - ```77D.0xDF002800.bin```
  - ```77D.0xDF020000.bin```
  - ```77D.0x40100000.bin``` as ```rom0x10000``` to base address 0x00100000
    (cached mirrof access of 0x40100000)
  - more as required if any of the referenced addresses are missing
  - TODO: can this be scripted in Ghidra?
- Add ROM1.BIN as
  - ```rom1xF0000000``` at base address 0xF0000000
- Do not auto analyze any of the files!
- Select Analysis -> One Shot
  - -> ASCII Strings
  - -> Embdedded Media
- After the analysis is done save the project: File -> Save All

## Start disassembling the bootloader

- Go to address ```0xE0000000```
- Press "L" to enter the label "bootloader" to make it easier to return here (e. g. with GoTo command on key "G")
- Press "F11" or right click and select "Disassemble ARM"

- Go to address ```0x40100000```
- Press "F12" or right click and select "Disassemble Thumb"

- Go to address ```0x00100000```
- Press "F12" or right click and select "Disassemble Thumb"

## Start disassembling the firmware

- Go to address ```0xE0040000```
- Press "L" to enther the label "firmware"
- Press "F12" or right click and select "Disassamble Thumb"
- Ghidra will analyze all referenced code that it can find, so this will take a while.
