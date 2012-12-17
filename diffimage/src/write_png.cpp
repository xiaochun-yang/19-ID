#include <vector>
#include <write_png.h>
#include <iostream>

#ifdef DIFFIMAGE_HAVE_PNG_Z
#include "png.h"
#ifndef png_jmpbuf
#  define png_jmpbuf(png_ptr) ((png_ptr)->jmpbuf)
#endif

class Simple_File_Wrapper{
  FILE *fp;

 public:
  Simple_File_Wrapper(){fp=NULL;};
  void set_file_pointer(const char *file_name){
    fp = fopen(file_name, "wb");
    if (fp == NULL) {
      throw diffimage_png::PNGError("png constructor of Simple File Wrapper");}
  };
  ~Simple_File_Wrapper(){
    if (fp != NULL){
      fclose(fp);
    }
  }
  FILE * get_file_pointer(){return fp;}
};

void user_write_fn2(png_structp png_ptr,
        png_bytep data, png_size_t length){
  std::vector<png_byte>* compressed = (std::vector<png_byte>*)png_ptr->io_ptr;
  try {
    for (int i = 0; i < length; ++i){
      compressed->push_back(*data++);
    }
  } catch (...) {
    png_error(png_ptr, "user_write_fn2 Error");
  }
};

void user_IO_flush_function(png_structp png_ptr){
  throw diffimage_png::PNGError(
    "user_IO_flush_function callback; contact Nick Sauter nksauter@lbl.gov");
  png_FILE_p io_ptr;
  if(png_ptr == NULL) return;
  io_ptr = (png_FILE_p)CVT_PTR((png_ptr->io_ptr));
  if (io_ptr != NULL)
      {fflush(io_ptr);}
};


/* write a png file */
void
write_png_detail(const char *file_name,int width,int height,unsigned char* image
                     /* , ... other image information ... */)
{
   Simple_File_Wrapper SFW;
   png_structp png_ptr;
   png_infop info_ptr;
   png_colorp palette;

   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also check that
    * the library version is compatible with the one used at compile time,
    * in case we are using dynamically linked libraries.  REQUIRED.
    */
   png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
      NULL, NULL, NULL);

   if (png_ptr == NULL)
   {
      throw diffimage_png::PNGError("write_png1");
   }

   /* Allocate/initialize the image information data.  REQUIRED */
   info_ptr = png_create_info_struct(png_ptr);
   if (info_ptr == NULL)
   {
      png_destroy_write_struct(&png_ptr,  png_infopp_NULL);
      throw diffimage_png::PNGError("write_png1");
   }

   /* Set error handling.  REQUIRED if you aren't supplying your own
    * error handling functions in the png_create_write_struct() call.
    */
   if (setjmp(png_jmpbuf(png_ptr)))
   {
      /* If we get here, we had a problem reading the file */
      png_destroy_write_struct(&png_ptr, &info_ptr);
      throw diffimage_png::PNGError("write_png1");
   }

   /* Exactly one of the following I/O initialization functions is REQUIRED */
   if (true) { /* I/O initialization method 1 */
     /* set up the output control if you are using standard C streams */
     SFW.set_file_pointer(file_name);
     png_init_io(png_ptr, SFW.get_file_pointer());
   }

#ifdef hilevel
   /* This is the easy way.  Use it if you already have all the
    * image info living info in the structure.  You could "|" many
    * PNG_TRANSFORM flags into the png_transforms integer here.
    */
   png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, png_voidp_NULL);
