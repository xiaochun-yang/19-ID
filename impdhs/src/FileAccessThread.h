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

#ifndef __Include_FileAccessThread_h__
#define __Include_FileAccessThread_h__

#include "XosThread.h"
#include "OperationThread.h"
#include "ImpConfig.h"

#define OP_GET_LAST_FILE "getLastFile"
#define OP_GET_NEXT_FILE_INDEX "getNextFileIndex"
#define OP_COPY_FILE "copyFile"
#define OP_WRITE_EXCITATION_SCAN_FILE "writeExcitationScanFile"
#define OP_LIST_FILES "listFiles"
#define OP_APPEND_TEXT_FILE "appendTextFile"
#define OP_READ_TEXT_FILE "readTextFile"


class DcsMessage;
class ImpersonService;

class FileAccessThread : public OperationThread
{
	
public:

    /**
     * @brief Constructor.
     *
     * Create a thread object with a no name.
     * The thread will not start until start() is called.
 	 * @param msg Dcs message to be processed by this thread
     **/
	FileAccessThread(ImpersonService* parent, DcsMessage* msg, const ImpConfig& c);
	
    /**
     * @brief Destructor.
     *
     * Terminates the thread if it is still running and frees up the resources.
     **/
	virtual ~FileAccessThread();
	
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
					
	DcsMessage* doGetLastFile() throw(XosException);
	DcsMessage* doGetNextFileIndex() throw (XosException);
	DcsMessage* doCopyFile() throw(XosException);
	DcsMessage* doWriteExcitationScanFile() throw(XosException);
	DcsMessage* doListFiles() throw(XosException);
	DcsMessage* doAppendTextFile() throw(XosException);
	DcsMessage* doReadTextFile() throw(XosException);

	/**
	 * @brief Copy file. oldPath must be readable by the user and newPath
	 * must be writable by the user.
	 * @param name User name
	 * @param sid Session id
	 * @param oldPath File name
	 * @param newPath New file name to copy the file to
	 * @exception XosException thrown if the impersonation 
	 * server returns HTTP code other than 200.
	 */
	void copyFile(const std::string& name, 
					const std::string& sid,
					const std::string& oldPath, 
					const std::string& newPath) 
		throw (XosException);

	/**
	 * @brief Copy file that belongs to one user to another user. 
	 * oldPath must be readable by oldName user and newPath must be
	 * writable by newName user.
	 * @param oldName User name that owns oldPath
	 * @param oldSid Session id of oldName user
	 * @param oldPath File name to be copied
	 * @param newName User name that owns newPath
	 * @param newSid Session id of newName user
	 * @param newPath New file name to copy the file to
	 * @exception XosException thrown if the impersonation 
	 * server returns HTTP code other than 200.
	 */
	void copyFile(const std::string& oldUser, 
					const std::string& oldSid,
					const std::string& oldPath, 
					const std::string& newName, 
					const std::string& newSid, 
					const std::string& newPath) 
		throw (XosException);
		

	static std::string headerFixed;

};


#endif // __Include_FileAccessThread_h__



