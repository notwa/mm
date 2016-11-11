# Zelda 64 Resources

i like to muck around in the memory of these games.

those who are more interested in the ROM may find [the binary template repo][bt]
more resourceful.

there is also a great deal of general [documentation and notes
on the wikis][cm] hosted at CloudModding.

[bt]: //github.com/EntranceJew/zelda-binary-templates
[cm]: http://cloudmodding.com/wiki

## Lua Scripts

this repo contains a ton of Lua scripts
written for [the latest version of Bizhawk.][bizhawk]
all the scripts you'll want to use are in the root Lua directory,
and their dependencies are in further subdirectories.
that means, if you want to use a script,
you **must** preserve the directory structure.
you **cannot,** say, extract one file from [this repo's archive][arch]
and expect it to work.
[bizhawk]: //github.com/tasvideos/bizhawk
[arch]: //github.com/notwa/mm/archive/master.zip

a summary of each script is available in [the Lua README.md file,][luarm]
and another for [the library files][librm] that the scripts use.

[luarm]: /Lua/README.md
[librm]: /Lua/lib/README.md

of these, you probably came for `cheat menu.lua`.
this script will bind your L button to open an on-screen menu
allowing you to control many aspects of the game.

![cheat menu.lua in action](/img/M_US10.2016-10-02%2019.02.17.png)

of immediate interest are the classic levitation and run-fast cheats,
but also the menu of warps to any area and any entrance in the game.
you can also change your Z-Targeting method to Hold in the 2nd
page of the Progress menu, in case you forgot to change it in-game.

## Assembly Hacks

i have written a handful of ROM and RAM hacks for Majora's Mask and Ocarina of Time.
these have all been written in the custom assembler syntax of
[_lips,_ a MIPS assembler written in Lua.][lips]
_lips_ is included in this repository; you do not need to acquire it separately.
[lips]: //github.com/notwa/lips

you only need to run `Lua/inject.lua` in Bizhawk
to run the *RAM hacks* — that is, modifications that act
directly on the game's RAM while it runs; not modifying the ROM.

for the *ROM hacks,* you will need to set up a lot more.
you will need:

* **bash 4.3** to run the shell scripts responsible for
  automatically running all the following software.

* **Python 3.4** to run the scripts responsible for
  splitting the ROM into files, and merging those files into a single ROM again.

* **LuaJIT 2.0** to run the *lips* assembler responsible for
  turning the assembly files into executable binary code.
  you might manage to use the *Lua 5.1* interpreter,
  but this is not strictly supported.

* **gcc 4.9** *or* **clang 3.6** to compile the programs responsible for
  (de)compressing the *Yaz* archive files, and for computing checksums.

the versions listed above are rough estimates, and newer versions of software
are likely to work fine.

if you're on Windows, and you're not afraid of the (\*nix) console,
you can set up [cygwin](//cygwin.com)
to install binaries of bash, python, and gcc.
then all that's left is to compile LuaJIT yourself.

last, but not least, you will need the approriate ROM for the ROM hack.
you will probably need to change the hard-coded paths to the ROMs.
*(note to self: change scripts to take the required ROM as their first argument)*

finally, you just run the appropriate shell scripts
for the ROM hacks you want to produce. for example:
```
$ cd asm
$ ./mm-bq
zelda@srd44
00-07-31 17:04:16
uncompressed 0031 V00B3C000
ratio: 59%
compressed 0031 V00B3C000
ratio: 59%
compressed 1552 V02EE7040
ratio: 1%
bootcode: 6105
crcs: 5CF5359C A893E696
```

### blah

to compile the C programs, you might need to pass `-std=gnu11`. basically:
```
gcc -std=gnu11 -Wall -Ofast z64yaz0.c -o z64yaz0
gcc -std=gnu11 -Wall -Ofast z64crc.c -o z64crc
```

in the future, it'd be nice to only depend on LuaJIT to build ROMs.

cygwin's newline mangling will be the death of me.

# Miscellaneous notes on Majora's Mask

for brevity, all addresses written here are given for the original US version.
refer to the spreadsheets or Lua tables for their equivalent in other versions.

## spreadsheets

some sheets have been put together to dump data in.
some of them can be used to predict the result of glitches.

* [Event Flags][eventflags]
  are being documented here.

* [Memory Addresses][gs_addrs]
  updates more frequently than [the Lua equivalent.][noice]

* [Entrance Data][ed]  
  a huge laggy mess that brings google docs to its knees.
  this has pretty much been deprecated by the [exit calculator][calc] script,
  which uses updated names, among other things.
  a [4 megabyte csv dump of all exits][csv] is also available.

* [Get Item Manipulation][gim]  
  mzxrules did the original OoT one, i just jammed in MM's data for the item table and chest contents.
  *spoilers:* no desirable results besides light arrows, if it were even possible.
  _potential crashes are not taken account for._

[eventflags]: //docs.google.com/spreadsheets/d/181V9dR5vBROdCVB4FkljG5oz2O4gGU5OTAkoPQX9X10/edit?usp=sharing
[gs_addrs]: //docs.google.com/spreadsheets/d/1HD8yZM1Jza3O8zO28n3k_Rjwdx58RSMA03915l51oDA/edit?usp=sharing
[noice]: /Lua/lib/addrs/M/common.lua
[gim]: //docs.google.com/spreadsheets/d/17LsLbF6aRePVRxisui8azPtDBfPmjugWIf91wPuXTsY
[ed]: //docs.google.com/spreadsheets/d/1e9kDyAW0gxXHFWS-GNEtVIo-rp39wQJJOtf3B0ehhqY
[calc]: /Lua/exit%20calculator.lua
[csv]: //eaguru.guru/t/_exits.csv

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
