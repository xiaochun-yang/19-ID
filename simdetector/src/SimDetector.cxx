#include "xos.h"
#include "XosException.h"
#include "XosStringUtil.h"
#include "XosFileUtil.h"
#include "SimDetector.h"
#include "DcsConfig.h"
#include "DetectorSystem.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"
#include <string>
#include <vector>
#include <glob.h>
#include <fstream>

#define USE_IMPSERVER 0

extern DetectorSystem* gDetectorSystem;

/*****************************************************************
 * PUBLIC
 * Constructor
 *****************************************************************/
SimDetector::SimDetector()
	: m_pSem(NULL), m_imageCount(0), m_state(DETECTOR_READY),
		m_imageDir(""), m_imageIndex(0),
		m_lastImageFile(""), m_detectorType("Q315CCD"),
		m_impHost(""), m_impPort(0), 
		m_imageExtList(".img .mccd .tif")
{
}

/*****************************************************************
 * PUBLIC
 * Destructor
 *****************************************************************/
SimDetector::~SimDetector()
{
}


/*****************************************************************
 * PUBLIC
 * Cleanup
 * Called by the DetectorService. return false if failed: it 
 * will be called at the beginning of detector thread.
 *****************************************************************/
bool SimDetector::Initialize( )
{
		
	const DcsConfig& config = gDetectorSystem->getConfig();
	
	if (!config.get("simdetector.imageDir", m_imageDir)) {
		LOG_SEVERE("Could not find simdetector.imageDir config\n");
      xos_error_exit("Exit");
		return false;
	}
				
	if (!config.get("simdetector.impHost", m_impHost)) {
		if (!config.get("imperson.host", m_impHost)) {
			LOG_SEVERE("Could not find simdetector.impHost imperson.host config\n");
      		xos_error_exit("Exit");
			return false;
		}
	}
	
	std::string tmp = "";
	if (!config.get("simdetector.impPort", tmp)) {
		if (!config.get("imperson.port", tmp)) {
			LOG_SEVERE("Could not find simdetector.impPort or imperson.port config\n");
      		xos_error_exit("Exit");
			return false;
		}
	}
	m_impPort = XosStringUtil::toInt(tmp, 61001);


	/////get all the files match the pattern
	glob_t globbuf;
	std::string defaultImages = m_imageDir + "/*.*";
	if (glob( defaultImages.c_str( ), GLOB_ERR, NULL, &globbuf ))
	{
		globfree( &globbuf );
		LOG_SEVERE1("glob to get files failed: %s\n", m_imageDir.c_str());
		xos_error_exit("Exit");
		return false;
	}

	LOG_INFO1("Default source image dir: %s\n", m_imageDir.c_str( ) );
	std::string filename;
	for (size_t i = 0; i < globbuf.gl_pathc; ++i) {

		filename = globbuf.gl_pathv[i];
		LOG_INFO1("image file: %s\n", filename.c_str( ) );
		m_images.push_back(filename);
	}
	LOG_INFO1( "image pool size %d", m_images.size( ) );

	globfree( &globbuf );
	
	
	// Create cassette dir list
	std::string input_filename("./cassette_dirs.txt");
	if (!config.get("simdetector.cassetteFile", input_filename)) {
		input_filename = "./cassette_dirs.txt";
	}

	std::ifstream file;
	file.open(input_filename.c_str());
	if (!file.is_open()) {
		LOG_SEVERE1("Cannot open file %s\n", input_filename.c_str());
		xos_error_exit("Exit");
	}	
	std::string line;
	while (!file.eof()) {
		line = "";
		while (getline(file, line)) {
			size_t pos1 = line.find_last_of("/");
			if (pos1 == std::string::npos)
				continue;
			std::string lastDir = line.substr(pos1);
			m_cassetteDirs.insert(std::map<std::string, std::string>::value_type(lastDir, line));
		}
	}
	
	
	return true;
}

/*****************************************************************
 * PUBLIC
 * reset
 * 
 *****************************************************************/
void SimDetector::reset()
{

	setState(DETECTOR_READY);
	
	strcpy(updateString, "");
	m_lastImageFile = "";
	
	
}

/*****************************************************************
 * PUBLIC
 * Cleanup
 * Called by the DetectorService before message queue is stopped.
 *****************************************************************/
