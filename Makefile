# Builds both editions of difficulty 3 from the same main program.
#   make            tictac77-rules and tictac77-minimax
#   make test       build with all checks and run the test suite
FC      = gfortran
FFLAGS  = -std=legacy -O2
LDFLAGS =

all: tictac77-rules tictac77-minimax

tictac77-rules: tictac.f ai3rul.f
	$(FC) $(FFLAGS) $(LDFLAGS) tictac.f ai3rul.f -o $@

tictac77-minimax: tictac.f ai3mmx.f
	$(FC) $(FFLAGS) $(LDFLAGS) tictac.f ai3mmx.f -o $@

test:
	python3 test_game.py

clean:
	rm -f tictac77-rules tictac77-minimax

.PHONY: all test clean
