#ifndef __DETECTOR_SYSTEM_H__
#define __DETECTOR_SYSTEM_H__

#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "DetectorService.h"
#include "activeObject.h"
#include "DcsConfig.h"
#include <string>

/**
 * DetectorSystem
 * One instance per application. This class loads config from file
 * and starts the DetectorService thread.
 */
class DetectorSystem: public Observer
{
public:
	DetectorSystem(const std::string& beamline);
	DetectorSystem(const std::string& beamline, const std::string& type);
	~DetectorSystem();

    void RunFront( );   //will block until signal by other thread through OnStop()

    void OnStop( );

    //implement Observer
    virtual void ChangeNotification( activeObject* pSubject );
    
    /**
     * Returns DcsConfig
     */
    const DcsConfig& getConfig() const
    {
    	return m_config;
    }
    

private:
    //help function
    BOOL WaitAllStart( );
    void WaitAllStop( );

    BOOL OnInit( );
    void Cleanup( );
    
    /**
     * Loads config from file
     */
    bool loadConfig();
    
    /**
     * Returns detector instance name from config
     */
    std::string getDetectorName() const;

    ////////////////////////////////////DATA////////////////////
private:
	//create managers first
	DcsMessageManager m_MsgManager;

	//create services
	DcsMessageService m_DcsServer;
	DetectorService      m_DetectorService;

    //wait signal to quit
    xos_event_t       m_EvtStop;
    bool              m_FlagStop;

    //to wait both detector and message service to start and stop
    xos_semaphore_t               m_SemWaitStatus;
    activeObject::Status volatile m_DcsStatus;
    activeObject::Status volatile m_DetectorStatus;
    
    /**
     * Configuration
     */
    DcsConfig m_config;
    std::string m_beamline;
    std::string m_detectorType;
    

};

#endif //#ifndef __DETECTOR_SYSTEM_H__
