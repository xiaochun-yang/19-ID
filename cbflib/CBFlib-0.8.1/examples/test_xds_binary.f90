
      PROGRAM TEST

      IMPLICIT  NONE
      CHARACTER(LEN=100) LINE
      INTEGER(2) IFRAME(1000,1000), DPREV
      INTEGER(4) JFRAME(1000,1000)
      INTEGER   IER, I, J, K
      INTERFACE
      INTEGER FUNCTION FCB_READ_XDS_I2(FILNAM,TAPIN,NX,NY,IFRAME,JFRAME)
!-----------------------------------------------------------------------
! Reads a 32 bit integer two's complement image compressed by a
! BYTE-OFFSET algorithm. W. Kabsch,  Version 9-2006
!
! REVISED 1-2007, H. J. Bernstein to conform to CBFlib_0.7.7
! (http://www.bernstein-plus-sons.com/software/CBF)
!
! The BYTE-OFFSET algorithm is a slightly simplified version of
! that described in Andy Hammersley's web page
! (http://www.esrf.fr/computing/Forum/imgCIF/cbf_definition.html)
!
!-----------------------------------------------------------------------
! FILNAM   - Name of the file countaining the image              (GIVEN)
! TAPIN    - Fortran device unit number assigned to image file   (GIVEN)
!   NX     - Number of "fast" pixels of the image                (GIVEN)
!   NY     - Number of "slow" pixels of the image                (GIVEN)
! IFRAME   - 16 bit coded image as needed by XDS                (RESULT)
! JFRAME   - 32 bit scratch array                               (RESULT)
! Returns (as function value)                                   (RESULT)
!             1: cannot handle this CBF format (not implemented)
!             0: No error
!            -1: Cannot determine endian architecture of this machine
!            -2: Cannot open image file
!            -3: Wrong image format
!            -4: Cannot read image
!-----------------------------------------------------------------------
      IMPLICIT                       NONE
      CHARACTER(len=*),INTENT(IN) :: FILNAM
      INTEGER,         INTENT(IN) :: TAPIN,NX,NY
      INTEGER(2),      INTENT(OUT):: IFRAME(NX*NY)
      INTEGER(4),      INTENT(OUT):: JFRAME(NX,NY)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      PRINT *,' NAME OF TEST CBF '
      READ *, LINE
      IER =  FCB_READ_XDS_I2(LINE,9,1000,1000,IFRAME,JFRAME)
      IF (IER.NE.0) THEN
	 PRINT *," ERROR: ", IER
      ELSE
	DPREV = 0
	DO I = 1,1000
	DO J = 1,1000
	  IF (IFRAME(I,J).NE.DPREV) THEN
	    PRINT *,"ROW ", I, ":"
	    PRINT *,(IFRAME(I,K),K=1,1000)
	    DPREV = IFRAME(I,1000)
	    GO TO 1000
	  ENDIF
	END DO
1000    CONTINUE
	END DO
      END IF
      STOP
      END
