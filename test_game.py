"""End-to-end tests for Tic-Tak-Tran, FORTRAN 77 edition.

Adapted from TranTacToe's tests/test_game.py. The game is built twice, once with each
difficulty-3 AI (ai3rul.f: rule-based, ai3mmx.f: explicit-stack minimax),
then driven over stdin: lucky number, difficulty, then moves as `row col`.

Run with: python3 test_game.py   (or: make test)
Set REQUIRE_FTNCHEK=1 to fail, not skip, when ftnchek is missing.
"""
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
MAIN = os.path.join(HERE, "tictac.f")
AIS = {"rules": "ai3rul.f", "minimax": "ai3mmx.f"}
SOURCES = [MAIN] + [os.path.join(HERE, f) for f in AIS.values()]
ALL_CELLS = [(r, c) for r in range(1, 4) for c in range(1, 4)]
RETIRE = [(0, 0)]
TIMEOUT = 5
RANDOM_RUNS = 20  # random difficulties are re-run, each with its own seed
SEEDS = [0, -1, 1, 2, 7, 42, 2147483646, 2147483647, -2147483647, 12345,
         99, 100, 31337, -5, 8, 9, 10, 11, 271828, 314159]
assert len(SEEDS) == RANDOM_RUNS
TALLY = {}  # AI name -> outcome counts from the exhaustive difficulty-3 test


def setUpModule():
    global BINS, _tmp
    _tmp = tempfile.mkdtemp()
    BINS = {}
    for name, ai in AIS.items():
        BINS[name] = os.path.join(_tmp, "tictac_" + name)
        subprocess.run(
            ["gfortran", "-std=legacy", "-Wall", "-Wextra", "-Werror",
             "-fcheck=all", MAIN, os.path.join(HERE, ai), "-o", BINS[name]],
            check=True,
        )


def tearDownModule():
    shutil.rmtree(_tmp)
    for name, tally in TALLY.items():
        print(f"difficulty 3 ({name}): {tally}")


