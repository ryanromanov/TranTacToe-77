C ======================================================================
C     PROGRAM NAME:   TIC-TAC-TRAN, FORTRAN 77 EDITION
C     AUTHOR:         RYAN ROMANOSKY
C     VERSION NO.:    SEE VERS BELOW
C
C     A PORT OF TRANTACTOE'S TICTAC.F TO STANDARD ANSI X3.9-1978
C     FORTRAN 77, WITH NO VENDOR EXTENSIONS:
C       - NO CLOCK, SO THE PLAYER TYPES A LUCKY NUMBER TO SEED THE
C         RANDOM NUMBER GENERATOR (RNDSET / RNDINT, PARK-MILLER).
C       - NO COMMAND LINE, SO THE VERSION IS SHOWN IN THE BANNER ONLY.
C       - NO RECURSION, SO DIFFICULTY 3 (BESTMV) LIVES IN ITS OWN
C         SOURCE FILE.  LINK EXACTLY ONE OF:
C           AI3RUL.F   RULE-BASED PERFECT PLAY
C           AI3MMX.F   MINIMAX WITH AN EXPLICIT STACK
C
C     BUILD:  MAKE   (OR GFORTRAN TICTAC.F AI3RUL.F -O TICTAC77)
C
C     THE BOARD IS B(ROW,COL), EMPTY CELLS ARE '_'.  THE USER IS 'X',
C     THE COMPUTER IS 'O'.  VICTOR: 0 NONE, 1 USER, 2 COMPUTER, 3 TIE.
C ======================================================================
      PROGRAM TICTAC
      CHARACTER*(*) VERS
      PARAMETER (VERS = '1.0.0')
      CHARACTER*1 BOARD(3,3)
      CHARACTER*3 RETIRE
      INTEGER X, Y, VICTOR, NTURN, DIFF
      DATA BOARD /9*'_'/
      DATA RETIRE /'no '/
      DATA VICTOR, NTURN, DIFF /0, 0, 0/

      CALL MENU(DIFF, VERS)
   10 IF (RETIRE .EQ. 'yes' .OR. VICTOR .NE. 0) GOTO 20
        CALL PRTBRD(BOARD)
        CALL GETPOS(X, Y, NTURN, RETIRE, BOARD)
        IF (RETIRE .NE. 'yes') THEN
          CALL MARKBD(X, Y, BOARD)
          IF (NTURN .GE. 3) CALL VCHECK(BOARD, VICTOR)
          IF (VICTOR .EQ. 0) THEN
            CALL SONNY(BOARD, DIFF)
            IF (NTURN .GE. 3) CALL VCHECK(BOARD, VICTOR)
          END IF
        END IF
        GOTO 10
   20 CONTINUE

      IF (VICTOR .EQ. 1) THEN
        WRITE (*,*) 'Congratulations! You''ve beaten the computer!'
        CALL TURING
      ELSE IF (VICTOR .EQ. 2) THEN
        WRITE (*,*) 'Congratulations! You''ve been beaten by the ',
     +              'computer'
        CALL TURING
      ELSE IF (VICTOR .EQ. 3) THEN
        WRITE (*,*) 'The tie goes to the mortal man.'
        CALL TURING
      END IF
      END

C ----------------------------------------------------------------------
C     MENU: BANNER, LUCKY NUMBER (THE RANDOM SEED) AND DIFFICULTY
C ----------------------------------------------------------------------
      SUBROUTINE MENU(DIFF, VERS)
      INTEGER DIFF, LUCKY
      CHARACTER*(*) VERS
      WRITE (*,900) VERS
      WRITE (*,*) 'FORTRAN 77 Edition'
      WRITE (*,*) 'This Fortran-based emulator is the most accurate ',
     +            'and'
      WRITE (*,*) 'graphically advanced way to play the game known ',
     +            'for its ability to render even the most expensive ',
     +            'GPUs into a molten pile of wasted savings accounts.'
      WRITE (*,*)
      WRITE (*,*) 'Pick a lucky number (any whole number):'
      CALL READI(LUCKY)
      CALL RNDSET(LUCKY)
      WRITE (*,*) 'Please choose your difficulty level'
      WRITE (*,*) '(1 being greenhorn, 2 being leftenant, 3 being ',
     +            'Navy Seal Copy Pasta)'
      CALL READI(DIFF)
   10 IF (DIFF .GE. 1 .AND. DIFF .LE. 3) GOTO 20
        WRITE (*,*) 'Error: Please choose a number between 1 and 3'
        CALL READI(DIFF)
        GOTO 10
   20 CONTINUE
      WRITE (*,*) 'Fight!'
  900 FORMAT (' Welcome to Tic-Tac-Tran! (v', A, ')')
      END