void SimDetector::Cleanup( )
{
}

	
/*****************************************************************
 * PUBLIC
 * detectorCollectImage
 * Callback for detector_collect_image operation.
 * This method gets called repeatedly until it returns true.
 * DetectorService wills send out operation_update
 * if this method returns false, and will send out
 * operation_complete if this method returns true.
 *****************************************************************/
bool SimDetector::detectorCollectImage( 
						const char position[],  
						char status_buffer[] )
{
	LOG_INFO1("detectorCollectImage enter: detector status = %d\n", getState());
	
	if (getState() == DETECTOR_READY) {
	
		m_lastImageFile = "";
		m_imageCount = 0;
		
	
		// Parse operation arguments
		if (parseOperation(position)) {
		
			// Ready to receive detector_transfer_image operation
			// while detector_collect_image operation is still
			// active.
			setState(WAIT_FOR_DETECTOR_TRANSFER_IMAGE);
			// Set update string and wake up the semaphore
			// so that the update message will be sent.
			startOscillation();
			// Return false to indicate the the operation
			// has not completed.
			return false;	
			
		} else {
		
			// Error. Send htos_operation_complete detector_collect_image error ...
			setState(DETECTOR_ERROR);
			snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, 
						"error invalid operation arguments");
			return true;
		}
	}
	
	// Can not process one detector_collect_image operation
	// at a time.
	setState(DETECTOR_ERROR);
	snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, 
				"Detector is busy");
	return true;
	
}
	
	
/*****************************************************************
 * PUBLIC
 * detectorCollectImage
 * Callback for detector_collect_image operation.
 * This method gets called repeatedly until it returns true.
 * DetectorService wills send out operation_update
 * if this method returns false, and will send out
 * operation_complete if this method returns true.
 *****************************************************************/
bool SimDetector::detectorCollectImageUpdate(char status_buffer[])
{
	// Do not return until we are notified of 
	// a state change.
	xos_semaphore_wait(m_pSem, 0);

	// Any other states
	getUpdateString(status_buffer);

	if (getState() == DETECTOR_FINISHED) {
	
		return true;
		
	} else if (getState() == DETECTOR_ERROR) {
	
		return true;
	}

	return false;
		
}

/*****************************************************************
 * PUBLIC
 * detectorCollectImage
 * Callback for detector_collect_image operation.
 * This method gets called repeatedly until it returns true.
 * DetectorService wills send out operation_update
 * if this method returns false, and will send out
 * operation_complete if this method returns true.
 *****************************************************************/
bool SimDetector::lastImageCollected(char status_buffer[])
{
	if (getState() == DETECTOR_FINISHED) {
		snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, m_lastImageFile.c_str());
		reset();
		return true;
	} else if (getState() == DETECTOR_ERROR) {
		strcpy(status_buffer, "");
		reset();
		return false;
	}
	
		
	strcpy(status_buffer, "");
	return false;
		
}

/*****************************************************************
 * PUBLIC
 * detectorOscillationReady
 * Callback for detector_transfer_image operation
 *****************************************************************/
void SimDetector::detectorTransferImage(const char argument[], char status_buffer[] )
{
	// Return normally
	snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, "normal");
	
	// Wrong state
	if (getState() != WAIT_FOR_DETECTOR_TRANSFER_IMAGE) {
		// Return normally
		snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, 
				"error wrong detector state for this operation");
		return;
	}
	
	++m_imageCount;
	
	
	// Detector is in NON-flush mode
	// For this simdetector, the image is ready to
	// be written out after 4 detector_transfer_image.
	if (m_imageCount > 1) {
	
		setErrorState("Too many images");
		// Return normally
		snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, 
				"error Detector image buffer is full");
		
	} else if (m_imageCount < 1) {
	
		prepareForOscillation();
		setState(WAIT_FOR_DETECTOR_OSCILLATION_READY);
		
	} else {	// m_imageCount == 4
	
		try {
		
			writeImageFile();
			setState(DETECTOR_FINISHED);
			sendOperationUpdate("normal");
			LOG_INFO("Finished frame\n");
			
			
		} catch (XosException& e) {
			setErrorState(e.getMessage().c_str());
			snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, 
					"normal error %s",
					e.getMessage().c_str());
		}
		
	}
		
}


/*****************************************************************
 * PUBLIC
 * detectorOscillationReady
 * Callback for detector_oscillation_ready operation
 *****************************************************************/
