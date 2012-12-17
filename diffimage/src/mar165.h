#ifndef __mar165_h__
#define __mar165_h__


#include "libimage.h"

#define MAXIMAGES 9

#define UINT16	unsigned short
#define INT16	short
#define UINT32	unsigned int
#define INT32	int



/* This number is  written into the byte_order fields in the
   native byte order of the machine writing the file */
#ifndef LITTLE_ENDIAN
#define LITTLE_ENDIAN	1234
#endif
#ifndef BIG_ENDIAN
#define BIG_ENDIAN	4321
#endif

/* possible orientations of frame data (stored in orienation field) */
#define HFAST			0	 /* Horizontal axis is fast */
#define VFAST			1	 /* Vertical axis is fast */

/* possible origins of frame data (stored in origin field) */
#define UPPER_LEFT		0
#define LOWER_LEFT		1
#define UPPER_RIGHT		2
#define LOWER_RIGHT		3

/* possible view directions of frame data for
   the given orientation and origin (stored in view_direction field) */
#define FROM_SOURCE		0
#define TOWARD_SOURCE		1

/*
1 = BYTE 8-bit unsigned integer.
2 = ASCII 8-bit byte that contains a 7-bit ASCII code; the last byte
must be NUL (binary zero).
3 = SHORT 16-bit (2-byte) unsigned integer.
4 = LONG 32-bit (4-byte) unsigned integer.
5 = RATIONAL Two LONGs: the first represents the numerator of a
fraction; the second, the denominator.
6 = SBYTE An 8-bit signed (twos-complement) integer.
7 = UNDEFINED An 8-bit byte that may contain anything, depending on
the definition of the field.
8 = SSHORT A 16-bit (2-byte) signed (twos-complement) integer.
9 = SLONG A 32-bit (4-byte) signed (twos-complement) integer.
10 = SRATIONAL Two SLONG’s: the first represents the numerator of a
fraction, the second the denominator.
11 = FLOAT Single precision (4-byte) IEEE format.
12 = DOUBLE Double precision (8-byte) IEEE format.
*/
#define TIFF_BYTE 1
#define TIFF_ASCII 2
#define TIFF_SHORT 3
#define TIFF_LONG 4
#define TIFF_RATIONAL 5
#define TIFF_SBYTE 6
#define TIFF_UNDEFINED 7
#define TIFF_SSHORT 8
#define TIFF_SLONG 9
#define TIFF_SRATIONAL 10
#define TIFF_FLOAT 11
#define TIFF_DOUBLE 12



