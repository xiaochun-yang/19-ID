#ifndef __SIMDETECTOR_H__
#define __SIMDETECTOR_H__

#include "xos.h"
#include "XosMutex.h"
#include "XosException.h"
#include "Detector.h"
#include <string>
#include <vector>
#include <map>

enum DetectorState
{
	DETECTOR_READY,
	WAIT_FOR_DETECTOR_OSCILLATION_READY,
	WAIT_FOR_DETECTOR_TRANSFER_IMAGE,
	DETECTOR_FINISHED,
	DETECTOR_ERROR
};

class SimDetector : public Detector
{
public:

	SimDetector();
	virtual ~SimDetector();

	//return false if failed: it will be called at the beginning of robot thread
	virtual bool Initialize( );

	virtual void Cleanup( );	
	
	virtual void reset();
	

    //if you want to sleep in your function, use this semaphore to wait.
    //Stop will wake you up
    virtual void SetSleepSemaphore( xos_semaphore_t* pSem ) 
    {
    	m_pSem = pSem;
    }
    
	
	/**
	 * Called by DetectorService when it receives an 
	 * htos_operation_start detector_collect_image operation. 
	 * If this method returns true, htos_operation_completed detector_collect_image
	 * will be sent with status_buffer has the status string.
	 * If this method returns false, status_string will not be used
	 * and DetectorService will call detectorCollectImageUpdate
	 * in an infinite loop and sends out 
	 * htos_operation_update detector_collect_image. The operation completed
	 * message will be sent only when detectorCollectImageUpdate returns true.
	 *
	 * @param position Operation arguments
	 * @param status_buffer Status string to be sent with 
	 * htos_operation_completed detector_collect_image. Only used if the 
	 * operation returns true.
	 * @return True to indicate that the operation is completed,
	 * and false if to indicate that the operation has started and is stil running.
	 * @see detectorCollectImageUpdate
	 * 
	 */
	virtual bool detectorCollectImage(const char position[], char status_buffer[] );

	/**
	 * Called by DetectorService in an infinite loop until this 
	 * method returns true.
	 * @param status_buffer Status string to be sent out with operation update
	 * or operation completed for detector_collect_image operation.
	 * @return False to send out htos_operation_update and indicate that 
	 * this method should be called again by the DetectorService. Returns true
	 * to send out htos_operation_completed detector_collect_image.
	 */
	virtual bool detectorCollectImageUpdate(char status_buffer[] );

	/**
	 * Called by DetectorService before it sends out 
	 * htos_set_string_completed lastCollectedImage, which happens
	 * after it has sent out htos_operation_completed detector_collect_image message.
	 * 
	 * @param status_buffer Image filename to be sent with 
	 * lastCollectedImage string message.
	 * @return 
	 */
	virtual bool lastImageCollected(char status_buffer[] );

	/**
	 * Called by DetectorService when it receives
	 * htos_operation_start detector_transfer_image operation.
	 * This message is processed intantly by DetectorService.
	 * It should return immediately.
	 * 
	 * @param position Operation arguments
	 * @param status_buffer Status string for operation completed message.
	 */
	virtual void detectorTransferImage(const char argument[], char status_buffer[] );

	/**
	 * Called by DetectorService when it receives
	 * htos_operation_start detector_oscillation_ready operation.
	 * This message is processed intantly by DetectorService.
	 * It should return immediately.
	 * 
	 * @param position Operation arguments
	 * @param status_buffer Status string for operation completed message.
	 */
	virtual void detectorOscillationReady(const char argument[], char status_buffer[] );

	/**
	 * Called by DetectorService when it receives
	 * htos_operation_start detector_stop operation.
	 * This message is processed intantly by DetectorService.
	 * It should return immediately.
	 * 
	 * @param position Operation arguments
	 * @param status_buffer Status string for operation completed message.
	 */
	virtual void detectorStop(const char argument[], char status_buffer[] );

	/**
	 * Callback for detector_reset_run operation
	 */
	/**
	 * Called by DetectorService when it receives
	 * htos_operation_start detector_reset_run operation.
	 * This message is processed intantly by DetectorService.
	 * It should return immediately.
	 * 
	 * @param position Operation arguments
	 * @param status_buffer Status string for operation completed message.
	 */
	virtual void detectorResetRun(const char argument[], char status_buffer[] );
	
	
	/**
 	 */
	virtual void setDetectorType(const std::string& type);

	/**
 	 */
	virtual std::string getDetectorType() const 
	{
		return m_detectorType;
	}


protected:


	/**
	 * Callback before sending out 
	 * htos_operation_update detector_collect_image start_oscillation
	 */
	virtual void startOscillation();
	
	/**
	 * Callback before sending out 
	 * htos_operation_update detector_collect_image prepare_for_oscillation
	 */
	virtual void prepareForOscillation();


private:

	FrameData m_data;
	char updateString[MAX_LENGTH_STATUS_BUFFER];

	xos_semaphore_t* m_pSem;
	XosMutex m_mutex;
	
	int m_imageCount;
	DetectorState m_state;
	
	std::string m_imageDir;
	std::vector<std::string> m_images;
	std::string m_imageFilter;
	size_t m_imageIndex;
	
	std::string m_lastImageFile;
	std::string m_detectorType;
	
	std::map<std::string, std::string> m_cassetteDirs;
	
	std::string m_impHost;
	int m_impPort;

	std::string m_imageExtList;
	
	
private:
	
	
	void lock();
	void unlock();
    
	void setErrorState(const char* err);
	bool parseOperation(const char positionp[]);
	
	void sendOperationUpdate(const char* str);
	void getUpdateString(char str[]);
	
	void writeImageFile() throw (XosException);
	std::string getNextImage();
	
	std::string getStateString();
	    
	DetectorState getState();

	void setState(DetectorState s );
	
	void copyFile(const std::string& name, 
					const std::string& sid,
					const std::string& oldPath, 
					const std::string& newPath)
			throw(XosException);
	
	void createDirectory(const std::string& name, 
					const std::string& sid,
					const std::string& path, 
					bool cerateParents)
			throw(XosException);
	
	void validateSourceImage(const std::string& path)
		throw(XosException);

	std::string getSrcImage(const std::string& dir,
									const std::string& name);

	std::string getDestImageExt() const;
};

#endif //   #ifndef __SIMDETECTOR_H__