#else
   /* This is the hard way */

   /* Set the image information here.  Width and height are up to 2^31,
    * bit_depth is one of 1, 2, 4, 8, or 16, but valid values also depend on
    * the color_type selected. color_type is one of PNG_COLOR_TYPE_GRAY,
    * PNG_COLOR_TYPE_GRAY_ALPHA, PNG_COLOR_TYPE_PALETTE, PNG_COLOR_TYPE_RGB,
    * or PNG_COLOR_TYPE_RGB_ALPHA.  interlace is either PNG_INTERLACE_NONE or
    * PNG_INTERLACE_ADAM7, and the compression_type and filter_type MUST
    * currently be PNG_COMPRESSION_TYPE_BASE and PNG_FILTER_TYPE_BASE. REQUIRED
    */
   png_set_IHDR(png_ptr, info_ptr, width, height, 8, PNG_COLOR_TYPE_RGB,
      PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

   /* set the palette if there is one.  REQUIRED for indexed-color images */
   palette = (png_colorp)png_malloc(png_ptr, PNG_MAX_PALETTE_LENGTH
             * sizeof (png_color));
   /* ... set palette colors ... */
   png_set_PLTE(png_ptr, info_ptr, palette, PNG_MAX_PALETTE_LENGTH);
   /* You must not free palette here, because png_set_PLTE only makes a link to
      the palette that you malloced.  Wait until you are about to destroy
      the png structure. */

   /* optional significant bit chunk */
   png_color_8 sig_bit;
   /* otherwise, if we are dealing with a color image then */
   sig_bit.red = 8;
   sig_bit.green = 8;
   sig_bit.blue = 8;
   png_set_sBIT(png_ptr, info_ptr, &sig_bit);


   /* Optional gamma chunk is strongly suggested if you have any guess
    * as to the correct gamma of the image.
    */
   //png_set_gAMA(png_ptr, info_ptr, gamma);
   png_text text_ptr[3];
   /* Optionally write comments into the image */
   text_ptr[0].key = "Title";
   text_ptr[0].text = "Mona Lisa";
   text_ptr[0].compression = PNG_TEXT_COMPRESSION_NONE;
   text_ptr[1].key = "Author";
   text_ptr[1].text = "Leonardo DaVinci";
   text_ptr[1].compression = PNG_TEXT_COMPRESSION_NONE;
   text_ptr[2].key = "Description";
   text_ptr[2].text = "<long text>";
   text_ptr[2].compression = PNG_TEXT_COMPRESSION_zTXt;
#ifdef PNG_iTXt_SUPPORTED
   text_ptr[0].lang = NULL;
   text_ptr[1].lang = NULL;
   text_ptr[2].lang = NULL;
#endif
   png_set_text(png_ptr, info_ptr, text_ptr, 3);

   /* other optional chunks like cHRM, bKGD, tRNS, tIME, oFFs, pHYs, */
   /* note that if sRGB is present the gAMA and cHRM chunks must be ignored
    * on read and must be written in accordance with the sRGB profile */

   /* Write the file header information.  REQUIRED */
   png_write_info(png_ptr, info_ptr);

   /* If you want, you can write the info in two steps, in case you need to
    * write your private chunk ahead of PLTE:
    *
    *   png_write_info_before_PLTE(write_ptr, write_info_ptr);
    *   write_my_chunk();
    *   png_write_info(png_ptr, info_ptr);
    *
    * However, given the level of known- and unknown-chunk support in 1.1.0
    * and up, this should no longer be necessary.
    */

   /* Once we write out the header, the compression type on the text
    * chunks gets changed to PNG_TEXT_COMPRESSION_NONE_WR or
    * PNG_TEXT_COMPRESSION_zTXt_WR, so it doesn't get written out again
    * at the end.
    */

   /* set up the transformations you want.  Note that these are
    * all optional.  Only call them if you want them.
    */
   /* pack pixels into bytes */
   png_set_packing(png_ptr);

   /* swap bytes of 16-bit files to most significant byte first */
   png_set_swap(png_ptr);

   /* swap bits of 1, 2, 4 bit packed pixel formats */
   png_set_packswap(png_ptr);

   /* turn on interlace handling if you are not using png_write_image() */
   bool interlacing(false);
   int number_passes;
   if (interlacing)
      number_passes = png_set_interlace_handling(png_ptr);
   else
      number_passes = 1;

   /* The easiest way to write the image (you may have a different memory
    * layout, however, so choose what fits your needs best).  You need to
    * use the first method if you aren't handling interlacing yourself.
    */
   int bytes_per_pixel = 3;
   png_uint_32 k;
   //png_byte image[height][width*bytes_per_pixel];
   png_bytep row_pointers[height];
   for (k = 0; k < height; k++)
     row_pointers[k] = image + k*width*bytes_per_pixel;

   /* One of the following output methods is REQUIRED */
#define entire
#ifdef entire /* write out the entire image data in one call */
   png_write_image(png_ptr, row_pointers);

   /* the other way to write the image - deal with interlacing */

#else //no_entire /* write out the image data by one or more scanlines */
   /* The number of passes is either 1 for non-interlaced images,
    * or 7 for interlaced images.
    */
   for (pass = 0; pass < number_passes; pass++)
   {
      /* Write a few rows at a time. */
      png_write_rows(png_ptr, &row_pointers[first_row], number_of_rows);

      /* If you are only writing one row at a time, this works */
      for (y = 0; y < height; y++)
      {
         png_write_rows(png_ptr, &row_pointers[y], 1);
      }
   }
#endif //no_entire /* use only one output method */

   /* You can write optional chunks like tEXt, zTXt, and tIME at the end
    * as well.  Shouldn't be necessary in 1.1.0 and up as all the public
    * chunks are supported and you can use png_set_unknown_chunks() to
    * register unknown chunks into the info structure to be written out.
    */

   /* It is REQUIRED to call this to finish writing the rest of the file */
   png_write_end(png_ptr, info_ptr);
#endif //hilevel

   /* If you png_malloced a palette, free it here (don't free info_ptr->palette,
      as recommended in versions 1.0.5m and earlier of this example; if
      libpng mallocs info_ptr->palette, libpng will free it).  If you
      allocated it with malloc() instead of png_malloc(), use free() instead
      of png_free(). */
   png_free(png_ptr, palette);
   palette=NULL;

   /* Similarly, if you png_malloced any data that you passed in with
      png_set_something(), such as a hist or trans array, free it here,
      when you can be sure that libpng is through with it. */
   //png_free(png_ptr, trans);
   //trans=NULL;

   /* clean up after the write, and free any memory allocated */
   png_destroy_write_struct(&png_ptr, &info_ptr);

   /* close the file--done automatically by destructor */
}
#else
void write_png_detail(const char *file_name,int width,int height,unsigned char* image /* , ... other image information ... */)
{
  std::cout<<"PNG file format not implemented...contact authors"<<std::endl;
}
#endif //DIFFIMAGE_HAVE_PNG_Z

