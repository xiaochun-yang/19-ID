



      
      !  FCB_READ_IMAGE_I2.F90
!
!  Derived from f90 test code by W. Kabsch
!  H. J. Bernstein, 24 March 2007
!
!  Reads the next binary image from a CIF files that
!  has already been opened.  Leaves the file open and
!  positioned just after the binary and still within
!  the text field
!
!  This version is for
!
!  2-D INTEGER*2 arrays
!
!  with function
!
!  FCB_READ_IMAGE_I2

      INTEGER FUNCTION FCB_READ_IMAGE_I2(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2,  &
        PADDING,TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,             &
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
      IMPLICIT                       NONE

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



! --  Definition of CBF_FORMAT
      INTEGER,PARAMETER:: &
        CBF_FORMAT            = Z'00000001'    !      1
! --  External functions called
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
      INTERFACE
      INTEGER FUNCTION FCB_DECOMPRESS_PACKED_I2 (ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2,      &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,  &
        REC_IN_FILE,BUFFER)
      INTEGER(8),   INTENT(IN):: DIM1,DIM2 
      INTEGER(2),  INTENT(OUT):: ARRAY(DIM1,DIM2)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN, COMPRESSION
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
! --  Local variables
      INTEGER             STEP,FIRST2,LAST2,FIRST4,LAST4,II,I,J
      INTEGER(4)          DIFF,PIXVALUE,MARKER,IADR
      INTEGER(2)          SHORTINT
      INTEGER(1)          LAST_CHAR,ONEBYTE,                          &
                          TWOBYTES(2),FOURBYTES(4),ENDIANORDER(4),    &
                          MARKBYTES(4)
      INTEGER  ENCODING

      !
      !     Definitions of CBF encodings parameters
      !
      INTEGER,PARAMETER:: &
        ENC_NONE         = Z'0001', & !Use BINARY encoding
        ENC_BASE64       = Z'0002', & !Use BASE64 encoding
        ENC_BASE32K      = Z'0004', & !Use X-BASE32K encoding
        ENC_QP           = Z'0008', & !Use QUOTED-PRINTABLE encoding
        ENC_BASE10       = Z'0010', & !Use BASE10 encoding
        ENC_BASE16       = Z'0020', & !Use BASE16 encoding
        ENC_BASE8        = Z'0040'    !Use BASE8  encoding

      INTEGER  SIZE
      INTEGER  ID

      !
      !     Definitions of CBF compression parameters
      !
      INTEGER,PARAMETER:: &
        CBF_INTEGER      = Z'0010', & !Uncompressed integer
        CBF_FLOAT        = Z'0020', & !Uncompressed IEEE floating point
        CBF_CANONICAL    = Z'0050', & !Canonical compression
        CBF_PACKED       = Z'0060', & !Packed compression
        CBF_PACKED_V2    = Z'0090', & !Packed compression
        CBF_BYTE_OFFSET  = Z'0070', & !Byte Offset Compression
        CBF_PREDICTOR    = Z'0080', & !Predictor_Huffman Compression
        CBF_NONE         = Z'0040', & !No compression flag
        CBF_COMPRESSION_MASK =     &
                           Z'00FF', & !Mask to sep compressiontype from flags
        CBF_FLAG_MASK    = Z'0F00', & !Mask to sep flags from compression type
        CBF_UNCORRELATED_SECTIONS =&
                           Z'0100', & !Flag for uncorrelated sections
        CBF_FLAT_IMAGE   = Z'0200'    !Flag for flat (linear) images


      INTEGER  BITS,VORZEICHEN,REELL
      CHARACTER(len=24)   DIGEST
      CHARACTER(len=14)   BYTEORDER
      !Possible parameter values for BYTEORDER are:
	 !"LITTLE_ENDIAN"     supported
	 !"BIG_ENDIAN"    not supported
      INTEGER(8)  DIMOVER
      INTEGER(8)  LDIM1       !Number of "fast" pixels of the image
      INTEGER(8)  LDIM2       !Number of "slow" pixels of the image
      INTEGER(8)  LDIM3
      INTEGER(4)  PREV_ELEMENT

      DATA             ENDIANORDER/Z'12',Z'34',Z'56',Z'78'/
      DATA             MARKBYTES/Z'0C',Z'1A',Z'04',Z'D5'/

!-----------------------------------------------------------------------
! --  Determine endian architecture of this machine
!-----------------------------------------------------------------------
! Definition: If the lowest memory address of multi-byte data is
!             considered the starting address of the data, the least
!             significant byte (LSB) is at the lowest memory address
!             for a 'little_endian' cpu architecture.
!
! Example:    The 32 bit hex value Z'12345678' is stored as follows:
!             ENDIAN ORDER   BYTE0   BYTE1 BYTE2 BYTE3
!              Big Endian    12       34    56    78(LSB)
!            Little Endian   78(LSB)  56    34    12
!-----------------------------------------------------------------------
      PIXVALUE=TRANSFER(ENDIANORDER,PIXVALUE)
      STEP=0
      IF (PIXVALUE .EQ. Z'78563412') THEN !Little Endian machine
	 STEP=1
	 FIRST2=1;LAST2=2
	 FIRST4=1;LAST4=4
      ENDIF
      IF (PIXVALUE .EQ. Z'12345678') THEN ! Big Endian machine
	 STEP=-1
	 FIRST2=2;LAST2=1
	 FIRST4=4;LAST4=1
      ENDIF
      IF (STEP.EQ.0)GO TO 110

!-----------------------------------------------------------------------
! --   Skip to the next binary and parse the MIME header
!-----------------------------------------------------------------------
      IF (FCB_NEXT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,BYTE_IN_FILE,&
	REC_IN_FILE,BUFFER,ENCODING,SIZE,ID,DIGEST,COMPRESSION,BITS,        &
	VORZEICHEN,REELL,BYTEORDER,DIMOVER,LDIM1,LDIM2,LDIM3,PADDING).NE.0) &
	 GO TO 130
      IF ((DIM1.NE.LDIM1).OR.(DIM2.NE.LDIM2))GO TO 130