void SimDetector::detectorOscillationReady(const char argument[], char status_buffer[] )
{

	// Wrong state
	if (getState() != WAIT_FOR_DETECTOR_OSCILLATION_READY) {
		snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, 
				"error wrong detector state for this operation");
		return;
	}
	
	startOscillation();

	setState(WAIT_FOR_DETECTOR_TRANSFER_IMAGE);
	snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, "normal");

}


/*****************************************************************
 * PUBLIC
 * detectorStop
 * Callback for detector_stop operation
 *****************************************************************/
void SimDetector::detectorStop(const char argument[], char status_buffer[] )
{
	m_imageCount = 0;
	
	
	if (getState() > DETECTOR_READY) {
		
		setState(DETECTOR_FINISHED);
		sendOperationUpdate("normal");		
	}
	
	snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, "normal");

}


/*****************************************************************
 * PUBLIC
 * detectorResetRun
 * Callback for detector_reset_run operation
 *****************************************************************/
void SimDetector::detectorResetRun(const char argument[], char status_buffer[] )
{

	m_imageCount = 0;
	
	if (getState() > DETECTOR_READY) {
		setState(DETECTOR_FINISHED);
		sendOperationUpdate("normal detector was reset");
	}
	
	snprintf(status_buffer, MAX_LENGTH_STATUS_BUFFER, "normal");

}

/*****************************************************************
 * PROTECTED
 * startOscillation
 * Set update string for detector_collect_image operation
 *****************************************************************/
void SimDetector::startOscillation()
{
	char shutter[10];
	
	strcpy(shutter, "shutter");

	if (m_imageCount < 2) {
		strcpy(shutter, "NULL");
	}
	
	char buff[MAX_LENGTH_STATUS_BUFFER];
	snprintf(buff, 
				MAX_LENGTH_STATUS_BUFFER, 
				"start_oscillation %s %f",
				shutter, m_data.exposureTime/2.0);
				
	// wake up detectorCollectImage
	sendOperationUpdate(buff);
	
}


/*****************************************************************
 * PROTECTED
 * prepareForOscillation
 * Set update string for detector_collect_image operation
 *****************************************************************/
void SimDetector::prepareForOscillation()
{
	char buff[MAX_LENGTH_STATUS_BUFFER];
	snprintf(buff, 
				MAX_LENGTH_STATUS_BUFFER, 
				"prepare_for_oscillation %f",
				m_data.oscillationStart);
	// wake up detectorCollectImage
	sendOperationUpdate(buff);

}

/*****************************************************************
 * PROTECTED
 * parseOperation
 * Parses arguments for detector_collect_image operation
 *****************************************************************/
bool SimDetector::parseOperation(const char position[])
{
	LOG_INFO1("Operation arguments = %s\n", position);
	int num = 0;
	if ((num=sscanf(position,
			 "%d %s %s %s %s %lf %lf %lf %lf %lf %lf %lf %d %d %s",
			 &m_data.runIndex,
			 m_data.fileName,
			 m_data.directory,
			 m_data.userName,
			 m_data.axisName,
			 &m_data.exposureTime,
			 &m_data.oscillationStart,
			 &m_data.oscillationRange,
			 &m_data.distance,
			 &m_data.wavelength,
			 &m_data.detectorX,
			 &m_data.detectorY,
			 &m_data.detectorMode,
			 (int*)&m_data.reuseDark,
			 m_data.sessionId)) != 15) {			
	
		LOG_WARNING1("Expecting 15 arguments but got %d\n", num);
		return false;
	}
		
	// Remove 'PRIVATE' from the sessionId string.
	std::string tmp(m_data.sessionId);
	size_t pos = tmp.find("PRIVATE");
	std::string tmp1 = tmp;
	if (pos == 0)
		tmp1 = tmp.substr(7);
	else if (pos > 0)
		tmp1 = tmp.substr(0, pos);

	strcpy(m_data.sessionId, tmp1.c_str());

	
	return true;
}

/*****************************************************************
 * PROTECTED
 * setState
 * Sets detector state
 *****************************************************************/
void SimDetector::setState(DetectorState state)
{
	lock();
	
	if (m_state != state) {
		m_state = state;
	}
	
	unlock();
	
}

/*****************************************************************
 * PROTECTED
 * getState
 * Returns detector state
 *****************************************************************/
DetectorState SimDetector::getState()
{
	DetectorState ret;
	
	lock();
	
	ret = m_state;
	
	unlock();
	
	return ret;
}


