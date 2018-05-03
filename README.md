# Zelda 64 Resources

i like to muck around in the memory of these games.

those who are more interested in the ROM may find [the binary template repo][bt]
more resourceful.

there is also a great deal of general [documentation and notes
on the wikis][cm] hosted at CloudModding.

[bt]: //github.com/EntranceJew/zelda-binary-templates
[cm]: //cloudmodding.com/wiki

## Lua Scripts

this repo contains a ton of Lua scripts
written for [version 2.2.2 of Bizhawk.][bizhawk]
all the scripts you'll want to use are in the root Lua directory,
and their dependencies are in further subdirectories.
that means, if you want to use a script,
you **must** preserve the directory structure.
you **cannot,** say, extract one file from [this repo's archive][arch]
and expect it to work.

[bizhawk]: http://tasvideos.org/BizHawk.html
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
you can set up [msys2](//www.msys2.org/)
to install binaries of bash, python, and gcc.
then all that's left is to compile LuaJIT yourself,
or you can [grab a 64-bit binary built by myself.](//eaguru.guru/t/luajit.7z)

last, but not least, you will need the appropriate ROM for the ROM hack.
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

# Spreadsheets

some sheets have been put together to dump data in.
some of them can be used to predict the result of glitches.

* [Event Flags][eventflags]
  are being documented here. this hasn't changed in a while,
  so there's now also [a copy on tcrf.][tcrfevent]

* [Memory Addresses][gs_addrs]
  updates more frequently than [the Lua equivalent.][noice]

* [Entrance Data][ed]  
  a huge laggy mess that brings google docs to its knees.
  this has pretty much been deprecated by the [exit calculator][calc] script,
  which uses updated names, among other things.
  a [4 megabyte csv dump of all exits][csv] is also available.

<!--
* [Get Item Manipulation][gim]  
  mzxrules did the original OoT one, i just jammed in MM's data for the item table and chest contents.
  *spoilers:* no desirable results besides light arrows, if it were even possible.
  _potential crashes are not taken account for._
-->

[eventflags]: //docs.google.com/spreadsheets/d/181V9dR5vBROdCVB4FkljG5oz2O4gGU5OTAkoPQX9X10/edit?usp=sharing
[tcrfevent]: //tcrf.net/Proto:The_Legend_of_Zelda:_Majora%27s_Mask/Debug_Version/Event_Editor#week_event_reg
[gs_addrs]: //docs.google.com/spreadsheets/d/1HD8yZM1Jza3O8zO28n3k_Rjwdx58RSMA03915l51oDA/edit?usp=sharing
[noice]: /Lua/lib/addrs/M/common.lua
[ed]: //docs.google.com/spreadsheets/d/1e9kDyAW0gxXHFWS-GNEtVIo-rp39wQJJOtf3B0ehhqY
[calc]: /Lua/exit%20calculator.lua
[csv]: //eaguru.guru/t/_exits.csv
[gim]: //docs.google.com/spreadsheets/d/17LsLbF6aRePVRxisui8azPtDBfPmjugWIf91wPuXTsY
