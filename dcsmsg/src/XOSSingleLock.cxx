#include "XOSSingleLock.h"

XOSSingleLock::XOSSingleLock( xos_mutex_t* pMutex )
{
    m_pMutex = pMutex;

    if (m_pMutex) xos_mutex_lock( m_pMutex );
}

XOSSingleLock::~XOSSingleLock( )
{
    if (m_pMutex) xos_mutex_unlock( m_pMutex );
}

