/****************************************************************
image_wrapper_polymorphic:  a polymorphic C++ wrapper for the
ssrl image library (libimage).

Motivation:  The image library defines a C-style handle for
detector images in several file formats, including ADSC, MAR, and
early-version CBF format.  The library was developed primarily
by Paul Ellis in the 1998-2000 time frame.
  Presently, 2008, a different developer (Nick Sauter) wants to
add support for other image formats (current version CBF), and
leverage existing C++ image file libaries.  It is not acceptable
to conform the new file support to the existing libimage API,
because it it written in C.  Nor is it acceptable to spend the time
porting the existing libimage support to some new superformat.
  It is conceivable that the CCP4 image library could be dropped
in as a single solution--future possibility.
  Short term--best solution is to create a thin polymorphic wrapper
to encapsulate either Paul Ellis's library or any other
library that needs to be implemented.
****************************************************************/
#ifndef DIFFIMAGE_LIBIMAGE_WRAPPER_H
#define DIFFIMAGE_LIBIMAGE_WRAPPER_H
#include <xos.h>
#include <string>
#include <libimage.h>

#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
#include <cbflib_adaptbx/basic.h>
#include <cbflib_adaptbx/cbf_adaptor.h>
#include <scitbx/error.h>
#endif

#include <markup.h>

namespace diffimage {

/* Base class encapsulates the original Paul Ellis library */
class libimage_base_wrapper {

private:
	img_object* p_image;

 protected:
  mutable int mMin, mMax;
  mutable bool mFoundMinMax;

 public:
  Markup* MK;
  int * image;

  libimage_base_wrapper(const std::string& filename);

  virtual ~libimage_base_wrapper(){
	  if (MK != NULL) {
		  delete MK;
	  }
	  if (p_image!=NULL){
		  img_free_handle(p_image);
	  }
  }

  const std::string& getFilename() {return getImageFilename();}
  const std::string& getImageFilename() {
  if (MK->image_has_markup())
		  return MK->getImageFilename();
	  return MK->getInputFilename();

  }
  const std::string& getMarkupFilename() {
	  if (MK->image_has_markup())
		  return MK->getMarkupFilename();
	  return MK->getInputFilename();
  }

  bool hasMarkup() {
	  return MK->image_has_markup();
  }

  inline int tags() const { return p_image->tags; }
  inline img_tag* tag() const { return p_image->tag; }

  virtual libimage_base_wrapper* read_data() {
    if (p_image==NULL) throw int(1);
    int ret(img_read(p_image, getImageFilename().c_str()));
    if (ret!=0) throw ret;
    image = p_image->image;
    return this;
  }

  virtual libimage_base_wrapper* read_header() {
    int ret(img_read_header(p_image, getImageFilename().c_str()));
    if (ret!=0) throw ret;
    return this;
  }

  // Return header read by read_data or read_header method
  virtual xos_result_t get_header(char* buf, int maxSize);

  virtual void findMinMax () const {

	  if (p_image==NULL) throw int(1);
	  if (image==NULL) throw int(1);

	  if ( mFoundMinMax ) {
		  return;
	  }

	  int max, min;
	  /* query minimum and maximum pixel values in image */
	  max = min = pixel (0, 0);
	  /* iterate over all pixels to set min and max values */
	  int pixelIndex = 0;
	  const int imagePixelCount = columns() * rows();
	  int * pixelPtr;
	  for ( pixelPtr = image, pixelIndex = 0;
			pixelIndex < imagePixelCount;
			pixelPtr++, pixelIndex++ ) {
		  if ( *pixelPtr> max ) max = *pixelPtr;
		  if ( *pixelPtr < min ) min = *pixelPtr;
	  }

	  mMax=max;
	  mMin=min;

	  mFoundMinMax = true;
  }

  virtual void getMinMax (int & max_, int & min_ ) const {
	  if (p_image==NULL) throw int(1);
	  if (image==NULL) throw int(1);

	  if ( ! mFoundMinMax ) {
		  findMinMax();
	  }

	  max_ = mMax;
	  min_ = mMin;
	  return;
  }



  bool isEmpty() const { return p_image->image == NULL; }

  virtual int columns() const { return img_columns(p_image); }
  virtual int rows() const { return img_rows(p_image); }
  virtual double get_number(const std::string& token) {
    return img_get_number(p_image, token.c_str()); }
  virtual int pixel(const int& x,const int& y) const {
    return img_pixel(p_image,x,y); }
  virtual const char* get_field(const std::string& token) const {
    return img_get_field(p_image, token.c_str()); }
  virtual std::string wrapper_type() const {return "Ellis library";}
};

#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
/* Derived class encapsulates the cbflib_adaptbx from cctbx */
class cbf_wrapper: public libimage_base_wrapper,
                          iotbx::detectors::CBFAdaptor {
  int p_slow,p_fast;
 public:
  scitbx::af::flex_int data_h;
  virtual ~cbf_wrapper(){}

  cbf_wrapper(const std::string& filename):
    iotbx::detectors::CBFAdaptor(filename),
    libimage_base_wrapper(filename){}

  virtual libimage_base_wrapper* read_data() {
    try {
      ((iotbx::detectors::CBFAdaptor*)this)->read_header();
      data_h = ((iotbx::detectors::CBFAdaptor*)this)->read_data();
      int* data_ptr = data_h.begin();
      image = data_ptr;
      p_slow = size1();
      p_fast = size2();
      return this;
    } catch (...){
      int ret(1);
      throw ret;
    }
  }

  virtual libimage_base_wrapper* read_header() {
    try {
      ((iotbx::detectors::CBFAdaptor*)this)->read_header();
      return this;
    } catch (...){
      int ret(1);
      throw ret;
    }
  }

  virtual int columns() { return p_fast; }
  virtual int rows() { return p_slow; }
  virtual double get_number(const std::string& token) {
    if (token=="OVERLOAD_CUTOFF") return overload();
    if (token=="WAVELENGTH") return wavelength();
    if (token=="SIZE1") return p_slow;  //in practice this shortcut is no help
    if (token=="SIZE2") return p_fast;  //rate limiting step is data read
    if (token=="DISTANCE") return distance();
    if (token=="BEAM_CENTER_X") return beam_index1*pixel_size();//assume slow
    if (token=="BEAM_CENTER_Y") return beam_index2*pixel_size();//assume fast
    if (token=="TIME") return 1.0; //not supported yet--coming soon
    if (token=="PIXEL_SIZE") return pixel_size();
    if (token=="OSC_START") return osc_start();
    if (token=="OSC_RANGE") return osc_range();
  }
  virtual inline int pixel(const int& x,const int& y) const {
    return image[x * p_slow + y]; }
  virtual const char* get_field(const std::string& token) const {
    if (token=="DETECTOR")
      return std::string("imgCIF (CBF)-formatted file").c_str();
  }
  virtual std::string wrapper_type() const {return "cbflib_adaptbx";}
};
#endif

	inline bool is_cbf_file(FILE* file) {
        int numread;
        char buff[16];
        const char* expect = "###CBF: VERSION";
        if (!file) { return false; }

        // Read the first 15 characters
        numread = (int)fread(buff, sizeof(unsigned char), 15, file);

        // Move the file pointer back to the beginning of the file
        fseek(file, 0, 0);

        if (numread != 15) { return false; }

        buff[15] = '\0';
        if (strncmp(buff, expect, 15) != 0) { return false; }

        return true;
	}

	libimage_base_wrapper* libimage_factory(const std::string& filename);

} //namespace diffimage
#endif //guards
