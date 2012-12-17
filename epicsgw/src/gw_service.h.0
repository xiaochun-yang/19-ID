#ifndef GW_SERVICE_H
#define GW_SERVICE_H
#include "xos.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"

class DcsMessageManager;
class GatewayDeviceManager;
class ChidManager;
class GatewayService: public DcsMessageTwoWay, public DcsMessageSender
{
public:
    GatewayService( );
    virtual ~GatewayService( );

    //implment activeObject
    virtual void start( );
    virtual void stop( );
    virtual void reset( );

    //implment DcsMessageTwoWay
    virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

    //implement DcsMessageSender used by its components to send message
    void sendoutDcsMessage( DcsMessage* pMsg );

private:
    void doTask( DcsMessage* pMsg );

    void replyAborted( DcsMessage* pMsg );
    
    void createString( DcsMessage* pMsg );
    void setString( DcsMessage* pMsg );

    void createShutter( DcsMessage* pMsg );
    void setShutter( DcsMessage* pMsg );
    
    void createPseudoMotor( DcsMessage* pMsg );
    void createRealMotor( DcsMessage* pMsg );
    void moveMotor( DcsMessage* pMsg );
    void configPseudoMotor( DcsMessage* pMsg );
    void configRealMotor( DcsMessage* pMsg );

    void epicsMain( );          //process messages
    void dcsScan( );            //min delay update

    static XOS_THREAD_ROUTINE EpicsThreadRoutine( void* pParam )
    {
        GatewayService* pObj = (GatewayService*)pParam;
        pObj->epicsMain( );
        XOS_THREAD_ROUTINE_RETURN;
    }
    static XOS_THREAD_ROUTINE DcsScanThreadRoutine( void* pParam )
    {
        GatewayService* pObj = (GatewayService*)pParam;
        pObj->dcsScan( );
        XOS_THREAD_ROUTINE_RETURN;
    }

private:
    //these two will share the same epics context
    xos_thread_t m_epicsMainThread;

    xos_thread_t m_dcsThread;

    xos_semaphore_t m_semWaitStatus;
    Status volatile m_dcsScanThreadStatus;
    bool   volatile m_aborting;

    //all message will be queued here for epics thread to do it
    MQueue          m_msgQueue;
    xos_semaphore_t m_semMsgQueue;

    static const double FLOAT_TOLERANCE;
    static DcsMessageManager* m_pDcsMsgManager;
    static GatewayDeviceManager* m_pDeviceManager;
    static ChidManager* m_pChidManager;
};
#endif
