## Libraries

#### actors.lua
TODO

#### classes.lua
For lazy people.
Populate the global namespace with all available classes,
excluding menu/interface classes.

#### extra.lua
Implements the `opairs` iterator function
and its helper functions,
providing iteration by sorted keys in alphabetical order.

#### flag manager.lua
Provides basic functions for poking at event flags and scene flags.

#### boilerplate.lua
Provides common functions used in the majority of scripts.
This should generally be imported before any other scripts, besides depend.lua.

#### lips.lua
TODO

#### menu classes.lua
Provides various classes for implementing onscreen menus.

#### menu input handlers.lua
Provides classes for interfacing user inputs with menus.

#### messages.lua
Provides functions for printing onscreen,
such as printing for a given number of game frames.

#### pt.lua
Dumps Lua tables as pseudo-yaml,
complete with references to prevent recursion.
Invaluable for debugging.
[Its repository is on gist][pt] — look there for basic usage.

#### serialize.lua
Serializes (saves, dumps) Lua tables for later deserialization (loading).

unlike `pt`, this dumps as Lua and cannot handle complicated (recursive) tables.

Also provides deferred printing,
to print to console all at once at the end of a frame,
which works around printing being otherwise slow on Bizhawk.

[pt]: https://gist.github.com/notwa/13fbddf05f654ba48321

#### setup.lua
TODO

### addrs

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

### menus/\*
Contains various submenus for `cheat menu.lua`.

### classes/\*
Contains various classes.
Note that the base `Class` function is defined in `boilerplate.lua`.