C ----------------------------------------------------------------------
C     PRTBRD: PRINT THE BOARD
C ----------------------------------------------------------------------
      SUBROUTINE PRTBRD(B)
      CHARACTER*1 B(3,3)
      INTEGER R, C
      WRITE (*,*)
      DO 10 R = 1, 3
        WRITE (*,900)
        WRITE (*,910) (B(R,C), C = 1, 3)
        WRITE (*,900)
   10 CONTINUE
      WRITE (*,*)
  900 FORMAT (' ', 1X, 5('-'), 1X, 5('-'), 1X, 5('-'))
  910 FORMAT (' |', 2X, A1, 2X, '|', 2X, A1, 2X, '|', 2X, A1, 2X, '|')
      END

C ----------------------------------------------------------------------
C     GETPOS: READ AND VALIDATE THE USER'S MOVE (X = ROW, Y = COLUMN).
C     ON SUCCESS NTURN IS INCREMENTED; 0 0 THEN 'yes' SETS RET.
C ----------------------------------------------------------------------
      SUBROUTINE GETPOS(X, Y, NTURN, RET, B)
      INTEGER X, Y, NTURN, TX, TY, IOS
      CHARACTER*3 RET
      CHARACTER*1 B(3,3)
      X = 0
      Y = 0
      WRITE (*,*) 'Please enter where you wish to place your marker'
      WRITE (*,*) 'Enter in the format "x y" with a space between ',
     +            'them'
      WRITE (*,*) 'Coordinates are 1-indexed and the top-left ',
     +            'corner is 1,1'
      WRITE (*,*) '( To retire, enter 0 0 )'
      CALL RDPAIR(TX, TY)

   10 IF (TX .GE. 1 .AND. TX .LE. 3) THEN
        IF (TY .GE. 1 .AND. TY .LE. 3) THEN
          IF (B(TX,TY) .EQ. '_') THEN
            X = TX
            Y = TY
            NTURN = NTURN + 1
            RETURN
          END IF
          CALL OVRLAI(TX, TY, B)
        ELSE
          WRITE (*,*) 'Error: your y-coordinates are wrong'
        END IF
        WRITE (*,*) 'Please re-enter your x- and y-coordinates:'
      ELSE IF (TX .EQ. 0 .AND. TY .EQ. 0) THEN
        WRITE (*,*) 'Are you sure you want to retire? Enter "yes" ',
     +              'to retire or anything else to continue.'
C       A FORMAT, NOT LIST-DIRECTED: F77 WANTS QUOTES ROUND 'yes' THERE
        READ (*, '(A)', IOSTAT=IOS) RET
        IF (IOS .LT. 0) CALL ENDINP
        IF (RET .EQ. 'yes') THEN
          CALL OAP
          RETURN
        END IF
        WRITE (*,*) 'Please enter your x- and y-coordinates:'
      ELSE
        WRITE (*,*) 'Error: your x-coordinates are wrong'
        WRITE (*,*) 'Please re-enter your x- and y-coordinates:'
      END IF
      CALL RDPAIR(TX, TY)
      GOTO 10
      END

C ----------------------------------------------------------------------
C     READI: READ ONE INTEGER, RE-ASKING UNTIL THE INPUT IS A NUMBER
C ----------------------------------------------------------------------
      SUBROUTINE READI(N)
      INTEGER N, IOS
   10 READ (*, *, IOSTAT=IOS) N
      IF (IOS .EQ. 0) RETURN
      IF (IOS .LT. 0) CALL ENDINP
      WRITE (*,*) 'Error: please enter a whole number'
      GOTO 10
      END

