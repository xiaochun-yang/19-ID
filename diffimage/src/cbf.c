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

/**
This file is modified from cbf_example.c and read_cbf.c written by Paul Ellis.

cbf_example.c: a simple program to write out parameters of CBF files
read_cbf.c 
read_cbf.h: program and header files for a simple function to read CBF files

For many applications, read_cbf.c and read_cbf.h may be used as-is and may also
be freely modified.

To compile the sample program:

(1) first make the CBF library files

cd cbf
make all
cd ..

(2)

cc -Icbf/include/ cbf_example.c read_cbf.c -lm -Lcbf/lib -lcbf -o cbf_example

There are 2 sample CBF data sets at:

  http://smb.slac.stanford.edu/~ellis/CBF_examples
  
NOTE IF INTEGRATING: the Q4 data set from 1-5 has a much larger 
                     anomalous signal than the mar345 data set from 9-1.

For more details about the library, refer to the documentation in cbf/doc.

 **/



#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <ctype.h>
extern "C" {
#include "xos.h"
#include "xos_log.h"
}
#include "libimage.h"
#include "cbf.h"

/**
 * The very start of the file has an identification item (magic number) (2). 
 * This item also describes the CBF version or level. The identifier is: 
 * ###CBF: VERSION
 *
 * which must always be present so that a program can easily identify whether 
 * or not a file is a CBF, by simply inputting the first 15 characters. (The space 
 * is a blank (ASCII 32) and not a tab. All identifier characters are uppercase only.) 
 * The first hash means that this line within a CIF would be a comment line, but the 
 * three hashes mean that this is a line describing the binary file layout for CBF. 
 * (All CBF internal identifiers start with the three hashes, and all other must 
 * immediately follow a "line separator".) No whitespace may precede the first hash sign. 
 * 
 * Following the file identifier is the version number of the file. e.g. the full 
 * line might appear as: 
 *
 * ###CBF: VERSION 0.6
 *
 * The version number must be separated from the file identifier characters by 
 * whitespace e.g. a blank (ASCII 32). 
 * The version number is defined as a major version number and minor version number 
 * separated by the decimal point. A change in the major version may well mean that a 
 * program for the previous version cannot input the new version as some major change 
 * has occurred to CBF (3). A change in the minor version may also mean incompatibility, 
 * if the CBF has been written using some new feature. e.g. a new form of linearity scaling 
 * may be specified and this would be considered a minor version change. A file containing 
 * the new feature would not be readable by a program supporting only an older 
 * version of the format. 
 **/
int img_test_cbf(FILE* file)
{
	int numread;
	char buff[16];
	const char* expect = "###CBF: VERSION";

	if (!file)
		return 1;

	// Read the first 15 characters
	numread = (int)fread(buff, sizeof(unsigned char), 15, file);

	// Move the file pointer back to the beginning of the file
	fseek(file, 0, 0);

	if (numread != 15)
		return 1;
	

	buff[15] = '\0';
	if (strncmp(buff, expect, 15) != 0)
		return 1;


	return 0;

}




/**
  Function to read a CBF image and experimental parameters 
 
     This function will read a CBF image into the int array "image".
     
     The function returns 0 on success and a CBF_xxx code on failure.
     
     If the image array is too small for the image, the function returns -1.
     
     NOTE: the detector is assumed to be a single surface consisting of a
           regular 2-dimensional raster.

     Parameters:

       image_name     (const char *): image file name     
       image          (int *):        array destination for the image
       image_size     (size_t):       size in ints of the destination array
       detector_type  (char *):       string destination for detector type 
                                      (assumed at least 32 characters long)
       slow_pixels    (size_t *):     number of pixels in the slow direction
       fast_pixels    (size_t *):     number of pixels in the fast direction
       slow_size      (double *):     pixel size in the slow direction (m)
       fast_size      (double *):     pixel size in the fast direction (m)
       slow_direction (double *):     3-d normalised slow direction vector
       fast_direction (double *):     3-d normalised fast direction vector
       wavelength     (double *):     wavelength (m)
       e_vector       (double *):     3-d normalised electric field vector
       polarization   (double *):     x-ray beam polarisation factor
       divergence_x   (double *):     divergence in the x direction (degrees)
       divergence_y   (double *):     divergence in the y direction (degrees)
       distance       (double *):     detector distance (m)
       slow_center    (double *):     slow pixel coordinate of beam center
       fast_center    (double *):     fast pixel coordinate of beam center
       axis           (double *):     3-d normalised rotation axis
       start          (double *):     starting rotation angle (degrees)
       rotation       (double *):     rotation range (degrees)
       gain           (double *):     detector gain (counts/x-ray photon)
       overload       (int *):        pixel overload value
       debug          (int):          print error messages if non-0

     NULL is permitted for any pointer parameter.
     
     Numerical values missing from the CBF file are set to 0.
     String values missing from the CBF file are set to "UNKNOWN".
  
  **/