void diffimage_png::write_png( Diffimage & D, const char * filename){

  unsigned char * buffer;
  buffer = D.get_display_buffer();
  std::pair<int,int> display_size = D.get_display_size();
  write_png_detail(filename, display_size.first, display_size.second, buffer);

}

#ifdef DIFFIMAGE_HAVE_PNG_Z

void
diffimage_png::get_png_buffer(Diffimage& D, std::vector<png_byte>* compressed){

  unsigned char * uncompressed_buffer;
  uncompressed_buffer = D.get_display_buffer();
  std::pair<int,int> display_size = D.get_display_size();
  compressed->clear();//initialize the return buffer

   int width = display_size.first;
   int height = display_size.second;

   png_structp png_ptr;
   png_infop info_ptr;
   png_colorp palette;

   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also check that
    * the library version is compatible with the one used at compile time,
    * in case we are using dynamically linked libraries.  REQUIRED.
    */
   png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
      NULL, NULL, NULL);

   if (png_ptr == NULL)
   {
      throw PNGError("write_png1");
   }

   /* Allocate/initialize the image information data.  REQUIRED */
   info_ptr = png_create_info_struct(png_ptr);
   if (info_ptr == NULL)
   {
      png_destroy_write_struct(&png_ptr,  png_infopp_NULL);
      throw PNGError("write_png1");
   }

   /* Set error handling.  REQUIRED if you aren't supplying your own
    * error handling functions in the png_create_write_struct() call.
    */
   if (setjmp(png_jmpbuf(png_ptr)))
   {
      /* If we get here, we had a problem reading the file */
      png_destroy_write_struct(&png_ptr, &info_ptr);
      throw PNGError("write_png1");
   }

   /* Exactly one of the following I/O initialization functions is REQUIRED */
     /* I/O initialization method 2 */
     /* If you are using replacement read functions */
     png_set_write_fn(png_ptr, (png_voidp)compressed, (png_rw_ptr) &user_write_fn2,
        (png_flush_ptr) &user_IO_flush_function);
     /* where user_io_ptr is a structure you want available to the callbacks */


   /* This is the hard way */

   /* Set the image information here.  Width and height are up to 2^31,
    * bit_depth is one of 1, 2, 4, 8, or 16, but valid values also depend on
    * the color_type selected. color_type is one of PNG_COLOR_TYPE_GRAY,
    * PNG_COLOR_TYPE_GRAY_ALPHA, PNG_COLOR_TYPE_PALETTE, PNG_COLOR_TYPE_RGB,
    * or PNG_COLOR_TYPE_RGB_ALPHA.  interlace is either PNG_INTERLACE_NONE or
    * PNG_INTERLACE_ADAM7, and the compression_type and filter_type MUST
    * currently be PNG_COMPRESSION_TYPE_BASE and PNG_FILTER_TYPE_BASE. REQUIRED
    */
   png_set_IHDR(png_ptr, info_ptr, width, height, 8, PNG_COLOR_TYPE_RGB,
      PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

   /* set the palette if there is one.  REQUIRED for indexed-color images */
   palette = (png_colorp)png_malloc(png_ptr, PNG_MAX_PALETTE_LENGTH
             * sizeof (png_color));
   /* ... set palette colors ... */
   png_set_PLTE(png_ptr, info_ptr, palette, PNG_MAX_PALETTE_LENGTH);
   /* You must not free palette here, because png_set_PLTE only makes a link to
      the palette that you malloced.  Wait until you are about to destroy
      the png structure. */

   /* optional significant bit chunk */
   png_color_8 sig_bit;
   /* otherwise, if we are dealing with a color image then */
   sig_bit.red = 8;
   sig_bit.green = 8;
   sig_bit.blue = 8;
   png_set_sBIT(png_ptr, info_ptr, &sig_bit);


   /* Optional gamma chunk is strongly suggested if you have any guess
    * as to the correct gamma of the image.
    */
   //png_set_gAMA(png_ptr, info_ptr, gamma);
   png_text text_ptr[3];
   /* Optionally write comments into the image */
   text_ptr[0].key = "Title";
   text_ptr[0].text = "Mona Lisa";
   text_ptr[0].compression = PNG_TEXT_COMPRESSION_NONE;
   text_ptr[1].key = "Author";
   text_ptr[1].text = "Leonardo DaVinci";
   text_ptr[1].compression = PNG_TEXT_COMPRESSION_NONE;
   text_ptr[2].key = "Description";
   text_ptr[2].text = "<long text>";
   text_ptr[2].compression = PNG_TEXT_COMPRESSION_zTXt;
   png_set_text(png_ptr, info_ptr, text_ptr, 3);

   /* other optional chunks like cHRM, bKGD, tRNS, tIME, oFFs, pHYs, */
   /* note that if sRGB is present the gAMA and cHRM chunks must be ignored
    * on read and must be written in accordance with the sRGB profile */

   /* Write the file header information.  REQUIRED */
   png_write_info(png_ptr, info_ptr);

   /* If you want, you can write the info in two steps, in case you need to
    * write your private chunk ahead of PLTE:
    *
    *   png_write_info_before_PLTE(write_ptr, write_info_ptr);
    *   write_my_chunk();
    *   png_write_info(png_ptr, info_ptr);
    *
    * However, given the level of known- and unknown-chunk support in 1.1.0
    * and up, this should no longer be necessary.
    */

   /* Once we write out the header, the compression type on the text
    * chunks gets changed to PNG_TEXT_COMPRESSION_NONE_WR or
    * PNG_TEXT_COMPRESSION_zTXt_WR, so it doesn't get written out again
    * at the end.
    */

   /* set up the transformations you want.  Note that these are
    * all optional.  Only call them if you want them.
    */
   /* pack pixels into bytes */
   png_set_packing(png_ptr);

   /* swap bytes of 16-bit files to most significant byte first */
   png_set_swap(png_ptr);

   /* swap bits of 1, 2, 4 bit packed pixel formats */
   png_set_packswap(png_ptr);

   /* turn on interlace handling if you are not using png_write_image() */
   bool interlacing(false);
   int number_passes;
   if (interlacing)
      number_passes = png_set_interlace_handling(png_ptr);
   else
      number_passes = 1;

   /* The easiest way to write the image (you may have a different memory
    * layout, however, so choose what fits your needs best).  You need to
    * use the first method if you aren't handling interlacing yourself.
    */
   int bytes_per_pixel = 3;
   png_uint_32 k;
   //png_byte image[height][width*bytes_per_pixel];
   png_bytep row_pointers[height];
   for (k = 0; k < height; k++)
     row_pointers[k] = uncompressed_buffer + k*width*bytes_per_pixel;

   /* One of the following output methods is REQUIRED */
   /* write out the entire image data in one call */
   png_write_image(png_ptr, row_pointers);

   /* You can write optional chunks like tEXt, zTXt, and tIME at the end
    * as well.  Shouldn't be necessary in 1.1.0 and up as all the public
    * chunks are supported and you can use png_set_unknown_chunks() to
    * register unknown chunks into the info structure to be written out.
    */

   /* It is REQUIRED to call this to finish writing the rest of the file */
   png_write_end(png_ptr, info_ptr);

   /* If you png_malloced a palette, free it here (don't free info_ptr->palette,
      as recommended in versions 1.0.5m and earlier of this example; if
      libpng mallocs info_ptr->palette, libpng will free it).  If you
      allocated it with malloc() instead of png_malloc(), use free() instead
      of png_free(). */
   png_free(png_ptr, palette);
   palette=NULL;

   /* Similarly, if you png_malloced any data that you passed in with
      png_set_something(), such as a hist or trans array, free it here,
      when you can be sure that libpng is through with it. */
   //png_free(png_ptr, trans);
   //trans=NULL;

   /* clean up after the write, and free any memory allocated */
   png_destroy_write_struct(&png_ptr, &info_ptr);

   /* close the file--done automatically by destructor */

}
#else
void diffimage_png::get_png_buffer(Diffimage& D, std::vector<unsigned char>* compressed){
}
#endif
