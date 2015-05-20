#ifndef __DETECTOR_H__
#define __DETECTOR_H__

#include "xos.h"
#include "FrameData.h"
#include <string>

#define MAX_LENGTH_STATUS_BUFFER 127

class Detector
{
public:
	Detector( ) { }
	virtual ~Detector( ) {}


	//return false if failed: it will be called at the 
	// beginning of detector thread
	virtual bool Initialize( ) = 0;

	virtual void Cleanup( ) = 0;
	
	virtual void reset() = 0;

	//all following methods:
	//it will be called in a loop until return TRUE.
	//it will have chance to send update message
	//it maybe abandonded before return TRUE.  It happens if command STOP or RESET received.
	//if you do not want to be interrupted, finish it in one function call.

    //if you want to sleep in your function, use this semaphore to wait.
    //Stop will wake you up
    virtual void SetSleepSemaphore( xos_semaphore_t* pSem ) { }
    

	/**
	 * Callback for detector_collect_image operation
	 */
	virtual bool detectorCollectImage(const char position[], char status_buffer[] ) = 0;

	/**
	 * Callback for detector_collect_image operation
	 */
	virtual bool detectorCollectImageUpdate(char status_buffer[] ) = 0;

	/**
	 * Callback for detector_collect_image operation
	 */
	virtual bool lastImageCollected(char status_buffer[] ) = 0;


	/**
	 * Callback for detector_transfer_image operation
	 */
	virtual void detectorTransferImage(const char argument[], char status_buffer[]) = 0;

	/**
	 * Callback for detector_oscillation_ready operation
	 */
	virtual void detectorOscillationReady(const char argument[], char status_buffer[]) = 0;

	/**
	 * Callback for detector_stop operation
	 */
	virtual void detectorStop(const char argument[], char status_buffer[]) =  0;

	/**
	 * Callback for detector_reset_run operation
	 */
	virtual void detectorResetRun(const char argument[], char status_buffer[]) = 0;
	
	/**
 	 */
	virtual void setDetectorType(const std::string& t) = 0;

	/**
	 */
	virtual std::string getDetectorType() const = 0;

protected:
	
    
	/**
	 * Callback before sending out 
	 * htos_operation_update detector_collect_image start_oscillation
	 */
	virtual void startOscillation() = 0;
	
	/**
	 * Callback before sending out 
	 * htos_operation_update detector_collect_image prepare_for_oscillation
	 */
	virtual void prepareForOscillation() = 0;
	
};

#endif //   #ifndef __DETECTOR_H__
