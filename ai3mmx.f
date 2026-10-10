C ======================================================================
C     DIFFICULTY 3, MINIMAX: THE SAME FULL GAME-TREE SEARCH AS THE
C     MODERN TICTAC.F, BUT FORTRAN 77 HAS NO RECURSION, SO THE SEARCH
C     KEEPS ITS OWN STACK (ONE ENTRY PER PLY) AND LOOPS WITH GOTO.
C     LINK WITH TICTAC.F INSTEAD OF AI3RUL.F.
C ======================================================================
      SUBROUTINE BESTMV(B, Y, Z)
      CHARACTER*1 B(3,3)
      INTEGER Y, Z, R, C, S, BEST
      LOGICAL FOUND
C     TAKE AN IMMEDIATE WIN RATHER THAN ANY EQUALLY-SCORED SLOWER ONE
      CALL FNDLIN(B, 'O', Y, Z, FOUND)
      IF (FOUND) RETURN
      BEST = -2
      DO 20 R = 1, 3
        DO 10 C = 1, 3
          IF (B(R,C) .EQ. '_') THEN
            B(R,C) = 'O'
            CALL SCORE(B, 'X', S)
            B(R,C) = '_'
            IF (S .GT. BEST) THEN
              BEST = S
              Y = R
              Z = C
            END IF
          END IF
   10   CONTINUE
   20 CONTINUE
      END

C ----------------------------------------------------------------------
C     SCORE: VALUE S OF BOARD B WITH MARK TO MOVE, ASSUMING BOTH SIDES
C     PLAY PERFECTLY: 1 O WINS, -1 X WINS, 0 TIE.  B IS RESTORED.
C
C     STACK ENTRY D DESCRIBES PLY D:
C       PLAYER(D)  WHO MOVES ('O' MAXIMISES, 'X' MINIMISES)
C       CELL(D)    THE CELL (1-9, ROW BY ROW) BEING TRIED; 0 = NONE YET
C       BEST(D)    THE BEST VALUE FOUND SO FAR
C       MOVED(D)   WHETHER ANY CELL WAS EMPTY (IF NOT, IT IS A TIE)
C ----------------------------------------------------------------------
      SUBROUTINE SCORE(B, MARK, S)
      CHARACTER*1 B(3,3), MARK, PLAYER(9)
      INTEGER S, D, K, R, C, V, CELL(9), BEST(9)
      LOGICAL MOVED(9), OWON, XWON, WON

      CALL WINS(B, 'O', OWON)
      CALL WINS(B, 'X', XWON)
      IF (OWON) THEN
        S = 1
        RETURN
      ELSE IF (XWON) THEN
        S = -1
        RETURN
      END IF
      D = 1
      PLAYER(1) = MARK

C     PUSH: START PLY D (PLAYER(D) IS ALREADY SET)
   50 CELL(D) = 0
      MOVED(D) = .FALSE.
      IF (PLAYER(D) .EQ. 'O') THEN
        BEST(D) = -2
      ELSE
        BEST(D) = 2
      END IF

C     NEXT: TRY THE NEXT EMPTY CELL AFTER CELL(D)
  100 K = CELL(D) + 1
  110 IF (K .GT. 9) GOTO 200
      R = (K - 1) / 3 + 1
      C = MOD(K - 1, 3) + 1
      IF (B(R,C) .NE. '_') THEN
        K = K + 1
        GOTO 110
      END IF
      CELL(D) = K
      MOVED(D) = .TRUE.
      B(R,C) = PLAYER(D)
      CALL WINS(B, PLAYER(D), WON)
      IF (WON) THEN
C       ONLY THE PLAYER WHO JUST MOVED CAN HAVE COMPLETED A LINE
        V = 1
        IF (PLAYER(D) .EQ. 'X') V = -1
        GOTO 300
      END IF
      D = D + 1
      IF (PLAYER(D-1) .EQ. 'O') THEN
        PLAYER(D) = 'X'
      ELSE
        PLAYER(D) = 'O'
      END IF
      GOTO 50

C     POP: PLY D HAS TRIED EVERY CELL; HAND ITS VALUE TO PLY D-1
  200 V = BEST(D)
      IF (.NOT. MOVED(D)) V = 0
      IF (D .EQ. 1) THEN
        S = V
        RETURN
      END IF
      D = D - 1

C     RETURN: THE MOVE AT CELL(D) IS WORTH V; UNDO IT AND KEEP THE BEST
  300 K = CELL(D)
      R = (K - 1) / 3 + 1
      C = MOD(K - 1, 3) + 1
      B(R,C) = '_'
      IF (PLAYER(D) .EQ. 'O') THEN
        BEST(D) = MAX(BEST(D), V)
      ELSE
        BEST(D) = MIN(BEST(D), V)
      END IF
      GOTO 100
      END
