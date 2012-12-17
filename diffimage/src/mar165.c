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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include "libimage.h"
#include "mar165.h"



/*************************************************************
 * Create a UINT16 from char 0-2
 * the mapping depends upon the byte order, whether 
 * it's little-endian or big-endian
 *************************************************************/
UINT16 twoBytesToUINT16(unsigned char* c, int little)
{
	UINT16 data;

	if (little) {
      
          data = (UINT16)((c [0]) + (c [1] <<  8));

	} else {

      
          data = (UINT16)((c [0] << 8) + (c [1]));
	}

	return data;
}

/*************************************************************
 * Create a int from char 0-2
 * the mapping depends upon the byte order, whether 
 * it's little-endian or big-endian
 *************************************************************/
int twoBytesToInt(unsigned char* c, int little)
{
	int data;

	if (little) {
      
          data = (int)(c [0]) + (int)(c [1] <<  8);

	} else {

      
          data = (int)(c [0] << 8) + (int)(c [1]);
	}

	return data;
}


/*************************************************************
 * Create a UINT32 from char 0-3
 * the mapping depends upon the byte order, whether 
 * it's little-endian or big-endian
 *************************************************************/
UINT32 fourBytesToUINT32(unsigned char* c, int little)
{
	UINT32 data;

	if (little) {
      
      data = (c [0]) + 
               (c [1] <<  8) +
               (c [2] << 16) +
               (c [3] << 24);

	} else {
      
      data = (c [0] << 24) + 
               (c [1] << 16) +
               (c [2] <<  8) +
               (c [3]);
	}

	return data;
}

/*************************************************************
 * Create an int from char 0-3
 * the mapping depends upon the byte order, whether 
 * it's little-endian or big-endian
 *************************************************************/
int fourBytesToInt(unsigned char* c, int little)
{
	int data;

	if (little) {
      
      data = (c [0]) + 
               (c [1] <<  8) +
               (c [2] << 16) +
               (c [3] << 24);

	} else {
      
      data = (c [0] << 24) + 
               (c [1] << 16) +
               (c [2] <<  8) +
               (c [3]);
	}

	return data;
}

/**
 * Truncate the bytes into sizeof(int) on this machine
 **/
/*************************************************************
 * Create an int from char 0-numBytes
 * the mapping depends upon the byte order, whether 
 * it's little-endian or big-endian.
 * If numBytes > sizeof(int)
 *************************************************************/
int bytesToInt(unsigned char* c, int numBytes, int little)
{
	int data = 0;
	int sizeOfInt = sizeof(int);
	int i;
	int bitsToShift;
	int max = (numBytes < sizeOfInt) ?  numBytes: sizeOfInt;

	if (little) {

		bitsToShift = 0;
		i = 0;
		while (i < max) {
			data += (c[i] << bitsToShift);
			bitsToShift += 8;
			++i;
		}
      
	} else {
      
		bitsToShift = (max-1)*8;
		i = numBytes - max;
		while (i > 0) {
			data += (c[i] << bitsToShift);
			bitsToShift -= 8;
			++i;
		}
	}

	return data;
}


/**
 * Create a INT32 from char 0-4
 * the mapping depends upon the byte order of the data, whether 
 * it's little-endian or big-endian
 **/
INT32 fourbytesToINT32(unsigned char* c, int little)
{
	UINT32 data;

	if (little) {
      
      data = (c [0]) + 
               (c [1] <<  8) +
               (c [2] << 16) +
               (c [3] << 24);

	} else {
      
      data = (c [0] << 24) + 
               (c [1] << 16) +
               (c [2] <<  8) +
               (c [3]);
	}

	return data;
}


/**
 **/