!-----------------------------------------------------------------------
! --  Advance to start of binary image data
!-----------------------------------------------------------------------
! In CBF the binary data begins immediately after the first occurence
! of the following 4 bytes (MARKBYTES) in the image file
!             Octet    Hex  Decimal             Purpose
!               1       0C   12       (ctrl-L) End the current page
!               2       1A   26       (ctrl-Z) Stop listings in MS-DOS
!               3       04   04       (Ctrl-D) Stop listings in UNIX
!               4       D5   213      Binary section begins
!               5..5+n-1              Binary data (n octets)
!-----------------------------------------------------------------------
      MARKER=TRANSFER(MARKBYTES,MARKER)
      FOURBYTES=0
      DO
	 DO I=1,3
	    FOURBYTES(I)=FOURBYTES(I+1)
	 ENDDO
	 BYTE_IN_FILE=BYTE_IN_FILE+1
	 IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,               &
	    REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(4)).NE.0) GO TO 140
	 PIXVALUE=TRANSFER(FOURBYTES,PIXVALUE)
	 IF (PIXVALUE.EQ.MARKER)EXIT
      ENDDO
      ! *** DEBUG *** PRINT *, "fwa-1 address of IMAGE at: "
      ! *** DEBUG *** PRINT *, "BYTE_IN_FILE: ", BYTE_IN_FILE
      ! *** DEBUG *** PRINT *, "REC_IN_FILE: ", REC_IN_FILE

!-----------------------------------------------------------------------
! --  Read data image of 32 bit two's complement integers, compressed
! --  by the BYTE-OFFSET algorithm.
! --  After the expansion the original pixel values are coded by 16 bit
! --  in a special way suitable for XDS (see INTEGER*2 FUNCTION CNT2PIX).
!-----------------------------------------------------------------------
      FCB_READ_IMAGE_I2=CBF_FORMAT  !Cannot handle this CBF format
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.&
	  (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_BYTE_OFFSET))THEN
	 PIXVALUE=0
	 NELEM_READ=0
	 
     DO J = 1, DIM2
     DO I = 1, DIM1
	    BYTE_IN_FILE=BYTE_IN_FILE+1
	    IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,            &
	       REC_IN_FILE,BYTE_IN_FILE,ONEBYTE).NE.0) GO TO 140
	    DIFF=ONEBYTE
	    IF (DIFF.EQ.-128)THEN
	       DO II=FIRST2,LAST2,STEP
		  BYTE_IN_FILE=BYTE_IN_FILE+1
		  IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,      &
		     REC_IN_FILE,BYTE_IN_FILE,TWOBYTES(II)).NE.0)GO TO 140
	       ENDDO
	       SHORTINT=TRANSFER(TWOBYTES,SHORTINT)
	       DIFF=SHORTINT
	       IF (DIFF.EQ.-32768)THEN
		  DO II=FIRST4,LAST4,STEP
		     BYTE_IN_FILE=BYTE_IN_FILE+1
		     IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,   &
			REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(II)).NE.0)    &
			GO TO 140
		  ENDDO
		  DIFF=TRANSFER(FOURBYTES,DIFF)
	       ENDIF
	    ENDIF
	    PIXVALUE=PIXVALUE+DIFF
	    ARRAY(I,J) = PIXVALUE
	    NELEM_READ=NELEM_READ+1
	 ENDDO
	 ENDDO
	 
	 FCB_READ_IMAGE_I2=0  !No error
	 ELSE
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.    &
	  ((IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED) .OR.          &
	   (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED_V2)))THEN
	  FCB_READ_IMAGE_I2=FCB_DECOMPRESS_PACKED_I2 (ARRAY,NELEM,NELEM_READ,   &
        VORZEICHEN, COMPRESSION, DIM1, DIM2,  &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,        &
        REC_IN_FILE,BUFFER)
      IF (NELEM_READ.NE.NELEM) PRINT *, "EARLY TERMINATION AT ",NELEM_READ
      PREV_ELEMENT = 0
      END IF
    END IF

!-----------------------------------------------------------------------
100   RETURN
110   FCB_READ_IMAGE_I2=-1 !Cannot determine endian architecture of this machine
      RETURN
130   FCB_READ_IMAGE_I2=-3 !Wrong image format
      GO TO 100
140   FCB_READ_IMAGE_I2=-4 !Cannot read image
      GO TO 100
      END FUNCTION FCB_READ_IMAGE_I2

      !  FCB_READ_IMAGE_I4.F90
