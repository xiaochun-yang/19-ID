/*
 *-----------------------------------------------------------
 *
 *	Parameter lists for detcon_entry.c
 *
 *-----------------------------------------------------------
 *
 */

enum {
	HWP_BIN = 0,		/* 1 for no binning, 2 for 2x2 binning */
	HWP_ADC,		/* 0 for slow, 1 for fast adc */
	HWP_SAVE_RAW,		/* 1 to save raw images */
	HWP_DARK,		/* 1 if this is a dark */
	HWP_DARK_MODE,		/* 1 for auto dark, else manual */
	HWP_NO_XFORM,		/* 1 fo no transform */
	HWP_FROM_DISK		/* 1 to read the image from disk instead of collecting it */
     };

enum {
	FLP_PHI = 0,		/* phi value */
	FLP_OMEGA,		/* omega */
	FLP_KAPPA,		/* kappa */
	FLP_TWOTHETA,		/* two theta */
	FLP_DISTANCE,		/* distance */
	FLP_WAVELENGTH,		/* wavelength */
	FLP_AXIS,		/* 1 for phi, 0 for omega */
	FLP_OSC_RANGE,		/* frame size */
	FLP_TIME,		/* time, if used */
	FLP_DOSE,		/* dose, if used */
	FLP_BEAM_X,		/* beam center, x */
	FLP_BEAM_Y,		/* beam center, y */
	FLP_COMPRESS,		/* 1 to compress output images */
	FLP_KIND,		/* "kind" sequence number */
	FLP_FILENAME,		/* filename */
	FLP_COMMENT,		/* comment to add to header */
	FLP_LASTIMAGE,		/* 1 for last image, 0 otherwise, -1 for flush */
	FLP_SUFFIX,		/* returns or sets the image suffix */
	FLP_IMBYTES,		/* image number of bytes */
	FLP_READ_FILENAME	/* filename to read from for HWP_FROM_DISK=1 */
     };
