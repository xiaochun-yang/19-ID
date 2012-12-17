#ifndef IMGSRVEXCEPTIONS_H_
#define IMGSRVEXCEPTIONS_H_

#include <exception>

class fileNotFoundException: public std::exception {
  virtual const char* what() const throw()
  {
    return "Image not on disk.";
  }
};

class invalidFilePermissionException: public std::exception {
  virtual const char* what() const throw()
  {
    return "Invalid file permissions.";
  }
};

 
class cacheAllocationException: public std::exception {
  virtual const char* what() const throw()
  {
    return "Exception allocating image in cache.";
  }
};

class loadingImageException: public std::exception {
  virtual const char* what() const throw()
  {
    return "Error loading image from disk.";
  }
};

#endif /*IMGSRVEXCEPTIONS_H_*/
