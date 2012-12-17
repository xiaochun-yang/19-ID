extern "C" {
#include "xos.h"
}

#include "XosTimeCheck.h"

XosTimeCheck::XosTimeCheck(const std::string& t)
	: title(t), start(clock()), end(0)
{
}

XosTimeCheck::~XosTimeCheck()
{
	if (end == 0)
		finish();
	
}
void XosTimeCheck::finish()
{
	end = clock();
	
	// compute elapsed seconds
	double dT = ((double)(end - start))/((double)CLOCKS_PER_SEC);
	
	printf("%s: dT = %f sec start = %d end = %d\n", 
			title.c_str(), dT,
			start, end); fflush(stdout);
	
}
