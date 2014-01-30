
      INTEGER FUNCTION FCB_OPEN_CIFIN(FILNAM,TAPIN,LAST_CHAR,                &
      FCB_BYTES_IN_REC,BYTE_IN_FILE,REC_IN_FILE,BUFFER)
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
      INTEGER                        FCB_RECORD_SIZE
      
      INTEGER,PARAMETER:: &
        CBF_FORMAT            = Z'00000001'    !      1
      INTEGER,PARAMETER:: &
        CBF_FILEOPEN          = Z'00000100'    !    256
      INTEGER,PARAMETER:: &
        CBF_FILEREAD          = Z'00000200'    !    512
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
      INQUIRE(IOLENGTH=FCB_RECORD_SIZE)BUFFER
      OPEN(UNIT=TAPIN,FILE=TRIM(FILNAM),STATUS='OLD',ACTION='READ',     &
        ACCESS='DIRECT',FORM='UNFORMATTED',RECL=FCB_RECORD_SIZE,        &
        IOSTAT=FCB_OPEN_CIFIN)
      ! *** DEBUG *** PRINT *, "RECL: ", FCB_RECORD_SIZE
      DO BYTE_IN_FILE = 1, FCB_BYTES_IN_REC
        BUFFER(BYTE_IN_FILE) = 0
      END DO
      READ(TAPIN,REC=1,IOSTAT=FCB_OPEN_CIFIN)BUFFER     !Read the first record 
      IF (FCB_CI_STRNCMPARR("###CBF: ",BUFFER,FCB_BYTES_IN_REC,8).NE.0) &
       THEN
        FCB_OPEN_CIFIN = CBF_FILEREAD
      ENDIF !Check for presence of the CBF-format keyword
      REC_IN_FILE=1
      BYTE_IN_FILE=0
      LAST_CHAR=0

      
      RETURN
      END FUNCTION FCB_OPEN_CIFIN
