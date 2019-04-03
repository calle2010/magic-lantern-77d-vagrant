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
    This address varies on different models
    - Magiclantern confusingly uses ROMBASEADDR but this is _not_ a base address,
      it is the entrypoint.
    - You can find the base address by looking in ```platform/<model>.<version>/Makefile.platform.default```
      for a line like ```ROMBASEADDR = 0xE0040000``` and mask out the low bits
  - _Important_ Do not run the analyzer yet!
- Right click in the ROM0.BIN listing, select Processor Options and enter ```1``` for TMode.
  This will set the disassembler to Thumb mode by default. It is still possible to disassemble
  ARM (see below). This setting is not persistent. In the next Ghidra session it will be
  default again.
- Add the copied ROMs to their respective base addresses. 
  In the listing for your main ROM, use File -> Add To   Program and use Options to set the 
  correct base address for each new file, eg:
  - ```77D.0x4000.bin``` as ```rom0x4000``` to base address 0x4000 etc
  - ```77D.0x40100000.bin```
  - ```77D.0xDF000000.bin```
  - ```77D.0xDF002800.bin```
  - ```77D.0xDF020000.bin```
  - ```77D.0x40100000.bin``` again as ```rom0x10000``` to base address 0x00100000
    - Addresses in the 0x40000000 region are mirrored to a lower address with a fixed offset,
      so these should be imported twice, one at each offset.
  - more as required if any of the referenced addresses are missing
  - TODO: This should be scripted in Ghidra
- Add ROM1.BIN as
  - ```rom1xF0000000``` at base address 0xF0000000
- In the memory map set the areas loaded at ```0xE0000000``` and ```0xF0000000``` as read-only 
  (remove the write flag).
  This will improve decompilation results.
- You could auto-analyze the file now, but it is very slow and not that reliable 
  (can crash after 8 hours, or never finish)
- Select Edit -> Options for ROM0.BIN
  - In Analyzers section uncheck "Non-Returning Functions - Discovered".
    It seems to be wrong most of the times, breaking the in the decompiler.
  - In Ghidra 9.0 and 9.0.1 this setting can't be saved (Apply button is gray).
    As a workaround, start te auto analyzer with this option disabled, but stop the
    analysis immediately again.
- Select Analysis -> One Shot
  - -> ASCII Strings
  - -> Embedded Media
- After the analysis is done save the project: File -> Save All
- You can now start disassembling

## Basic Ghidra commands

- "D" disassembles at your cursor.  This tries to guess if it's standard ARM or Thumb, and is normally good
- "F12" forces Thumb mode, "F11" forces standard ARM
- You can "Ctrl-Z" to undo your guess
  - So if "D" looks bad, you can undo and try both modes manually
- "C" unsets code to unknown; this is useful if you notice Ghidra has mistakenly disassembled something
  that is not code, eg, an array of pointers, or an ASCII string.  You can select a region then "C"
- "G" jumps to an address or label
- "Ctrl-Alt-U" goes to the next undefined byte; useful if "D" worked on a big block and you want to check
  the end of it
- "Alt-leftarrow" goes backwards in your movement history, "Alt-rightarrow" goes forward

See also the Ghidra cheat sheet at https://ghidra-sre.org/CheatSheet.html

## Start disassembling the bootloader

- Go to address ```0xE0000000```
- Press "L" to enter the label "bootloader" to make it easier to return here (e. g. with GoTo command on key "G")
- Press "F11" or right click and select "Disassemble ARM"

- Go to address ```0x00100000```
- Press "F12" or right click and select "Disassemble Thumb"

## Start disassembling the firmware

- Go to address ```0xE0040000``` (or whatever the entrypoint "ROMBASEADDR" is for your camera)
- Press "L" to enter the label "firmware_entry"
- Press "F12" or right click and select "Disassamble Thumb"
- Ghidra will analyze all referenced code that it can find, so this will take a while.
- Don't forget to save after the analyzer is done.

## Analyzer further stubs
- Find the stubs.S for your camera, and for every address that looks like a code address,
  do G, L (set label to stubs name), D
- eg for 200D, stubs.S has this line:
  - NSTUB(0xE00400FD,  cstart)
  - So G 0xe00400fd, L "cstart", F12
(Todo: script this)

## Find more code areas which haven't been disassembled yet

Many functions will not be found yet. To get better cross-reference results it makes sense to analyze more of the code.

- look for instruction patterns like
  ```
  push {...}
  mov
  ```
  or
  ```
  push {...}
  mov.w
  ```
  etc.
- select one of these occurence
- use "Search for Instruction Patterns" with operands masked
- select all in the list
- right click -> make selection
- in ROM listing window, press F12 to start analyzing all selected places
