
      PROGRAM TEST

      IMPLICIT  NONE
      CHARACTER(LEN=100) LINE
      INTEGER(2) IFRAME(1000,1000), DPREV
      INTEGER(4) JFRAME(1000,1000)
      INTEGER(4) KFRAME(50,60,70)
      INTEGER,PARAMETER:: FCB_BYTES_IN_REC=131072
      INTEGER   IER, I, J, K, TAPIN, SIZE
      INTEGER   BYTE_IN_FILE, REC_IN_FILE, DTARG, ID
      INTEGER(1) LAST_CHAR, BUFFER(FCB_BYTES_IN_REC)
      INTEGER COMPRESSION, BITS, VORZEICHEN, REELL, ENCODING
      INTEGER(8) DIM1, DIM2, DIM3, DIMOVER, PADDING
      INTEGER(8) NELEM, NELEM_READ
      CHARACTER(len=24)   DIGEST
      CHARACTER(len=14)   BYTEORDER

      
      
      INTERFACE
      INTEGER FUNCTION FCB_EXIT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,&
                                      BYTE_IN_FILE,REC_IN_FILE,BUFFER,  &
                                      PADDING )
!-----------------------------------------------------------------------
!     Skip to end of binary section that was just read
!-----------------------------------------------------------------------
      INTEGER,   INTENT(IN)   :: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: BYTE_IN_FILE,REC_IN_FILE
      INTEGER(1),INTENT(INOUT):: LAST_CHAR,BUFFER(FCB_BYTES_IN_REC)
      INTEGER(8),INTENT(IN)   :: PADDING
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      INTERFACE
      INTEGER FUNCTION FCB_OPEN_CIFIN(FILNAM,TAPIN,LAST_CHAR,                &
      FCB_BYTES_IN_REC,BYTE_IN_FILE,REC_IN_FILE,BUFFER)
!-----------------------------------------------------------------------
! --  Open CBF file named FILNAM and connect to unit number TAPIN
!-----------------------------------------------------------------------
!     We have chosen to use the direct access method to read the file
!     with explicit buffer handling. This approach is general but
!     clumpsy. Rather than putting the buffer and its control variables
!     into COMMON these are passed as local arguments to make the routines
!     inherently 'threadsafe' in a parallel programming environment.
!     Note also, that a reading error could occur for the last record
!     if it did not fill a full block. This could be avoided if the
!     images were padded with a sufficient number of additional bytes
!     (arbitrary values) after the end of the valid binary data.
!
!     The more natural method would use byte stream I/O which is,
!     unfortunately, only an extension of Fortran 90 that has been
!     implemented in some compilers (like the Intel ifort) but
!     not in all (like the SGI IRIX f90).
!     For BSD style opens, there is a special variant on the direct
!     access open with a recl of 1 to give byte-by-byte access.
!-----------------------------------------------------------------------
! FILNAM   - Name of the file countaining the image              (GIVEN)
! TAPIN    - Fortran device unit number assigned to image file   (GIVEN)
! LAST_CHAR - 
!            Last character read                                (RESULT)
! FCB_BYTES_IN_REC -
!            Number of bytes in a record                         (GIVEN)
! BYTE_IN_FILE -
!            Byte (counting from 1) of the byte to read         (RESULT)
! REC_IN_FILE -
!            Record (counting from 1) of next record to read    (RESULT)
! BUFFER -   Array of length FCB_BYTES_IN_REC                    (GIVEN)
!-----------------------------------------------------------------------
      IMPLICIT                   NONE
      CHARACTER(len=*),INTENT(IN) :: FILNAM
      INTEGER,         INTENT(IN) :: TAPIN,FCB_BYTES_IN_REC
      INTEGER(1),      INTENT(OUT):: LAST_CHAR
      INTEGER,         INTENT(OUT):: BYTE_IN_FILE,REC_IN_FILE
      INTEGER(1),    INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      INTERFACE
      INTEGER FUNCTION FCB_NEXT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,&
                                      BYTE_IN_FILE,REC_IN_FILE,BUFFER,  &
                                      ENCODING,SIZE,ID,DIGEST,          &
                                      COMPRESSION,BITS,VORZEICHEN,REELL,&
                                      BYTEORDER,DIMOVER,DIM1,DIM2,DIM3, &
                                      PADDING )