!
!  Derived from f90 test code by W. Kabsch
!  H. J. Bernstein, 24 March 2007
!
!  Reads the next binary image from a CIF files that
!  has already been opened.  Leaves the file open and
!  positioned just after the binary and still within
!  the text field
!
!  This version is for
!
!  2-D INTEGER*4 arrays
!
!  with function
!
!  FCB_READ_IMAGE_I4

      INTEGER FUNCTION FCB_READ_IMAGE_I4(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2,  &
        PADDING,TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,             &
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
      IMPLICIT                       NONE

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



! --  Definition of CBF_FORMAT
      INTEGER,PARAMETER:: &
        CBF_FORMAT            = Z'00000001'    !      1
! --  External functions called
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
      INTERFACE
      INTEGER FUNCTION FCB_DECOMPRESS_PACKED_I4 (ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2,  &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,                   &
        REC_IN_FILE,BUFFER)
      INTEGER(8),   INTENT(IN):: DIM1,DIM2 
      INTEGER(4),  INTENT(OUT):: ARRAY(DIM1,DIM2)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN, COMPRESSION
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
! --  Local variables
      INTEGER             STEP,FIRST2,LAST2,FIRST4,LAST4,II,I,J
      INTEGER(4)          DIFF,PIXVALUE,MARKER,IADR
      INTEGER(2)          SHORTINT
      INTEGER(1)          LAST_CHAR,ONEBYTE,                          &
                          TWOBYTES(2),FOURBYTES(4),ENDIANORDER(4),    &
                          MARKBYTES(4)
      INTEGER  ENCODING

      !
      !     Definitions of CBF encodings parameters
      !
      INTEGER,PARAMETER:: &
        ENC_NONE         = Z'0001', & !Use BINARY encoding
        ENC_BASE64       = Z'0002', & !Use BASE64 encoding
        ENC_BASE32K      = Z'0004', & !Use X-BASE32K encoding
        ENC_QP           = Z'0008', & !Use QUOTED-PRINTABLE encoding
        ENC_BASE10       = Z'0010', & !Use BASE10 encoding
        ENC_BASE16       = Z'0020', & !Use BASE16 encoding
        ENC_BASE8        = Z'0040'    !Use BASE8  encoding

      INTEGER  SIZE
      INTEGER  ID

      !
      !     Definitions of CBF compression parameters
      !
      INTEGER,PARAMETER:: &
        CBF_INTEGER      = Z'0010', & !Uncompressed integer
        CBF_FLOAT        = Z'0020', & !Uncompressed IEEE floating point
        CBF_CANONICAL    = Z'0050', & !Canonical compression
        CBF_PACKED       = Z'0060', & !Packed compression
        CBF_PACKED_V2    = Z'0090', & !Packed compression
        CBF_BYTE_OFFSET  = Z'0070', & !Byte Offset Compression
        CBF_PREDICTOR    = Z'0080', & !Predictor_Huffman Compression
        CBF_NONE         = Z'0040', & !No compression flag
        CBF_COMPRESSION_MASK =     &
                           Z'00FF', & !Mask to sep compressiontype from flags
        CBF_FLAG_MASK    = Z'0F00', & !Mask to sep flags from compression type
        CBF_UNCORRELATED_SECTIONS =&
                           Z'0100', & !Flag for uncorrelated sections
        CBF_FLAT_IMAGE   = Z'0200'    !Flag for flat (linear) images


      INTEGER  BITS,VORZEICHEN,REELL
      CHARACTER(len=24)   DIGEST
      CHARACTER(len=14)   BYTEORDER
      !Possible parameter values for BYTEORDER are:
	 !"LITTLE_ENDIAN"     supported
	 !"BIG_ENDIAN"    not supported
      INTEGER(8)  DIMOVER
      INTEGER(8)  LDIM1       !Number of "fast" pixels of the image
      INTEGER(8)  LDIM2       !Number of "slow" pixels of the image
      INTEGER(8)  LDIM3
      INTEGER(4)  PREV_ELEMENT

      DATA             ENDIANORDER/Z'12',Z'34',Z'56',Z'78'/
      DATA             MARKBYTES/Z'0C',Z'1A',Z'04',Z'D5'/

!-----------------------------------------------------------------------
! --  Determine endian architecture of this machine
!-----------------------------------------------------------------------
! Definition: If the lowest memory address of multi-byte data is
!             considered the starting address of the data, the least
!             significant byte (LSB) is at the lowest memory address
!             for a 'little_endian' cpu architecture.
!
! Example:    The 32 bit hex value Z'12345678' is stored as follows:
!             ENDIAN ORDER   BYTE0   BYTE1 BYTE2 BYTE3
!              Big Endian    12       34    56    78(LSB)
!            Little Endian   78(LSB)  56    34    12
!-----------------------------------------------------------------------
      PIXVALUE=TRANSFER(ENDIANORDER,PIXVALUE)
      STEP=0
      IF (PIXVALUE .EQ. Z'78563412') THEN !Little Endian machine
	 STEP=1
	 FIRST2=1;LAST2=2
	 FIRST4=1;LAST4=4
      ENDIF
      IF (PIXVALUE .EQ. Z'12345678') THEN ! Big Endian machine
	 STEP=-1
	 FIRST2=2;LAST2=1
	 FIRST4=4;LAST4=1
      ENDIF
      IF (STEP.EQ.0)GO TO 110

!-----------------------------------------------------------------------
! --   Skip to the next binary and parse the MIME header
!-----------------------------------------------------------------------
      IF (FCB_NEXT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,BYTE_IN_FILE,&
	REC_IN_FILE,BUFFER,ENCODING,SIZE,ID,DIGEST,COMPRESSION,BITS,        &
	VORZEICHEN,REELL,BYTEORDER,DIMOVER,LDIM1,LDIM2,LDIM3,PADDING).NE.0) &
	 GO TO 130
      IF ((DIM1.NE.LDIM1).OR.(DIM2.NE.LDIM2))GO TO 130

