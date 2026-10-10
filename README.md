# TranTacToe-77

Tic-Tak-Tran, the FORTRAN 77 edition: a terminal tic-tac-toe game written in standard ANSI X3.9-1978 FORTRAN 77, with no vendor extensions. It's a port of [TranTacToe](https://github.com/ryanromanov/TranTacToe), which is written in modern Fortran.

You play `X`; the computer plays `O`.

## Build & play

```sh
make                 # builds tictac77-rules and tictac77-minimax
./tictac77-rules
make test            # build with all checks and run the test suite
```

Prebuilt Linux and macOS binaries are attached to each [release](../../releases).

The game asks for input in this order: a lucky number (it seeds the random number generator), the difficulty (1–3), then your moves as `row col`. Entering `0 0` and then `yes` retires.

## Two difficulty-3 editions

F77 has no recursion, so the unbeatable difficulty 3 lives in its own file, which defines `BESTMV`. `tictac.f` is linked with one of the two:

| | `tictac77-rules` (`ai3rul.f`) | `tictac77-minimax` (`ai3mmx.f`) |
|---|---|---|
| Method | 8 classic rules: win, block, fork, block fork, centre, opposite corner, corner, side | Full game-tree search on an explicit stack |
| Ever loses? | Never (all 457 user move sequences) | Never (all 569 user move sequences) |
| Against a random player | 90.4% wins, 9.6% ties | 80.6% wins, 19.4% ties |
| Moves | Its own | Same as modern TranTacToe in all 952 positions |

## What differs from modern TranTacToe

| Modern feature | F77 replacement |
|---|---|
| `random_init` / `random_number` | A Park–Miller generator (`RNDSET`, `RNDINT`), computed with Schrage's method so it never overflows 32-bit INTEGER. F77 has no clock, so your lucky number is the seed. |
| `--version` | Dropped. F77 cannot read the command line, so the version is shown only in the banner. |
| Recursive minimax | Moved into a separate file: rule-based or explicit-stack (see above). |
| `read(*,*)` of `yes` | `READ (*,'(A)')`, because F77 list-directed input expects character values in quotes. |
| `do while`, `implicit none`, `::`, `"..."`, long names | Labelled `DO`/`GOTO`, explicit declarations, `'...'`, 6-character names (`PRTBRD`, `RDPAIR`, `SCANLN`, …). |

Where standard F77 leaves things up to the compiler:
- The random number generator needs INTEGER to hold 2³¹−1.
- Re-prompting after bad input relies on the compiler skipping past the bad line.
- Long message lines may wrap on period systems.

## Conformance

`test_game.py` runs [ftnchek](https://www.dsm.fordham.edu/~ftnchek/) with `-f77=all -portability=all -sixchar -declare` and requires a clean report. To install ftnchek, run `brew install ftnchek` (macOS) or `apt install ftnchek` (Debian/Ubuntu). The tests also play every possible user move sequence against both difficulty-3 editions.

## Releasing

Bump `VERS` in `tictac.f`, merge, then tag that commit: `git tag v0.3.0 && git push origin v0.3.0`. The release workflow checks that the tag matches `VERS`.
