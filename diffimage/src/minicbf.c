/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 

************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <ctype.h>
extern "C" {
#include "xos.h"
#include "xos_log.h"
}
#include "minicbf.h"
#include "cbf_simple.h"

extern int img_test_cbf(FILE* file);

#define MINICBF_FAILNEZ(x, msg) { \
    int err = (x); \
    if (err) { \
        if (DEBUG) { \
            xos_error( "%s: 0X%X\n", msg, err ); \
        } \
        cbf_free_handle( minicbf ); \
        return err; \
    } \
}

typedef struct MyInfo {
    char detector[2048];
    char detector_sn[2048];
    double pixelWidth;
    double pixelHeight;
    double exposureTime;
    double countCutoff;
    double wavelength;
    double distance;
    double beamCenterX;
    double beamCenterY;
    double startAngle;
    double delta;
} MyMiniHeaderInfo_t;


#define LINE_START_WITH(x) (!strncmp( line, x, strlen(x) ))
static void minicbf_parseOneLine( const char * line,
MyMiniHeaderInfo_t *info ) {
    if (LINE_START_WITH("# Detector: ")) {
        const char* pSN = strstr( line, ", S/N " );
        size_t tag_length = 6;
        if (!pSN) {
            pSN = strstr( line, " SN: " );
            tag_length = 5;
        }
        if (pSN) {
            size_t l = pSN - line - 12;
            strncpy( info->detector, line + 12, l );
            sscanf( pSN + tag_length, " %s", info->detector_sn );
        } else {
            const char *p = line + 12;
            char *pDest = info->detector;
            while (*p != '\r' && *p != '\n' && *p != '\0') {
                *pDest++ = *p++;
            }
        }
    } else if (LINE_START_WITH("# Pixel_size ")) {
        sscanf( line, "# Pixel_size %lf m x %lf", &info->pixelWidth, &info->pixelHeight );
    } else if (LINE_START_WITH("# Exposure_time ")) {
        sscanf( line, "# Exposure_time %lf", &info->exposureTime );
    } else if (LINE_START_WITH("# Count_cutoff ")) {
        sscanf( line, "# Count_cutoff %lf", &info->countCutoff );
    } else if (LINE_START_WITH("# Wavelength ")) {
        sscanf( line, "# Wavelength %lf", &info->wavelength );
    } else if (LINE_START_WITH("# Detector_distance ")) {
        sscanf( line, "# Detector_distance %lf", &info->distance );
    } else if (LINE_START_WITH("# Beam_xy ")) {
        sscanf( line, "# Beam_xy (%lf, %lf)", &info->beamCenterX, &info->beamCenterY );
    } else if (LINE_START_WITH("# Start_angle ")) {
        sscanf( line, "# Start_angle %lf", &info->startAngle );
    } else if (LINE_START_WITH("# Angle_increment ")) {
        sscanf( line, "# Angle_increment %lf", &info->delta );
    }
}