!-----------------------------------------------------------------------
! --  Advance to start of binary image data
!-----------------------------------------------------------------------
! In CBF the binary data begins immediately after the first occurence
! of the following 4 bytes (MARKBYTES) in the image file
!             Octet    Hex  Decimal             Purpose
!               1       0C   12       (ctrl-L) End the current page
!               2       1A   26       (ctrl-Z) Stop listings in MS-DOS
!               3       04   04       (Ctrl-D) Stop listings in UNIX
!               4       D5   213      Binary section begins
!               5..5+n-1              Binary data (n octets)
!-----------------------------------------------------------------------
      MARKER=TRANSFER(MARKBYTES,MARKER)
      FOURBYTES=0
      DO
	 DO I=1,3
	    FOURBYTES(I)=FOURBYTES(I+1)
	 ENDDO
	 BYTE_IN_FILE=BYTE_IN_FILE+1
	 IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,               &
	    REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(4)).NE.0) GO TO 140
	 PIXVALUE=TRANSFER(FOURBYTES,PIXVALUE)
	 IF (PIXVALUE.EQ.MARKER)EXIT
      ENDDO
      ! *** DEBUG *** PRINT *, "fwa-1 address of IMAGE at: "
      ! *** DEBUG *** PRINT *, "BYTE_IN_FILE: ", BYTE_IN_FILE
      ! *** DEBUG *** PRINT *, "REC_IN_FILE: ", REC_IN_FILE

!-----------------------------------------------------------------------
! --  Read data image of 32 bit two's complement integers, compressed
! --  by the BYTE-OFFSET algorithm.
! --  After the expansion the original pixel values are coded by 16 bit
! --  in a special way suitable for XDS (see INTEGER*2 FUNCTION CNT2PIX).
!-----------------------------------------------------------------------
      FCB_READ_IMAGE_I4=CBF_FORMAT  !Cannot handle this CBF format
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.&
	  (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_BYTE_OFFSET))THEN
	 PIXVALUE=0
	 NELEM_READ=0
	 
     DO J = 1, DIM2
     DO I = 1, DIM1
	    BYTE_IN_FILE=BYTE_IN_FILE+1
	    IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,            &
	       REC_IN_FILE,BYTE_IN_FILE,ONEBYTE).NE.0) GO TO 140
	    DIFF=ONEBYTE
	    IF (DIFF.EQ.-128)THEN
	       DO II=FIRST2,LAST2,STEP
		  BYTE_IN_FILE=BYTE_IN_FILE+1
		  IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,      &
		     REC_IN_FILE,BYTE_IN_FILE,TWOBYTES(II)).NE.0)GO TO 140
	       ENDDO
	       SHORTINT=TRANSFER(TWOBYTES,SHORTINT)
	       DIFF=SHORTINT
	       IF (DIFF.EQ.-32768)THEN
		  DO II=FIRST4,LAST4,STEP
		     BYTE_IN_FILE=BYTE_IN_FILE+1
		     IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,   &
			REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(II)).NE.0)    &
			GO TO 140
		  ENDDO
		  DIFF=TRANSFER(FOURBYTES,DIFF)
	       ENDIF
	    ENDIF
	    PIXVALUE=PIXVALUE+DIFF
	    ARRAY(I,J) = PIXVALUE
	    NELEM_READ=NELEM_READ+1
	 ENDDO
	 ENDDO
	 
	 FCB_READ_IMAGE_I4=0  !No error
	 ELSE
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.    &
	  ((IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED) .OR.          &
	   (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED_V2)))THEN
	  FCB_READ_IMAGE_I4=FCB_DECOMPRESS_PACKED_I4 (ARRAY,NELEM,NELEM_READ,   &
        VORZEICHEN, COMPRESSION, DIM1, DIM2,  &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,        &
        REC_IN_FILE,BUFFER)
      IF (NELEM_READ.NE.NELEM) PRINT *, "EARLY TERMINATION AT ",NELEM_READ
      PREV_ELEMENT = 0
      END IF
    END IF

!-----------------------------------------------------------------------
100   RETURN
110   FCB_READ_IMAGE_I4=-1 !Cannot determine endian architecture of this machine
      RETURN
130   FCB_READ_IMAGE_I4=-3 !Wrong image format
      GO TO 100
140   FCB_READ_IMAGE_I4=-4 !Cannot read image
      GO TO 100
      END FUNCTION FCB_READ_IMAGE_I4

      !  FCB_READ_IMAGE_3D_I2.F90
