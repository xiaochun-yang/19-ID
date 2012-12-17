#include <pthread.h>
#include "xos.h"
#include "common.h"
#include "cadef.h"
#include "PointerList.h"

//used by operation getEPICSPV and setEPICSPV
//only manage chid for getEPICSPV and setEPICSPV
//may be extended to manage all chid include gw_device's chid

class EPICSChid
{
public:
    EPICSChid( const char name[] );
    virtual ~EPICSChid( )
    {
        if (m_chid)
        {
            if (ca_state(m_chid) != cs_closed)
            {
                ca_clear_channel( m_chid );
            }
            m_chid = NULL;
        }
    }

    bool getPV( float timeout );
    const char* getResult( ) const { return m_result; }

    void setValue( const char* newValue );
    bool putPV( float timeout ); 

    chid m_chid;
private:
    //forbid
    EPICSChid( );

    char m_result[1024];
};

class ChidManager
{
public:
    ChidManager( int maxNum = 100 );
    ~ChidManager( );

    EPICSChid* add( const char name[] );
    EPICSChid* find( const char name[] );

    void clearAll( );

    static ChidManager& GetObject( );

private:
    EPICSChid* _find( const char name[] ); //no lock

    //xos_mutex_t         m_lock;
    pthread_rwlock_t          m_rwLock;

    CPPNativeList<EPICSChid*> m_allChidList;

    static ChidManager* m_pTheSingleObject;
};
