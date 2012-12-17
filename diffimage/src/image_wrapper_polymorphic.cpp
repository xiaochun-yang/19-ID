/*
 * image_wrapper_polymorphic.cpp
 *
 *  Created on: Apr 8, 2009
 *      Author: penjitk
 */
#include <xos.h>
#include <libimage.h>
#include <marheader.h>
#ifdef IMAGEMAGICK_MARKUP
#include <LabelitMarkup.h>
#endif
#include <image_wrapper_polymorphic.h>
using namespace std;

diffimage::libimage_base_wrapper::libimage_base_wrapper(const std::string& filename)
	  : MK(NULL), p_image(NULL),image(NULL),
	  mFoundMinMax(false)
{
	  // should be moved to a factory
#ifdef IMAGEMAGICK_MARKUP
	  MK = new LabelitMarkup(filename.c_str());
#else
	  MK = new Markup(filename.c_str());
#endif
	  MK->parse_markup();
	  p_image = img_make_handle();
	  if (p_image==NULL) throw int(1);
}

xos_result_t diffimage::libimage_base_wrapper::get_header(char* buf, int maxSize)
{
	if ((buf == NULL) || (maxSize <= 0))
		return XOS_FAILURE;
	char* ptr = buf;
#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
  if (wrapper_type()=="cbflib_adaptbx") {
sprintf(ptr, "imfCIF-formatted file\n"); ptr = buf + strlen(buf);
sprintf(ptr, "size_slow:          %7.0f\n",image->get_number("SIZE1")); ptr = buf + strlen(buf);
sprintf(ptr, "size_fast:          %7.0f\n",image->get_number("SIZE2")); ptr = buf + strlen(buf);
sprintf(ptr, "overload cutoff:  %9.0f\n",image->get_number("OVERLOAD_CUTOFF")); ptr = buf + strlen(buf);
sprintf(ptr, "wavelength (Angstr):%7.4f\n",image->get_number("WAVELENGTH")); ptr = buf + strlen(buf);
sprintf(ptr, "distance (mm):      %7.2f\n",image->get_number("DISTANCE")); ptr = buf + strlen(buf);
sprintf(ptr, "pixel size (mm):    %7.2f\n",image->get_number("PIXEL_SIZE")); ptr = buf + strlen(buf);
sprintf(ptr, "beam_slow (mm):     %7.2f\n",image->get_number("BEAM_CENTER_X")); ptr = buf + strlen(buf);
sprintf(ptr, "beam_fast (mm):     %7.2f\n",image->get_number("BEAM_CENTER_Y")); ptr = buf + strlen(buf);
sprintf(ptr, "osc_start (deg):    %7.2f\n",image->get_number("OSC_START")); ptr = buf + strlen(buf);
sprintf(ptr, "osc_range (deg):    %7.2f\n",image->get_number("OSC_RANGE")); ptr = buf + strlen(buf);

  	return XOS_SUCCESS;
  } else {
#endif
	int tagIndex;
	int tagCount = tags();
	img_tag *aTag = tag();
	char spacer[200];
	long len;
	const char *imgField;

	// print each tag and data item to the file
	for ( tagIndex = 0; tagIndex < tagCount; tagIndex++ ) {

		if ( aTag[tagIndex].tag == NULL )
			break;
		len = strlen( aTag[tagIndex].tag );
		strcpy( spacer, "                        " );
		spacer[20-len] = 0;
		sprintf(ptr, "%s %s %s\n", aTag[tagIndex].tag, spacer, aTag[tagIndex].data );

		// move the pointer
		ptr = buf+strlen(buf);
	}

	imgField = get_field("DETECTOR");
	if (imgField != NULL && strcmp(imgField, "MAR 345") == 0) {
		append_mar345_header_to_buf(getImageFilename().c_str(), ptr, maxSize-strlen(buf));
	}

	return XOS_SUCCESS;
#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
  }
#endif
}


diffimage::libimage_base_wrapper* diffimage::libimage_factory(const std::string& filename)
{
#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
	FILE* cbf_file = fopen(filename.c_str(),"rb");
	bool is_cbf(is_cbf_file(cbf_file));
	fclose(cbf_file);
	if (is_cbf) {
		return (new cbf_wrapper(filename));
	}
#endif
	return new libimage_base_wrapper(filename);
}