/*****************************************************************
 * PRIVATE
 * sendOperationUpdate
 * Sets string for operation_update detector_collect_image
 *****************************************************************/
void SimDetector::sendOperationUpdate(const char* str)
{
	snprintf(updateString, MAX_LENGTH_STATUS_BUFFER, str);
	
	// Wake up detectorCollectImageUpdate if it is waiting
	xos_semaphore_post(m_pSem);
}

/*****************************************************************
 * PRIVATE
 * getUpdateString
 * Returns the updateString
 *****************************************************************/
void SimDetector::getUpdateString(char str[])
{
	snprintf(str, MAX_LENGTH_STATUS_BUFFER, updateString);
}

/*****************************************************************
 * PRIVATE
 * setErrorState
 * Sets the state to ERROR and sets error string
 *****************************************************************/
void SimDetector::setErrorState(const char* err)
{

	char lastError[MAX_LENGTH_STATUS_BUFFER];
	snprintf(lastError, 
				MAX_LENGTH_STATUS_BUFFER, 
				"error %s",
				err);

	setState(DETECTOR_ERROR);
	sendOperationUpdate(lastError);
}

/*****************************************************************
 * PRIVATE
 * lock
 * Mutex lock for state
 *****************************************************************/
void SimDetector::lock()
{
	m_mutex.lock();
}

/*****************************************************************
 * PRIVATE
 * unlock
 * Mutex unlock for state
 *****************************************************************/
void SimDetector::unlock()
{
	m_mutex.unlock();
}

/*****************************************************************
 * PRIVATE
 * getNextImage
 *****************************************************************/
std::string SimDetector::getNextImage()
{
    LOG_INFO1( "current image index: %d", m_imageIndex );
	if (m_imageIndex >= m_images.size())
		m_imageIndex = 0;

	std::string ret = m_images[m_imageIndex];
	++m_imageIndex;
		
	return ret;
}

/*****************************************************************
 * PRIVATE
 * getStateString
 * Returns detector state as string.
 *****************************************************************/
std::string SimDetector::getStateString()
{
	DetectorState state = getState();
	
	if (state == DETECTOR_READY)
		return "detector_ready";
	else if (state == WAIT_FOR_DETECTOR_OSCILLATION_READY)
		return "wait_for_detector_oscillation_ready";
	else if (state == WAIT_FOR_DETECTOR_TRANSFER_IMAGE)
		return "wait_for_detector_transfer_image";
	else if (state == DETECTOR_FINISHED)
		return "detector_finished";
	else if (state == DETECTOR_ERROR)
		return "detector_error";
		
	return "unknown";
}

/*****************************************************************
 * PRIVATE
 * writeImageFile
 *****************************************************************/
void SimDetector::writeImageFile()
	throw (XosException)
{
	// First, try to find a cassette directory from the list
	// that matches the destination dir. The list is read from a
	// cassette_dirs.txt file in the current work directory.
	// If no cassetet dir matches the destination dir, pick up an image
	// from the default image source directory directory, which is 
	// set by the config simdetector.imageDir.
	// For example:
	// dest filename = /data/joeuser/screening_results/cassette130/myoglobin/crystal0383/inf1_0_001.img
	// src cassette dir list in cassette_dirs.txt:
	// 		/data/blctl/test_cassettes/cassette130
	// 		/data/blctl/test_cassettes/cassette131
	// 		/data/blctl/test_cassettes/cassette132
	// In order to determine which src cassette to use for the 
	// requested destination file, we need to search the cassette dir list.
	// Create a list of cassette names from cassette_dirs.txt.
	// Here we have cassette130, cassette131 and cassette132.
	// Then search for the cassetet name in the dest filename.
	// In this case, we will find cassette130 in the dest filename.
	// The src image file is therefore 
	// /data/blctl/test_cassettes/cassette132/myoglobin/crystal0383/inf1_0_001.img
	std::string destDir = std::string(m_data.directory);

	LOG_INFO1("Detector type = %s\n", m_detectorType.c_str());
	std::string destImage = destDir + std::string("/") + m_data.fileName + getDestImageExt();
	
	std::string srcImage = "";
	
	std::string cassetteName = "";
	std::string cassetteDir = "";
	std::map<std::string, std::string>::iterator i = m_cassetteDirs.begin();
	size_t pos = std::string::npos;
	std::string aDir = "";
	for (; i != m_cassetteDirs.end(); ++i) {
		if ((pos=destDir.find(i->first)) == std::string::npos)
			continue;
			
		// Found cassette dir that matches the output dir
		cassetteName = i->first;
		cassetteDir = i->second;
		// source image's extension is always .img regardless of 
		// what the actual image header says.
//		srcImage = cassetteDir +  destDir.substr(pos+cassetteName.size()) 
//						+ std::string("/") + m_data.fileName + ".img";
		aDir = cassetteDir + destDir.substr(pos+cassetteName.size());
		srcImage = getSrcImage(aDir, m_data.fileName);
		
	}
	
	// does not find casstte dir that matches the output dir.
	// Use image from default image dir.
	if (srcImage.empty()) {
		srcImage = getNextImage();
	}

	// Make sure the source image file exists and is readable.
	validateSourceImage(srcImage);

	LOG_INFO1("Exposure time = %f seconds\n", m_data.exposureTime);
	// Simulate exposure time
	xos_thread_sleep((int)m_data.exposureTime*1000);
	
	// Detector write out time.
	xos_thread_sleep(1000);
	
	// Copy image file using the impersonation server
	LOG_INFO2("Copying %s to %s\n",
				srcImage.c_str(), destImage.c_str());
    copyFile(m_data.userName, m_data.sessionId, srcImage, destImage);
    m_lastImageFile = destImage;

}

