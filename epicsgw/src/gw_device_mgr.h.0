#include "GwString.h"
#include "GwShutter.h"
#include "GwBaseMotor.h"
#include "PointerList.h"

class GatewayDeviceManager
{
public:
    GatewayDeviceManager( int maxNum = 100 );
    ~GatewayDeviceManager( );

    GwString* addString( const char name[], const char foreignName[] );
    GwString* findString( const char name[] );

    GwShutter* addShutter( const char name[], const char foreignName[] );
    GwShutter* findShutter( const char name[] );
    
    GwBaseMotor* addPseudoMotor( const char name[], const char fName[] );
    GwBaseMotor* findPseudoMotor( const char name[] );
    
    GwBaseMotor* addRealMotor( const char name[], const char fName[] );
    GwBaseMotor* findRealMotor( const char name[] );

    GwBaseMotor* findMotor( const char name[] )
    {
        GwBaseMotor* result = findPseudoMotor( name );
        if (result) return result;

        return findRealMotor( name );
    }

    GwBaseDevice* findDevice( const char name[] );

    std::string getMotorType( const char fName[] );

    void clearAll( );

    void abortAll( );

    //called by worker thread
    void scan( unsigned long ticks );

    static GatewayDeviceManager& GetObject( );

private:
    GwString* _findString( const char name[] ); //no lock
    GwShutter* _findShutter( const char name[] );
    GwBaseMotor* _findPseudoMotor( const char name[] );
    GwBaseMotor* _findRealMotor( const char name[] );

    GwBaseDevice* _findDevice( const char name[] );

    void _makeSureDeviceNotExist( const char name[] );

    pthread_rwlock_t                 m_rwLock;
    //xos_mutex_t                      m_lock;

    CPPNativeList<GwBaseDevice*>     m_allDeviceList;
    CPPNativeList<GwString*>         m_stringList;
    CPPNativeList<GwShutter*>        m_shutterList;
    CPPNativeList<GwBaseMotor*>      m_pseudoMotorList;
    CPPNativeList<GwBaseMotor*>      m_realMotorList;

    static GatewayDeviceManager* m_pTheSingleObject;
    static DcsConfig*         volatile m_pDcsConfig;
};
