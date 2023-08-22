# ASSEMBLING
use [waterbear](https://github.com/wtetzner/waterbear) for assembling, make sure SFR.I is on the same folder as the sources

NOTE: SFR.I IS NOT MADE BY ME, IT'S ONLY INCUDED FOR THE SAKE OF CONVENIENCE, IT'S ORIGINALLY TAKEN FROM [THIS REPO](https://github.com/jahan-addison/snake)

waterbear usage on your favourite Command Line program:
`waterbear assemble program.s -o program.vms`

# TEST PROGRAMS LIST

## SPEEDTEST
program used for checking whether the 6MHz Ceramic clock can be used in handheld mode and how it affects the sound timer

controls:
- A: apply speed
- MODE: go back to BIOS
- Dpad Left/Right: select clock rate

Clock modes:
```text
1 - Quartz with /12 div   (2KHz)
2 - Quartz with /6 div    (5KHz)
3 - RC with /12 div       (66KHz)
4 - RC with /6 div        (133KHz)
5 - Ceramic with /12 div  (500KHz)
6 - Ceramic with /6 div   (1MHz)
```

WARNING: THIS PROGRAM WILL RAPIDLY DRAIN YOUR VMU'S BATTERY!
MAKE SURE TO EITHER USE AN AA BATTERY ADAPTOR OR USE RECHARGEABLE CR2032 BATTERIES (LIR or ML)

## SOUND3_TEST
program used for checking the Timer 1 Mode 3 audio output characteristics

controls:
- Dpad Up/Down: adjust upper nibble of selected value
- Dpad Left/Right: adjust lower nibble of selected value
- A: select next value (wraps back to 0)
- B: apply values
- SLEEP: cycle between Timer 1 RUN settings
- MODE: go back to BIOS

Timer 1 RUN settings:
```
1 - both halves are off
2 - only low half is on
3 - only high half is on
4 - both halves are on
```

List of values on-screen:
```
T1HR - frequency parameter of upper timer half
T1HC - duty parameter of upper timer half
T1LR - frequency parameter of lower timer half
T1LC - duty parameter of lower timer half
```

WARNING: THIS PROGRAM WILL RAPIDLY DRAIN YOUR VMU'S BATTERY!
MAKE SURE TO EITHER USE AN AA BATTERY ADAPTOR OR USE RECHARGEABLE CR2032 BATTERIES (LIR or ML)

## EXT_REGISTER_TST
program for checking EXT register behaviour

controls:
```
Dpad up/down: increment or decrement selected address nibble
Dpad left/right: select address nibble
A and B: select EXT bit
MODE: go back to BIOS
SLEEP: flip selected EXT bit
```

on startup there should be a string saying "`THIS' FLASH `" on the very top of the screen, according to the datasheet, referencing the internal BIOS ROM using the LDC instruction should be possible, if this is correct the string should show something different under the same address

# MISC PROGRAMS LIST

## HELLOWORLD
a simple, typed "Hello, world!" on your dreamcast VMU using the font engine from the EXT test program, just press MODE to exit back to the BIOS