void debug_header(frame_header* header)
	// Print out the data structure
{
	int im;

	/* File/header format parameters (256 bytes) */
	printf("header_type = %u\n", header->header_type); 
	printf("header_name = %s\n", header->header_name); 
	printf("header_major_version = %u\n", header->header_major_version); 
	printf("header_minor_version = %u\n", header->header_minor_version); 
	printf("header_byte_order = %u\n", header->header_byte_order); 
	printf("data_byte_order = %u\n", header->data_byte_order); 
	printf("header_size = %u\n", header->header_size); 
	printf("frame_type = %u\n", header->frame_type); 
	printf("magic_number = %u\n", header->magic_number); 
	printf("compression_type = %u\n", header->compression_type); 
	printf("compression1 = %u\n", header->compression1); 
	printf("compression2 = %u\n", header->compression2); 
	printf("compression3 = %u\n", header->compression3); 
	printf("compression4 = %u\n", header->compression4); 
	printf("compression5 = %u\n", header->compression5); 
	printf("compression6 = %u\n", header->compression6); 
	printf("nheaders = %u\n", header->nheaders); 
	printf("nfast = %u\n", header->nfast); 
	printf("nslow = %u\n", header->nslow); 
	printf("depth = %u\n", header->depth); 
	printf("record_length = %u\n", header->record_length); 
	printf("signif_bits = %u\n", header->signif_bits); 
	printf("data_type = %u\n", header->data_type); 
	printf("saturated_value = %u\n", header->saturated_value); 
	printf("sequence = %u\n", header->sequence); 
	printf("nimages = %u\n", header->nimages); 
	printf("origin = %u\n", header->origin); 
	printf("orientation = %u\n", header->orientation); 
	printf("view_direction = %u\n", header->view_direction); 
	printf("overflow_location = %u\n", header->overflow_location); 
	printf("over_8_bits = %u\n", header->over_8_bits); 
	printf("over_16_bits = %u\n", header->over_16_bits); 
	printf("multiplexed = %u\n", header->multiplexed); 
	printf("nfastimages = %u\n", header->nfastimages); 
	printf("nslowimages = %u\n", header->nslowimages); 
	printf("background_applied = %u\n", header->background_applied); 
	printf("bias_applied = %u\n", header->bias_applied); 
	printf("flatfield_applied = %u\n", header->flatfield_applied); 
	printf("distortion_applied = %u\n", header->distortion_applied); 
	printf("original_header_type = %u\n", header->original_header_type); 
	printf("file_saved = %u\n", header->file_saved); 

	/* Data statistics (128) */
	printf("total_counts = %d%d\n", header->total_counts[0], header->total_counts[1]); 
	printf("special_counts1 = %d%d\n", header->special_counts1[0], header->special_counts1[1]); 
	printf("special_counts2 = %d%d\n", header->special_counts2[0], header->special_counts2[1]); 
	printf("min = %d\n", header->min); 
	printf("max = %d\n", header->max); 
	printf("mean = %d\n", header->mean); 
	printf("rms = %d\n", header->rms); 
	printf("p10 = %d\n", header->p10); 
	printf("p90 = %d\n", header->p90); 
	printf("stats_uptodate = %d\n", header->stats_uptodate); 
	for (im = 0; im < MAXIMAGES; ++im) {
		printf("pixel_noise[%d] = %d\n", im, header->pixel_noise[im]); 
	}


	/* More statistics (256) */
	for (im = 0; im < MAXIMAGES; ++im) {
		printf("percentile[%d] = %d\n", im, header->percentile[im]); 
	}

	/* Goniostat parameters (128 bytes) */
	printf("xtal_to_detector = %d\n", header->xtal_to_detector); 
	printf("beam_x = %d\n", header->beam_x); 
	printf("beam_y = %d\n", header->beam_y); 
	printf("integration_time = %d\n", header->integration_time); 
	printf("exposure_time = %d\n", header->exposure_time); 
	printf("readout_time = %d\n", header->readout_time); 
	printf("nreads = %d\n", header->nreads); 
	printf("start_twotheta = %d\n", header->start_twotheta); 
	printf("start_omega = %d\n", header->start_omega); 
	printf("start_chi = %d\n", header->start_chi); 
	printf("start_kappa = %d\n", header->start_kappa); 
	printf("start_phi = %d\n", header->end_phi); 
	printf("start_delta = %d\n", header->end_delta); 
	printf("start_gamma = %d\n", header->end_gamma); 
	printf("start_xtal_to_detector = %d\n", header->end_xtal_to_detector); 
	printf("end_twotheta = %d\n", header->end_twotheta); 
	printf("end_omega = %d\n", header->end_omega); 
	printf("end_chi = %d\n", header->end_chi); 
	printf("end_kappa = %d\n", header->end_kappa); 
	printf("end_phi = %d\n", header->end_phi); 
	printf("end_delta = %d\n", header->end_delta); 
	printf("end_gamma = %d\n", header->end_gamma); 
	printf("end_xtal_to_detector = %d\n", header->end_xtal_to_detector); 
	printf("rotation_axis = %d\n", header->rotation_axis); 
	printf("rotation_range = %d\n", header->rotation_range); 
	printf("detector_rotx = %d\n", header->detector_rotx); 
	printf("detector_roty = %d\n", header->detector_roty); 
	printf("detector_rotz = %d\n", header->detector_rotz); 

	printf("detector_type = %d\n", header->detector_type); 
	printf("pixelsize_x = %d\n", header->pixelsize_x); 
	printf("pixelsize_y = %d\n", header->pixelsize_y); 
	printf("mean_bias = %d\n", header->mean_bias); 
	printf("photons_per_100adu = %d\n", header->photons_per_100adu); 


	/* Detector parameters (128 bytes) */
	printf("source_type = %d\n", header->source_type); 
	printf("source_dx = %d\n", header->source_dx); 
	printf("source_dy = %d\n", header->source_dy); 
	printf("source_wavelength = %d\n", header->source_wavelength); 
	printf("source_power = %d\n", header->source_power); 
	printf("source_voltage = %d\n", header->source_voltage); 
	printf("source_current = %d\n", header->source_current); 
	printf("source_bias = %d\n", header->source_bias); 
	printf("source_polarization_x = %d\n", header->source_polarization_x); 
	printf("source_polarization_y = %d\n", header->source_polarization_y); 

	
	printf("optics_type = %d\n", header->optics_type); 
	printf("optics_dx = %d\n", header->optics_dx); 
	printf("optics_dy = %d\n", header->optics_dy); 
	printf("optics_wavelength = %d\n", header->optics_wavelength); 
	printf("optics_dispersion = %d\n", header->optics_dispersion); 
	printf("optics_crossfire_x = %d\n", header->optics_crossfire_x); 
	printf("optics_crossfire_y = %d\n", header->optics_crossfire_y); 
	printf("optics_angle = %d\n", header->optics_angle); 
	printf("optics_polarization_x = %d\n", header->optics_polarization_x); 
	printf("optics_polarization_y = %d\n", header->optics_polarization_y); 

	
	/* File parameters (1024 bytes) */
	printf("filetitle = %s\n", header->filetitle); 
	printf("filepath = %s\n", header->filepath); 
	printf("filename = %s\n", header->filename); 
	printf("acquire_timestamp = %s\n", header->acquire_timestamp); 
	printf("header_timestamp = %s\n", header->header_timestamp); 
	printf("save_timestamp = %s\n", header->save_timestamp); 
	printf("file_comments = %s\n", header->file_comments); 

	
	/* Dataset parameters (512 bytes) */
	printf("dataset_comments = %s\n", header->dataset_comments); 

}

