#ifndef  __Include_XosTimeCheck_h__
#define __Include_XosTimeCheck_h__

extern "C" {
#include "xos.h"
}

#include <string>

class XosTimeCheck
{
public:
	XosTimeCheck(const std::string& t);
	~XosTimeCheck();
	
	void finish();
	
private:
	std::string title;
	clock_t start;
	clock_t end;
};

#endif // __Include_XosTimeCheck_h__


