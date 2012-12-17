#ifndef __XOS_SINGLE_LOCK_H__
#define __XOS_SINGLE_LOCK_H__


#include "xos.h"

class XOSSingleLock
{
public:
    XOSSingleLock( xos_mutex_t* pMutex );
    ~XOSSingleLock( );

private:
    xos_mutex_t* m_pMutex;
};

#endif //#ifndef __XOS_SINGLE_LOCK_H__