C ----------------------------------------------------------------------
C     RDPAIR: READ TWO INTEGERS, RE-ASKING UNTIL BOTH ARE NUMBERS
C ----------------------------------------------------------------------
      SUBROUTINE RDPAIR(I, J)
      INTEGER I, J, IOS
   10 READ (*, *, IOSTAT=IOS) I, J
      IF (IOS .EQ. 0) RETURN
      IF (IOS .LT. 0) CALL ENDINP
      WRITE (*,*) 'Error: please enter two whole numbers, like "2 3"'
      GOTO 10
      END

C ----------------------------------------------------------------------
C     ENDINP: QUIT CLEANLY WHEN INPUT ENDS (CTRL-D OR END OF A PIPE)
C ----------------------------------------------------------------------
      SUBROUTINE ENDINP
      WRITE (*,*)
      WRITE (*,*) 'No more input. Quitting program...'
      STOP
      END

C ----------------------------------------------------------------------
C     OAP: QUIT
C ----------------------------------------------------------------------
      SUBROUTINE OAP
      WRITE (*,*) 'Quitting program...'
      CALL TURING
      END

C ----------------------------------------------------------------------
C     OVRLAI: COMPLAIN ABOUT AN OCCUPIED CELL
C ----------------------------------------------------------------------
      SUBROUTINE OVRLAI(TX, TY, B)
      INTEGER TX, TY
      CHARACTER*1 B(3,3)
      IF (B(TX,TY) .EQ. 'X') THEN
        WRITE (*,*) 'You''ve already got an ''X'' there mate!'
      ELSE
        WRITE (*,*) 'You can''t go where the AI has gone before...'
      END IF
      WRITE (*,*)
      END

C ----------------------------------------------------------------------
C     MARKBD: MARK THE BOARD FOR THE USER
C ----------------------------------------------------------------------
      SUBROUTINE MARKBD(X, Y, B)
      INTEGER X, Y
      CHARACTER*1 B(3,3)
      B(X,Y) = 'X'
      END

C ----------------------------------------------------------------------
C     "THE THREE LAWS WILL LEAD TO ONLY ONE LOGICAL OUTCOME."
C     SONNY: THE COMPUTER'S MOVE.  ASSUMES AN EMPTY CELL EXISTS.
C ----------------------------------------------------------------------
      SUBROUTINE SONNY(B, DIFF)
      CHARACTER*1 B(3,3)
      INTEGER DIFF, Y, Z, R, C, K, NEMPTY
      LOGICAL FOUND
      FOUND = .FALSE.
C     "A ROBOT MAY NOT HARM A HUMAN OR, BY INACTION, ALLOW A HUMAN
C       BEING TO COME TO HARM."
C     DIFFICULTY 1 PLAYS A RANDOM EMPTY CELL (THE FALLBACK BELOW).

C     "A ROBOT MUST OBEY ORDERS GIVEN IT BY HUMAN BEINGS EXCEPT WHERE
C       SUCH ORDERS WOULD CONFLICT WITH THE FIRST LAW."
C     DIFFICULTY 2 COMPLETES ITS OWN LINE, ELSE BLOCKS THE USER'S,
C       ELSE PLAYS RANDOMLY.
      IF (DIFF .EQ. 2) THEN
        CALL FNDLIN(B, 'O', Y, Z, FOUND)
        IF (.NOT. FOUND) CALL FNDLIN(B, 'X', Y, Z, FOUND)
      END IF

C     "A ROBOT MUST PROTECT ITS OWN EXISTENCE AS LONG AS SUCH
C       PROTECTION DOES NOT CONFLICT WITH THE FIRST OR SECOND LAW."
C     DIFFICULTY 3 NEVER LOSES (SEE AI3RUL.F / AI3MMX.F).
      IF (DIFF .EQ. 3) THEN
        CALL BESTMV(B, Y, Z)
        FOUND = .TRUE.
      END IF

C     RANDOM FALLBACK: COUNT THE EMPTY CELLS, THEN TAKE THE K-TH ONE
      IF (.NOT. FOUND) THEN
        NEMPTY = 0
        DO 20 R = 1, 3
          DO 10 C = 1, 3
            IF (B(R,C) .EQ. '_') NEMPTY = NEMPTY + 1
   10     CONTINUE
   20   CONTINUE
        CALL RNDINT(NEMPTY, K)
        DO 40 R = 1, 3
          DO 30 C = 1, 3
            IF (B(R,C) .EQ. '_') THEN
              K = K - 1
              IF (K .EQ. 0) THEN
                Y = R
                Z = C
                GOTO 50
              END IF
            END IF
   30     CONTINUE
   40   CONTINUE
   50   CONTINUE
      END IF
      B(Y,Z) = 'O'
      END