/**
 * Find out if this machine is big-endian or little-endian
 **/
static UINT32 getLocalByteOrder()
{
   UINT32 thisMachine = 1;
   unsigned char* p = (unsigned char*)&thisMachine;

   // Big-endian byte representation of 1 is 0x0 0x0 0x0 0x1
   // Little-endian byte representation of 1 is 0x1 0x0 0x0 0x0
   if (p[0] == 0) {
	   thisMachine = BIG_ENDIAN;
	   printf("This machine is big-endian\n");
	   return thisMachine;
   }

	thisMachine = LITTLE_ENDIAN;
	printf("This machine is little-endian\n");
	return thisMachine;
}



/**
 * If the frame_header->header_byte_order is not the same as this machines's
 * byte order, then we need to reverse the bytes for each data field, except
 * the header_byte_order and data_byte_order fields ab.
 **/
int parsePrivateHeader(unsigned char* privateHeader, frame_header* header, int isLittle)
{

   // Convert fields in the header to the appropriate byte order
	int im;


	int chunkOffset = 0;
	int offset = 0;
	unsigned char* str = &privateHeader[0];


	/* File/header format parameters (256 bytes) */
	header->header_type = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	strcpy(header->header_name, (char*)&str[offset]); offset += 16;    
	header->header_major_version = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->header_minor_version = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->header_byte_order = fourBytesToUINT32(&str[offset], isLittle); offset += 4; ;
	header->data_byte_order = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 

	if ((header->header_byte_order != LITTLE_ENDIAN) && (header->header_byte_order != BIG_ENDIAN))
		return 1;

	if ((header->data_byte_order != LITTLE_ENDIAN) && (header->data_byte_order != BIG_ENDIAN))
		return 1;

	header->header_size = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->frame_type = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->magic_number = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->compression_type = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->compression1 = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->compression2 = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->compression3 = fourBytesToUINT32(&str[offset], isLittle); offset += 4;
	header->compression4 = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->compression5 = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->compression6 = fourBytesToUINT32(&str[offset], isLittle); offset += 4;
	header->nheaders = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 

	header->nfast = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 

	if (header->nfast <= 0)
		return 1;

	header->nslow = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 

	if (header->nslow <= 0)
		return 1;

	header->depth = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 

	if (header->depth <= 0)
		return 1;

	header->record_length = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->signif_bits = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->data_type = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->saturated_value = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->sequence = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->nimages = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->origin = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->orientation = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->view_direction = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->overflow_location = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->over_8_bits = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->over_16_bits = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->multiplexed = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->nfastimages = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->nslowimages = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->background_applied = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->bias_applied = fourBytesToUINT32(&str[offset], isLittle); offset += 4;
	header->flatfield_applied = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->distortion_applied = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->original_header_type = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->file_saved = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 


	chunkOffset += 256;
	offset = 0;

	str = &privateHeader[chunkOffset];


	/* Data statistics (128) */
	header->total_counts[0] = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->total_counts[1] = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->special_counts1[0] = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->special_counts1[1] = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->special_counts2[0] = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->special_counts2[1] = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->min = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->max = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->mean = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->rms = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	header->p10 = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->p90 = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	header->stats_uptodate = fourBytesToUINT32(&str[offset], isLittle); offset += 4; 
	for (im = 0; im < MAXIMAGES; ++im) {
		header->pixel_noise[im] = fourBytesToUINT32(&str[offset], isLittle); offset += 4;  
	}



	chunkOffset += 128;
	offset = 0;

	str = &privateHeader[chunkOffset];

	/* More statistics (256) */
	for (im = 0; im < MAXIMAGES; ++im) {
		header->percentile[im] = twoBytesToUINT16(&str[offset], isLittle); offset += 2;  
	}

	chunkOffset += 256;
	offset = 0;

	str = &privateHeader[chunkOffset];


	/* Goniostat parameters (128 bytes) */
	header->xtal_to_detector = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->beam_x = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->beam_y = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->integration_time = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->exposure_time = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->readout_time = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->nreads = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->start_twotheta = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->start_omega = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->start_chi = fourbytesToINT32(&str[offset], isLittle); offset += 4; ; 
	header->start_kappa = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->start_phi = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->start_delta = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->start_gamma = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->start_xtal_to_detector = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->end_twotheta = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->end_omega = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->end_chi = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->end_kappa = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->end_phi = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->end_delta = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->end_gamma = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->end_xtal_to_detector = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->rotation_axis = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->rotation_range = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->detector_rotx = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->detector_roty = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->detector_rotz = fourbytesToINT32(&str[offset], isLittle); offset += 4;  


	chunkOffset += 128;
	offset = 0;

	str = &privateHeader[chunkOffset];

	/* Detector parameters (128 bytes) offset = 256 + 128 + 256 + 128 = 768 */
	header->detector_type = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->pixelsize_x = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->pixelsize_y = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->mean_bias = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->photons_per_100adu = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	for (im = 0; im < MAXIMAGES; ++im) {
		header->measured_bias[im] = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	}
	for (im = 0; im < MAXIMAGES; ++im) {
		header->measured_temperature[im] = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	}
	for (im = 0; im < MAXIMAGES; ++im) {
		header->measured_pressure[im] = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	}

	chunkOffset += 128;
	offset = 0;

	str = &privateHeader[chunkOffset];

	/* X-ray source and optics parameters (128 bytes) offset = 256 + 128 + 256 + 128*2 = 896 */
	header->source_type = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->source_dx = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->source_dy = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->source_wavelength = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->source_power = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->source_voltage = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->source_current = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->source_bias = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->source_polarization_x = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->source_polarization_y = fourbytesToINT32(&str[offset], isLittle); offset += 4;  


	header->optics_type = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->optics_dx = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->optics_dy = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->optics_wavelength = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->optics_dispersion = fourbytesToINT32(&str[offset], isLittle); offset += 4; 
	header->optics_crossfire_x = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->optics_crossfire_y = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->optics_angle = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->optics_polarization_x = fourbytesToINT32(&str[offset], isLittle); offset += 4;  
	header->optics_polarization_y = fourbytesToINT32(&str[offset], isLittle); offset += 4;  


	chunkOffset += 128;
	offset = 0;

	str = &privateHeader[chunkOffset];

	
	/* File parameters (1024 bytes) */
	strcpy(header->filetitle, (char*)&str[offset]); offset += 128;  
	strcpy(header->filepath, (char*)&str[offset]); offset += 128;  
	strcpy(header->filename, (char*)&str[offset]); offset += 64; 
	strcpy(header->acquire_timestamp, (char*)&str[offset]); offset += 32;  
	strcpy(header->header_timestamp, (char*)&str[offset]); offset += 32;  
	strcpy(header->save_timestamp, (char*)&str[offset]); offset += 32;  
	strcpy(header->file_comments, (char*)&str[offset]); offset += 512;  


	chunkOffset += 1024;
	offset = 0;
	str = &privateHeader[chunkOffset];

	
	/* Dataset parameters (512 bytes) */
	strcpy(header->dataset_comments, (char*)&str[offset]);

	return 0;

}