!
!  Derived from f90 test code by W. Kabsch
!  H. J. Bernstein, 24 March 2007
!
!  Reads the next binary image from a CIF files that
!  has already been opened.  Leaves the file open and
!  positioned just after the binary and still within
!  the text field
!
!  This version is for
!
!  3-D INTEGER*2 arrays
!
!  with function
!
!  FCB_READ_IMAGE_3D_I2

      INTEGER FUNCTION FCB_READ_IMAGE_3D_I2(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, DIM3,  &
        PADDING,TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,             &
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
      IMPLICIT                       NONE

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



! --  Definition of CBF_FORMAT
      INTEGER,PARAMETER:: &
        CBF_FORMAT            = Z'00000001'    !      1
! --  External functions called
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
      INTERFACE
      INTEGER FUNCTION FCB_DECOMPRESS_PACKED_3D_I2 (ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, DIM3,  &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,                   &
        REC_IN_FILE,BUFFER)
      INTEGER(8),   INTENT(IN):: DIM1,DIM2,DIM3 
      INTEGER(2),  INTENT(OUT):: ARRAY(DIM1,DIM2,DIM3)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN, COMPRESSION
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
! --  Local variables
      INTEGER             STEP,FIRST2,LAST2,FIRST4,LAST4,II,I,J,K
      INTEGER(4)          DIFF,PIXVALUE,MARKER,IADR
      INTEGER(2)          SHORTINT
      INTEGER(1)          LAST_CHAR,ONEBYTE,                          &
                          TWOBYTES(2),FOURBYTES(4),ENDIANORDER(4),    &
                          MARKBYTES(4)
      INTEGER  ENCODING

      !
      !     Definitions of CBF encodings parameters
      !
      INTEGER,PARAMETER:: &
        ENC_NONE         = Z'0001', & !Use BINARY encoding
        ENC_BASE64       = Z'0002', & !Use BASE64 encoding
        ENC_BASE32K      = Z'0004', & !Use X-BASE32K encoding
        ENC_QP           = Z'0008', & !Use QUOTED-PRINTABLE encoding
        ENC_BASE10       = Z'0010', & !Use BASE10 encoding
        ENC_BASE16       = Z'0020', & !Use BASE16 encoding
        ENC_BASE8        = Z'0040'    !Use BASE8  encoding

      INTEGER  SIZE
      INTEGER  ID

      !
      !     Definitions of CBF compression parameters
      !
      INTEGER,PARAMETER:: &
        CBF_INTEGER      = Z'0010', & !Uncompressed integer
        CBF_FLOAT        = Z'0020', & !Uncompressed IEEE floating point
        CBF_CANONICAL    = Z'0050', & !Canonical compression
        CBF_PACKED       = Z'0060', & !Packed compression
        CBF_PACKED_V2    = Z'0090', & !Packed compression
        CBF_BYTE_OFFSET  = Z'0070', & !Byte Offset Compression
        CBF_PREDICTOR    = Z'0080', & !Predictor_Huffman Compression
        CBF_NONE         = Z'0040', & !No compression flag
        CBF_COMPRESSION_MASK =     &
                           Z'00FF', & !Mask to sep compressiontype from flags
        CBF_FLAG_MASK    = Z'0F00', & !Mask to sep flags from compression type
        CBF_UNCORRELATED_SECTIONS =&
                           Z'0100', & !Flag for uncorrelated sections
        CBF_FLAT_IMAGE   = Z'0200'    !Flag for flat (linear) images


      INTEGER  BITS,VORZEICHEN,REELL
      CHARACTER(len=24)   DIGEST
      CHARACTER(len=14)   BYTEORDER
      !Possible parameter values for BYTEORDER are:
	 !"LITTLE_ENDIAN"     supported
	 !"BIG_ENDIAN"    not supported
      INTEGER(8)  DIMOVER
      INTEGER(8)  LDIM1       !Number of "fast" pixels of the image
      INTEGER(8)  LDIM2       !Number of "slow" pixels of the image
      INTEGER(8)  LDIM3
      INTEGER(4)  PREV_ELEMENT

      DATA             ENDIANORDER/Z'12',Z'34',Z'56',Z'78'/
      DATA             MARKBYTES/Z'0C',Z'1A',Z'04',Z'D5'/

!-----------------------------------------------------------------------
! --  Determine endian architecture of this machine
!-----------------------------------------------------------------------
! Definition: If the lowest memory address of multi-byte data is
!             considered the starting address of the data, the least
!             significant byte (LSB) is at the lowest memory address
!             for a 'little_endian' cpu architecture.
!
! Example:    The 32 bit hex value Z'12345678' is stored as follows:
!             ENDIAN ORDER   BYTE0   BYTE1 BYTE2 BYTE3
!              Big Endian    12       34    56    78(LSB)
!            Little Endian   78(LSB)  56    34    12
!-----------------------------------------------------------------------
      PIXVALUE=TRANSFER(ENDIANORDER,PIXVALUE)
      STEP=0
      IF (PIXVALUE .EQ. Z'78563412') THEN !Little Endian machine
	 STEP=1
	 FIRST2=1;LAST2=2
	 FIRST4=1;LAST4=4
      ENDIF
      IF (PIXVALUE .EQ. Z'12345678') THEN ! Big Endian machine
	 STEP=-1
	 FIRST2=2;LAST2=1
	 FIRST4=4;LAST4=1
      ENDIF
      IF (STEP.EQ.0)GO TO 110

!-----------------------------------------------------------------------
! --   Skip to the next binary and parse the MIME header
!-----------------------------------------------------------------------
      IF (FCB_NEXT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,BYTE_IN_FILE,&
	REC_IN_FILE,BUFFER,ENCODING,SIZE,ID,DIGEST,COMPRESSION,BITS,        &
	VORZEICHEN,REELL,BYTEORDER,DIMOVER,LDIM1,LDIM2,LDIM3,PADDING).NE.0) &
	 GO TO 130
      IF ((DIM1.NE.LDIM1).OR.(DIM2.NE.LDIM2))GO TO 130

