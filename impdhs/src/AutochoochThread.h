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

#ifndef __Include_AutochoochThread_h__
#define __Include_AutochoochThread_h__

#include "XosThread.h"
#include "OperationThread.h"
#include "ImpConfig.h"

#define OP_RUN_AUTOCHOOCH "runAutochooch"

class DcsMessage;
class ImpersonService;

class AutochoochThread : public OperationThread
{
	
public:

    /**
     * @brief Constructor.
     *
     * Create a thread object with a no name.
     * The thread will not start until start() is called.
 	 * @param msg Dcs message to be processed by this thread
     **/
	AutochoochThread(ImpersonService* parent, 
						DcsMessage* msg,
						const ImpConfig& c);
	
    /**
     * @brief Destructor.
     *
     * Terminates the thread if it is still running and frees up the resources.
     **/
	virtual ~AutochoochThread();
	
    /**
     * @brief This method is called by the thread routine to execute 
     * autochooch task. It, in turn, calls exec().
     *
     * It runs inside the newly created thread. 
     * When this method returns, the thread will automatically exit.
     **/
    virtual void run();
    
   
    /**
     * @brief Execute the autochooch
     *
     * Executes autochooch tasks on the current thread
     **/
	void exec();
	

private:


	// Operation parameters from dcs message
	std::string user;
	std::string sessionId;
	std::string outputDir;
	std::string rootFileName;
	std::string dcssUser;
	std::string dcssSessionId;
	std::string dcssDir;
	std::string atom;
	std::string edge;

	std::string beamline;
	std::string datapoints;
	int datapointCount;
	
	// Unique string for identifying tmp files
	// for this operation.
	std::string uniqueName;
	
	// Results
	double inflectionEnergy;
	double inflectionFP;
	double inflectionFPP;
	double peakEnergy;
	double peakFP;
	double peakFPP;
	double remoteEnergy;
	double remoteFP;
	double remoteFPP;
	std::string smoothExpData;
	std::string smoothNormData;
	std::string fpFppData;
	
	
	std::string tmpScanFile;
	std::string tmpSmoothExpFile;
	std::string tmpSmoothNormFile;
	std::string tmpFpFppFile;
	std::string tmpSummaryFile;
	std::string tmpBeamlineFile;


	std::string userScanFile;
	std::string userSmoothExpFile;
	std::string userSmoothNormFile;
	std::string userFpFppFile;
	std::string userSummaryFile;
	std::string userBeamlineFile;

	std::string dcssScanFile;
	std::string dcssSmoothExpFile;
	std::string dcssSmoothNormFile;
	std::string dcssFpFppFile;
	std::string dcssSummaryFile;



	// Sub tasks called by exec()
	void runAutochooch() throw (XosException);
	void runAutochooch1() throw (XosException);
	void runAutochooch2() throw (XosException);
	bool writeScanFiles(std::string& warning) throw (XosException);
	bool saveResults(std::string& warning) throw (XosException);
	void deleteOutputFiles() throw (XosException);
		
	// Utility functions
	
	/**
	 * @brief Creates a unique file name.
	 * @return Unique filename
	 */
	std::string createUniqueName() const;
	
	/**
	 * @brief Encodes string for URI
	 * @return URI encoded string
	 */
	std::string encode(const std::string& str);
	
	void parseData(const std::string& data, std::string& ret)
		throw (XosException);
	
	/**
	 * @brief Checks if the directory exists or not
	 * @param name User name
	 * @param sid Session id
	 * @param path Directory path
	 * @return True if the directory exists. False otherwise.
	 * @exception XosException thrown if the impersonation 
	 * server returns HTTP code other than 200.
	 */
	/**
	 * @brief Creates a directory
	 * @param name User name
	 * @param sid Session id
	 * @param path Directory path
	 * @exception XosException thrown if the impersonation 
	 * server returns HTTP code other than 200.
	 */
	void directoryWritable(const std::string& name, 
					const std::string& sid,
					const std::string& path) 
		throw (XosException);


	/**
	 * @brief Writes content to a file
	 * @param name User name
	 * @param sid Session id
	 * @param path File name
	 * @param content Content to be written to the file
	 * @exception XosException thrown if the impersonation 
	 * server returns HTTP code other than 200.
	 */
	void writeFile(const std::string& name, 
					const std::string& sid,
					const std::string& path, 
					const std::string& content) 
		throw (XosException);
		

	/**
	 * @brief Read file.
	 * @param name User name
	 * @param sid Session id
	 * @param path File name
	 * @param content The returned content of the file
	 * @exception XosException thrown if the impersonation 
	 * server returns HTTP code other than 200.
	 */
	void readFile(const std::string& name, 
					const std::string& sid,
					const std::string& path, 
					std::string& content)
		throw (XosException);


	void writeScanFile(const std::string& name, 
						const std::string& sid,
						const std::string& path)
		throw (XosException);

};


#endif // __Include_AutochoochThread_h__



