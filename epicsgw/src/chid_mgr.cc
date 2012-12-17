#include "chid_mgr.h"
#include "XOSSingleLock.h"
#include "pthread_rwlock_holder.h"

ChidManager* ChidManager::m_pTheSingleObject(NULL);

EPICSChid::EPICSChid( const char name[] ): m_chid(NULL)
{
    CLEAR_BUFFER(m_result);
    if (ca_create_channel( name, NULL, NULL, 99, &m_chid ) != ECA_NORMAL)
    {
        LOG_WARNING1( "ca_create_channel for %s failed", name );
        m_chid = NULL;
    }
    if (ca_pend_io( 0.5 ) == ECA_TIMEOUT)
    {
        LOG_WARNING1( "ca_pend_io( 0.5) timeout for ca_search %s", name );
    }
}

bool EPICSChid::getPV( float timeout )
{
    if (ca_state(m_chid) != cs_conn)
    {
        LOG_WARNING1( "%s not connected", ca_name(m_chid) );
        strcpy( m_result, "not connected" );
        return false;
    }
        
    int status = ca_bget( m_chid, m_result );
    if (status != ECA_NORMAL)
    {
        LOG_WARNING2( "ca_bget() failed for %s: %s", ca_name(m_chid), ca_message(status) );
        strcpy( m_result, "ca_bget failed " );
        return false;
    }
    status = ca_pend_io( timeout );
    if (status == ECA_TIMEOUT)
    {
        LOG_WARNING1( "timeout for ca_bget %s", ca_name(m_chid) );
        strcpy( m_result, "timeout" );
        return false;
    }
    else if (status != ECA_NORMAL)
    {
        LOG_WARNING2( "pendio for ca_bget() failed for %s: %s", ca_name(m_chid), ca_message(status) );
        strcpy( m_result, "error" );
        return false;
    }
    return true;
}

void EPICSChid::setValue( const char* newValue )
{
    if (!newValue)
    {
        m_result[0] = 0;
        return;
    }
    CLEAR_BUFFER(m_result);
    strncpy( m_result, newValue, sizeof(m_result) - 1 );
}
bool EPICSChid::putPV( float timeout )
{
    if (ca_state(m_chid) != cs_conn)
    {
        LOG_WARNING1( "%s not connected", ca_name(m_chid) );
        strcpy( m_result, "not connected" );
        return false;
    }
        
    if (ca_bput( m_chid, m_result ) != ECA_NORMAL)
    {
        LOG_WARNING1( "ca_bput() failed for %s", ca_name(m_chid) );
        strcpy( m_result, "ca_bput failed" );
        return false;
    }
    int status = ca_pend_io( timeout );
    if (status == ECA_TIMEOUT)
    {
        LOG_WARNING1( "timeout for ca_bput %s", ca_name(m_chid) );
        strcpy( m_result, "timeout" );
        return false;
    }
    else if (status != ECA_NORMAL)
    {
        LOG_WARNING2( "error for ca_bput %s: %d", ca_name(m_chid), status );
        strcpy( m_result, "error" );
        return false;
    }
    return true;
}

ChidManager::ChidManager( int maxNum ): m_allChidList( maxNum)
{
    LOG_FINEST( "+ChidManager constructor" );
    if (m_pTheSingleObject != NULL)
    {
        throw "only one ChidManager allowed in whole system";
    }

    //xos_mutex_create( &m_lock );
    pthread_rwlock_init( &m_rwLock, NULL );

    m_pTheSingleObject = this;
    LOG_FINEST( "-ChidManager constructor" );
}
ChidManager::~ChidManager( )
{
    LOG_FINEST( "+ChidManager destructor" );
    clearAll( );

    //xos_mutex_close( &m_lock );
    pthread_rwlock_destroy( &m_rwLock );
    LOG_FINEST( "-ChidManager destructor" );
}

EPICSChid* ChidManager::add( const char name[] )
{
    LOG_FINEST1( "+ChidMgr::add %s", name );
    //XOSSingleLock hold_lock( &m_lock );
    HoldWriterLock hold_writer_lock( &m_rwLock );

    LOG_FINEST( "hold lock" );
    EPICSChid* pChid = _find( name );
    LOG_FINEST( "find" );
    if (pChid)
    {
        LOG_FINEST( "-ChidManager::add already exist" );
        return pChid;
    }

    if (m_allChidList.GetLength( ) >= m_allChidList.GetMaxLength( ))
    {
        LOG_WARNING( "all chid list full" );
        return NULL;
    }

    LOG_FINEST( "before new chid" );
    pChid = new EPICSChid( name );
    if (pChid == NULL)
    {
        LOG_WARNING1( "no memory for %s", name );
        return NULL;
    }
    m_allChidList.AddHead( pChid );

    LOG_FINEST( "-ChidMgr::add OK" );
    return pChid;
}
EPICSChid* ChidManager::find( const char name[] )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldReaderLock hold_reader_lock( &m_rwLock );
    return _find( name );
}
EPICSChid* ChidManager::_find( const char name[] )
{
    //LOG_FINEST1( "+ chid mgr find %s", name );
    int index = m_allChidList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        EPICSChid* pChid = m_allChidList.GetAt( index );
        if (pChid)
        {
            //LOG_FINEST2( "[%d]=%s", index, ca_name(pChid->m_chid) );
            if (!strcmp( ca_name(pChid->m_chid), name))
            {
                //LOG_FINEST( "found" );
                return pChid;
            }
        }
        index = m_allChidList.GetNext( index );
    }
    //LOG_FINEST( "notfound" );
    return NULL;
}
void ChidManager::clearAll( )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldWriterLock hold_writer_lock( &m_rwLock );

    int index = m_allChidList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        EPICSChid* pChid = m_allChidList.GetAt( index );
        if (pChid)
        {
            delete pChid;
        }
        index = m_allChidList.GetNext( index );
    }
    
    m_allChidList.Clean( );
}
ChidManager& ChidManager::GetObject( )
{
    if (m_pTheSingleObject == NULL)
    {
        m_pTheSingleObject = new ChidManager( );
    }
    return *m_pTheSingleObject;
}