!-----------------------------------------------------------------------
! --  Advance to start of binary image data
!-----------------------------------------------------------------------
! In CBF the binary data begins immediately after the first occurence
! of the following 4 bytes (MARKBYTES) in the image file
!             Octet    Hex  Decimal             Purpose
!               1       0C   12       (ctrl-L) End the current page
!               2       1A   26       (ctrl-Z) Stop listings in MS-DOS
!               3       04   04       (Ctrl-D) Stop listings in UNIX
!               4       D5   213      Binary section begins
!               5..5+n-1              Binary data (n octets)
!-----------------------------------------------------------------------
      MARKER=TRANSFER(MARKBYTES,MARKER)
      FOURBYTES=0
      DO
	 DO I=1,3
	    FOURBYTES(I)=FOURBYTES(I+1)
	 ENDDO
	 BYTE_IN_FILE=BYTE_IN_FILE+1
	 IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,               &
	    REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(4)).NE.0) GO TO 140
	 PIXVALUE=TRANSFER(FOURBYTES,PIXVALUE)
	 IF (PIXVALUE.EQ.MARKER)EXIT
      ENDDO
      ! *** DEBUG *** PRINT *, "fwa-1 address of IMAGE at: "
      ! *** DEBUG *** PRINT *, "BYTE_IN_FILE: ", BYTE_IN_FILE
      ! *** DEBUG *** PRINT *, "REC_IN_FILE: ", REC_IN_FILE

!-----------------------------------------------------------------------
! --  Read data image of 32 bit two's complement integers, compressed
! --  by the BYTE-OFFSET algorithm.
! --  After the expansion the original pixel values are coded by 16 bit
! --  in a special way suitable for XDS (see INTEGER*2 FUNCTION CNT2PIX).
!-----------------------------------------------------------------------
      FCB_READ_IMAGE_3D_I2=CBF_FORMAT  !Cannot handle this CBF format
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.&
	  (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_BYTE_OFFSET))THEN
	 PIXVALUE=0
	 NELEM_READ=0
	 DO K = 1, DIM3
     DO J = 1, DIM2
     DO I = 1, DIM1
	    BYTE_IN_FILE=BYTE_IN_FILE+1
	    IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,            &
	       REC_IN_FILE,BYTE_IN_FILE,ONEBYTE).NE.0) GO TO 140
	    DIFF=ONEBYTE
	    IF (DIFF.EQ.-128)THEN
	       DO II=FIRST2,LAST2,STEP
		  BYTE_IN_FILE=BYTE_IN_FILE+1
		  IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,      &
		     REC_IN_FILE,BYTE_IN_FILE,TWOBYTES(II)).NE.0)GO TO 140
	       ENDDO
	       SHORTINT=TRANSFER(TWOBYTES,SHORTINT)
	       DIFF=SHORTINT
	       IF (DIFF.EQ.-32768)THEN
		  DO II=FIRST4,LAST4,STEP
		     BYTE_IN_FILE=BYTE_IN_FILE+1
		     IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,   &
			REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(II)).NE.0)    &
			GO TO 140
		  ENDDO
		  DIFF=TRANSFER(FOURBYTES,DIFF)
	       ENDIF
	    ENDIF
	    PIXVALUE=PIXVALUE+DIFF
	    ARRAY(I,J,K) = PIXVALUE
	    NELEM_READ=NELEM_READ+1
	 ENDDO
	 ENDDO
	 ENDDO
	 
	 FCB_READ_IMAGE_3D_I2=0  !No error
	 ELSE
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.    &
	  ((IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED) .OR.          &
	   (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED_V2)))THEN
	  FCB_READ_IMAGE_3D_I2=FCB_DECOMPRESS_PACKED_3D_I2 (ARRAY,NELEM,NELEM_READ,   &
        VORZEICHEN, COMPRESSION, DIM1, DIM2,DIM3,  &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,        &
        REC_IN_FILE,BUFFER)
      IF (NELEM_READ.NE.NELEM) PRINT *, "EARLY TERMINATION AT ",NELEM_READ
      PREV_ELEMENT = 0
      END IF
    END IF

!-----------------------------------------------------------------------
100   RETURN
110   FCB_READ_IMAGE_3D_I2=-1 !Cannot determine endian architecture of this machine
      RETURN
130   FCB_READ_IMAGE_3D_I2=-3 !Wrong image format
      GO TO 100
140   FCB_READ_IMAGE_3D_I2=-4 !Cannot read image
      GO TO 100
      END FUNCTION FCB_READ_IMAGE_3D_I2

      !  FCB_READ_IMAGE_3D_I4.F90