#ifdef __cplusplus
extern "C" {
#endif


typedef struct frame_header_type 
{
	/* File/header format parameters (256 bytes) offset = 0 */
	UINT32        header_type;	/* flag for header type  (can be used as magic number) */
	char		  header_name[16];		/* header name (MMX) */
	UINT32        header_major_version;	/* header_major_version (n.) */
	UINT32        header_minor_version; 	/* header_minor_version (.n) */
	UINT32        header_byte_order;/* BIG_ENDIAN (Motorola,MIPS); LITTLE_ENDIAN (DEC, Intel) */
	UINT32        data_byte_order;	/* BIG_ENDIAN (Motorola,MIPS); LITTLE_ENDIAN (DEC, Intel) */
	UINT32        header_size;	/* in bytes			*/
	UINT32        frame_type;	/* flag for frame type */
	UINT32        magic_number;	/* to be used as a flag - usually to indicate new file */
	UINT32        compression_type;	/* type of image compression    */
	UINT32        compression1;	/* compression parameter 1 */
	UINT32        compression2;	/* compression parameter 2 */
	UINT32        compression3;	/* compression parameter 3 */
	UINT32        compression4;	/* compression parameter 4 */
	UINT32        compression5;	/* compression parameter 4 */
	UINT32        compression6;	/* compression parameter 4 */
	UINT32        nheaders;	        /* total number of headers 	*/
 	UINT32        nfast;		/* number of pixels in one line */
 	UINT32        nslow;		/* number of lines in image     */
 	UINT32        depth;		/* number of bytes per pixel    */
 	UINT32        record_length;	/* number of pixels between succesive rows */
 	UINT32        signif_bits;	/* true depth of data, in bits  */
 	UINT32        data_type;	/* (signed,unsigned,float...) */
 	UINT32        saturated_value;	/* value marks pixel as saturated */
	UINT32        sequence;	        /* TRUE or FALSE */
	UINT32        nimages;	        /* total number of images - size of each is nfast*(nslow/nimages) */
 	UINT32        origin;		/* corner of origin 		*/
 	UINT32        orientation;	/* direction of fast axis 	*/
    UINT32        view_direction;   /* direction to view frame      */
	UINT32        overflow_location;/* FOLLOWING_HEADER, FOLLOWING_DATA */
	UINT32        over_8_bits;	/* # of pixels with counts > 255 */
	UINT32        over_16_bits;	/* # of pixels with count > 65535 */
	UINT32        multiplexed;	/* multiplex flag */
	UINT32        nfastimages;	/* # of images in fast direction */
	UINT32        nslowimages;	/* # of images in slow direction */
	UINT32        background_applied; /* flags correction has been applied - hold magic number ? */
	UINT32        bias_applied;	  /* flags correction has been applied - hold magic number ? */
	UINT32        flatfield_applied;  /* flags correction has been applied - hold magic number ? */
	UINT32        distortion_applied; /* flags correction has been applied - hold magic number ? */
	UINT32        original_header_type;	/* Header/frame type from file that frame is read from */
	UINT32        file_saved;         /* Flag that file has been saved, should be zeroed if modified */
	char		  reserve1[(64-40)*sizeof(INT32)-16];

	/* Data statistics (128) offset = 0 + 256 = 256 */
	UINT32        total_counts[2];	/* 64 bit integer range = 1.85E19*/
	UINT32        special_counts1[2];
	UINT32        special_counts2[2];
	UINT32        min;
	UINT32        max;
	UINT32        mean;
	UINT32        rms;
	UINT32        p10;
	UINT32        p90;
	UINT32        stats_uptodate;
    UINT32        pixel_noise[MAXIMAGES];		/* 1000*base noise value (ADUs) */
	char		  reserve2[(32-13-MAXIMAGES)*sizeof(INT32)];

	/* More statistics (256) offset = 256 + 128 = 384 */
	UINT16 percentile[128];


	/* Goniostat parameters (128 bytes) offset = 256 + 128 + 256 = 640 */
	INT32		xtal_to_detector;		/* 1000*distance in millimeters */
	INT32		beam_x;			/* 1000*x beam position (pixels) */
	INT32		beam_y;			/* 1000*y beam position (pixels) */
	INT32		integration_time;		/* integration time in milliseconds */
	INT32		exposure_time;		/* exposure time in milliseconds */
	INT32		readout_time;		/* readout time in milliseconds */
	INT32		nreads;			/* number of readouts to get this image */
	INT32		start_twotheta;		/* 1000*two_theta angle */
	INT32		start_omega;		/* 1000*omega angle */
	INT32		start_chi;			/* 1000*chi angle */
	INT32		start_kappa;		/* 1000*kappa angle */
	INT32		start_phi;			/* 1000*phi angle */
	INT32		start_delta;		/* 1000*delta angle */
	INT32		start_gamma;		/* 1000*gamma angle */
	INT32		start_xtal_to_detector;	/* 1000*distance in mm (dist in um)*/
	INT32		end_twotheta;		/* 1000*two_theta angle */
	INT32		end_omega;			/* 1000*omega angle */
	INT32		end_chi;			/* 1000*chi angle */
	INT32		end_kappa;			/* 1000*kappa angle */
	INT32		end_phi;			/* 1000*phi angle */
	INT32		end_delta;			/* 1000*delta angle */
	INT32		end_gamma;			/* 1000*gamma angle */
	INT32		end_xtal_to_detector;	/* 1000*distance in mm (dist in um)*/
	INT32		rotation_axis;		/* active rotation axis */
	INT32		rotation_range;		/* 1000*rotation angle */
	INT32		detector_rotx;		/* 1000*rotation of detector around X */
	INT32		detector_roty;		/* 1000*rotation of detector around Y */
	INT32		detector_rotz;		/* 1000*rotation of detector around Z */
	char		reserve3[(32-28)*sizeof(INT32)];

	/* Detector parameters (128 bytes) offset = 256 + 128 + 256 + 128 = 768 */
	INT32		detector_type;		/* detector type */
	INT32		pixelsize_x;		/* pixel size (nanometers) */
	INT32		pixelsize_y;		/* pixel size (nanometers) */
	INT32		mean_bias;			/* 1000*mean bias value */
	INT32		photons_per_100adu;	/* photons / 100 ADUs */
	INT32		measured_bias[MAXIMAGES];	/* 1000*mean bias value for each image*/
	INT32		measured_temperature[MAXIMAGES];	/* Temperature of each detector in milliKelvins */
	INT32		measured_pressure[MAXIMAGES];	/* Pressure of each chamber in microTorr */
	/* Retired reserve4 when MAXIMAGES set to 9 from 16 and two fields removed, and temp and pressure added
	char reserve4[(32-(5+3*MAXIMAGES))*sizeof(INT32)];
	*/

	/* X-ray source and optics parameters (128 bytes) offset = 256 + 128 + 256 + 128*2 = 896 */
	/* X-ray source parameters (8*4 bytes) */
	INT32		source_type;		/* (code) - target, synch. etc */
	INT32		source_dx;			/* Optics param. - (size microns) */
	INT32		source_dy;			/* Optics param. - (size microns) */
	INT32		source_wavelength;		/* wavelength (femtoMeters) */
	INT32		source_power;		/* (Watts) */
	INT32		source_voltage;		/* (Volts) */
	INT32		source_current;		/* (microAmps) */
	INT32		source_bias;		/* (Volts) */
	INT32		source_polarization_x;	/* () */
	INT32		source_polarization_y;	/* () */
	char		reserve_source[4*sizeof(INT32)];

	/* X-ray optics_parameters (8*4 bytes) */
	INT32		optics_type;		/* Optics type (code)*/
	INT32		optics_dx;			/* Optics param. - (size microns) */
	INT32		optics_dy;			/* Optics param. - (size microns) */
	INT32		optics_wavelength;		/* Optics param. - (size microns) */
	INT32		optics_dispersion;		/* Optics param. - (*10E6) */
	INT32		optics_crossfire_x;	/* Optics param. - (microRadians) */
	INT32		optics_crossfire_y;	/* Optics param. - (microRadians) */
	INT32		optics_angle;		/* Optics param. - (monoch. 2theta - microradians) */
	INT32		optics_polarization_x;	/* () */
	INT32		optics_polarization_y;	/* () */
	char		reserve_optics[4*sizeof(INT32)];

	char		reserve5[((32-28)*sizeof(INT32))];

	/* File parameters (1024 bytes) offset = 256 + 128 + 256 + 128*3 = 1024 */
	char		filetitle[128];		/* Title 				*/
	char		filepath[128];		/* path name for data file		*/
	char		filename[64];		/* name of data file			*/
	char		acquire_timestamp[32];	/* date and time of acquisition		*/
	char		header_timestamp[32];	/* date and time of header update	*/
	char		save_timestamp[32];	/* date and time file saved 		*/
	char		file_comments[512];	/* comments  - can be used as desired 	*/
	char		reserve6[1024-(128+128+64+(3*32)+512)];

	/* Dataset parameters (512 bytes) offset = 256 + 128 + 256 + 128*3 + 1024 = 2048 */
	char		dataset_comments[512];	/* comments  - can be used as desired 	*/

	/* offset = 2560 */
	char		pad[3072-(256+128+256+(3*128)+1024+512)];     /* pad out to 3072 bytes */

} frame_header;

typedef struct {
	UINT16		tag;
	UINT16		type;
	UINT32		count;
	UINT32		value;
} tiff_ifd;

#define MAX_TAGS 100

typedef struct 
{
	UINT32		byteOrder;
	UINT32		magicNumber;
	tiff_ifd	ifd[MAX_TAGS];
	int			numIFD;

} tiff_header;

	
	
int img_read_mar165(img_handle img, const char *name);
int img_read_mar165_header(img_handle img, const char *name);



#ifdef __cplusplus
}
#endif


#endif //__mar165_h__




