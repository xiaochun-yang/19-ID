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

#ifndef __Include_SilThread_h__
#define __Include_SilThread_h__

#include "XosThread.h"
#include "ImpConfig.h"
#include "XosMutex.h"

class DcsMessage;
class ImpersonService;

class SilThread : public XosThread
{
	
public:

    /**
     * @brief Constructor.
     *
     * Create a thread object with a no name.
     * The thread will not start until start() is called.
 	 * @param msg Dcs message to be processed by this thread
     **/
	SilThread(ImpersonService* parent, const ImpConfig& c);
	
    /**
     * @brief Destructor.
     *
     * Terminates the thread if it is still running and frees up the resources.
     **/
	virtual ~SilThread();
	
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
	
	/**
	 */
	std::string getSilId();
	
	/**
	 */
	void setSilId(std::string id);
	
	/**
	 */
	void stop();
	

private:

	ImpersonService* m_parent;
	const ImpConfig& m_config;

	// Operation parameters from dcs message
	std::string m_silId;
	int m_eventId;
	bool m_done;

    std::string m_cassetteList;
	
	XosMutex m_locker;
	
	
	/**
	 * Get the latest event id for the sil
	 */
	int getLatestEventId(std::string sil_id) throw (XosException);
	
    /**
     * For automatic cassetteInfo update
     */
    std::string getCassetteListFromWeb( ) throw (XosException); 
    std::string convertToString( const std::string& contents );
	/**
	 */
	bool isDone();

};


#endif // __Include_SilThread_h__