!
!  Derived from f90 test code by W. Kabsch
!  H. J. Bernstein, 24 March 2007
!
!  Reads the next binary image from a CIF files that
!  has already been opened.  Leaves the file open and
!  positioned just after the binary and still within
!  the text field
!
!  This version is for
!
!  3-D INTEGER*4 arrays
!
!  with function
!
!  FCB_READ_IMAGE_3D_I4

      INTEGER FUNCTION FCB_READ_IMAGE_3D_I4(ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, DIM3,  &
        PADDING,TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,             &
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
      IMPLICIT                       NONE

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



! --  Definition of CBF_FORMAT
      INTEGER,PARAMETER:: &
        CBF_FORMAT            = Z'00000001'    !      1
! --  External functions called
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
      INTERFACE
      INTEGER FUNCTION FCB_DECOMPRESS_PACKED_3D_I4 (ARRAY,NELEM,NELEM_READ, &
        ELSIGN, COMPRESSION, DIM1, DIM2, DIM3,  &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,                   &
        REC_IN_FILE,BUFFER)
      INTEGER(8),   INTENT(IN):: DIM1,DIM2,DIM3 
      INTEGER(4),  INTENT(OUT):: ARRAY(DIM1,DIM2,DIM3)
      INTEGER(8),  INTENT(OUT):: NELEM_READ
      INTEGER(8),   INTENT(IN):: NELEM
      INTEGER,      INTENT(IN):: ELSIGN, COMPRESSION
      INTEGER,      INTENT(IN):: TAPIN,FCB_BYTES_IN_REC
      INTEGER,   INTENT(INOUT):: REC_IN_FILE,BYTE_IN_FILE
      INTEGER(1),INTENT(INOUT):: BUFFER(FCB_BYTES_IN_REC)
      END FUNCTION
!-----------------------------------------------------------------------
      END INTERFACE
! --  Local variables
      INTEGER             STEP,FIRST2,LAST2,FIRST4,LAST4,II,I,J,K
      INTEGER(4)          DIFF,PIXVALUE,MARKER,IADR
      INTEGER(2)          SHORTINT
      INTEGER(1)          LAST_CHAR,ONEBYTE,                          &
                          TWOBYTES(2),FOURBYTES(4),ENDIANORDER(4),    &
                          MARKBYTES(4)
      INTEGER  ENCODING

      !
      !     Definitions of CBF encodings parameters
      !
      INTEGER,PARAMETER:: &
        ENC_NONE         = Z'0001', & !Use BINARY encoding
        ENC_BASE64       = Z'0002', & !Use BASE64 encoding
        ENC_BASE32K      = Z'0004', & !Use X-BASE32K encoding
        ENC_QP           = Z'0008', & !Use QUOTED-PRINTABLE encoding
        ENC_BASE10       = Z'0010', & !Use BASE10 encoding
        ENC_BASE16       = Z'0020', & !Use BASE16 encoding
        ENC_BASE8        = Z'0040'    !Use BASE8  encoding

      INTEGER  SIZE
      INTEGER  ID

      !
      !     Definitions of CBF compression parameters
      !
      INTEGER,PARAMETER:: &
        CBF_INTEGER      = Z'0010', & !Uncompressed integer
        CBF_FLOAT        = Z'0020', & !Uncompressed IEEE floating point
        CBF_CANONICAL    = Z'0050', & !Canonical compression
        CBF_PACKED       = Z'0060', & !Packed compression
        CBF_PACKED_V2    = Z'0090', & !Packed compression
        CBF_BYTE_OFFSET  = Z'0070', & !Byte Offset Compression
        CBF_PREDICTOR    = Z'0080', & !Predictor_Huffman Compression
        CBF_NONE         = Z'0040', & !No compression flag
        CBF_COMPRESSION_MASK =     &
                           Z'00FF', & !Mask to sep compressiontype from flags
        CBF_FLAG_MASK    = Z'0F00', & !Mask to sep flags from compression type
        CBF_UNCORRELATED_SECTIONS =&
                           Z'0100', & !Flag for uncorrelated sections
        CBF_FLAT_IMAGE   = Z'0200'    !Flag for flat (linear) images


      INTEGER  BITS,VORZEICHEN,REELL
      CHARACTER(len=24)   DIGEST
      CHARACTER(len=14)   BYTEORDER
      !Possible parameter values for BYTEORDER are:
	 !"LITTLE_ENDIAN"     supported
	 !"BIG_ENDIAN"    not supported
      INTEGER(8)  DIMOVER
      INTEGER(8)  LDIM1       !Number of "fast" pixels of the image
      INTEGER(8)  LDIM2       !Number of "slow" pixels of the image
      INTEGER(8)  LDIM3
      INTEGER(4)  PREV_ELEMENT

      DATA             ENDIANORDER/Z'12',Z'34',Z'56',Z'78'/
      DATA             MARKBYTES/Z'0C',Z'1A',Z'04',Z'D5'/

!-----------------------------------------------------------------------
! --  Determine endian architecture of this machine
!-----------------------------------------------------------------------
! Definition: If the lowest memory address of multi-byte data is
!             considered the starting address of the data, the least
!             significant byte (LSB) is at the lowest memory address
!             for a 'little_endian' cpu architecture.
!
! Example:    The 32 bit hex value Z'12345678' is stored as follows:
!             ENDIAN ORDER   BYTE0   BYTE1 BYTE2 BYTE3
!              Big Endian    12       34    56    78(LSB)
!            Little Endian   78(LSB)  56    34    12
!-----------------------------------------------------------------------
      PIXVALUE=TRANSFER(ENDIANORDER,PIXVALUE)
      STEP=0
      IF (PIXVALUE .EQ. Z'78563412') THEN !Little Endian machine
	 STEP=1
	 FIRST2=1;LAST2=2
	 FIRST4=1;LAST4=4
      ENDIF
      IF (PIXVALUE .EQ. Z'12345678') THEN ! Big Endian machine
	 STEP=-1
	 FIRST2=2;LAST2=1
	 FIRST4=4;LAST4=1
      ENDIF
      IF (STEP.EQ.0)GO TO 110

!-----------------------------------------------------------------------
! --   Skip to the next binary and parse the MIME header
!-----------------------------------------------------------------------
      IF (FCB_NEXT_BINARY(TAPIN,LAST_CHAR,FCB_BYTES_IN_REC,BYTE_IN_FILE,&
	REC_IN_FILE,BUFFER,ENCODING,SIZE,ID,DIGEST,COMPRESSION,BITS,        &
	VORZEICHEN,REELL,BYTEORDER,DIMOVER,LDIM1,LDIM2,LDIM3,PADDING).NE.0) &
	 GO TO 130
      IF ((DIM1.NE.LDIM1).OR.(DIM2.NE.LDIM2))GO TO 130

!-----------------------------------------------------------------------
! --  Advance to start of binary image data
!-----------------------------------------------------------------------
! In CBF the binary data begins immediately after the first occurence
! of the following 4 bytes (MARKBYTES) in the image file
!             Octet    Hex  Decimal             Purpose
!               1       0C   12       (ctrl-L) End the current page
!               2       1A   26       (ctrl-Z) Stop listings in MS-DOS
!               3       04   04       (Ctrl-D) Stop listings in UNIX
!               4       D5   213      Binary section begins
!               5..5+n-1              Binary data (n octets)
!-----------------------------------------------------------------------
      MARKER=TRANSFER(MARKBYTES,MARKER)
      FOURBYTES=0
      DO
	 DO I=1,3
	    FOURBYTES(I)=FOURBYTES(I+1)
	 ENDDO
	 BYTE_IN_FILE=BYTE_IN_FILE+1
	 IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,               &
	    REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(4)).NE.0) GO TO 140
	 PIXVALUE=TRANSFER(FOURBYTES,PIXVALUE)
	 IF (PIXVALUE.EQ.MARKER)EXIT
      ENDDO
      ! *** DEBUG *** PRINT *, "fwa-1 address of IMAGE at: "
      ! *** DEBUG *** PRINT *, "BYTE_IN_FILE: ", BYTE_IN_FILE
      ! *** DEBUG *** PRINT *, "REC_IN_FILE: ", REC_IN_FILE

