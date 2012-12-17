#ifndef __DETECTOR_SERVICE_H__
#define __DETECTOR_SERVICE_H__

#include "activeObject.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"
#include "Detector.h"
#include <string>

#define DETECTOR_TYPE_LENGTH 255


typedef void (Detector::*PTR_DETECTOR_FUNC)( const char argument[], char status_buffer[] );

class DcsMessageManager;

/**
 * DetectorService
 * Handles the message loop and calls registered callback for each 
 * operation.
 */
class DetectorService : public DcsMessageTwoWay
{
public:
	DetectorService(const std::string& type);
	virtual ~DetectorService(void);

	//implement activeObject
	virtual void start( );
	virtual void stop( );
	virtual void reset( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

private:
	static XOS_THREAD_ROUTINE Run( void* pParam )
	{
		DetectorService* pObj = (DetectorService*)pParam;
		pObj->ThreadMethod( );
        XOS_THREAD_ROUTINE_RETURN;
	}

	void ThreadMethod( );

	void SendoutDcsMessage( DcsMessage* pMsg );

	/**
	 * Generic method for processing an instant message
	 * for the detector
	 */
	void handleInstantMessage( PTR_DETECTOR_FUNC pMethod );
	
	/**
	 * Method for processing detector_collect_image operation.
	 * This is NOT an instant message.
	 */
	void detectorCollectImage();
	
	/**
	 * Instant messages. 
	 */
	void detectorTransferImage();
	void detectorOscillationReady();
	void detectorStop();
	void detectorResetRun();
	
	
	//////////////DATA
private:
	//save reference to manager
	DcsMessageManager& m_MsgManager;
	//message queue: messages waiting to execute: this is time consuming message
	MQueue m_MsgQueue;

	//thread
    xos_thread_t m_Thread;
	xos_semaphore_t m_SemThreadWait;    //this is wait for message and stop
    xos_semaphore_t m_SemStopOnly;      //this is for stop only, used as timer

	//detector
	Detector* m_pDetector;
	
	// Detector class. Used by DetectorFactory to create
	// a detector of the desired type.
	std::string m_detectorClass;
	

	//special data
	//This is also used as a flag, to check we are already running an operation
	DcsMessage* volatile m_pCurrentOperation;

	DcsMessage* volatile m_pInstantOperation;

	static struct MsgToMethod
	{
		const char*          m_OperationName;
		bool	             m_Immediately;
		void (DetectorService::*m_pMethod)();
	} m_msgActionMap[];
};

#endif //#ifndef __DETECTOR_SERVICE_H__