C ----------------------------------------------------------------------
C     SCANLN: SCAN WINNING LINE I (1-3 ROWS, 4-6 COLS, 7-8 DIAGONALS)
C       N:      HOW MANY OF ITS CELLS HOLD MARK
C       EY,EZ:  ONE OF ITS EMPTY CELLS, OR 0,0 IF IT HAS NONE
C ----------------------------------------------------------------------
      SUBROUTINE SCANLN(B, I, MARK, N, EY, EZ)
      CHARACTER*1 B(3,3), MARK
      INTEGER I, N, EY, EZ, K, LR(3,8), LC(3,8)
      SAVE LR, LC
      DATA LR /1,1,1, 2,2,2, 3,3,3, 1,2,3, 1,2,3, 1,2,3,
     +         1,2,3, 1,2,3/
      DATA LC /1,2,3, 1,2,3, 1,2,3, 1,1,1, 2,2,2, 3,3,3,
     +         1,2,3, 3,2,1/
      N = 0
      EY = 0
      EZ = 0
      DO 10 K = 1, 3
        IF (B(LR(K,I),LC(K,I)) .EQ. MARK) N = N + 1
        IF (B(LR(K,I),LC(K,I)) .EQ. '_') THEN
          EY = LR(K,I)
          EZ = LC(K,I)
        END IF
   10 CONTINUE
      END

C ----------------------------------------------------------------------
C     FNDLIN: FIND A LINE WITH TWO OF MARK AND ONE EMPTY CELL (Y,Z)
C ----------------------------------------------------------------------
      SUBROUTINE FNDLIN(B, MARK, Y, Z, FOUND)
      CHARACTER*1 B(3,3), MARK
      INTEGER Y, Z, I, N, EY, EZ
      LOGICAL FOUND
      FOUND = .FALSE.
      DO 10 I = 1, 8
        CALL SCANLN(B, I, MARK, N, EY, EZ)
        IF (N .EQ. 2 .AND. EY .NE. 0) THEN
          Y = EY
          Z = EZ
          FOUND = .TRUE.
          RETURN
        END IF
   10 CONTINUE
      END

C ----------------------------------------------------------------------
C     WINS: W IS TRUE IF MARK HOLDS A COMPLETE LINE
C ----------------------------------------------------------------------
      SUBROUTINE WINS(B, MARK, W)
      CHARACTER*1 B(3,3), MARK
      INTEGER I, N, EY, EZ
      LOGICAL W
      W = .FALSE.
      DO 10 I = 1, 8
        CALL SCANLN(B, I, MARK, N, EY, EZ)
        IF (N .EQ. 3) W = .TRUE.
   10 CONTINUE
      END

C ----------------------------------------------------------------------
C     VCHECK: SET VICTOR IF SOMEONE HAS WON OR THE BOARD IS FULL
C ----------------------------------------------------------------------
      SUBROUTINE VCHECK(B, VICTOR)
      CHARACTER*1 B(3,3)
      INTEGER VICTOR, R, C
      LOGICAL XWON, OWON
      CALL WINS(B, 'X', XWON)
      CALL WINS(B, 'O', OWON)
      IF (XWON) THEN
        VICTOR = 1
      ELSE IF (OWON) THEN
        VICTOR = 2
      ELSE
        DO 20 R = 1, 3
          DO 10 C = 1, 3
            IF (B(R,C) .EQ. '_') RETURN
   10     CONTINUE
   20   CONTINUE
        VICTOR = 3
      END IF
      END