!-----------------------------------------------------------------------
! --  Read data image of 32 bit two's complement integers, compressed
! --  by the BYTE-OFFSET algorithm.
! --  After the expansion the original pixel values are coded by 16 bit
! --  in a special way suitable for XDS (see INTEGER*2 FUNCTION CNT2PIX).
!-----------------------------------------------------------------------
      FCB_READ_IMAGE_3D_I4=CBF_FORMAT  !Cannot handle this CBF format
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.&
	  (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_BYTE_OFFSET))THEN
	 PIXVALUE=0
	 NELEM_READ=0
	 DO K = 1, DIM3
     DO J = 1, DIM2
     DO I = 1, DIM1
	    BYTE_IN_FILE=BYTE_IN_FILE+1
	    IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,            &
	       REC_IN_FILE,BYTE_IN_FILE,ONEBYTE).NE.0) GO TO 140
	    DIFF=ONEBYTE
	    IF (DIFF.EQ.-128)THEN
	       DO II=FIRST2,LAST2,STEP
		  BYTE_IN_FILE=BYTE_IN_FILE+1
		  IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,      &
		     REC_IN_FILE,BYTE_IN_FILE,TWOBYTES(II)).NE.0)GO TO 140
	       ENDDO
	       SHORTINT=TRANSFER(TWOBYTES,SHORTINT)
	       DIFF=SHORTINT
	       IF (DIFF.EQ.-32768)THEN
		  DO II=FIRST4,LAST4,STEP
		     BYTE_IN_FILE=BYTE_IN_FILE+1
		     IF (FCB_READ_BYTE(TAPIN,FCB_BYTES_IN_REC,BUFFER,   &
			REC_IN_FILE,BYTE_IN_FILE,FOURBYTES(II)).NE.0)    &
			GO TO 140
		  ENDDO
		  DIFF=TRANSFER(FOURBYTES,DIFF)
	       ENDIF
	    ENDIF
	    PIXVALUE=PIXVALUE+DIFF
	    ARRAY(I,J,K) = PIXVALUE
	    NELEM_READ=NELEM_READ+1
	 ENDDO
	 ENDDO
	 ENDDO
	 
	 FCB_READ_IMAGE_3D_I4=0  !No error
	 ELSE
      IF ((BYTEORDER.EQ."LITTLE_ENDIAN").AND.(ENCODING.EQ.ENC_NONE).AND.    &
	  ((IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED) .OR.          &
	   (IAND(COMPRESSION,CBF_COMPRESSION_MASK).EQ.CBF_PACKED_V2)))THEN
	  FCB_READ_IMAGE_3D_I4=FCB_DECOMPRESS_PACKED_3D_I4 (ARRAY,NELEM,NELEM_READ,   &
        VORZEICHEN, COMPRESSION, DIM1, DIM2,DIM3,  &
        TAPIN,FCB_BYTES_IN_REC,BYTE_IN_FILE,        &
        REC_IN_FILE,BUFFER)
      IF (NELEM_READ.NE.NELEM) PRINT *, "EARLY TERMINATION AT ",NELEM_READ
      PREV_ELEMENT = 0
      END IF
    END IF

!-----------------------------------------------------------------------
100   RETURN
110   FCB_READ_IMAGE_3D_I4=-1 !Cannot determine endian architecture of this machine
      RETURN
130   FCB_READ_IMAGE_3D_I4=-3 !Wrong image format
      GO TO 100
140   FCB_READ_IMAGE_3D_I4=-4 !Cannot read image
      GO TO 100
      END FUNCTION FCB_READ_IMAGE_3D_I4
      