static int read_flat_raster_cbf (const char *image_name,
                          int        **image,
                          size_t      *image_size,
                          char        detector_type [32],
                          int        *slow_pixels,
                          int        *fast_pixels,
                          double     *slow_size,
                          double     *fast_size,
                          double      slow_direction [3],
                          double      fast_direction [3],
                          double     *wavelength,
                          double      e_vector [3],
                          double     *polarization,
                          double     *divergence_x,
                          double     *divergence_y,
                          double     *distance,
                          double     *slow_center,
                          double     *fast_center,
                          double      axis [3],
                          double     *start,
                          double     *rotation,
                          double     *gain,
                          int        *overload,
                          int         debug,
			  int 		readHeaderOnly)
{
  FILE *in;

  cbf_handle cbf;
  
  cbf_detector detector;
  
  cbf_goniometer goniometer;

  int error, count;
  
  size_t dimension [2];
  
  const char *type;

  double d10 [3], d01 [3], c00 [3], c10 [3], c01 [3], l10, l01, 
         ovl, ratio, norm;


    /* Open the file */

  in = fopen (image_name, "rb");

  if (!in)
  {
    if (debug)
    
      xos_error(" Couldn't open the CBF file \"%s\"\n", image_name);

    return (CBF_FILEOPEN);
  }

  // Fast and simple test to find out if the file is in cbf format or not
  // Check the first 15 characters.
  error = img_test_cbf(in);

  if (error) {
	  if (debug)
		xos_error(" CBFLIB ERROR: %s is not in cbf format\n", image_name);

	  fclose(in);
	  return error;
  }


    /* Create the cbf handle for the image file */

  error = cbf_make_handle (&cbf);
  
  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x creating handle for \"%s\"\n", 
                         error, image_name);

    fclose (in);

    return (error);
  }
  

    /* Read as CBF format */

  error = cbf_read_file (cbf, in, MSG_DIGESTNOW);
  
  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x reading \"%s\"\n", 
                         error, image_name);

    return (error | cbf_free_handle (cbf));
  }
  


    /* Point the parser at the first datablock */

  error = cbf_rewind_datablock (cbf);

  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x rewinding datablock in \"%s\"\n", 
                         error, image_name);

    return (error | cbf_free_handle (cbf));
  }


    /* Get the image dimensions (first = slow, second = fast) */

  error = cbf_get_image_size (cbf, 0, 0, &dimension [0], &dimension [1]);
  
  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x parsing image dimensions in \"%s\"\n",
                         error, image_name);

    return (error | cbf_free_handle (cbf));
  }
  
  if (slow_pixels)
  
    *slow_pixels = (int)dimension [0];

  if (fast_pixels)
  
    *fast_pixels = (int)dimension [1];

  
    /* Wavelength */
    
  if (wavelength)
  {
    error = cbf_get_wavelength (cbf, wavelength);
    
    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading wavelength in \"%s\"\n",
                           error, image_name);
                           
      if (error == CBF_NOTFOUND)
    
        *wavelength = 0;
        
      else
      
        return (error | cbf_free_handle (cbf));
    }
    
    *wavelength *= 1E-10;
  }


    /* Polarization */
    
  if (e_vector || polarization)
  {
    error = cbf_get_polarization (cbf, &ratio, &norm);
    
    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading polarization in \"%s\"\n",
                           error, image_name);
                           
      if (error == CBF_NOTFOUND && !e_vector)
    
        *polarization = 0;
        
      else

        return (error | cbf_free_handle (cbf));
    }
    else
    {
      if (polarization)
      
        *polarization = ratio;
        
      if (e_vector)
      {
        e_vector [0] =  cos (norm * 0.017453292519943295769);
        e_vector [1] = -sin (norm * 0.017453292519943295769);
        e_vector [2] =  0;
      }
    }
  }
        
  
    /* Divergence */
    
  if (divergence_x || divergence_y)
  {
    error = cbf_get_divergence (cbf, divergence_x, divergence_y, NULL);
    
    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading divergence in \"%s\"\n",
                           error, image_name);
                           
      if (error == CBF_NOTFOUND)
      {
        if (divergence_x)
        
          *divergence_x = 0;
    
        if (divergence_y)
        
          *divergence_y = 0;
      }
      else
      
        return (error | cbf_free_handle (cbf));
    }
  }


    /* Gain */

  if (gain)
  {
    error = cbf_get_gain (cbf, 0, gain, NULL);
  
    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading gain in \"%s\"\n",
                           error, image_name);
                           
      if (error == CBF_NOTFOUND)
    
        *gain = 0;
        
      else
      
        return (error | cbf_free_handle (cbf));
    }
  }


    /* Overload value */
      
  if (overload)
  {
    error = cbf_get_overload (cbf, 0, &ovl);
  
    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading overload in \"%s\"\n",
                           error, image_name);
                           
      if (error == CBF_NOTFOUND)
    
        *overload = 0;
        
      else
      
        return (error | cbf_free_handle (cbf));
    }
    else
    
      *overload = (int)ovl;
  }


    /* Detector type */
    
  if (detector_type)
  {
    error = cbf_find_category (cbf, "diffrn_detector");
    
    if (!error)
  
      error = cbf_find_column (cbf, "type");
      
    if (!error)

      error = cbf_get_value (cbf, &type);
      
    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading detector type in \"%s\"\n",
                           error, image_name);
                           
      if (error == CBF_NOTFOUND)
      
        strcpy (detector_type, "UNKNOWN");
        
      else
      
        return (error | cbf_free_handle (cbf));
    }
        
    else
    {
      for (count = 0; *type && count < 31; *type++)
        
        if (isalnum (*type))
          
          detector_type [count++] = (char)toupper (*type);

      detector_type [count] = '\0';
    }
  }


    /* Construct detector object */

  error = cbf_construct_detector (cbf, &detector, 0);

  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x parsing detector parameters in \"%s\"\n",
                         error, image_name);

    return (error | cbf_free_handle (cbf));
  }


      /* Crystal to detector distance */
      
  if (distance)
  {
    error = cbf_get_detector_distance (detector, distance);
    
    if (error)
    
      if (error == CBF_NOTFOUND)
    
        *distance = 0;
        
      else
      
        return (error | cbf_free_detector (detector) | cbf_free_handle (cbf));

    else
    
      *distance *= 0.001;
  }      
    
  
      /* Beam center */
      
  if (slow_center || fast_center)
  {
    error = cbf_get_beam_center (detector, slow_center, fast_center,
                                           NULL, NULL);
    
    if (error)
    
      if (error == CBF_NOTFOUND)
      {
        if (slow_center)
        
          *slow_center = 0;
          
        if (fast_center)
        
          *fast_center = 0;
      }
      else
      
        return (error | cbf_free_detector (detector) | cbf_free_handle (cbf));
  }      
    
  
    /* Get 3-dimensional pixel coordinates for (0,0) (1,0) (0,1) */
    
  d10 [0] = d10 [1] = d10 [2] = 0;
  d01 [0] = d01 [1] = d01 [2] = 0;

  error = cbf_get_pixel_coordinates (detector, 0, 0, 
                                     &c00 [0], &c00 [1], &c00 [2]);
                                     
  if (!error)
  
    error = cbf_get_pixel_coordinates (detector, 1, 0, 
                                     &c10 [0], &c10 [1], &c10 [2]);
                                     
  if (!error)
  
    error = cbf_get_pixel_coordinates (detector, 0, 1, 
                                     &c01 [0], &c01 [1], &c01 [2]);

  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x calculating pixel coordinates in \"%s\"\n",
                         error, image_name);

    return (error | cbf_free_detector (detector) | cbf_free_handle (cbf));
  }


    /* Free the detector handle */
    
  error = cbf_free_detector (detector);
  
  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x freeing detector handle in \"%s\"\n",
                         error, image_name);

    return (error | cbf_free_handle (cbf));
  }


    /* Calculate 3-dimensional deltas from (0,0) to (1,0) and (0,1) */
    
  d10 [0] = c10 [0] - c00 [0];
  d10 [1] = c10 [1] - c00 [1];
  d10 [2] = c10 [2] - c00 [2];

  d01 [0] = c01 [0] - c00 [0];
  d01 [1] = c01 [1] - c00 [1];
  d01 [2] = c01 [2] - c00 [2];


    /* Calculate pixel edge dimensions and normalise the edge vectors */

  l10 = sqrt (d10 [0] * d10 [0] + d10 [1] * d10 [1] + d10 [2] * d10 [2]);
  l01 = sqrt (d01 [0] * d01 [0] + d01 [1] * d01 [1] + d01 [2] * d01 [2]);

  if (l10 <= 0 || l01 <= 0)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x calculating pixel dimensions in \"%s\"\n",
                         error, image_name);

    return (CBF_UNDEFINED | cbf_free_handle (cbf));
  }
            
  d10 [0] /= l10;
  d10 [1] /= l10;
  d10 [2] /= l10;
    
  d01 [0] /= l01;
  d01 [1] /= l01;
  d01 [2] /= l01;
  
  if (slow_size)
  
    *slow_size = l10 * 1E-3;
    
  if (fast_size)
  
    *fast_size = l01 * 1E-3;

  if (slow_direction)
  {
    slow_direction [0] = d10 [0];
    slow_direction [1] = d10 [1];
    slow_direction [2] = d10 [2];
  }

  if (fast_direction)
  {
    fast_direction [0] = d01 [0];
    fast_direction [1] = d01 [1];
    fast_direction [2] = d01 [2];
  }


    /* Oscillation vector, starting angle and rotation */

  error = cbf_construct_goniometer (cbf, &goniometer);

  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x parsing goniometer parameters in \"%s\"\n",
                         error, image_name);

    return (error | cbf_free_handle (cbf));
  }

  if (axis)
  {
    error = cbf_get_rotation_axis (goniometer, 0, 
                                   &axis [0], &axis [1], &axis [2]);

    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading rotation axis in \"%s\"\n",
                         error, image_name);

      return (error | cbf_free_goniometer (goniometer)
                    | cbf_free_handle (cbf));
    }
  }

  if (start || rotation)
  {
    error = cbf_get_rotation_range (goniometer, 0, start, rotation);
    
    if (error)
    {
      if (debug)
    
        xos_error(" CBFLIB ERROR %x reading rotation range in \"%s\"\n",
                         error, image_name);

      if (error == CBF_NOTFOUND)
      {
        if (start)
        
          *start = 0;
          
        if (rotation)
        
          *rotation = 0;
      }
      else
      
        return (error | cbf_free_goniometer (goniometer) 
                      | cbf_free_handle (cbf));
    }
  }


    /* Free the goniometer handle */
    
  error = cbf_free_goniometer (goniometer);

  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x freeing goniometer handle in \"%s\"\n",
                       error, image_name);

    return (error | cbf_free_handle (cbf));
  }
  
  
  if (readHeaderOnly)
	  goto done;

  // Set the image_size to the image_size.
  if (image_size)
	  *image_size = dimension [0] * dimension [1];

  // Allocate enough memory to hold the image
  *image = (int*)malloc(sizeof(int)* dimension [0] * dimension [1]);

  if (!*image) {
      
	  if (debug) 
		  xos_error(" READ ERROR failed to allocate memory for the image %s size %d\n",
                         image_name, dimension [0] * dimension [1]);

    cbf_free_handle (cbf);
	return 1;
  }
      
  error = cbf_get_image (cbf, 0, 0, *image, 
                                sizeof(int), 1, dimension [0], dimension [1]);
  
  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x reading image data from \"%s\"\n", 
                         error, image_name);

    return (error | cbf_free_handle (cbf));
  }
  

