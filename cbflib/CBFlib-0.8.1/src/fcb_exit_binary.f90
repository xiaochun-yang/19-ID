
      INTEGER FUNCTION FCB_EXIT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,&
                                      BYTE_IN_FILE,REC_IN_FILE,BUFFER,  &
                                      PADDING )
!-----------------------------------------------------------------------
!     Skip to end of binary section that was just read
!-----------------------------------------------------------------------
      IMPLICIT                   NONE
      INTEGER,   INTENT(IN)   :: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: BYTE_IN_FILE,REC_IN_FILE
      INTEGER(1),INTENT(INOUT):: LAST_CHAR,BUFFER(FCB_BYTES_IN_REC)
      INTEGER(8),INTENT(IN)   :: PADDING
!External functions called
       INTERFACE
      INTEGER FUNCTION FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,     &
				     REC_IN_FILE,BYTE_IN_FILE,IBYTE)
!-----------------------------------------------------------------------
! Get byte number BYTE_IN_FILE from file  (first byte is BYTE_IN_FILE=1)
!-----------------------------------------------------------------------
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      INTEGER(1),  INTENT(OUT):: IBYTE
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
       INTERFACE
      INTEGER FUNCTION FCB_READ_LINE(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,  &
			 BYTE_IN_FILE,REC_IN_FILE,BUFFER,LINE,N,LINELEN)
!-----------------------------------------------------------------------
!     Reads successive bytes into byte array LINE(N), stopping at N,
!     error or first CR(Z'0D') or LF(Z'0A'), discarding a LF after a CR.
!-----------------------------------------------------------------------
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC,N
      INTEGER,   INTENT(INOUT):: BYTE_IN_FILE,REC_IN_FILE
      INTEGER,     INTENT(OUT):: LINELEN
      INTEGER(1),INTENT(INOUT):: LAST_CHAR,BUFFER(FCB_BYTES_IN_REC)
      INTEGER(1),  INTENT(OUT):: LINE(N)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
       INTERFACE
      INTEGER FUNCTION FCB_CI_STRNCMPARR(STRING, ARRAY, N, LIMIT)
!-----------------------------------------------------------------------
! Compares up to LIMIT characters of STRING and ARRAY case insensitive
!-----------------------------------------------------------------------
      CHARACTER(LEN=*),INTENT(IN):: STRING
      INTEGER,         INTENT(IN):: N,LIMIT
      INTEGER(1),      INTENT(IN):: ARRAY(N)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
!-----------------------------------------------------------------------

      INTEGER,PARAMETER           ::  LINESIZE=2048
      INTEGER(1) LINE(LINESIZE)     ! BUFFER FOR THE NEXT LINE
      INTEGER LINELEN               ! VALID CHARACTERS IN LINE
      INTEGER ITEM                  ! 1 FOR MIME ITEM FOUND, 0 OTHERWISE
      INTEGER QUOTE
      INTEGER TEXT_BITS
      INTEGER COUNT
      
      INTEGER BOUND_FOUND
      

      CHARACTER*31 BOUNDARY
      DATA BOUNDARY/"--CIF-BINARY-FORMAT-SECTION----"/
!-----------------------------------------------------------------------

! --  Skip the trailing pad
      BYTE_IN_FILE = BYTE_IN_FILE+PADDING
      
! --  Skip to MIME boundary
      BOUND_FOUND = 0
      DO
        FCB_EXIT_BINARY =                                                  &
          FCB_READ_LINE(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,BYTE_IN_FILE,     &
          REC_IN_FILE,BUFFER,LINE,LINESIZE,LINELEN)
        IF(FCB_EXIT_BINARY.NE.0 ) RETURN
        ! *** DEBUG *** PRINT *," LINELEN, LINE: ", LINELEN, LINE(1:LINELEN)
        IF (BOUND_FOUND .EQ. 0) THEN
          IF (FCB_CI_STRNCMPARR(BOUNDARY,LINE,LINELEN,31).EQ.0) THEN
            BOUND_FOUND = 1
          ! *** DEBUG *** PRINT *,  &
          !  "MIME BOUNDARY --CIF-BINARY-FORMAT-SECTION---- FOUND"
          END IF
        END IF
        IF (LINE(1).EQ.IACHAR(';')) THEN
          IF (LINELEN.EQ.1.OR.LINE(2).EQ.32.OR.LINE(2).EQ.9)  THEN
            IF (BOUND_FOUND.EQ.0) THEN
              PRINT *, " END OF TEXT FOUND BEFORE MIME BOUNDARY"
            ELSE
              EXIT
            END IF
          END IF
        END IF
      END DO

      FCB_EXIT_BINARY = 0
      RETURN
      END FUNCTION FCB_EXIT_BINARY

