#include <markup.h>
#include <diffimage.h>
#include <iostream>

int main(int argc, char* argv[]) {
  std::string arg1(argv[1]);
  Diffimage D(255, 100,100,125,125);
  D.load(arg1.c_str());

  double zoom = 4;
  double gray = 400;//400;
  int sizex = 1000;
  int sizey = 1000;
  double percentx = 0.75;
  double percenty = 0.20;

  std::string jpegFilename(argv[2]);
  std::string thumbFilename(argv[3]);

  printf("parameters: %f %f %f %f\n", zoom, gray, percentx, percenty );

  /* calculate center of image */
  int im_centerx = (int)(percentx * (double) D.get_image_size_x());
  int im_centery = (int)(percenty * (double) D.get_image_size_y());

  /* set parameters for creating the jpeg file */
  D.set_display_size( sizex, sizey );
  D.set_image_center( im_centerx, im_centery );
  D.set_zoom (zoom);
  D.set_contrast_min (0);
  D.set_contrast_max ((int)gray);
  D.set_jpeg_quality (90);
  D.set_sampling_quality (3);

  std::cout<<"thumbnail view created: "<<argv[3]<<std::endl;

  /* create the thumbnail image */
  D.set_mode (DIFFIMAGE_MODE_THUMB);

  if (   D.create_jpeg_file( thumbFilename.c_str() ) != XOS_SUCCESS ) {
    xos_error( "web_client_thread -- error creating thumbnail jpeg file" );
  }

  std::cout<<"full size view created: "<<argv[2]<<std::endl;

  /* create full image */
  D.set_mode (DIFFIMAGE_MODE_FULL);
  if ( D.create_jpeg_file( jpegFilename.c_str() ) != XOS_SUCCESS ) {
    xos_error( "web_client_thread -- error creating full jpeg file" );
  }

}
