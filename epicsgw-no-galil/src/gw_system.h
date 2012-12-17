#ifndef GW_SYSTEM_H
#define GW_SYSTEM_H
#include "xos.h"
#include "DcsConfig.h"
#include "gw_service.h"
#include "DcsMessageManager.h"
#include "gw_device_mgr.h"
#include "DcsMessageService.h"
#include "chid_mgr.h"

class GatewaySystem: public Observer
{
public:
    GatewaySystem( );
    virtual ~GatewaySystem( );

    bool loadConfig( const char* name );

    void runFront( );

    void onStop( );

    //implement Observer
    virtual void ChangeNotification( activeObject* pObj );

    static GatewaySystem* getInstance( );
private:
    BOOL waitAllStart( );
    void waitAllStop( );

    BOOL onInit( );
    void cleanup( );

private:
    DcsMessageManager       m_dcsMsgManager;
    GatewayDeviceManager    m_deviceManager;
    ChidManager             m_chidManager;

    DcsMessageService   m_dcsServer;
    GatewayService      m_gwServer;

    xos_event_t         m_evtStop;
    int                 m_flagStop;

    xos_semaphore_t     m_semWaitStatus;
    activeObject::Status volatile m_dcsStatus;
    activeObject::Status volatile m_gwStatus;

    DcsConfig&            m_config;

    static GatewaySystem* m_pSingleton;
};
#endif
