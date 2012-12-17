#include <pthread.h>

class HoldReaderLock
{
public:
    HoldReaderLock( pthread_rwlock_t* pRWLock ): m_pRWLock(NULL)
    , m_locked(0)
    {
        m_pRWLock = pRWLock;
        if (m_pRWLock)
        {
            m_locked = (pthread_rwlock_rdlock( m_pRWLock ) == 0);
        }
    }
    ~HoldReaderLock( )
    {
        if (m_pRWLock && m_locked)
        {
            pthread_rwlock_unlock( m_pRWLock );
        }
    }
private:

    pthread_rwlock_t* m_pRWLock;
    int               m_locked;
};
class HoldWriterLock
{
public:
    HoldWriterLock( pthread_rwlock_t* pRWLock ): m_pRWLock(NULL)
    , m_locked(0)
    {
        m_pRWLock = pRWLock;
        if (m_pRWLock)
        {
            m_locked = (pthread_rwlock_wrlock( m_pRWLock ) == 0);
        }
    }
    ~HoldWriterLock( )
    {
        if (m_pRWLock && m_locked)
        {
            pthread_rwlock_unlock( m_pRWLock );
        }
    }
private:

    pthread_rwlock_t* m_pRWLock;
    int               m_locked;
};