/**
 **/
void mar165_init()
{
	// Find out if this machine is little-endian or big-endian.
	getLocalByteOrder();

	int sizeOfUINT16 = sizeof(UINT16);
	int sizeOfUINT32 = sizeof(UINT32);

	if (sizeOfUINT16 != 2)
		printf("WARNING: UINT16 on this machine is %d bytes; expecting 2 bytes.\n", sizeOfUINT16);
	if (sizeOfUINT32 != 4)
		printf("WARNING: UINT32 on this machine is %d bytes; expecting 4 bytes.\n", sizeOfUINT32);

}

/** 
 * Returns size of the given type
 **/
int tiffSizeOf(UINT16 type)
{
	switch (type) {

		case TIFF_BYTE:
			return 1;
		case TIFF_ASCII:
			return 1;
		case TIFF_SHORT:
			return 2;
		case TIFF_LONG:
			return 4;
		case TIFF_RATIONAL:
			return 8;
	}

	return 0;
}

/**
 * Extract the first 4 bytes from the string
 **/
int img_test_tiff(FILE* file, int* isLittle, int* magicNumber)
{
	int numread;
	unsigned char str[4];

	if (!file || !isLittle || !magicNumber)
		return 1;

	numread = (int)fread(str, sizeof(unsigned char), 4, file);

	// Move file pointer to the beginning of the file
	fseek(file, 0, 0);

	if (numread != 4)
		return 1;


	// Byte 0 and 1 must be either MM or II
	// The byte order used within the file. Legal values are:
	// II (4949.H)
	// MM (4D4D.H)
	// In the II format, byte order is always from the least significant byte to the most
	// significant byte, for both 16-bit and 32-bit integers This is called little-endian byte
	// order. In the MM format, byte order is always from most significant to least
	// significant, for both 16-bit and 32-bit integers. This is called big-endian byte
	// order.
	if (str[0] != str[1])
		return 1;

	if ((str[0] != 'I') && (str[0] != 'M'))
		return 1;

	if (str[0] =='I') {
	    *isLittle = 1;
	} else if (str[0] == 'M') {
		*isLittle = 0;

	}

	// Byte 2 and 3 must represent a UINT16 number 42.
	// An arbitrary but carefully chosen number (42) that further identifies the file as a
	// TIFF file. Note that if the data is in big-endian, we get 0x0 0x2A.
	// Data in little-endian will be 0x2A 0x0.
	*magicNumber = twoBytesToInt(&str[2], *isLittle);


	if (*magicNumber != 42)
		return 1;

	return 0;

}


