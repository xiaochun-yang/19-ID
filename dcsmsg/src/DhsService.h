#ifndef __SIMPLE_DHS_SERVICE_H__
#define __SIMPLE_DHS_SERVICE_H__
#include "activeObject.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "MQueue.h"

//
// you can make it more fancy once the C++ supports downgrade a
// pointer to derived class function to base class function
//

#define MY_ARRAY_LENGTH(a) (sizeof(a) / sizeof(a[0]))

class DcsMessageManager;
class DhsService: public DcsMessageTwoWay, public DcsMessageSender
{
public:
	DhsService(void);
	virtual ~DhsService(void);

	//implement activeObject
	virtual void start( );
	virtual void stop( );
	virtual void reset( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

    //implement DcsMessageSender so it can be used in derived classes
	void sendoutDcsMessage( DcsMessage* pMsg );

    //MUST MUST MUST implemented by derived classes
    virtual void callFunction( int functionIndex, int objectIndex ) = 0;

    //need implement by derived classes
    //called in "the" thread
    //before enter message loop
    virtual BOOL Initialize( ) { return TRUE; }
    //after exit message loop but before quit
    virtual void Cleanup( ) { }
    //when there is no message to process
    virtual void Poll( ) { }
    //called after got message from queue
    //give derived classes a chance to clear or set something
    virtual void forNewMessage( ) { }

    //called by other thread (mostly dcsmsgservice thread)
    virtual void Abort( ) { }

    //help class
    bool stringRegistered( int index ) const;
    bool stringRegistered( const char* stringName ) const;

protected:
    struct DeviceMap
    {
		const char*     m_localName;

        //if true, the dhs will ask dcss to send config when connected
        bool            m_askConfig;

        //called at stoh_register_XXX
        //use this to send init config or contents or position
		int             m_indexMethodInit;

        //if true, the message will NOT be put in the queue
        //it will call the related function immediately
        //by the other thread (tcp/ip part)
        //normally should be software only quick access
        //it shoul only read or the contents it changed should be
        //declared volatile and may need mutex protection
		bool	          m_immediate;

        //main or first operaion
        int m_indexMethod;

        //second operation used by motor and encoder
        int m_indexMethod2;
    };

    typedef char DeviceName[MAX_OBJECT_NAME_LENGTH + 1];

protected:
    //derived class must call these in its constructor
    //void setupFunctionTable( pStandardFunction table[], int num );
    void setupMapOperation( DeviceMap map[], int num );
    void setupMapString( DeviceMap map[], int num );
    void setupMapMotor( DeviceMap map[], int num );
    void setupMapEncoder( DeviceMap map[], int num );
    void setupMapIonChamber( DeviceMap map[], int num );
    void setupMapShutter( DeviceMap map[], int num );
protected:
	static XOS_THREAD_ROUTINE Run( void* pParam )
	{
		DhsService* pObj = (DhsService*)pParam;
		pObj->ThreadMethod( );
        XOS_THREAD_ROUTINE_RETURN;
	}
    void clearDcsMessagePointer( DcsMessage* &pMsg );

    BOOL registerDevice( DcsMessage* pMsg );
    void askConfig( const char* deviceName );

    BOOL enqueueMessage( DcsMessage* pMsg );
    BOOL handleMessage( DcsMessage* pMsg );
    BOOL prepareMap( const DcsMessage* pMsg,
    int& total, DeviceMap* &pMap, DeviceName* &pName,
    bool& secondMethod ) const;

	void ThreadMethod( );
    DcsMessage* waitMessageFromQueue( );
    void replyAborted( DcsMessage* pMsg );

	//help functions to simplify coding
	void sendoutOperationCompletedMessage( const char * status, const void *pBinary = NULL, size_t lBinary = 0 ) {
		sendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, status, pBinary, lBinary ) );
	}
	void sendoutOperationUpdateMessage( const char * status, const void *pBinary = NULL, size_t lBinary = 0 ) {
		sendoutDcsMessage( m_MsgManager.NewOperationUpdateMessage( m_pCurrentMessage, status, pBinary, lBinary ) );
	}

protected:
	//save reference to manager
	DcsMessageManager& m_MsgManager;
	//message queue: messages waiting to execute: this is time consuming message
	MQueue             m_MsgQueue;
	xos_semaphore_t    m_SemMsgQueue;

	//thread
    xos_thread_t    m_Thread;

	//special data
    //used in immediately function call
	DcsMessage* volatile m_pInstantMessage;

    //used in queue message call
	//This is also used as a flag, to check we are already running an operation
	DcsMessage* volatile m_pCurrentMessage;

    //set when an abort message received
    //cleared after all queued message aborted
    //that abort message is also put into the queue as a mark of end
    //of aborting
    bool        volatile m_aborting;

    //the mapping will be defined in derived classes so:
    //pStandardFunction* m_pFunctionTable;
    //int                m_numFunction;

    DeviceMap* m_pOperationMap;
    int        m_numOperation;

    DeviceMap* m_pStringMap;
    int        m_numString;

    DeviceMap* m_pMotorMap;
    int        m_numMotor;

    DeviceMap* m_pIonChamberMap;
    int        m_numIonChamber;

    DeviceMap* m_pEncoderMap;
    int        m_numEncoder;

    DeviceMap* m_pShutterMap;
    int        m_numShutter;

    DeviceName*         m_pOperationName;
    DeviceName*         m_pStringName;
    DeviceName*         m_pMotorName;
    DeviceName*         m_pIonChamberName;
    DeviceName*         m_pEncoderName;
    DeviceName*         m_pShutterName;
};

#endif //#ifndef __SIMPLE_DHS_SERVICE_H__