def run(inp, ai="rules"):
    try:
        p = subprocess.run(
            [BINS[ai]], input=inp, capture_output=True, text=True,
            timeout=TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return None
    return p


def play(diff, moves, extra="", seed=42, ai="rules"):
    """Run one game; returns (outcome, stdout). Moves are (row, col) pairs."""
    inp = (f"{seed}\n{diff}\n" + "".join(f"{r} {c}\n" for r, c in moves)
           + extra)
    p = run(inp, ai)
    if p is None:
        return "hang", ""
    out = p.stdout + p.stderr
    for outcome, marker in (
        ("runtime_error", "Fortran runtime error"),
        ("user_win", "beaten the computer"),
        ("computer_win", "been beaten by"),
        ("tie", "mortal man"),
        ("quit", "Quitting program"),
    ):
        if marker in out:
            return outcome, out
    return f"other(rc={p.returncode})", out


def last_board(out):
    rows = [l for l in out.splitlines() if l.strip().startswith("|")][-3:]
    return [[cell.strip() for cell in row.split("|")[1:4]] for row in rows]


class SourceFormat(unittest.TestCase):
    def test_no_code_past_column_72(self):
        # Fixed-form Fortran silently drops anything past column 72.
        for src in SOURCES:
            with open(src) as f:
                long_lines = [
                    i for i, line in enumerate(f, 1)
                    if len(line.rstrip("\n")) > 72 and line[:1] not in "cC*"
                ]
            self.assertEqual(long_lines, [], src)

    def test_no_tabs(self):
        # Tabs are not in the FORTRAN 77 character set.
        for src in SOURCES:
            with open(src) as f:
                self.assertNotIn("\t", f.read(), src)

    @unittest.skipUnless(shutil.which("ftnchek")
                         or os.environ.get("REQUIRE_FTNCHEK"),
                         "ftnchek not installed")
    def test_ftnchek_clean(self):
        # Flags every non-F77 extension, names over six characters,
        # portability problems and undeclared variables.
        for ai in AIS.values():
            with self.subTest(ai=ai):
                p = subprocess.run(
                    ["ftnchek", "-f77=all", "-portability=all", "-sixchar",
                     "-declare", "-quiet", MAIN, ai],
                    cwd=HERE, capture_output=True, text=True,
                )
                self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
                self.assertNotRegex(p.stdout, r"(?i)warning|error",
                                    p.stdout)


class Version(unittest.TestCase):
    def test_banner_shows_version(self):
        with open(MAIN) as f:
            version = re.search(r"PARAMETER \(VERS = '([0-9.]+)'\)",
                                f.read()).group(1)
        _, out = play(1, RETIRE, "yes\n")
        self.assertIn(f"Welcome to Tic-Tak-Tran! (v{version})", out)


class Input(unittest.TestCase):
    def test_board_prints_and_retire_quits(self):
        outcome, out = play(1, RETIRE, "yes\n")
        self.assertEqual(outcome, "quit")
        self.assertIn("|  _  |  _  |  _  |", out)

    def test_declining_retire_resumes_game(self):
        outcome, out = play(1, RETIRE, "no\n1 1\n0 0\nyes\n")
        self.assertEqual(outcome, "quit")
        self.assertEqual(last_board(out)[0][0], "X")

    def test_letters_at_seed_prompt(self):
        p = run("lucky\n7\n1\n0 0\nyes\n")
        self.assertEqual(p.stdout.count("please enter a whole number"), 1)
        self.assertIn("Quitting program", p.stdout)
        self.assertNotIn("Fortran runtime error", p.stdout + p.stderr)

    def test_letters_at_difficulty_prompt(self):
        p = run("7\nabc\n1\n0 0\nyes\n")
        self.assertIn("please enter a whole number", p.stdout)
        self.assertIn("Quitting program", p.stdout)
        self.assertNotIn("Fortran runtime error", p.stdout + p.stderr)

    def test_letters_at_move_prompt(self):
        outcome, out = play(1, [], "a b\n1 x\n2 2\n0 0\nyes\n")
        self.assertEqual(outcome, "quit")
        self.assertEqual(out.count("please enter two whole numbers"), 2)
        self.assertEqual(last_board(out)[1][1], "X")

    def test_end_of_input_quits_cleanly(self):
        # at the seed, difficulty, move and retire prompts
        for inp in ("", "7\n", "7\n1\n", "7\n1\n0 0\n"):
            with self.subTest(inp=inp):
                p = run(inp)
                self.assertIn("No more input", p.stdout)
                self.assertNotIn("Fortran runtime error",
                                 p.stdout + p.stderr)

    def test_out_of_range_after_occupied_cell(self):
        outcome, out = play(1, [(1, 1), (1, 1), (5, 5)] + RETIRE, "yes\n")
        self.assertEqual(outcome, "quit")
        self.assertIn("x-coordinates are wrong", out)


class Random(unittest.TestCase):
    def first_reply(self, seed):
        _, out = play(1, [(2, 2)] + RETIRE, "yes\n", seed=seed)
        board = last_board(out)
        return next((r, c) for r in range(3) for c in range(3)
                    if board[r][c] == "O")

    def test_same_seed_same_game(self):
        self.assertEqual(self.first_reply(42), self.first_reply(42))

    def test_seeds_reach_every_cell(self):
        # Around the user's centre move, the computer should be able to
        # answer in all 8 cells, given enough different lucky numbers.
        with ThreadPoolExecutor() as pool:
            replies = set(pool.map(self.first_reply, range(200)))
        self.assertEqual(len(replies), 8, replies)


class Games(unittest.TestCase):
    def assert_finishes(self, diff, moves, extra="", allowed=None):
        allowed = allowed or {"user_win", "computer_win", "tie", "quit"}
        with ThreadPoolExecutor() as pool:
            results = list(pool.map(
                lambda s: play(diff, moves, extra, seed=s)[0], SEEDS
            ))
        self.assertTrue(set(results) <= allowed, results)

    def test_sweep_every_cell(self):
        # User tries every cell in order; occupied ones are re-prompted.
        for diff in (1, 2, 3):
            with self.subTest(diff=diff):
                self.assert_finishes(diff, ALL_CELLS * 3)

    def test_difficulty_2_corner_opening(self):
        self.assert_finishes(2, [(1, 3)] + RETIRE, "yes\n", {"quit"})

    def never_loses(self, ai):
        # Difficulty 3 is deterministic, so explore every user move sequence.
        tally = {}
        frontier = [[]]
        with ThreadPoolExecutor() as pool:
            while frontier:
                results = pool.map(
                    lambda m: (m, play(3, m + RETIRE, "yes\n", ai=ai)),
                    frontier,
                )
                frontier = []
                for moves, (outcome, out) in results:
                    if outcome == "quit":
                        board = last_board(out)
                        frontier += [
                            moves + [(r, c)] for r, c in ALL_CELLS
                            if board[r - 1][c - 1] == "_"
                        ]
                    else:
                        tally[outcome] = tally.get(outcome, 0) + 1
                        self.assertNotEqual(outcome, "user_win", moves)
                        self.assertIn(outcome, ("computer_win", "tie"), moves)
        self.assertTrue(tally)  # the tree was actually explored
        TALLY[ai] = tally

    def test_difficulty_3_never_loses_rules(self):
        self.never_loses("rules")

    def test_difficulty_3_never_loses_minimax(self):
        self.never_loses("minimax")


if __name__ == "__main__":
    unittest.main(verbosity=2)