/**
 **/
int setImageFields(img_handle img, frame_header* header)
{
	int status = 0;

	// header->pixelsize_x = pixel size (nm)
	// Note: header->pixelsize_x/1000.0 to give pixelsize in um/pixel doesn't seem to give a 
	// number in the sensible range, compared to the numbers coming from other detectors.
	// header->pixelsize_x/10^6 seems to give a more likely value. 
	double pixelsize = ((double)header->pixelsize_x)/1000000.0; // pixel size in um/pixel

	// header->start_xtal_to_detector = 1000*distance in mm (distance is in um)
	double distance = header->start_xtal_to_detector/1000.0;

	// header->beam_x = 1000*x beam position (pixels)
	double beam_center_x = ((double)header->beam_x) * pixelsize / 1000.0;  // beam_center_x position in um

	// header->beam_y = 1000*x beam position (pixels)
	double beam_center_y = ((double)header->beam_y) * pixelsize / 1000.0;  // beam_center_x position in um


	// Required fields
	status  |= img_set_number(img, "SIZE1", "%.6g", header->nfast);
	status  |= img_set_number(img, "SIZE2", "%.6g", header->nslow);
	status  |= img_set_number(img, "PIXEL_SIZE", "%.6g", pixelsize);
	status  |= img_set_number(img, "PIXEL SIZE", "%.6g", pixelsize);
	status  |= img_set_number(img, "OVERLOAD_CUTOFF", "%.6g", header->saturated_value); // value marks pixel as saturated
	int detectorWidth = (int)(header->nfast*pixelsize);
	if (abs(detectorWidth-165) < 5)
		status  |= img_set_field(img, "DETECTOR", "MARCCD165"); // mar 165
	else if (abs(detectorWidth-225) < 5)
		status  |= img_set_field(img, "DETECTOR", "MARCCD225"); // mar 225
	else if (abs(detectorWidth-300) < 5)
		status  |= img_set_field(img, "DETECTOR", "MARCCD300"); // mar 300
	else if (abs(detectorWidth-325) < 5)
		status  |= img_set_field(img, "DETECTOR", "MARCCD325"); // mar 325
	else
		status  |= img_set_field(img, "DETECTOR", "MARCCD165"); // default mar 165
	status  |= img_set_number(img, "DETECTOR_TYPE", "%d", header->detector_type); // ????
	status  |= img_set_number(img, "WAVELENGTH", "%.6g", header->source_wavelength/100000.0); // in angstrom (10^-10) header->source_wavelength is in fm(10^-15)
	status  |= img_set_number(img, "DISTANCE", "%.6g", distance);  // in um
	status  |= img_set_number(img, "BEAM_CENTER_X", "%.6g", beam_center_x); // in um
	status  |= img_set_number(img, "BEAM_CENTER_Y", "%.6g", beam_center_y); // in um
	status  |= img_set_number(img, "TIME", "%.6g", header->exposure_time/1000.0); // exposure time in seconds  (header->exposure is in ms)
	status  |= img_set_number(img, "EXPOSURE TIME", "%.6g", header->exposure_time/1000.0); // exposure time in seconds  (header->exposure is in ms)
	status  |= img_set_number(img, "PHI", "%.4f", header->start_phi*0.001); 
	status  |= img_set_number(img, "OSC_START", "%.4f", header->start_phi*0.001); 
	status  |= img_set_number(img, "OSC_END", "%.4f", header->end_phi*0.001); 
	status  |= img_set_number(img, "OSC_RANGE", "%.4f", header->rotation_range*0.001); 
	status  |= img_set_number(img, "OSCILLATION RANGE", "%.4f", header->rotation_range*0.001); 



//	status  |= img_set_number(img, "HEADER_TYPE", "%.6g", header->header_type);
/*	status  |= img_set_field(img, "HEADER NAME", header->header_name);
	status  |= img_set_number(img, "MAJOR VERSION", "%.6g", header->header_major_version);
	status  |= img_set_number(img, "MINOR VERSION", "%.6g", header->header_minor_version);
	status  |= img_set_number(img, "HEADER BYTE ORDER", "%.6g", header->header_byte_order);
	status  |= img_set_number(img, "DATA BYTE ORDER", "%.6g", header->data_byte_order);
	status  |= img_set_number(img, "HEADER SIZE", "%.6g", header->header_size);
	status  |= img_set_number(img, "FRAME TYPE", "%.6g", header->frame_type);
	status  |= img_set_number(img, "MAGIC NUMBER", "%.6g", header->magic_number);
	status  |= img_set_number(img, "COMPRESSION TYPE", "%.6g", header->compression_type);
	status  |= img_set_number(img, "COMPRESSION1", "%.6g", header->compression1);
	status  |= img_set_number(img, "COMPRESSION2", "%.6g", header->compression2);
	status  |= img_set_number(img, "COMPRESSION3", "%.6g", header->compression3);
	status  |= img_set_number(img, "COMPRESSION4", "%.6g", header->compression4);
	status  |= img_set_number(img, "COMPRESSION5", "%.6g", header->compression5);
	status  |= img_set_number(img, "COMPRESSION6", "%.6g", header->compression6);
	status  |= img_set_number(img, "NHEADERS", "%.6g", header->nheaders);
	status  |= img_set_number(img, "NFAST", "%.6g", header->nfast);
	status  |= img_set_number(img, "NSLOW", "%.6g", header->nslow);;
	status  |= img_set_number(img, "DEPTH", "%.6g", header->depth);
	status  |= img_set_number(img, "RECORD LENGTH", "%.6g", header->record_length);
	status  |= img_set_number(img, "SIGNIFCANT BITS", "%.6g", header->signif_bits);
	status  |= img_set_number(img, "DATE TYPE", "%.6g", header->data_type);
	status  |= img_set_number(img, "SATURATED VALUE", "%.6g", header->saturated_value);
	status  |= img_set_number(img, "SEQUENCE", "%.6g", header->sequence);
	status  |= img_set_number(img, "NIMAGES", "%.6g", header->nimages);
	status  |= img_set_number(img, "ORIGIN", "%.6g", header->origin);
	status  |= img_set_number(img, "ORIENTATION", "%.6g", header->orientation);
	status  |= img_set_number(img, "VIEW DIRECTION", "%.6g", header->view_direction);
	status  |= img_set_number(img, "OVERFLOW LOCATION", "%.6g", header->overflow_location);;
	status  |= img_set_number(img, "OVER 8 BITS", "%.6g", header->over_8_bits);
	status  |= img_set_number(img, "OVER 16 BITS", "%.6g", header->over_16_bits); 
	status  |= img_set_number(img, "MULTIPLEXED", "%.6g", header->multiplexed); 
	status  |= img_set_number(img, "NFASTIMAGES", "%.6g", header->nfastimages); 
	status  |= img_set_number(img, "NSLOWIMAGES", "%.6g", header->nslowimages); 
	status  |= img_set_number(img, "BACKGROUND APPLED", "%.6g", header->background_applied); 
	status  |= img_set_number(img, "BIAS APPLIED", "%.6g", header->bias_applied); 
	status  |= img_set_number(img, "FLAT FIELD APPLIED", "%.6g", header->flatfield_applied); 
	status  |= img_set_number(img, "DISTORTION APPLIED", "%.6g", header->distortion_applied); 
	status  |= img_set_number(img, "ORIGINAL HEADER TYPE", "%.6g", header->original_header_type); 
	status  |= img_set_number(img, "FIELD SAVED", "%.6g", header->file_saved); */

	// Data statistics (128) 
/*	header->total_counts([0]);
	header->total_counts(s[1]); 
	header->special_counts1[0]);
	header->special_counts1[1]); 
	header->special_counts2[0]);
	header->special_counts2[1]); 
	header->min); 
	header->max); 
	header->mean); 
	header->rms); 
	&header->p10); 
	header->p90); 
	header->stats_uptodate); 
	for (im = 0; im < MAXIMAGES; ++im) {
		header->pixel_noise[im]); 
	}


	// More statistics (256) 
	for (im = 0; im < MAXIMAGES; ++im) {
		header->percentile[im]); 
	}*/

	// Goniostat parameters (128 bytes) 
/*	status  |= img_set_number(img, "XTAL TO DETECTOR", "%.6g", header->xtal_to_detector); 
	status  |= img_set_number(img, "BEAM_X", "%.6g", header->beam_x); 
	status  |= img_set_number(img, "BEAM_Y", "%.6g", header->beam_y); 
	status  |= img_set_number(img, "INTEGRATION TIME", "%.6g", header->integration_time); 
	status  |= img_set_number(img, "EXPOSURE TIME", "%.6g", header->exposure_time); 
	status  |= img_set_number(img, "READOUT TIME", "%.6g", header->readout_time); 
	status  |= img_set_number(img, "NREADS", "%.6g", header->nreads); 
	status  |= img_set_number(img, "START TWO THETA", "%.6g", header->start_twotheta); 
	status  |= img_set_number(img, "START OMEGA", "%.6g", header->start_omega); 
	status  |= img_set_number(img, "START CHI", "%.6g", header->start_chi); 
	status  |= img_set_number(img, "START KAPPA", "%.6g", header->start_kappa); 
	status  |= img_set_number(img, "START PHI", "%.6g", header->start_phi); 
	status  |= img_set_number(img, "START DELTA", "%.6g", header->start_delta); 
	status  |= img_set_number(img, "START GAMMA", "%.6g", header->start_gamma); 
	status  |= img_set_number(img, "START XTAL TO DETECTOR", "%.6g", header->start_xtal_to_detector); 
	status  |= img_set_number(img, "END TWO THETA", "%.6g", header->end_twotheta); 
	status  |= img_set_number(img, "ENDN OMEGA", "%.6g", header->end_omega); 
	status  |= img_set_number(img, "END CHI", "%.6g", header->end_chi); 
	status  |= img_set_number(img, "END KAPPA", "%.6g", header->end_kappa); 
	status  |= img_set_number(img, "END PHI", "%.6g", header->end_phi); 
	status  |= img_set_number(img, "END DELTA", "%.6g", header->end_delta); 
	status  |= img_set_number(img, "END GAMMA", "%.6g", header->end_gamma); 
	status  |= img_set_number(img, "EBD XTAL TO DETECTOR", "%.6g", header->end_xtal_to_detector); 
	status  |= img_set_number(img, "ROTATION AXIS", "%.6g", header->rotation_axis); 
	status  |= img_set_number(img, "ROTATION RANGE", "%.6g", header->rotation_range); 
	status  |= img_set_number(img, "DETECTOR ROTX", "%.6g", header->detector_rotx); 
	status  |= img_set_number(img, "DETECTOR ROTY", "%.6g", header->detector_roty); 
	status  |= img_set_number(img, "DETECTOR ROTZ", "%.6g", header->detector_rotz); 


	// Detector parameters (128 bytes) 
	status  |= img_set_number(img, "SOURCE TYPE", "%.6g", header->source_type); 
	status  |= img_set_number(img, "SOURCE DX", "%.6g", header->source_dx); 
	status  |= img_set_number(img, "SOURCE DY", "%.6g", header->source_dy); 
	status  |= img_set_number(img, "WAVELENGTH", "%.6g", header->source_wavelength); 
	status  |= img_set_number(img, "SOURCE POWER", "%.6g", header->source_power); 
	status  |= img_set_number(img, "SOURCE VOLTAGE", "%.6g", header->source_voltage); 
	status  |= img_set_number(img, "SOURCE CURRENT", "%.6g", header->source_current); 
	status  |= img_set_number(img, "SOURCE BIAS", "%.6g", header->source_bias); 
	status  |= img_set_number(img, "SOURCE POLARIZATION X", "%.6g", header->source_polarization_x); 
	status  |= img_set_number(img, "SOURCE POLARIZATION Y", "%.6g", header->source_polarization_y); 

	
	status  |= img_set_number(img, "OPTICS TYPE", "%.6g", header->optics_type); 
	status  |= img_set_number(img, "OPTICS DX", "%.6g", header->optics_dx); 
	status  |= img_set_number(img, "OPTICS DY", "%.6g", header->optics_dy); 
	status  |= img_set_number(img, "OPTICS WAVELENGTH", "%.6g", header->optics_wavelength); 
	status  |= img_set_number(img, "OPTICS DISPERSION", "%.6g", header->optics_dispersion); 
	status  |= img_set_number(img, "OPTICS CROSSFIRE X", "%.6g", header->optics_crossfire_x); 
	status  |= img_set_number(img, "OPTICS CROSSFIRE Y", "%.6g", header->optics_crossfire_y); 
	status  |= img_set_number(img, "OPTICS ANGLE", "%.6g", header->optics_angle); 
	status  |= img_set_number(img, "OPTICS POLARIZATION X", "%.6g", header->optics_polarization_x); 
	status  |= img_set_number(img, "OPTICS POLARIZATION Y", "%.6g", header->optics_polarization_y); 

	
	// File parameters (1024 bytes) 
	status  |= img_set_field(img, "FILE TITLE", header->filetitle); 
	status  |= img_set_field(img, "FILE PATH", header->filepath); 
	status  |= img_set_field(img, "FILE NAME", header->filename); 
	status  |= img_set_field(img, "AQUIRE TIMESTAMP", header->acquire_timestamp); 
	status  |= img_set_field(img, "HEADER TIMESTAMP", header->header_timestamp); 
	status  |= img_set_field(img, "HEADER SAVED TIMESTAMP", header->save_timestamp); 
	status  |= img_set_field(img, "FILE COMMENTS", header->file_comments); 

	
	// Dataset parameters (512 bytes) 
	status  |= img_set_field(img, "DATASET COMMENTS", header->dataset_comments); */

	return status;


}