/*****************************************************************
 * PRIVATE
 * copyFile
 * Copy a file from src to dest using the impersonation server.
 * the dest file must belong to the user passed in as argument.
 *****************************************************************/
void SimDetector::copyFile(const std::string& name, 
					const std::string& sid,
					const std::string& oldPath, 
					const std::string& newPath)
	throw (XosException)
{
	try {

#ifdef USE_IMPSERVER

	HttpClientImp client;
	client.setAutoReadResponseBody(true);
	// Set read timeout to 10 seconds.
	client.setReadTimeout(10000);

	HttpRequest* request = client.getRequest();

	std::string uri;
	uri += std::string("/copyFile?impUser=") + name
		   + "&impSessionID=" + sid
		   + "&impOldFilePath=" + oldPath
		   + "&impNewFilePath=" + newPath
		   + "&impBackupExist=true"
		   + "&impFileMode=0740";
		   

	request->setURI(uri);
	request->setHost(m_impHost);
	request->setPort(m_impPort);
	request->setMethod(HTTP_GET);
	
	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		LOG_WARNING4("Failed to copy file from %s to %s (user = %s, session = %.7s)", oldPath.c_str(), newPath.c_str(), name.c_str(), sid.c_str());
		throw XosException(std::string("Failed to copy image file from " + oldPath
						+ " to " + newPath) 
						+ response->getStatusPhrase());
	}

    std::string warningMsg;
    if (response->getHeader( "impWarningMsg", warningMsg )) {
        //cannot send warning message to dcss from here,
        //we just log it
        LOG_WARNING1( "imperson copyFile warning: %s", warningMsg.c_str( ) );
    }

#else // not USE_IMPSERVER

	LOG_INFO2("Copying %s to %s\n",
				oldPath.c_str(), newPath.c_str());
    XosFileUtil::copyFile(oldPath.c_str(), newPath.c_str());
	

#endif // ifdef USE_IMPSERVER

	} catch (XosException& e) {
		LOG_WARNING1("Exception raised in SimDetector::copyFile %s", e.getMessage().c_str());
		throw;
	}

	
}

/*****************************************************************
 * PRIVATE
 * copyFile
 * Copy a file from src to dest using the impersonation server.
 * the dest file must belong to the user passed in as argument.
 *****************************************************************/
