#ifndef __Include_XosMutex_h__
#define __Include_XosMutex_h__

#include "xos.h"
#include "XosException.h"

class XosMutex
{

public:

	XosMutex() throw (XosException);
	~XosMutex();
		
	void lock() throw (XosException);
	void unlock() throw (XosException);
	bool trylock() throw (XosException);
	void destroy();
	
private:

	xos_mutex_t m_mutex;
};

#endif // __Include_XosMutex_h__




