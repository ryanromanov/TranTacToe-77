# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The FORTRAN 77 edition of Tic-Tak-Tran (a port of ryanromanov/TranTacToe), a terminal tic-tac-toe game. The human plays `X`, the computer `O`. **The code must stay standard ANSI FORTRAN 77 with no vendor extensions**; that's the point of the repo.

## Build & test

```sh
make                                   # tictac77-rules, tictac77-minimax
python3 test_game.py                   # or: make test
python3 test_game.py Input.test_declining_retire_resumes_game
```

The tests feed stdin in this order: lucky number, difficulty, then moves as `row col` (`0 0` + `yes` retires).

They fail on:
- code past column 72
- tab characters
- any ftnchek warning (`-f77=all -portability=all -sixchar -declare`)
- any compiler warning (`-Wall -Wextra -Werror`)

Difficulty 3 is exhaustively checked for both editions. CI sets `REQUIRE_FTNCHEK=1`, so ftnchek can't be silently skipped.

## Files

- `tictac.f`: main program and everything except difficulty 3.
- `ai3rul.f` / `ai3mmx.f`: two implementations of `SUBROUTINE BESTMV(B, Y, Z)`. Link exactly one with `tictac.f`.

## F77 rules to keep (gfortran -std=legacy will NOT catch most of these)

- **Fixed form:**
  - Labels go in columns 1–5, continuation characters (`+`) in column 6, code in columns 7–72.
  - `C` in column 1 starts a comment.
  - Code is ALL-CAPS; the game's messages are mixed case.
- **Names:** at most 6 characters, no underscores.
- **Not allowed:** `IMPLICIT NONE`, `::`, `DO WHILE`/`END DO`, `!` comments, `"..."` strings (double apostrophes inside `'...'` instead), initialization in declarations (use `DATA`), recursion.
- **Functions:** no side effects. Helpers that modify the board are SUBROUTINEs (ftnchek checks this).
- **COMMON:** a block that must keep its values needs `SAVE /NAME/` in every unit that names it, or it becomes undefined on RETURN. ftnchek doesn't catch this.
- **Reading text:** use a format (`READ (*,'(A)')`). F77 list-directed input wants quotes round character values.
- **Randomness and versions:** no clock and no command line. The RNG is seeded from the player's lucky number, and the version (`VERS`) appears only in the banner.