done:


    /* Free the cbf handle */
      
  error = cbf_free_handle (cbf);

  if (error)
  {
    if (debug)
    
      xos_error(" CBFLIB ERROR %x freeing CBF handle for \"%s\"\n", 
                         error, image_name);

    return (error);
  }


    /* Success */

  return 0;
}

/**
 **/
static int img_read_cbf_(img_handle img, const char* name, int readHeaderOnly)
{
  int		  error;
  int         *image;
  size_t      image_size;

  char        detector_type [32];
  int         slow_pixels;
  int         fast_pixels;
  double      slow_size;
  double      fast_size;
  double      slow_direction [3];
  double      fast_direction [3];
  double      wavelength;
  double      e_vector [3];
  double      polarization;
  double      divergence_x;
  double      divergence_y;
  double      distance;
  double      slow_center;
  double      fast_center;
  double      axis [3];
  double      start;
  double      rotation;
  double      gain;
  int         overload;
  int		  debug = 0;



    /* Allocate space for an image up to 8192 x 8192 */
    

    error = read_flat_raster_cbf (name,
                                  &image,
                                  &image_size,
                                  detector_type,
                                  &slow_pixels,
                                  &fast_pixels,
                                  &slow_size,
                                  &fast_size,
                                  slow_direction,
                                  fast_direction,
                                  &wavelength,
                                  e_vector,
                                  &polarization,
                                  &divergence_x,
                                  &divergence_y,
                                  &distance,
                                  &slow_center,
                                  &fast_center,
                                  axis,
                                  &start,
                                  &rotation,
                                  &gain,
                                  &overload,
                                  debug,
				  readHeaderOnly);

    if (error)
    {
      	if (debug)
      		xos_error (" ERROR %x in read of \"%s\"\n", error, name);
                       
		return 2;
    }
    
    
      /* Print the parameters */  
   
    xos_log ("\n");
    xos_log (" Image name:          \"%s\"\n", name);
    xos_log (" Detector type:       \"%s\"\n", detector_type);
    xos_log (" Image dimensions:    %d x %d\n", slow_pixels, fast_pixels);
    xos_log (" Pixel dimensions:    %8.2e m x %8.2e m\n", slow_size, fast_size);
    xos_log (" Slow direction:      (%.4f %.4f %.4f)\n", slow_direction [0],
                                                        slow_direction [1],
                                                        slow_direction [2]);
    xos_log (" Fast direction:      (%.4f %.4f %.4f)\n", fast_direction [0],
                                                        fast_direction [1],
                                                        fast_direction [2]);
    xos_log (" Wavelength:          %8.2e m\n", wavelength);
    xos_log (" Polarization vector: (%.4f %.4f %.4f)\n", e_vector [0],
                                                        e_vector [1],
                                                        e_vector [2]);
    xos_log (" Polarization ratio:  %.4f\n", polarization);
    xos_log (" Divergence:          (%.4f %.4f)\n", divergence_x, divergence_y);
    xos_log (" Detector distance:   %.4f m\n", distance);
    xos_log (" Beam center:         (%.4f %.4f)\n", slow_center, fast_center);
    xos_log (" Rotation axis:       (%.4f %.4f %.4f)\n", axis [0],
                                                        axis [1],
                                                        axis [2]);
    xos_log (" Starting rotation:   %.4f degrees\n", start);
    xos_log (" Rotation range:      %.4f degrees\n", rotation);
    xos_log (" Detector gain:       %.4f\n", gain);
    xos_log (" Pixel overload:      %d\n", overload);

	error  |= img_set_number(img, "SIZE1", "%.6g", slow_pixels);
	error  |= img_set_number(img, "SIZE2", "%.6g", fast_pixels);
	error  |= img_set_number(img, "PIXEL_SIZE", "%.6g", slow_size); // in mm
	error  |= img_set_number(img, "OVERLOAD_CUTOFF", "%.6g", overload); // value marks pixel as saturated
	error  |= img_set_field(img, "DETECTOR", detector_type); // 
	error  |= img_set_number(img, "WAVELENGTH", "%.6g", wavelength*1e10); // in angstrom (10^-10) 
	error  |= img_set_number(img, "DISTANCE", "%.6g", distance);  // in mm
	error  |= img_set_number(img, "BEAM_CENTER_X", "%.6g", slow_center*slow_size); // in mm
	error  |= img_set_number(img, "BEAM_CENTER_Y", "%.6g", fast_center*fast_size); // in mm
//	error  |= img_set_number(img, "TIME", "%.6g", header->exposure_time/1000.0); // exposure time in seconds 
	error  |= img_set_number(img, "PHI", "%.4f", start); // in mm
	error  |= img_set_number(img, "OSC_START", "%.4f", start); // in degrees
	error  |= img_set_number(img, "OSC_RANGE", "%.4f", rotation); // in degrees
	error  |= img_set_number(img, "DETECTOR_GAIN", "%.4f", gain); // (counts/x-ray photon)
	
	img->size[0] = slow_pixels;
	img->size[1] = fast_pixels;
	img->image = image;

	return 0;

}

int img_read_cbf(img_handle img, const char* name)
{
	return img_read_cbf_(img, name, 0);
}

int img_read_cbf_header(img_handle img, const char* name)
{
	return img_read_cbf_(img, name, 1);
}




