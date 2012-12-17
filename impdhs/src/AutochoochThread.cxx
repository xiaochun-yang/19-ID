/**********************************************************************************
                        Copyright 2002
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.


                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
 of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
 Leland Stanford Junior University, nor their employees, makes any war-
 ranty, express or implied, or assumes any liability or responsibility
 for accuracy, completeness or usefulness of any information, apparatus,
 product or process disclosed, or represents that its use will not in-
 fringe privately-owned rights.  Mention of any product, its manufactur-
 er, or suppliers shall not, nor is it intended to, imply approval, dis-
 approval, or fitness for any particular use.  The U.S. and the Univer-
 sity at all times retain the right to use and disseminate the furnished
 items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.


                       Permission Notice

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
 BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*********************************************************************************/

#include "DcsMessage.h"
#include "DcsMessageManager.h"
#include "ImpersonService.h"
#include "ImpersonSystem.h"
#include "AutochoochThread.h"
#include "log_quick.h"
#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"
#include <vector>
#include <map>


#ifdef WIN32
#define snprintf _snprintf
#endif


/*******************************************************************
 *
 *
 *
 *******************************************************************/
AutochoochThread::AutochoochThread(ImpersonService* parent, 
								   DcsMessage* pMsg,
								   const ImpConfig& c)
	: OperationThread(parent, pMsg, c)
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
AutochoochThread::~AutochoochThread()
{
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::run()
{
	exec();
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::exec()
{

	LOG_FINEST("in AutochoochThread::run\n"); fflush(stdout);

	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();

	try {	

	
	if (strcmp(m_pMsg->GetOperationName(), "runAutochooch") != 0)
		throw XosException("unknown operation");
		
	std::string tmpDir = m_config.getChoochTmpDir();
			
				
	LOG_FINEST1("impHost = %s\n", m_config.getImpHost().c_str());
	LOG_FINEST1("impPort = %d\n", m_config.getImpPort());
	LOG_FINEST1("tmpDir = %s\n", tmpDir.c_str());
	LOG_FINEST1("choochBinDir = %s\n", m_config.getChoochBinDir().c_str());
	LOG_FINEST1("choochDatDir = %s\n", m_config.getChoochDataDir().c_str());
				
		
	// Get operation parameters
	// runAutochooch operationHandle user sessionId userDir rootFileName dcssUser dcssSessionId dcssDir atom edge beamline minE maxE area datapoints
	// where datapoint is {x1 y1 x2 y2 xn,yn} or {x1 y1 z1 x2 y2 z2 xn,yn zn}
	// Operation arguments include everthing after operationHandler
	char param[10][250];
	if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s %s %s %s %s %s %s %s", 
		param[0], param[1], param[2], param[3], param[4], 
		param[5], param[6], param[7], param[8], param[9]) != 10)
		throw XosException("Invalid arguments for runAutochooch operation");
	

	int i = 0;
	user = param[i]; ++i;
	sessionId = param[i]; ++i;
	outputDir = param[i]; ++i;
	rootFileName = param[i]; ++i;
	dcssUser = param[i]; ++i;
	dcssSessionId = param[i]; ++i;
	dcssDir = param[i]; ++i;
	atom = param[i]; ++i;
	edge = param[i]; ++i;
	beamline = param[i]; ++i;

	
	// Strip off the prefix PRIVATE
	if (sessionId.find("PRIVATE") == 0)
		sessionId = sessionId.substr(7);
		
	if (dcssSessionId.find("PRIVATE") == 0)
		dcssSessionId = dcssSessionId.substr(7);
		
	
	char* str = strchr(m_pMsg->GetOperationArgument(), '{');
	if (str == NULL) {
		throw XosException("Missing datapoint list");
	}
	
	++str;
	
	datapoints = str;
	while (datapoints[datapoints.size()-1] == '}') {
		datapoints[datapoints.size()-1] = '\0';
	}

	datapointCount = 0;

	// Parse data points
	std::vector<std::string> vec;
	XosStringUtil::tokenize(datapoints, " ", vec);
	double key = 0.0;
	bool even = true;
	std::map<double, std::string> hash;
	// Sort datapoints
	std::vector<std::string>::iterator vi = vec.begin();
	for (; vi != vec.end(); ++vi) {
		if (even) {
			key = XosStringUtil::toDouble(*vi, 0.0);
		} else {
			hash.insert(std::map<double, std::string>::value_type(key, *vi));
		}
		even = !even;
	}

	// Write sorted datapoints to string
	datapointCount = hash.size();
	datapoints = "";
	char tmp[250];
	std::map<double, std::string>::iterator hi = hash.begin();
	for (; hi != hash.end(); ++hi) {
		sprintf(tmp, "%f %s\n", hi->first, hi->second.c_str());
		datapoints += tmp;
	}
	


	// tmp dir where intermediate files are generated
	// Files in this dir will be deleted as soon as the 
	// operation is completed.
	tmpDir += "/" + user;
	
	// Create unique string to be appended to 
	// the file names of the intermediate files
	// This is so that different instances of 
	// autochooch can run and spits out output files
	// in the same dir without filename conflict.
	uniqueName = createUniqueName();
	
	
	// Generate file names to be saved in tmp dir
	// Generate file names to be saved in dcss's dir
	tmpScanFile = tmpDir + "/rawdata" + uniqueName;
	tmpSmoothExpFile = tmpDir + "/smooth_exp" + uniqueName + ".bip";
	tmpSmoothNormFile = tmpDir + "/smooth_norm" + uniqueName + ".bip";
	tmpFpFppFile = tmpDir + "/fp_fpp" + uniqueName + ".bip";
	tmpSummaryFile = tmpDir + "/summary" + uniqueName;
	tmpBeamlineFile = tmpDir + "/" + beamline + uniqueName + ".par";


	// Generate file names to be saved in user's dir
	userScanFile = outputDir + "/" + rootFileName + "scan";
	std::string smoothExpFileName;
	std::string smoothNormFileName;
	std::string fpFppFileName;
	std::string summaryFileName;
   	smoothExpFileName = rootFileName + "smooth_exp.bip";
   	smoothNormFileName = rootFileName + "smooth_norm.bip";
   	fpFppFileName = rootFileName + "fp_fpp.bip";
   	summaryFileName =  rootFileName + "summary";
           
	userSmoothExpFile = outputDir + "/" + smoothExpFileName;
	userSmoothNormFile = outputDir + "/" + smoothNormFileName;
	userFpFppFile = outputDir + "/" + fpFppFileName;
	userSummaryFile = outputDir + "/" + summaryFileName;
	userBeamlineFile = outputDir + "/" + beamline + ".par";
	
	// Generate file names to be saved in dcss's dir
	dcssScanFile = dcssDir + "/" + rootFileName + "scan";
	dcssSmoothExpFile = dcssDir + "/" + rootFileName + "smooth_exp.bip";
	dcssSmoothNormFile = dcssDir + "/" + rootFileName + "smooth_norm.bip";
	dcssFpFppFile = dcssDir + "/" + rootFileName + "fp_fpp.bip";
	dcssSummaryFile = dcssDir + "/" + rootFileName + "summary";
	

	LOG_FINEST1("user = %s\n", user.c_str());
	LOG_FINEST1("sessionId = %.7s\n", sessionId.c_str());
	LOG_FINEST1("outputDir = %s\n", outputDir.c_str());
	LOG_FINEST1("rootFileName = %s\n", rootFileName.c_str());
	LOG_FINEST1("dcssUser = %s\n", dcssUser.c_str());
	LOG_FINEST1("dcssSessionId = %s\n", dcssSessionId.c_str());
	LOG_FINEST1("dcssDir = %s\n", dcssDir.c_str());
	LOG_FINEST1("atom = %s\n", atom.c_str());
	LOG_FINEST1("edge = %s\n", edge.c_str());
	LOG_FINEST1("beamline = %s\n", beamline.c_str());
	LOG_FINEST1("uniqueName = %s\n", uniqueName.c_str());
	LOG_FINEST1("datapoint count = %d\n", datapointCount);
	
	LOG_FINEST2("impHost = %s, imPort = %d\n", m_config.getImpHost().c_str(),
				m_config.getImpPort());
	
	
	// Make sure /tmp/userName exists
		directoryWritable(user, sessionId, tmpDir);
		
	// Make sure output dir exists
		directoryWritable(user, sessionId, outputDir);
	
	// Check if dcss dir exists
	try {
			directoryWritable(dcssUser, dcssSessionId, dcssDir);
	} catch (XosException& e) {
		// Send a warning message if fails here
//		std::string warning("");
		//warning += "htos_log warning " + m_config.getDhsName() + " " + e.getMessage();
		//pReply = manager.NewDcsTextMessage(warning.c_str());
		//m_parent->SendoutDcsMessage( pReply );
	}

	std::string warningMsg("");
	
	// Write scan files in tmp, user and dcss dirs
	if (!writeScanFiles(warningMsg)) {
		// Send a warning message if fails here
//		std::string warning("");
//		warning += "htos_log warning " + m_config.getDhsName() + " " + warningMsg;
//		pReply = manager.NewDcsTextMessage(warning.c_str());
//		m_parent->SendoutDcsMessage( pReply );
	}
		
	// Run Benny_auto
	runAutochooch1();
	

	// Part1 result
	std::string space(" ");
	std::string result =  dcssScanFile
					    + space + dcssSmoothExpFile
						+ space + dcssSmoothNormFile;

	// Send an update message since have have completed 
	// step one of this operation.
	pReply = manager.NewOperationUpdateMessage( m_pMsg, result.c_str());
	m_parent->SendoutDcsMessage( pReply );

		
	// Run Chooch_auto and wasel
	runAutochooch2();
	

	// Reads output files from tmp dir and save them in user and dcss dir
	warningMsg = "";
	if (!saveResults(warningMsg)) {
		// Send a warning message if fails here
//		std::string warning("");
//		warning += "htos_log warning " + m_config.getDhsName() + " " + warningMsg;
//		pReply = manager.NewDcsTextMessage(warning.c_str());
//		m_parent->SendoutDcsMessage( pReply );
	}
		

	// Reads output files
	deleteOutputFiles();
		
	// Part2 result
	result = "normal " + XosStringUtil::fromDouble(inflectionEnergy)
			+ space + XosStringUtil::fromDouble(inflectionFP)
			+ space + XosStringUtil::fromDouble(inflectionFPP)
			+ space + XosStringUtil::fromDouble(peakEnergy)
			+ space + XosStringUtil::fromDouble(peakFP)
			+ space + XosStringUtil::fromDouble(peakFPP)
			+ space + XosStringUtil::fromDouble(remoteEnergy)
			+ space + XosStringUtil::fromDouble(remoteFP)
			+ space + XosStringUtil::fromDouble(remoteFPP)
			+ space + dcssScanFile
			+ space + smoothExpFileName
			+ space + smoothNormFileName
			+ space + fpFppFileName;
			
	// Operation completed message
	pReply = manager.NewOperationCompletedMessage( m_pMsg, result.c_str());
	
	
	} catch (XosException& e) {
		LOG_WARNING(e.getMessage().c_str());
		std::string tmp("error ");
		tmp += e.getMessage();
		pReply = manager.NewOperationCompletedMessage( m_pMsg, tmp.c_str());
	} catch (...) {
		LOG_WARNING("unknown exception in AutochoochThread::exec"); fflush(stdout);
		pReply = manager.NewOperationCompletedMessage( m_pMsg, "error unknown");
	}
	
	m_parent->SendoutDcsMessage( pReply );
	
	manager.DeleteDcsMessage(m_pMsg);
		
	m_pMsg = NULL;
	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::runAutochooch()
	throw (XosException)
{

	HttpClientImp client;
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_POST);
	
	std::string space(" ");

	std::string commandline = m_config.getChoochBinDir() + "/chooch_remote.sh " + uniqueName;
	commandline += space + atom + space + edge 
				+ space + beamline;
	commandline = encode(commandline);
	std::string env1 = encode("CHOOCHBIN=" + m_config.getChoochBinDir());
	std::string env2 = encode("CHOOCHDAT=" + m_config.getChoochDataDir());
	std::string env3 = encode("USER=" + user);
	std::string env4 = encode("TMPDIR=" + m_config.getChoochTmpDir());
	
	std::string uri;
	uri += std::string("/runScript?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + std::string("&impShell=/bin/sh")
		   + "&impDirectory=" + m_config.getChoochTmpDir()
		   + "&impCommandLine=" + commandline
		   + "&impEnv1=" + env1
		   + "&impEnv2=" + env2
		   + "&impEnv3=" + env3
		   + "&impEnv4=" + env4;

	request->setURI(uri);
	
	request->setContentType("text/plain");
	request->setContentLength(0);

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) 
		throw XosException(response->getStatusPhrase());
		
	LOG_FINEST1("HTTP status phrase = %s\n", response->getStatusPhrase().c_str());
	
	std::string& body = response->getBody();
	
	
	// Look for ERROR messages
	size_t pos = 0;
	size_t pos1 = 0;
	std::string errorMessage;
	while (pos != std::string::npos) {
		pos = body.find("ERROR", pos);
		if (pos != std::string::npos) {
			pos1 = body.find("\n", pos);
			errorMessage += body.substr(pos, pos1-pos) + "\n";
			pos = pos+1;
		}
	}
	
	if (!errorMessage.empty())
		throw XosException(errorMessage);
		
	
	// parse response body and extract f' and f'' 
	pos = body.find("Inflection_info");
	if (pos == std::string::npos) {
		throw XosException("Failed to execute autochooch: " + body);
	
//		throw XosException("Failed to get Inflection_info");
	}


	pos1 = body.find("\n", pos);
	std::string line = body.substr(pos, pos1-pos);
	std::vector<std::string> params;
	if (!XosStringUtil::tokenize(line, " \t\n", params) || (params.size() != 4))
		throw XosException("Failed to parse Inflection_info data");
	inflectionEnergy = XosStringUtil::toDouble(params[1], 0.0);
	inflectionFP = XosStringUtil::toDouble(params[2], 0.0);
	inflectionFPP = XosStringUtil::toDouble(params[3], 0.0);
	
	
	pos = body.find("Peak_info", pos1);
	if (pos == std::string::npos)
		throw XosException("Failed to get Peak_info");

	pos1 = body.find("\n", pos);
	line = body.substr(pos, pos1-pos);
	params.clear();
	if (!XosStringUtil::tokenize(line, " \t\n", params) || (params.size() != 4))
		throw XosException("Failed to parse Peak_info data");
	peakEnergy = XosStringUtil::toDouble(params[1], 0.0);
	peakFP = XosStringUtil::toDouble(params[2], 0.0);
	peakFPP = XosStringUtil::toDouble(params[3], 0.0);
	
		
	pos = body.find("Remote_info", pos1);
	if (pos == std::string::npos)
		throw XosException("Failed to get Remote_info");

	pos1 = body.find("\n", pos);
	line = body.substr(pos, pos1-pos);
	params.clear();
	if (!XosStringUtil::tokenize(line, " \t\n\r", params) || (params.size() != 4))
		throw XosException("Failed to parse Remote_info data");
	remoteEnergy = XosStringUtil::toDouble(params[1], 0.0);
	remoteFP = XosStringUtil::toDouble(params[2], 0.0);
	remoteFPP = XosStringUtil::toDouble(params[3], 0.0);
	
	LOG_FINEST3("Inflection energy = %f, fp = %f, fpp = %f\n",
			inflectionEnergy, inflectionFP, inflectionFPP);

	LOG_FINEST3("Peak energy = %f, fp = %f, fpp = %f\n",
			peakEnergy, peakFP, peakFPP);

	LOG_FINEST3("Remote energy = %f, fp = %f, fpp = %f\n",
			remoteEnergy, remoteFP, remoteFPP);
			

	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::runAutochooch1()
	throw (XosException)
{

	HttpClientImp client;
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_POST);
	
	std::string space(" ");

	std::string commandline = m_config.getChoochBinDir() + "/chooch_remote1.sh " + uniqueName;
	commandline += space + atom + space + edge 
				+ space + beamline;
	commandline = encode(commandline);
	std::string env1 = encode("CHOOCHBIN=" + m_config.getChoochBinDir());
	std::string env2 = encode("CHOOCHDAT=" + m_config.getChoochDataDir());
	std::string env3 = encode("USER=" + user);
	std::string env4 = encode("TMPDIR=" + m_config.getChoochTmpDir());
	
	std::string uri;
	uri += std::string("/runScript?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + std::string("&impShell=/bin/sh")
		   + "&impDirectory=" + m_config.getChoochTmpDir()
		   + "&impCommandLine=" + commandline
		   + "&impEnv1=" + env1
		   + "&impEnv2=" + env2
		   + "&impEnv3=" + env3
		   + "&impEnv4=" + env4;

	request->setURI(uri);
	
	request->setContentType("text/plain");
	request->setContentLength(0);

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) 
		throw XosException(response->getStatusPhrase());
		
	LOG_FINEST1("HTTP status phrase = %s\n", response->getStatusPhrase().c_str());
	
	std::string& body = response->getBody();
	
	
	// Look for ERROR messages
	size_t pos = 0;
	size_t pos1 = 0;
	std::string errorMessage;
	while (pos != std::string::npos) {
		pos = body.find("ERROR", pos);
		if (pos != std::string::npos) {
			pos1 = body.find("\n", pos);
			errorMessage += body.substr(pos, pos1-pos) + "\n";
			pos = pos+1;
		}
	}
	
	if (!errorMessage.empty())
		throw XosException(errorMessage);
		
		
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::runAutochooch2()
	throw (XosException)
{

	HttpClientImp client;
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_POST);
	
	std::string space(" ");

	std::string commandline = m_config.getChoochBinDir() + "/chooch_remote2.sh " + uniqueName;
	commandline += space + atom + space + edge 
				+ space + beamline;
	commandline = encode(commandline);
	std::string env1 = encode("CHOOCHBIN=" + m_config.getChoochBinDir());
	std::string env2 = encode("CHOOCHDAT=" + m_config.getChoochDataDir());
	std::string env3 = encode("USER=" + user);
	std::string env4 = encode("TMPDIR=" + m_config.getChoochTmpDir());
	
	std::string uri;
	uri += std::string("/runScript?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + std::string("&impShell=/bin/sh")
		   + "&impDirectory=" + m_config.getChoochTmpDir()
		   + "&impCommandLine=" + commandline
		   + "&impEnv1=" + env1
		   + "&impEnv2=" + env2
		   + "&impEnv3=" + env3
		   + "&impEnv4=" + env4;

	request->setURI(uri);
	
	request->setContentType("text/plain");
	request->setContentLength(0);

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) 
		throw XosException(response->getStatusPhrase());
		
	LOG_FINEST1("HTTP status phrase = %s\n", response->getStatusPhrase().c_str());
	
	std::string& body = response->getBody();
	
	
	// Look for ERROR messages
	size_t pos = 0;
	size_t pos1 = 0;
	std::string errorMessage;
	while (pos != std::string::npos) {
		pos = body.find("ERROR", pos);
		if (pos != std::string::npos) {
			pos1 = body.find("\n", pos);
			errorMessage += body.substr(pos, pos1-pos) + "\n";
			pos = pos+1;
		}
	}
	
	if (!errorMessage.empty())
		throw XosException(errorMessage);
		
	
	// parse response body and extract f' and f'' 
	pos = body.find("Inflection_info");
	if (pos == std::string::npos) {
		throw XosException("Failed to execute autochooch: " + body);
	
//		throw XosException("Failed to get Inflection_info");
	}


	pos1 = body.find("\n", pos);
	std::string line = body.substr(pos, pos1-pos);
	std::vector<std::string> params;
	if (!XosStringUtil::tokenize(line, " \t\n", params) || (params.size() != 4))
		throw XosException("Failed to parse Inflection_info data");
	inflectionEnergy = XosStringUtil::toDouble(params[1], 0.0);
	inflectionFP = XosStringUtil::toDouble(params[2], 0.0);
	inflectionFPP = XosStringUtil::toDouble(params[3], 0.0);
	
	
	pos = body.find("Peak_info", pos1);
	if (pos == std::string::npos)
		throw XosException("Failed to get Peak_info");

	pos1 = body.find("\n", pos);
	line = body.substr(pos, pos1-pos);
	params.clear();
	if (!XosStringUtil::tokenize(line, " \t\n", params) || (params.size() != 4))
		throw XosException("Failed to parse Peak_info data");
	peakEnergy = XosStringUtil::toDouble(params[1], 0.0);
	peakFP = XosStringUtil::toDouble(params[2], 0.0);
	peakFPP = XosStringUtil::toDouble(params[3], 0.0);
	
		
	pos = body.find("Remote_info", pos1);
	if (pos == std::string::npos)
		throw XosException("Failed to get Remote_info");

	pos1 = body.find("\n", pos);
	line = body.substr(pos, pos1-pos);
	params.clear();
	if (!XosStringUtil::tokenize(line, " \t\n\r", params) || (params.size() != 4))
		throw XosException("Failed to parse Remote_info data");
	remoteEnergy = XosStringUtil::toDouble(params[1], 0.0);
	remoteFP = XosStringUtil::toDouble(params[2], 0.0);
	remoteFPP = XosStringUtil::toDouble(params[3], 0.0);
	
	LOG_FINEST3("Inflection energy = %f, fp = %f, fpp = %f\n",
			inflectionEnergy, inflectionFP, inflectionFPP);

	LOG_FINEST3("Peak energy = %f, fp = %f, fpp = %f\n",
			peakEnergy, peakFP, peakFPP);

	LOG_FINEST3("Remote energy = %f, fp = %f, fpp = %f\n",
			remoteEnergy, remoteFP, remoteFPP);
			

	
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool AutochoochThread::writeScanFiles(std::string& warning)
	throw (XosException)
{

	// Write scan data file in /tmp/username as input for Benny_auto
	writeScanFile(user, sessionId, tmpScanFile);

	// Write scan data to dcss dir
	writeScanFile(user, sessionId, userScanFile);
	
	//try {

		// Write scan data to dcss dir
	//	writeScanFile(dcssUser, dcssSessionId, dcssScanFile);
		
	//} catch (XosException& e) {
	//	warning = "Failed to write scan file in shared dir " + e.getMessage();
	//	return false;
	//}
	
	return true;
}



/*******************************************************************
 *
 * saveResults
 *
 *******************************************************************/
bool AutochoochThread::saveResults(std::string& warning)
	throw (XosException)
{

	std::string smooth_exp_data;
	std::string smooth_norm_data;
	std::string fp_fpp_data;
	std::string beamline_data;

	readFile(user, sessionId, tmpSmoothExpFile, smooth_exp_data);
	readFile(user, sessionId, tmpSmoothNormFile, smooth_norm_data);
	readFile(user, sessionId, tmpFpFppFile, fp_fpp_data);
	readFile(user, sessionId, tmpBeamlineFile, beamline_data);
	
	parseData(smooth_exp_data, smoothExpData);
	parseData(smooth_norm_data, smoothNormData);
	parseData(fp_fpp_data, fpFppData);
	
	writeFile(user, sessionId, userSmoothExpFile, smooth_exp_data);
	writeFile(user, sessionId, userSmoothNormFile, smooth_norm_data);
	writeFile(user, sessionId, userFpFppFile, fp_fpp_data);
	writeFile(user, sessionId, userBeamlineFile, beamline_data);
	
	
	// Write summary file here
	std::string summary;
	std::string eol("\n");
	summary += "beamlineId=" + beamline + eol
				+ "atom=" + atom + eol
				+ "edge=" + edge + eol
				+ "inflectionE=" + XosStringUtil::fromDouble(inflectionEnergy) + eol
				+ "inflectionFp=" + XosStringUtil::fromDouble(inflectionFP) + eol
				+ "inflectionFpp=" + XosStringUtil::fromDouble(inflectionFPP) + eol
				+ "peakE=" + XosStringUtil::fromDouble(peakEnergy) + eol
				+ "peakFp=" + XosStringUtil::fromDouble(peakFP) + eol
				+ "peakFpp=" + XosStringUtil::fromDouble(peakFPP) + eol
				+ "remoteE=" + XosStringUtil::fromDouble(remoteEnergy) + eol
				+ "remoteFp=" + XosStringUtil::fromDouble(remoteFP) + eol
				+ "remoteFpp=" + XosStringUtil::fromDouble(remoteFPP) + eol;
	
	writeFile(user, sessionId, userSummaryFile, summary);

	try {
		writeFile(dcssUser, dcssSessionId, dcssSmoothExpFile, smooth_exp_data);
		writeFile(dcssUser, dcssSessionId, dcssSmoothNormFile, smooth_norm_data);
		writeFile(dcssUser, dcssSessionId, dcssFpFppFile, fp_fpp_data);
		writeFile(dcssUser, dcssSessionId, dcssSummaryFile, summary);
	} catch (XosException& e) {
		warning = "Failed to save autochooch results in shared dir " + e.getMessage();
		return false;
	}
	
	return true;
}



/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::deleteOutputFiles()
	throw (XosException)
{
	try {
	
	HttpClientImp client;
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string uri;
	uri += std::string("/deleteFile?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + "&impDirectory=" + m_config.getChoochTmpDir()
		   + "&impFileFilter=*" + uniqueName + "*";

	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_GET);
	

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		LOG_WARNING2("Failed to delete files: %s/%s", 
					m_config.getChoochTmpDir().c_str(), 
					uniqueName.c_str());
		LOG_WARNING2("Failed to delete files: http error %d %s", 
						response->getStatusCode(), 
						response->getStatusPhrase().c_str());
	}

	} catch (XosException& e) {
		LOG_WARNING3("failed to delete files %s/%s: %s", m_config.getChoochTmpDir().c_str(), 
					uniqueName.c_str(), e.getMessage().c_str());
	   // Ignore this error. Do not rethrow.
	}
	
	
}