/**
 * Read the headers
 * marccd165 file has two header portions: 1024 byts of standard tiff header from byte position 0
 * and 3072 bytes of private headerfrom byte position 1024.
 * Here we will ignore the standard tiff header except for the first 4 bytes. 
 * The first 2 bytes will tell us if this file is written in little or big endian.
 * The next two bytes should contain tiff's magic number, 42.
 * The private header from byte position 1024 will be mapped to frame_header data structure,
 * based on an assumption that the data is written using UINT16 = 2 bytes and UINT32 = 4 bytes.
 * The frame_header data structure is defined in the header file.
 **/
static int img_read_mar165_header_(img_handle img, FILE* file,
						 int* isLittle, int* rows, int* cols, 
						 int* bytesPerPixel)
{
	unsigned char str1[1024];
	unsigned char str2[3072];
	int isHeaderLittle;
	int magicNumber;
	int status;
	frame_header header;
	unsigned long numread;

	// Test the first 4 bytes and then move the file pointer back to the beginning of the file
	status = img_test_tiff(file, &isHeaderLittle, &magicNumber);

	if (status != 0)
		return status;
	
	// Read tiff header. Expect the standard tiff header to be 1024 bytes long.
	// This is according to the marccd165 spec.
	numread = fread(str1, sizeof(unsigned char), 1024, file);

	// Do process it if it doesn't conform to the format we expect
	// Return non-zero to indicate to the calling function that 
	// we can not process this file.
	if (numread != 1024)
		return 1;

	// Read the next 3072 bytes
	numread = fread(str2, sizeof(unsigned char), 3072, file);

	if (numread != 3072)
		return 1;

	// Map the array of 3072 characters to frame_header data structure
	status = parsePrivateHeader(str2, &header, isHeaderLittle);

	if (status != 0)
		return status;

	*isLittle = (header.data_byte_order == LITTLE_ENDIAN);
	*rows = header.nfast;
	*cols = header.nslow;
	*bytesPerPixel = header.depth;

		
//	debug_header(&header);

	// Extract fields from the frame_header and put them in the image_obj fields.
	status = setImageFields(img, &header);

	return status;

}

