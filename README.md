This is an attempt to implement the "Pazaak" card game, as found in
the Knights of the Old Republic (and other) video games, for the Atari
2600.  It is also a learning experience for me and will thus likely
proceed extremely slowly.

To build the game, you will need [dasm][], an assembler for the 6507,
the microprocessor that powers the Atari 2600.  Aside from that,
you'll need `make` in order to use the `Makefile`, and an Atari
emulator, such as [Stella][].

As with most hobby Atari 2600 projects, Cantina requires the
"standard" support files, `macro.h` and `vcs.h`.  These are
distributed with the dasm source code and are not intended for
redistribution.  You can either copy them into the local directory or
use the `DASMINC` environment variable to specify their location
(which, in the dasm source, is in `machines/atari2600/`).

When you have the prerequisites installed, simply run `make`.  You'll
see a bunch of output from dasm.  If you don't see any messages
mentioning "Unrecoverable error(s)", the build should have been
successful.  You can now load `cantina.bin` into your emulator.

[dasm]: https://sourceforge.net/projects/dasm-dillon/
[Stella]: https://stella-emu.github.io/
