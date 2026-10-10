# Tic-Tak-Tran, FORTRAN 77 Edition

A port of `../TicTac.f` to standard ANSI X3.9-1978 FORTRAN 77, with no vendor extensions.

```sh
gfortran -std=legacy f77/tictac.f f77/ai3rul.f -o tictac77   # rule-based difficulty 3
gfortran -std=legacy f77/tictac.f f77/ai3mmx.f -o tictac77   # minimax difficulty 3
./tictac77
python3 f77/test_game.py    # builds both variants and runs all tests
```

Input order: lucky number, difficulty (1–3), then moves as `row col`. Entering `0 0` and then `yes` retires.

## What differs from the modern game, and why

| Modern feature | F77 replacement |
|---|---|
| `random_init` / `random_number` | Park–Miller generator (`RNDSET`, `RNDINT`), computed with Schrage's method so it never overflows 32-bit INTEGER. F77 has no clock, so the player's lucky number is the seed. |
| `--version` (`get_command_argument`) | Dropped. F77 cannot read the command line, so the version appears only in the banner. |
| Recursive minimax | F77 has no recursion. Difficulty 3 is a separate file defining `BESTMV`: `ai3rul.f` plays by rules, and `ai3mmx.f` runs minimax with an explicit stack. |
| `read(*,*) ret` for `yes` | `READ (*,'(A)')`, because F77 list-directed input expects character values in quotes. |
| `do while`, `implicit none`, `::`, `"..."`, names longer than 6 characters | Labelled `DO`/`GOTO`, explicit declarations, `'...'`, and 6-character names (e.g. `PRTBRD`, `RDPAIR`, `SCANLN`). |

`test_game.py` checks conformance with [ftnchek](https://www.dsm.fordham.edu/~ftnchek/) (`-f77=all -portability=all -sixchar -declare`); the check is skipped if ftnchek isn't installed. On macOS: `brew install ftnchek`.