/**
 * Read the image data, assuming that the img_handle has been set correctly from
 * the header portion of the file. The fields in the img_handle that we need 
 * are SIZE1, SIZE2, PIXEL SIZE and BYTE_ORDER. Is this necessary?
 **/
int img_read_mar165_data(img_handle img, FILE* file, 
						 int isLittle, int rows, int cols, 
						 const int bytesPerPixel)
{
	// Image size is nfast*nslow*depth
	unsigned char *c;
	int numread = 0;

	if ((rows < 0) || (cols < 0) || (bytesPerPixel < 0)) {
		printf("ERROR: invalid rows (%d) or cols (%d) or bytes per pixel (%d)\n",
			rows, cols, bytesPerPixel);
		return 1;
	}

	// Image size is rows*cols
	if ( img_set_dimensions(img, rows, cols) ) {
		printf("ERROR: allocating memory for mar image");
		return img_BAD_ALLOC;
	}

	int byteOffset = 0;
	int * pixel = img->image;

	unsigned char* data;
	const int rowLength = cols*bytesPerPixel;
	const int rowLengthBytes = rowLength * sizeof(unsigned char);
	data = (unsigned char*)malloc( rowLengthBytes );
	
	int x,y=0;
	for (y=0; y < rows; y++) {
		numread = (int)fread( data, sizeof(unsigned char), rowLengthBytes, file);
		if (numread != rowLength ) {
			printf("ERROR: Failed to read image: expecting image size %d but got %d\n",
				bytesPerPixel, numread);

			free (data);
			return img_BAD_ALLOC;
		}

		byteOffset = 0;
		for (x=0;x< cols ; x++) {

			c = &data[byteOffset];

			// Convert x bytes to a native integer
			// If x is > sizeof(int), the value is probably 
			// going to be unreliable.
			if (bytesPerPixel == 2) {
				*pixel = twoBytesToInt(c, isLittle);	
			} else if (bytesPerPixel == 4) {
				*pixel = fourBytesToInt(c, isLittle);
			} else {
				*pixel = bytesToInt(c, bytesPerPixel, isLittle);
			}
			// move by 2 bytes
			byteOffset += bytesPerPixel;
			++pixel;
		}
	}

	free (data);

	return 0;

}