/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::parseData(const std::string& data, std::string& ret)
	throw (XosException)
{
	
	std::string line;	
	std::string tmp("_sub_trace.y1");
	
	size_t pos = data.find(tmp);
	if (pos == std::string::npos)	
		throw XosException("Failed to parse output file");
		
	size_t pos1 = data.find("\n", pos);
	if (pos1 == std::string::npos)	
		throw XosException("Failed to parse output file");
		
	pos = pos1 + 1;
	float x, y, z;
	char buf[500];
	int count = 0;
	ret += "{";
	while (pos1 != std::string::npos) {
	
		pos1 = data.find("\n", pos);
		
		if (pos1 != std::string::npos)
			line = XosStringUtil::trim(data.substr(pos, pos1-pos));
		else
			line = XosStringUtil::trim(data.substr(pos));
		
		pos = pos1 + 1;
		
		if (line.size() < 2)
			continue;				

		int numCols = sscanf(line.c_str(), "%f %f %f", &x, &y, &z);
		
		if (numCols < 2)
			continue;
		
		if (count != 0) {
			ret += " ";			
		}
						
		if (numCols == 2) {
			snprintf(buf, 500, "%f %f", x, y);
		} else if (numCols == 3) {
			snprintf(buf, 500, "%f %f %f", x, y, z);
		}
		
		++count;
		ret += buf;
			
	}
	
	ret += "}";
	
	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
std::string AutochoochThread::encode(const std::string& str)
{
	size_t prev = 0;
	size_t pos = 0;
	std::string disallowed(" \"#<>%{}\\^[]'=");
	std::string ret;
	char tmp[10];
	char* percent = "%";
    for (pos = 0; pos < str.size(); ++pos) {
    	if (disallowed.find(str[pos]) != std::string::npos) {
    		if (pos > prev) {
    			ret += str.substr(prev, pos-prev);
    		}
    		sprintf(tmp, "%s%X", percent, (int)str[pos]);
    		ret += tmp;
    		prev = pos+1;
    	}
    }
    if (pos > prev)
    	ret += str.substr(prev);



    return ret;
}


/*******************************************************************
 *
 * Generate a unique name from
 * hostname + pid + time
 * Limit the length to 22 characters.
 *
 *******************************************************************/
std::string AutochoochThread::createUniqueName() const
{
	std::string str = "";
	double num;
	for (int i = 0; i < 15; ++i) {
		num = (double)rand() * 26.0 / (double)RAND_MAX;
		if (rand() < RAND_MAX/2) {
			str += (char)('A' + (int)num);
		} else {
			str += (char)('a' + (int)num);
		}
		
	}
	
	return str;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::directoryWritable(const std::string& name, 
					const std::string& sid,
					const std::string& path)
	throw (XosException)
{

	HttpClientImp client;
	std::string slash("/");
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string uri;
	uri += std::string("/writableDirectory?impUser=") + name
		   + "&impSessionID=" + sid
		   + "&impDirectory=" + path
		   + "&impCreateParents=true&impFileMode=0740";
		   
//	LOG_FINEST1("in directoryWritable: uri ==> %s\n", uri.c_str());
		  
	
	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_GET);
	

	// Send the request and wait for a response
	HttpResponse* response = NULL;
	try {
		response = client.finishWriteRequest();
	} catch (XosException& e) {
		LOG_SEVERE2("Failed to create dir %s: %s\n", path.c_str(), e.getMessage().c_str()); 
		throw XosException("Failed to create dir " + path 
							+ std::string(": ") + e.getMessage());
	}

	
	if (response->getStatusCode() != 200) {
		LOG_SEVERE2("Failed to create dir %s for user %s\n", 
						name.c_str(), path.c_str()); 
		LOG_SEVERE2("Failed to create dir: http error %d %s", 
				response->getStatusCode(),
				response->getStatusPhrase().c_str());
		throw XosException("Failed to create dir " + path 
							+ std::string(": ") + response->getStatusPhrase());
	}

}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::writeScanFile(const std::string& name, 
					const std::string& sid,
					const std::string& path)
	throw (XosException)
{
		

	HttpClientImp client;
	HttpResponse* response = NULL;
	std::string slash("/");
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

   try {

	std::string uri;
	uri += std::string("/writeFile?impUser=") + name
		   + "&impSessionID=" + sid
		   + "&impFilePath=" + path
		   + "&impFileMode=0740";
		   
	
	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_POST);
	

	std::string space(" ");
	std::string endofline("\n");
	std::string body("fluorescence scan data for " + atom + " " + edge + " edge\n");
	body += XosStringUtil::fromInt(datapointCount) + endofline;
	
	request->setContentType("text/plain");
	request->setContentLength(body.size() + datapoints.size());
	

	client.writeRequestBody((char*)body.c_str(), (int)body.size());
	client.writeRequestBody((char*)datapoints.c_str(), (int)datapoints.size());


	// Send the request and wait for a response
	response = client.finishWriteRequest();

	} catch (XosException& e) {
		LOG_SEVERE2("Failed to write scan file: %s: %s\n", path.c_str(), e.getMessage().c_str());  
		throw XosException("failed to write scan file " + path + ": " + e.getMessage());
	}

	
	if (response->getStatusCode() != 200) {
		LOG_SEVERE2("Failed to write scan file: %s for user %s\n", name.c_str(), path.c_str());  
		LOG_SEVERE2("Failed to write scan file: http error %d %s", 
				response->getStatusCode(),
				response->getStatusPhrase().c_str());
	   throw XosException("Failed to write scan file " + path + ": " + response->getStatusPhrase());
	}

		
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::writeFile(const std::string& name, 
					const std::string& sid,
					const std::string& path,
					const std::string& content)
	throw (XosException)
{
		

	HttpClientImp client;
	HttpResponse* response = NULL;
	std::string slash("/");
	client.setAutoReadResponseBody(true);

	try {

	HttpRequest* request = client.getRequest();

	std::string uri;
	uri += std::string("/writeFile?impUser=") + name
		   + "&impSessionID=" + sid
		   + "&impFilePath=" + path
		   + "&impFileMode=0740";
		   
	
	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_POST);
	
	
	request->setContentType("text/plain");
	request->setContentLength(content.size());
	

	client.writeRequestBody((char*)content.c_str(), (int)content.size());


	// Send the request and wait for a response
	response = client.finishWriteRequest();

	} catch (XosException& e) {
		LOG_SEVERE2("Failed to write file %s: %s", path.c_str(), e.getMessage().c_str());
		throw XosException("Failed to write file " + path + ": " + e.getMessage());
	}

	
	if (response->getStatusCode() != 200) {
		LOG_SEVERE1("Failed to write file %s", path.c_str());
		LOG_SEVERE2("Failed to write file: http error %d %s", 
				response->getStatusCode(),
				response->getStatusPhrase().c_str());
		throw XosException(response->getStatusPhrase());
	}

		
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AutochoochThread::readFile(const std::string& name, 
					const std::string& sid,
					const std::string& filename, 
					std::string& content)
	throw (XosException)
{

	try {

	HttpClientImp client;
	client.setAutoReadResponseBody(true);


	HttpRequest* request = client.getRequest();

	std::string uri;
	uri += std::string("/readFile?impUser=") + name
		   + "&impSessionID=" + sid
		   + "&impFilePath=" + filename;

	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_GET);
	


	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		LOG_SEVERE3("Failed to read file %s: http error %d %s", 
						filename.c_str(), response->getStatusCode(),
						response->getStatusPhrase().c_str());
		throw XosException(std::string("Failed to read file ") 
					+ filename + " " 
					+ response->getStatusPhrase());
	}

	
	content = response->getBody();

	} catch (XosException& e) {
		LOG_SEVERE2("Failed to read file %s; %s", filename.c_str(), e.getMessage().c_str());
		throw XosException("Failed to read file " + filename + ": " + e.getMessage());
	}

	
}

