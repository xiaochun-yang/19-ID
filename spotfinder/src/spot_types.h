#ifndef LIBDISTL_TYPES_H
#define LIBDISTL_TYPES_H
namespace Distl {

template<class T>
struct list_types
{
  typedef std::vector<T> list_t;
};

}
#endif

