extern "C" {
#include "xos.h"
}
#include <string>
#include "XosException.h"
#include <errno.h>

/**
 * Default constructor
 **/
XosException::XosException()
    : code(errno), reason("XosException: unknown reason")
{
}

/**
 * Constructor
 **/
XosException::XosException(const std::string& why)
    : code(errno), reason(why)
{
}

/**
 * Constructor
 **/
XosException::XosException(int c, const std::string& why)
    : code(c), reason(why)
{
}