C ----------------------------------------------------------------------
C     RANDOM NUMBERS: PARK AND MILLER'S "MINIMAL STANDARD" GENERATOR,
C     SEED = 16807 * SEED MOD (2**31 - 1), USING SCHRAGE'S METHOD SO
C     NO INTERMEDIATE RESULT OVERFLOWS A 32-BIT INTEGER.  THE STATE IS
C     KEPT IN COMMON /RNDCOM/, INITIALISED BY BLOCK DATA RNDDAT.  THE
C     BLOCK IS SAVED IN EVERY UNIT THAT NAMES IT: WITHOUT SAVE, F77
C     LETS IT BECOME UNDEFINED ON RETURN (E.G. UNDER AN OVERLAY LOADER).
C ----------------------------------------------------------------------
      BLOCK DATA RNDDAT
      INTEGER ISEED
      COMMON /RNDCOM/ ISEED
      SAVE /RNDCOM/
      DATA ISEED /1/
      END

C     RNDSET: SEED FROM ANY INTEGER (SEED MUST LIE IN 1 .. 2**31-2)
      SUBROUTINE RNDSET(LUCKY)
      INTEGER LUCKY, ISEED, I, K
      COMMON /RNDCOM/ ISEED
      SAVE /RNDCOM/
      ISEED = MOD(LUCKY, 2147483646)
      IF (ISEED .LT. 0) ISEED = -ISEED
      ISEED = ISEED + 1
C     WARM UP SO THAT NEARBY LUCKY NUMBERS GIVE UNRELATED GAMES
      DO 10 I = 1, 8
        CALL RNDINT(2, K)
   10 CONTINUE
      END

C     RNDINT: RETURN K, A RANDOM INTEGER IN 1 .. N
      SUBROUTINE RNDINT(N, K)
      INTEGER N, K, ISEED, IA, IM, IQ, IR, H
      PARAMETER (IA = 16807, IM = 2147483647, IQ = 127773, IR = 2836)
      COMMON /RNDCOM/ ISEED
      SAVE /RNDCOM/
      H = ISEED / IQ
      ISEED = IA * (ISEED - H * IQ) - IR * H
      IF (ISEED .LT. 0) ISEED = ISEED + IM
      K = INT(DBLE(ISEED) / DBLE(IM) * DBLE(N)) + 1
      END

C ----------------------------------------------------------------------
C     TURING: A RANDOM PARTING QUOTE
C ----------------------------------------------------------------------
      SUBROUTINE TURING
      INTEGER COIN
      CHARACTER*55 STARS
      PARAMETER (STARS =
     +  '*******************************************************')
      CALL RNDINT(10, COIN)
      WRITE (*,*)
      IF (COIN .LT. 3) THEN
        WRITE (*,*)
        WRITE (*,*) STARS
        WRITE (*,*)
        WRITE (*,*) '  Machines take me by surprise with great ',
     +              'frequency.'
        WRITE (*,*) '                                      - ',
     +              'Alan Turing'
      ELSE IF (COIN .LT. 5) THEN
        WRITE (*,*) STARS
        WRITE (*,*)
        WRITE (*,*) '  We are not interested in the fact that the ',
     +              'brain has'
        WRITE (*,*) 'the consistency of cold porridge.'
        WRITE (*,*) '                                         - ',
     +              'Alan Turing'
      ELSE IF (COIN .LT. 7) THEN
        WRITE (*,*) STARS
        WRITE (*,*)
        WRITE (*,*) 'I propose to consider the question,'
        WRITE (*,*) '          ''Can machines think?'''
        WRITE (*,*) '                     - Alan Turing'
      ELSE IF (COIN .LT. 9) THEN
        WRITE (*,*) STARS
        WRITE (*,*)
        WRITE (*,*) 'Det. Spooner: Human beings have dreams. Even ',
     +              'dogs have dreams, but not'
        WRITE (*,*) '              you, you are just a machine. An ',
     +              'imitation of life.'
        WRITE (*,*) 'Can a robot write a symphony? Can a robot turn ',
     +              'a... canvas into a beautiful masterpiece?'
        WRITE (*,*) 'Sonny: Can *you*?'
      ELSE
        WRITE (*,*) STARS
        WRITE (*,*) 'Software-industry battles are fought by highly ',
     +              'paid and out-of-shape nerds furiously pounding ',
     +              'computer keyboards while they guzzle diet Coke.'
        WRITE (*,*) '                                - ',
     +              'Nathan Myhrvold'
      END IF
      WRITE (*,*)
      WRITE (*,*) STARS
      WRITE (*,*)
      END
