# Miscellaneous notes on Majora's Mask

for brevity, all addresses written here are given for the original US version.
refer to the spreadsheets or Lua tables for their equivalent in other versions.

## save files

save contents are mostly documented by [the save file binary templates.][savebt]

[savebt]: //github.com/EntranceJew/zelda-binary-templates/tree/master/filetypes/Save

*note: the following text is specific to MM; OoT is slightly different.*

in the versions of the game with owl saves,
regular saves are 0x100C in size, and owl saves are 0x3CA0.
owls use the extra space primarily to store the pictograph picture.

the game checks a checksum, and for the text "ZELDA3".
each slot has one backup copy of itself, though they don't seem to be used?
if a slot is corrupted, it will show up as empty in the menu.

the checksum is a 16-bit sum of all bytes up to that point, allowing overflows.
i've written [a checksum-fixing program][chksum] in Python for Bizhawk savefiles.
i've also written an [010][010] Editor [script][chksum2]
and its [OoT variant][chksumOoT]
for properly formed save files, such as those made by nemu64.

owl saves always have 0x24 added to their checksum for some reason.

[chksum]: /chksum.py
[chksum2]: //github.com/EntranceJew/zelda-binary-templates/blob/master/scripts/FixSaveMM.1sc
[chksumOoT]: //github.com/EntranceJew/zelda-binary-templates/blob/master/scripts/FixSaveOoT.1sc
[010]: http://www.sweetscape.com/010editor/

bizhawk save files, at the time of writing, have the first file offset to 0x20800.
also, their byte order is wrong.

here's my usual process (in bash) for hacking on save files:
```
alias revend='objcopy -I binary -O binary --reverse-bytes=4'
s="Legend of Zelda, The - Majora's Mask (USA).SaveRAM"
x=mm-save.xxd
revend "$s"
xxd "$s" > $x
$EDITOR $x
xxd -r $x > "$s"
./chksum.py $s
revend "$s"
```

## MM Save Files

because no one likes first cycle.

sometime i'll bother checking what the bombers/lottery codes are for these.

* [Bizhawk US 1.0 race file](//eaguru.guru/t/MM%20US%20Race%20File%20for%20Bizhawk.zip )
* [mupen64plus US 1.0 race file](//eaguru.guru/t/Legend%20of%20Zelda%2C%20The%20-%20Majora%27s%20Mask%20%28U%29%20%5B%21%5D.zip)

you can make your own by using [the provided setup race file script.][racelua]
simply run the script and play Song of Time after South Clock Town has loaded.

using this script will also set the bombers code to 12345,
set the daily lottery numbers to 123, 456, 789,
and set the Oceanside Spider House puzzle solution to
Red, Blue, Red, Blue, Red, Blue.

[racelua]: /Lua/setup%20race%20file.lua

## bitfields

### scene flags

two regions of 0x960 bytes are allocated for all the scene flags in the game.
the first at `801EFAE0` is loaded from save files,
the second at `801F35D8` is used for in-game changes.
basically, edit the first for save hacking, and the second for in-game hacking.

each scene in the game uses 0x14 bytes of scene flags.
this implies there's 0x78 possible scenes: 0x78\*0x14 = 0x960.

the current scene's flags are always copied into the same place in memory.
they appear in a different order than in save files, however.

(four bytes each)  
`803E8978` corresponds to offset 0x04 in the save file.  
`803E897C` corresponds to offset 0x08.  
`803E8988` corresponds to offset 0x00.  
`803E898C` corresponds to offset 0x0C.  
`803E8994` corresponds to offset 0x10.  

### Link's status

here's [an incomplete document on some of Link's bitfields][linkfields] for JP 1.0.

[linkfields]: /mm-bitflags.txt 