/**
 * Extract an image from the file
 * Returns 0 if the file is parsed successfully.
 * The following conditions are tested in this order:
 * - File contains at least 1024 bytes
 * - Byte 0 and 1 contain characters, either MM or II
 * - Byte 2 and 3 contain a UINT16 integer number 42
 * - Byte 4-7 contain a UINT32 integer representing a byte offset
 *   of the first IFD.
 * - The file must contain another 3072 bytes (from byte 1025 onwards)
 * - The 3072 bytes must map correctly to frame_header data structure.
 * - The frame_header must contain valid values for nfast, nslow and depth fields.
 * - The file must contain the image size = nfast * nslow * depth
 *   starting from 2097 byte position.
 * @param img The returned image parsed from the file
 * @param name File that contains the image
 **/
int img_read_mar165(img_handle img, const char* name)
{
	FILE* file;
	int status = 0;
	int isLittle;
	int rows;
	int cols;
	int bytesPerPixel;

	// Initialize some global variables.
//	mar165_init();


	// Open the data file
	file = fopen(name, "r");

	if (!file) {
//		xos_error("failed to read file = %s\n", name);
		return img_BAD_OPEN;
	}


	status = img_read_mar165_header_(img, file, &isLittle, &rows, &cols, &bytesPerPixel);

	if (status != 0)
		goto theEnd;

	status = img_read_mar165_data(img, file, isLittle, rows, cols, bytesPerPixel);

	if (status != 0)
		goto theEnd;


theEnd:

	// Do we need to reorder the image bytes as well?


	fclose(file);

	return status;
}

/**
 * Read header only
 */
int img_read_mar165_header(img_handle img, const char* name)
{
	FILE* file;
	int status = 0;
	int isLittle;
	int rows;
	int cols;
	int bytesPerPixel;

	// Open the data file
	file = fopen(name, "r");

	if (!file) {
//		xos_error("failed to read file = %s\n", name);
		return img_BAD_OPEN;
	}

	status = img_read_mar165_header_(img, file, &isLittle, &rows, &cols, &bytesPerPixel);

	fclose(file);

	return status;
}