int img_read_minicbf_internal( img_handle img, const char* name,
int headerOnly ) {
    FILE *f = NULL;
    cbf_handle minicbf;
    int status;
    const int DEBUG = 0;

    const char *header = NULL;
    const char *lineStart;
    const char *lineEnd;
    size_t line_length;

    unsigned int compression;
    int binary_id;
    size_t elsize;
    int elsigned;
    int elunsigned;
    size_t elements;
    size_t elements_read;
    int minelement;
    int maxelement;
    const char *byteorder = "little_endian";
    size_t dim1;
    size_t dim2;
    size_t dim3;
    size_t padding;

    unsigned char * image;

    /* onlly 2048 used */
    char oneLine[4096] = {0};

    MyMiniHeaderInfo_t miniHeaderInfo = {0};

    f = fopen( name, "rb" );
    if (!f) {
        if (DEBUG) {
            xos_error(" Couldn't open the MINICBF file \"%s\"\n", name);
        }
        return CBF_FILEOPEN;
    }

    status = img_test_cbf( f );
    if (status) {
	    if (DEBUG) {
		    xos_error(" CBFLIB ERROR: %s is not in cbf format\n", name);
        }
	    fclose( f );
	    return status;
    }

    status = cbf_make_handle( &minicbf );
    if (status) {
        if (DEBUG) {
            xos_error("xbf_make_handle faile: 0X%X", status );
        }
	    fclose( f );
        return status;
    }
    MINICBF_FAILNEZ(cbf_read_widefile( minicbf, f, MSG_DIGESTNOW ),
    "cbf_read_widefile failed:" );
    /* MUST NOT close the file according to the document */

    MINICBF_FAILNEZ(cbf_find_tag( minicbf, "_array_data.header_contents" ),
    "cbf_find_tag header_contents failed:" );

    MINICBF_FAILNEZ(cbf_get_value( minicbf, &header ),
    "cbf_get_value for header failed: " );
    
    lineStart = header;

    while (lineStart && lineStart[0]) {
        lineEnd = strchr( lineStart, '\n' );
        if (lineEnd) {
            ++lineEnd;
            line_length = lineEnd - lineStart;
        } else {
            line_length = strlen(lineStart);
        }
        if (line_length >= sizeof(oneLine)) {
            MINICBF_FAILNEZ( CBF_FORMAT,
            "line too long: " );
        }
        memset( oneLine, 0, sizeof(oneLine) );
        strncpy( oneLine, lineStart, line_length );

        if (DEBUG) {
            printf( "\n processing :%s\n", oneLine );
        }
        minicbf_parseOneLine( oneLine, &miniHeaderInfo );

        lineStart += line_length;
    }

    /* get image header */
    MINICBF_FAILNEZ(cbf_find_tag( minicbf, "_array_data.data" ),
    "cbf_find_tag for image failed: " );

    MINICBF_FAILNEZ(cbf_get_integerarrayparameters_wdims( minicbf,
    &compression, &binary_id, &elsize, &elsigned, &elunsigned,
    &elements, &minelement, &maxelement, &byteorder,
    &dim1, &dim2, &dim3, &padding ),
    "cbf_get_integerarrayparameters failed: " );

    if (DEBUG) {
        printf("dim1=%lu dim2=%lu dim3=%lu\n", dim1, dim2, dim3 );
        printf("elsize=%lu signed=%d unsigned=%d byteorder=%s\n",
        elsize, elsigned, elunsigned, byteorder );
    }

    if (miniHeaderInfo.detector[0] == '\0') {
        MINICBF_FAILNEZ(CBF_NOTFOUND, "no minicbf" );
    }

    /* now save the info */
	status  |= img_set_number(img, "SIZE1", "%.6g", dim2);

	status  |= img_set_number(img, "SIZE2", "%.6g", dim1);

	status  |= img_set_number(img, "PIXEL_SIZE", "%.6g",
    miniHeaderInfo.pixelWidth * 1000.0); // in mm

	status  |= img_set_number(img, "OVERLOAD_CUTOFF", "%.6g",
    miniHeaderInfo.countCutoff);

	status  |= img_set_field(img, "DETECTOR", miniHeaderInfo.detector); 
    if (miniHeaderInfo.detector_sn[0] != '\0') {
	    status  |= img_set_field(img, "DETECTOR_SN",
        miniHeaderInfo.detector_sn); 
    }

	status  |= img_set_number(img, "WAVELENGTH", "%.6g",
    miniHeaderInfo.wavelength);

	status  |= img_set_number(img, "DISTANCE", "%.6g",
    miniHeaderInfo.distance * 1000.0);  // in mm

	status  |= img_set_number(img, "BEAM_CENTER_X", "%.6g",
    miniHeaderInfo.pixelWidth * miniHeaderInfo.beamCenterX * 1000.0); // in mm

	status  |= img_set_number(img, "BEAM_CENTER_Y", "%.6g",
    miniHeaderInfo.pixelHeight * miniHeaderInfo.beamCenterY * 1000.0); // in mm

	status  |= img_set_number(img, "EXPOSURE TIME", "%.6g",
    miniHeaderInfo.exposureTime); // exposure time in seconds 

	status  |= img_set_number(img, "PHI", "%.4f", miniHeaderInfo.startAngle);

	status  |= img_set_number(img, "OSC_START", "%.4f",
    miniHeaderInfo.startAngle);

	status  |= img_set_number(img, "OSC_RANGE", "%.4f", miniHeaderInfo.delta);

    if (headerOnly) {
        cbf_free_handle( minicbf );
        return 0;
    }

    image = (unsigned char *)malloc(elements * elsize);
    if (image == NULL) {
        MINICBF_FAILNEZ(CBF_ALLOC, "no memory for image" );
        return CBF_ALLOC;
    }

    MINICBF_FAILNEZ(cbf_get_integerarray( minicbf, &binary_id, (void*)image,
    elsize, elsigned, elements, &elements_read),
    "cbf_get_integerarray failed:" );


    if (elements != elements_read) {
        MINICBF_FAILNEZ( CBF_FORMAT, "cbf_get_integerarray wrong length:" );
    }


	img->size[0] = dim2;
	img->size[1] = dim1;
	img->image = (int*)image;
    cbf_free_handle( minicbf );
    return 0;
}

int img_read_minicbf_header( img_handle img, const char* name ) {
    img_read_minicbf_internal( img, name, 1 );
}
int img_read_minicbf( img_handle img, const char* name ) {
    img_read_minicbf_internal( img, name, 0 );
}
