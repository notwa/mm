# Zelda 64 Lua Scripts

These are written for
[the latest revision of Bizhawk.][biz]

[biz]: https://github.com/TASVideos/bizhawk/

Note that some scripts lack full support for Ocarina of Time.

## Scripts

#### cheat menu.lua
Provides an onscreen UI for many features.
Has four different input methods;
refer to the comment near the start of the script.
Generally, it's opened with L and navigated with the D-Pad.

#### count flags.lua
Simply counts the number of scene flags globally set.

#### inject.lua
Assembles and injects code into the game.

#### m64p entry.lua
Ignore this for now.
This is a rough interfacing script for passing to mupen64plus,
and serves no purpose on Bizhawk.

#### setup hundred.lua
Instantly gives you all the items in the game, etc.

Does not set scene/event flags,
except the one required for the Great Spin Attack.

#### setup race file.lua
Sets up a race file.

A race file is a save in which the first cycle has been completed,
the Deku Mask has been acquired,
and some other details.

#### test chests.lua
TODO

#### test movement.lua
Tests the fastest form of basic movement in Majora's Mask.
Run it in the Clock Town Great Fairy's Fountain.

### Monitors

#### monitor actors.lua
Lists actor data onscreen,
and focuses the camera on them.
Actors may be selected using the D-Pad.

#### monitor debug memory editor.lua
(Ocarina of Time) Used for determining which values
listed by the in-game debug memory editor are constant.

#### monitor debug text.lua
TODO

#### monitor epona.lua
used to investigate [this glitch with unloading Epona.][eponaglitch]

[eponaglitch]: https://www.youtube.com/watch?v=kX0ZcIS8P84

#### monitor event flags.lua
Monitors event flags,
and announces which bits are being changed,
and if they have ever been seen changing before.

#### monitor exits.lua
Dumps information on the current exit value;
scene name, entrance, entrance with unused offset;
using human-readable English names.

Provides the function `dump_all_exits(fn)`
which produces [a large csv file.][csv]

[csv]: https://eaguru.guru/t/_exits.csv

#### monitor misc.lua
Monitors unknown regions of memory.
Currently, this region is a chunk of save data, ignoring known addresses.

#### monitor rooms.lua
Parses and dumps the currently loaded room headers.

#### monitor scene flags.lua
Monitors the current scene's flags,
and announces which bits are being changed,
and if they have ever been seen changing before.

#### watch animations.lua
Monitors Link's used animations.

## Libraries

See [the README in the lib directory][libs] for information.

[libs]: /Lua/lib/README.md

## Data

Any data (that isn't provided by the games themselves)
is located in the data directory.

Much of this should be self-explanitory. However,
files beginning with an underscores contain serialized tables
(generally from monitor scripts)
and usually won't make sense out of context.
