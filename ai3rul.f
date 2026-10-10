C ======================================================================
C     DIFFICULTY 3, RULE-BASED: PERFECT PLAY WITHOUT A GAME-TREE
C     SEARCH.  THE FIRST RULE THAT APPLIES PICKS THE CELL (Y,Z):
C       1. WIN:         COMPLETE A LINE OF O'S
C       2. BLOCK:       STOP A LINE OF X'S
C       3. FORK:        MAKE TWO THREATS AT ONCE
C       4. BLOCK FORK:  IF X COULD FORK, MAKE A THREAT WHOSE FORCED
C                       ANSWER DOES NOT GIVE X A FORK, OR ELSE TAKE A
C                       CELL THAT LEAVES X NO FORK
C       5. CENTRE
C       6. OPPOSITE CORNER (OPPOSITE ONE OF X'S)
C       7. EMPTY CORNER
C       8. EMPTY SIDE
C     TIES ARE BROKEN BY SCANNING CELLS ROW BY ROW, SO PLAY IS
C     DETERMINISTIC.  LINK WITH TICTAC.F INSTEAD OF AI3MMX.F.
C ======================================================================
      SUBROUTINE BESTMV(B, Y, Z)
      CHARACTER*1 B(3,3)
      INTEGER Y, Z, R, C, TR, TC, N
      LOGICAL FOUND, SAFE, FORKS
      INTEGER CR(4), CC(4), SR(4), SC(4)
      SAVE CR, CC, SR, SC
      DATA CR /1,1,3,3/, CC /1,3,1,3/, SR /1,2,2,3/, SC /2,1,3,2/

C     1. WIN, 2. BLOCK
      CALL FNDLIN(B, 'O', Y, Z, FOUND)
      IF (FOUND) RETURN
      CALL FNDLIN(B, 'X', Y, Z, FOUND)
      IF (FOUND) RETURN

C     3. FORK
      DO 20 R = 1, 3
        DO 10 C = 1, 3
          IF (B(R,C) .EQ. '_') THEN
            B(R,C) = 'O'
            CALL NTHRT(B, 'O', N)
            B(R,C) = '_'
            IF (N .GE. 2) GOTO 900
          END IF
   10   CONTINUE
   20 CONTINUE

C     4. BLOCK FORK
      CALL XFORKS(B, FORKS)
      IF (FORKS) THEN
C       FIRST CHOICE: A THREAT THAT FORCES X SOMEWHERE HARMLESS
        DO 40 R = 1, 3
          DO 30 C = 1, 3
            IF (B(R,C) .EQ. '_') THEN
              B(R,C) = 'O'
              CALL FNDLIN(B, 'O', TR, TC, FOUND)
              SAFE = .FALSE.
              IF (FOUND) THEN
                B(TR,TC) = 'X'
                CALL NTHRT(B, 'X', N)
                SAFE = N .LT. 2
                B(TR,TC) = '_'
              END IF
              B(R,C) = '_'
              IF (SAFE) GOTO 900
            END IF
   30     CONTINUE
   40   CONTINUE
C       SECOND CHOICE: A CELL AFTER WHICH X HAS NO FORK LEFT
        DO 60 R = 1, 3
          DO 50 C = 1, 3
            IF (B(R,C) .EQ. '_') THEN
              B(R,C) = 'O'
              CALL XFORKS(B, FORKS)
              SAFE = .NOT. FORKS
              B(R,C) = '_'
              IF (SAFE) GOTO 900
            END IF
   50     CONTINUE
   60   CONTINUE
      END IF

C     5. CENTRE
      R = 2
      C = 2
      IF (B(R,C) .EQ. '_') GOTO 900

C     6. OPPOSITE CORNER
      DO 70 TR = 1, 4
        R = CR(TR)
        C = CC(TR)
        IF (B(R,C) .EQ. '_' .AND. B(4-R,4-C) .EQ. 'X') GOTO 900
   70 CONTINUE

C     7. EMPTY CORNER
      DO 80 TR = 1, 4
        R = CR(TR)
        C = CC(TR)
        IF (B(R,C) .EQ. '_') GOTO 900
   80 CONTINUE

C     8. EMPTY SIDE (SONNY GUARANTEES ONE IS LEFT BY NOW)
      DO 90 TR = 1, 4
        R = SR(TR)
        C = SC(TR)
        IF (B(R,C) .EQ. '_') GOTO 900
   90 CONTINUE

  900 Y = R
      Z = C
      END

C ----------------------------------------------------------------------
C     NTHRT: N IS HOW MANY EMPTY CELLS WOULD COMPLETE A LINE FOR MARK
C     (TWO OR MORE IS A FORK: THE OPPONENT CANNOT BLOCK THEM ALL)
C ----------------------------------------------------------------------
      SUBROUTINE NTHRT(B, MARK, N)
      CHARACTER*1 B(3,3), MARK
      INTEGER N, R, C
      LOGICAL W
      N = 0
      DO 20 R = 1, 3
        DO 10 C = 1, 3
          IF (B(R,C) .EQ. '_') THEN
            B(R,C) = MARK
            CALL WINS(B, MARK, W)
            B(R,C) = '_'
            IF (W) N = N + 1
          END IF
   10   CONTINUE
   20 CONTINUE
      END

C ----------------------------------------------------------------------
C     XFORKS: F IS TRUE IF X COULD MAKE A FORK WITH ITS NEXT MOVE
C ----------------------------------------------------------------------
      SUBROUTINE XFORKS(B, F)
      CHARACTER*1 B(3,3)
      INTEGER R, C, N
      LOGICAL F
      F = .FALSE.
      DO 20 R = 1, 3
        DO 10 C = 1, 3
          IF (B(R,C) .EQ. '_') THEN
            B(R,C) = 'X'
            CALL NTHRT(B, 'X', N)
            B(R,C) = '_'
            IF (N .GE. 2) F = .TRUE.
          END IF
   10   CONTINUE
   20 CONTINUE
      END