!-----------------------------------------------------------------------
!     Skip to the next binary and parse MIME header.
!-----------------------------------------------------------------------
      INTEGER,   INTENT(IN)   :: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: BYTE_IN_FILE,REC_IN_FILE
      INTEGER(1),INTENT(INOUT):: LAST_CHAR,BUFFER(FCB_BYTES_IN_REC)
      INTEGER,   INTENT(OUT)  :: ENCODING,SIZE,ID,COMPRESSION,BITS,  &
                                 VORZEICHEN,REELL
      CHARACTER(*), INTENT(OUT):: BYTEORDER,DIGEST
      INTEGER(8),      INTENT(OUT):: DIMOVER
      INTEGER(8),      INTENT(OUT):: DIM1
      INTEGER(8),      INTENT(OUT):: DIM2
      INTEGER(8),      INTENT(OUT):: DIM3
      INTEGER(8),      INTENT(OUT):: PADDING

      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      INTERFACE
      INTEGER FUNCTION FCB_READ_IMAGE_I2(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, PADDING,                &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,                     &
        REC_IN_FILE,BUFFER)
      
!-----------------------------------------------------------------------
! Reads a 16-bit integer twos complement 2D image
!
! compressed by a BYTE_OFFSET algorithm by W. Kabsch based
! on a proposal by A. Hammersley or
! compressed by a PACKED algorithm by J. P. Abrahams as
! used in CCP4, with modifications by P. Ellis and
! H. J. Bernstein.
!
! The BYTE-OFFSET algorithm is a slightly simplified version of
! that described in Andy Hammersley's web page
! (http://www.esrf.fr/computing/Forum/imgCIF/cbf_definition.html)
!
!-----------------------------------------------------------------------
! ARRAY    - Image                                              (RESULT)
! NELEM    - The number of elements to be read                   (GIVEN)
! NELEM_READ
!          - The number of elements actually read               (RESULT)
! ELSIGN   - Flag for signed (1) OR unsigned (0) data            (GIVEN)
! COMPRESSION
!          - The actual compression of the image                (RESULT)
! DIM1     - The fastest dimension of ARRAY                      (GIVEN)
! DIM2     - The slowest dimension                               (GIVEN)
! TAPIN    - Fortran device unit number assigned to image file   (GIVEN)
! FCB_BYTES_IN_REC
!          - The number of bytes in each bufferload to read      (GIVEN)
! BYTE_IN_FILE
!          - The position in the file of the next byte to read   (GIVEN,
!                                                                RESULT)
! REC_IN_FILE
!          - The record number from 1 of the block in BUFFER     (GIVEN,
!                                                                RESULT)
! BUFFER   - Buffer of bytes read from the file                  (GIVEN,
!                                                                RESULT)
! PADDING  - Pad bytes after the binary                         (RESULT)
!
! Returns (as function value)                                   (RESULT)
!             CBF_FORMAT (=1): 
!                cannot handle this CBF format (not implemented)
!             0: No error
!-----------------------------------------------------------------------
      INTEGER(8),   INTENT(IN):: DIM1,DIM2
      INTEGER(2),  INTENT(OUT):: ARRAY(DIM1,DIM2)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN
      INTEGER,     INTENT(OUT):: COMPRESSION
      INTEGER(8),  INTENT(OUT):: PADDING
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      INTERFACE
      INTEGER FUNCTION FCB_READ_IMAGE_I4(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, PADDING,                &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,                     &
        REC_IN_FILE,BUFFER)
      
!-----------------------------------------------------------------------
! Reads a 32-bit integer twos complement 2D image
!
! compressed by a BYTE_OFFSET algorithm by W. Kabsch based
! on a proposal by A. Hammersley or
! compressed by a PACKED algorithm by J. P. Abrahams as
! used in CCP4, with modifications by P. Ellis and
! H. J. Bernstein.
!
! The BYTE-OFFSET algorithm is a slightly simplified version of
! that described in Andy Hammersley's web page
! (http://www.esrf.fr/computing/Forum/imgCIF/cbf_definition.html)
!
!-----------------------------------------------------------------------
! ARRAY    - Image                                              (RESULT)
! NELEM    - The number of elements to be read                   (GIVEN)
! NELEM_READ
!          - The number of elements actually read               (RESULT)
! ELSIGN   - Flag for signed (1) OR unsigned (0) data            (GIVEN)
! COMPRESSION
!          - The actual compression of the image                (RESULT)
! DIM1     - The fastest dimension of ARRAY                      (GIVEN)
! DIM2     - The slowest dimension                               (GIVEN)
! TAPIN    - Fortran device unit number assigned to image file   (GIVEN)
! FCB_BYTES_IN_REC
!          - The number of bytes in each bufferload to read      (GIVEN)
! BYTE_IN_FILE
!          - The position in the file of the next byte to read   (GIVEN,
!                                                                RESULT)
! REC_IN_FILE
!          - The record number from 1 of the block in BUFFER     (GIVEN,
!                                                                RESULT)
! BUFFER   - Buffer of bytes read from the file                  (GIVEN,
!                                                                RESULT)
! PADDING  - Pad bytes after the binary                         (RESULT)
!
! Returns (as function value)                                   (RESULT)
!             CBF_FORMAT (=1): 
!                cannot handle this CBF format (not implemented)
!             0: No error
!-----------------------------------------------------------------------
      INTEGER(8),   INTENT(IN):: DIM1,DIM2
      INTEGER(4),  INTENT(OUT):: ARRAY(DIM1,DIM2)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN
      INTEGER,     INTENT(OUT):: COMPRESSION
      INTEGER(8),  INTENT(OUT):: PADDING
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      INTERFACE
      INTEGER FUNCTION FCB_READ_IMAGE_3D_I2(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, DIM3, PADDING,        &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,                   &
        REC_IN_FILE,BUFFER)
      
!-----------------------------------------------------------------------
! Reads a 16-bit integer twos complement 3D image
!
! compressed by a BYTE_OFFSET algorithm by W. Kabsch based
! on a proposal by A. Hammersley or
! compressed by a PACKED algorithm by J. P. Abrahams as
! used in CCP4, with modifications by P. Ellis and
! H. J. Bernstein.
!
! The BYTE-OFFSET algorithm is a slightly simplified version of
! that described in Andy Hammersley's web page
! (http://www.esrf.fr/computing/Forum/imgCIF/cbf_definition.html)
!
!-----------------------------------------------------------------------
! ARRAY    - Image                                              (RESULT)
! NELEM    - The number of elements to be read                   (GIVEN)
! NELEM_READ
!          - The number of elements actually read               (RESULT)
! ELSIGN   - Flag for signed (1) OR unsigned (0) data            (GIVEN)
! COMPRESSION
!          - The actual compression of the image                (RESULT)
! DIM1     - The fastest dimension of ARRAY                      (GIVEN)
! DIM2     - The slowest dimension                               (GIVEN)
! TAPIN    - Fortran device unit number assigned to image file   (GIVEN)
! FCB_BYTES_IN_REC
!          - The number of bytes in each bufferload to read      (GIVEN)
! BYTE_IN_FILE
!          - The position in the file of the next byte to read   (GIVEN,
!                                                                RESULT)
! REC_IN_FILE
!          - The record number from 1 of the block in BUFFER     (GIVEN,
!                                                                RESULT)
! BUFFER   - Buffer of bytes read from the file                  (GIVEN,
!                                                                RESULT)
! PADDING  - Pad bytes after the binary                         (RESULT)
!
! Returns (as function value)                                   (RESULT)
!             CBF_FORMAT (=1): 
!                cannot handle this CBF format (not implemented)
!             0: No error
!-----------------------------------------------------------------------
      INTEGER(8),   INTENT(IN):: DIM1,DIM2,DIM3
      INTEGER(2),  INTENT(OUT):: ARRAY(DIM1,DIM2,DIM3)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN
      INTEGER,     INTENT(OUT):: COMPRESSION
      INTEGER(8),  INTENT(OUT):: PADDING
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      INTERFACE
      INTEGER FUNCTION FCB_READ_IMAGE_3D_I4(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, DIM3, PADDING,        &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,                   &
        REC_IN_FILE,BUFFER)
      
!-----------------------------------------------------------------------
! Reads a 32-bit integer twos complement 3D image
!
! compressed by a BYTE_OFFSET algorithm by W. Kabsch based
! on a proposal by A. Hammersley or
! compressed by a PACKED algorithm by J. P. Abrahams as
! used in CCP4, with modifications by P. Ellis and
! H. J. Bernstein.
!
! The BYTE-OFFSET algorithm is a slightly simplified version of
! that described in Andy Hammersley's web page
! (http://www.esrf.fr/computing/Forum/imgCIF/cbf_definition.html)
!
!-----------------------------------------------------------------------
! ARRAY    - Image                                              (RESULT)
! NELEM    - The number of elements to be read                   (GIVEN)
! NELEM_READ
!          - The number of elements actually read               (RESULT)
! ELSIGN   - Flag for signed (1) OR unsigned (0) data            (GIVEN)
! COMPRESSION
!          - The actual compression of the image                (RESULT)
! DIM1     - The fastest dimension of ARRAY                      (GIVEN)
! DIM2     - The slowest dimension                               (GIVEN)
! TAPIN    - Fortran device unit number assigned to image file   (GIVEN)
! FCB_BYTES_IN_REC
!          - The number of bytes in each bufferload to read      (GIVEN)
! BYTE_IN_FILE
!          - The position in the file of the next byte to read   (GIVEN,
!                                                                RESULT)
! REC_IN_FILE
!          - The record number from 1 of the block in BUFFER     (GIVEN,
!                                                                RESULT)
! BUFFER   - Buffer of bytes read from the file                  (GIVEN,
!                                                                RESULT)
! PADDING  - Pad bytes after the binary                         (RESULT)
!
! Returns (as function value)                                   (RESULT)
!             CBF_FORMAT (=1): 
!                cannot handle this CBF format (not implemented)
!             0: No error
!-----------------------------------------------------------------------
      INTEGER(8),   INTENT(IN):: DIM1,DIM2,DIM3
      INTEGER(4),  INTENT(OUT):: ARRAY(DIM1,DIM2,DIM3)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN
      INTEGER,     INTENT(OUT):: COMPRESSION
      INTEGER(8),  INTENT(OUT):: PADDING
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
      
      TAPIN=9

      PRINT *,' NAME OF TEST CBF '
      READ *, LINE
      
      IER = FCB_OPEN_CIFIN(LINE,TAPIN,LAST_CHAR,                &
      FCB_BYTES_IN_REC,BYTE_IN_FILE,REC_IN_FILE,BUFFER)
      IF (IER.NE.0) THEN
        PRINT *,"FILE OPEN ERROR: ", IER
        STOP
      END IF

      ! Read an  array 1000 x 1000 INTEGER(4) in a flat field of 1000
 
       PRINT *, " 1000 x 1000 I4 TEST "

     
      NELEM = 1000*1000
      DIM1 = 1000
      DIM2 = 1000
      IER =  FCB_READ_IMAGE_I4(JFRAME,NELEM,NELEM_READ, &
        1, COMPRESSION, DIM1, DIM2,  PADDING,           &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,            &
        REC_IN_FILE,BUFFER)

      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_READ_IMAGE_I4 ERROR: ", IER
         STOP
      ELSE
        DPREV = 0
        DO J = 1,1000
        DO I = 1,1000
          DTARG = 1000
          IF (JFRAME(I,J).NE.DTARG) THEN
            PRINT *, "IFRAME(",I,",",J,") = ", &
              JFRAME(I,J), ", SHOULD BE ",DTARG
          END IF
        END DO
        END DO
      END IF
      
      IER = FCB_EXIT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,&
              BYTE_IN_FILE,REC_IN_FILE,BUFFER, PADDING )
              
      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_EXIT_BINARY ERROR: ", IER
         STOP
      END IF
      
 
      ! Read an  array 1000 x 1000 INTEGER(2) in a flat field of 1000

      PRINT *, " 1000 x 1000 I2 TEST "

  
      IER =  FCB_READ_IMAGE_I2(IFRAME,NELEM,NELEM_READ, &
        1, COMPRESSION, DIM1, DIM2,  PADDING,           &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,            &
        REC_IN_FILE,BUFFER)

      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_READ_IMAGE_I2 ERROR: ", IER
         STOP
      ELSE
        DPREV = 0
        DO J = 1,1000
        DO I = 1,1000
          DTARG = 1000
          IF (IFRAME(I,J).NE.DTARG) THEN
            PRINT *, "IFRAME(",I,",",J,") = ", &
              IFRAME(I,J), ", SHOULD BE ",DTARG
          END IF
        END DO
        END DO
      END IF
      
      IER = FCB_EXIT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,&
              BYTE_IN_FILE,REC_IN_FILE,BUFFER, PADDING )
              
      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_EXIT_BINARY ERROR: ", IER
         STOP
      END IF
      

      ! Read an  array 1000 x 1000 INTEGER(4) in a flat field of 1000
      !   except for -3 along the main diagonal and its transpose

      PRINT *, " 1000 x 1000 I4 TEST, WITH -3 on diag and transpose "


      IER =  FCB_READ_IMAGE_I4(JFRAME,NELEM,NELEM_READ, &
        1, COMPRESSION, DIM1, DIM2,  PADDING,           &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,            &
        REC_IN_FILE,BUFFER)

      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_READ_IMAGE_I4 ERROR: ", IER
         STOP
      ELSE
        DPREV = 0
        DO J = 1,1000
        DO I = 1,1000
          DTARG = 1000
          IF (I .EQ. J .OR. 1001-I .EQ. J) THEN
            DTARG = -3
          END IF
          IF (JFRAME(I,J).NE.DTARG) THEN
            PRINT *, "IFRAME(",I,",",J,") = ", &
              JFRAME(I,J), ", SHOULD BE ",DTARG
          END IF
        END DO
        END DO
      END IF
     
      IER = FCB_EXIT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,&
              BYTE_IN_FILE,REC_IN_FILE,BUFFER, PADDING )
              
      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_EXIT_BINARY ERROR: ", IER
         STOP
      END IF
      

      ! Read an  array 1000 x 1000 INTEGER(2) in a flat field of 1000
      !   except for -3 along the main diagonal and its transpose


      PRINT *, " 1000 x 1000 I2 TEST, WITH -3 on diag and transpose "

      IER =  FCB_READ_IMAGE_I2(IFRAME,NELEM,NELEM_READ, &
        1, COMPRESSION, DIM1, DIM2,  PADDING,           &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,            &
        REC_IN_FILE,BUFFER)

      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_READ_IMAGE_I2 ERROR: ", IER
         STOP
      ELSE
        DPREV = 0
        DO J = 1,1000
        DO I = 1,1000
          DTARG = 1000
          IF (I .EQ. J .OR. 1001-I .EQ. J) THEN
            DTARG = -3
          END IF
          IF (IFRAME(I,J).NE.DTARG) THEN
            PRINT *, "IFRAME(",I,",",J,") = ", &
              IFRAME(I,J), ", SHOULD BE ",DTARG
          END IF
        END DO
        END DO
      END IF
      

      IER = FCB_EXIT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,&
              BYTE_IN_FILE,REC_IN_FILE,BUFFER, PADDING )
              
      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_EXIT_BINARY ERROR: ", IER
         STOP
      END IF
      
            
      ! Read an array 50 x 60 x 70 INTEGER(4) in a flat field of 1000, 
      !  except for -3 along the main diagonal and the values i+j+k-3 
      !  every 1000th pixel

      PRINT *, " 50 x 60 x 70 3D_I4 TEST "

      DIM1 = 50
      DIM2 = 60
      DIM3 = 70
      NELEM = DIM1*DIM2*DIM3

      IER =  FCB_READ_IMAGE_3D_I4(KFRAME,NELEM,NELEM_READ, &
        1, COMPRESSION, DIM1, DIM2, DIM3, PADDING,           &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,            &
        REC_IN_FILE,BUFFER)

      IF (IER.NE.0) THEN 
         PRINT *,"  FCB_READ_IMAGE_3D_I4 ERROR: ", IER
         STOP
      ELSE
        DPREV = 0
        DO K = 1,70
        DO J = 1,60
        DO I = 1,50
           DTARG = 1000
          IF (I .EQ. J .OR. J .EQ. K) THEN
            DTARG = -3
          END IF
          IF (MOD(I-1+(J-1)*50+(K-1)*50*60,1000).EQ.0) THEN
            DTARG = I+J+K-3
          END IF
          IF (KFRAME(I,J,K).NE.DTARG) THEN
            PRINT *, "KFRAME(",I,",",J,",",K,") = ", &
              KFRAME(I,J,K), ", SHOULD BE ",DTARG
          END IF
        END DO
        END DO
        END DO
      END IF
      
      PRINT *, "TESTS COMPLETED"


      STOP
      END
