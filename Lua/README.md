# Zelda 64 Lua Scripts

These are written for
[the latest revision of Bizhawk,][biz]
but some compatiblity is provided for
[a fork of mupen64plus with Lua support.][m64p-lua]

[biz]: https://github.com/TASVideos/bizhawk/
[m64p-lua]: https://github.com/notwa/mupen64plus-core

Note that some scripts lack full support for Ocarina of Time.

## Scripts

#### actor listor.lua
Lists actor data onscreen,
and focuses the camera on them.
Actors may be selected using the D-Pad.

#### cheat menu.lua
Provides an onscreen UI for many features.
Has four different input methods;
refer to the comment near the start of the script.
Generally, it's opened with L and navigated with the D-Pad.

#### count flags.lua
Simply counts the number of scene flags globally set.

#### exit calculator.lua
Dumps information on the current exit value;
scene name, entrance, entrance with unused offset;
using human-readable English names.

Provides the function `dump_all_exits(fn)`
which produces [a large csv file.][csv]

[csv]: https://eaguru.guru/t/_exits.csv

#### movement tests.lua
Tests the fastest form of basic movement in Majora's Mask.
Run it in the Clock Town Great Fairy's Fountain.

#### oneshot.lua
Instantly gives you all the items in the game, etc.

Does not set scene/event flags,
except the one required for the Great Spin Attack.

#### race.lua
Sets up a race file.

A race file is a save in which the first cycle has been completed,
the Deku Mask has been acquired,
and some other details.

#### room debug.lua
Parses and dumps the currently loaded room headers.

#### m64p entry.lua
Ignore this for now.
This is a rough interfacing script for passing to mupen64plus,
and serves no purpose on Bizhawk.

### Monitors

These scripts look for changes in RAM regions and print them in detail.

These are mostly used for documenation.

#### event flag monitor.lua
Monitors event flags,
and announces which bits are being changed,
and if they have ever been seen changing before.

#### scene flag monitor.lua
Monitors the current scene's flags,
and announces which bits are being changed,
and if they have ever been seen changing before.

#### misc monitor.lua
Monitors unknown regions of memory.
Currently, this region is a chunk of save data, ignoring known addresses.

#### oot memory editor monitor.lua
(Ocarina of Time) Used for determining which values
listed by the in-game debug memory editor are constant.

#### watch animations.lua
Monitors Link's used animations.

## Libraries

Or rather, scripts that have no functionality on their own.

#### depend.lua
Meant to override Lua's native `require` function,
to force reloading of the given script.

This is useless outside of development.
In fact, this could cause bugs in code that depends on
`require` yielding the same tables twice.

#### boilerplate.lua
Provides common functions used in the majority of scripts.
This should generally be imported before any other scripts, besides depend.lua.

#### addrs/init.lua
Using boilerplate.lua's functions,
this provides the bulk of the interface to the games.

Note that this particular initialization script populates the global namespace
with `version`, `oot`, `mm`, and most importantly `addrs`.

#### addrs/basics.lua
Returns a table of tables of offsetable common addresses
between every known version of OoT and MM.

**table keys:**

* **link:** the bulk of the player's state in the game;
not to be confused with Link's actor.
most of this is saved to SRAM.

* **global:** global context.
this is passed as an argument to many functions in the game's code
and contains a wealth of miscellaneous game state information.
this is actually allocated on heap, but its address never changes
— except on the file select screen?

* **actor:** Link's actor.
this includes position, rotation, animation status, etc.
Link's actor is the only actor that
has the same address consistently,
as it's always the first one loaded.

#### addrs/versions.lua
Returns a dictionary of md5 and sha1 hashes
of every known version of OoT and MM.

The format of version strings is
`(O|M) (US|JP|EU)(1[0-9]|GC|DE|DB)( MQ)?`,
where:
* O: Ocarina of Time
* M: Majora's Mask
* US: American NTSC (United States)
* JP: Japanese NTSC
* EU: European PAL
* [two digits]: version number of a release build for the N64
* GC: Gamecube
* DE: Demo (includes Debug features)
* DE: Debug
* MQ: Master Quest

#### pt.lua
Dumps Lua tables as pseudo-yaml,
complete with references to prevent recursion.
Invaluable for debugging.
[Its repository is on gist][pt] — look there for basic usage.

[pt]: https://gist.github.com/notwa/13fbddf05f654ba48321

#### extra.lua
Implements the `opairs` iterator function
and its helper functions,
providing iteration by sorted keys in alphabetical order.

#### serialize.lua
Serializes (saves, dumps) Lua tables for later deserialization (loading).

unlike `pt`, this dumps as Lua and cannot handle complicated (recursive) tables.

#### messages.lua
Provides functions for printing onscreen,
such as printing for a given number of game frames.

Also provides deferred printing,
to print to console all at once at the end of a frame,
which works around printing being otherwise slow on Bizhawk.

#### flag manager.lua
Provides basic functions for poking at event flags and scene flags.

#### classes.lua
For lazy people.
Populate the global namespace with all available classes,
excluding menu/interface classes.

#### menu classes.lua
Provides various classes for implementing onscreen menus.

#### menu input handlers.lua
Provides classes for interfacing user inputs with menus.

#### menus/\*
Contains various submenus for `cheat menu.lua`.

#### classes/\*
Contains various classes.
Note that the base `Class` function is defined in `boilerplate.lua`.

## Data

Any data (that isn't provided by the games themselves)
is located in the data directory.

Much of this should be self-explanitory. However,
files beginning with an underscores contain serialized tables
(generally from monitor scripts)
and usually won't make sense out of context.
