#ifndef DIFFIMAGE_WRITE_PNG_H
#define DIFFIMAGE_WRITE_PNG_H

#include <vector>
#include <string>
#include <diffimage.h>

namespace diffimage_png {

class PNGError : public std::exception {
private:
  std::string s;
  const char* file;
public:
  inline PNGError(std::string s):s(s){}
  virtual const char* what() const throw();
  virtual ~PNGError() throw();
};
inline const char* PNGError::what() const throw() {
  char m[120];
  sprintf (m,"%s",s.c_str());
  std::string mess(m);
  return mess.c_str();
}
inline PNGError::~PNGError() throw() {}

/*
    The purpose of this function is to prototype future functionality
    wherein the diffimage server can write files in PNG format as well
    as the currently-used JPEG format.  PNG compression gives better-
    looking pictures when the image server is used to render color
    overlays computed by LABELIT.

    As a prototype, write_png makes no functional changes to the
    production version of the image server.  New code is only compiled
    when supplied with the flag DIFFIMAGE_HAVE_PNG_Z; and only linked
    against the system-supplied libpng when linked with the SConscript
    on linux.

    This code writes a static PNG file.  Adapting it to the image server
    would require the implementation of a streaming PNG function, similar
    to the jpegsoc module.  Questions...contact Nick Sauter 510-486-5713
*/

void write_png( Diffimage &, char const * );
void get_png_buffer( Diffimage &, std::vector<unsigned char>* );
} //namespace diffimage_png

#endif //write png
