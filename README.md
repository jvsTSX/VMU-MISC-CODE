# TEST PROGRAMS

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