void SimDetector::createDirectory(const std::string& name, 
					const std::string& sid,
					const std::string& path, 
					bool createParents)
	throw (XosException)
{
   try {

#ifdef USE_IMPSERVER

	HttpClientImp client;
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string create("false");
	if (createParents)
		create = "true";

	std::string uri;
	uri += std::string("/createDirectory?impUser=") + name
		   + "&impSessionID=" + sid
		   + "&impDirectory=" + path
			+ "&impCreateParents=" + create
		   + "&impFileMode=0740";
		   

	request->setURI(uri);
	request->setHost(m_impHost);
	request->setPort(m_impPort);
	request->setMethod(HTTP_GET);
	
	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() == 573) {
		// Directory already exist then do nothing
		LOG_INFO1("Directory %s already exists", path.c_str());
	} else if (response->getStatusCode() != 200) {
		LOG_WARNING4("Failed create image directory %s (user = %s, session = %.7s): %s", path.c_str(), name.c_str(), sid.c_str(), response->getStatusPhrase().c_str());
		throw XosException(std::string("Failed to create image directory ") + path
						+ ": " + response->getStatusPhrase());
	}

#else // not USE_IMPSERVER

	if (!createParents) {
		if (mkdir(m_data.directory, 0770 )) {
			if (errno != EEXIST) {
				throw XosException(errno, XosFileUtil::getErrorString(errno, "Failed to create dir: " + m_data.directory ));
		}

		return;

	}

	// Create directory and its parents
	std::vector<std::string> dirs;
	if (!XosStringUtil::tokenize(m_data.directory, "/", dirs))
		throw XosException("Invalid directory " + std::string(m_data.directory));

    //make sure the directory exists and we can write to it
	std::vector<std::string>::iterator i = dirs.begin();
    std::string path = "";
    for (; i != dirs.end(); ++i) {
    	path += "/" + *i;
		if (mkdir(path.c_str(), 0770 ))
		{
			if (errno != EEXIST)
			{
				throw XosException(errno, XosFileUtil::getErrorString(errno, "Failed to create dir: " + m_data.directory ));
			}
		}
	}


#endif // ifdef USE_IMPSERVER
	
	} catch (XosException& e) {
		LOG_WARNING1("Exception raised in SimDetector::createDirectory %s", e.getMessage().c_str());
		throw;
	}
}

/**
 * Make sure the directory can be read, 
 * the file extension can be found,
 * and the src file exists.
 */
void SimDetector::validateSourceImage(const std::string& path)
	throw(XosException)
{
	FILE* f = fopen(path.c_str(), "r");
	if (f == null) {
		LOG_WARNING1("Cannot find or read source image file %s", path.c_str());
		throw XosException("cannot find or read source image file " + path);
	}

	fclose(f);
}

std::string SimDetector::getSrcImage(const std::string& dir,
											const std::string& name)
{
		/////get all the files match the pattern
		glob_t globbuf;
		std::string basename = dir + "/" + name;
		std::string filter = basename + ".*";

		if (glob(filter.c_str( ), GLOB_ERR, NULL, &globbuf ))
		{
			globfree( &globbuf );
			LOG_WARNING1("glob to get files failed in getSrcImage: %s\n", filter.c_str());
			return basename + ".img";
		}

		std::string fname = "";
		size_t pos = std::string::npos;
		std::string ext = "";
		for (size_t i = 0; i < globbuf.gl_pathc; ++i) {
			fname = globbuf.gl_pathv[i];
			pos = fname.find_last_of(".");
			if (pos == std::string::npos)
				continue;
			ext = fname.substr(pos);
			if (m_imageExtList.find(ext) == std::string::npos)
				continue;
			globfree( &globbuf );
			LOG_INFO1("found matching name = %s\n", fname.c_str());
			return fname;
		}

		globfree( &globbuf );
		
		return basename + ".img";
		
}

std::string SimDetector::getDestImageExt() const
{
	if ((m_detectorType == "Q315CCD") || (m_detectorType == "Q4CCD")) {
		return ".img";
	} else if (m_detectorType == "PILATUS6") {
        return ".cbf";
	} else if (m_detectorType == "MAR325") {
		return ".mccd";
	} else if (m_detectorType == "MAR345") {
		switch (m_data.detectorMode) {
			case 0:
				return ".mar2300";
			case 1: 
				return ".mar2000";
			case 2:
				return ".mar1600";
			case 3:
				return ".mar1200";
			case 4:
				return ".mar3450";
			case 5:
				return ".mar3000";
			case 6:
				return ".mar2400";
			case 7:
				return ".mar1800";
		}
	}

	return ".img";
}

void SimDetector::setDetectorType(const std::string& type)
{
	if (type.empty())
		return;

	if ((type != "MAR325") && (type != "Q315CCD") && (type != "Q4CCD") && (type != "MAR345") && (type != "PILATUS6"))
		return;

	m_detectorType = type;

	LOG_INFO1("setDetectorType: new type = %s\n", m_detectorType.c_str());
}

