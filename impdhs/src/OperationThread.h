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

#ifndef __Include_OperationThread_h__
#define __Include_OperationThread_h__

#include "XosThread.h"
#include "DcsMessage.h"
#include "DcsMessageManager.h"

class ImpersonService;
class DcsMessage;
class ImpConfig;


class OperationThread : public XosThread
{
	
public:

    /**
     * @brief Constructor.
     *
     * Create a thread object with a no name.
     * The thread will not start until start() is called.
 	 * @param msg Dcs message to be processed by this thread
     **/
	OperationThread(ImpersonService* parent, DcsMessage* msg,
					const ImpConfig& c)
		: m_parent(parent), m_pMsg(msg), m_config(c)
	{
	}
	
    /**
     * @brief Destructor.
     *
     * Frees up the resources.
     **/
	virtual ~OperationThread()
	{
		if (m_pMsg) 
			DcsMessageManager::GetObject().DeleteDcsMessage(m_pMsg);

		m_pMsg = NULL;
	}
	
	/**
	 * @brief Returns the dcs message
	 * @return dcs message
	 **/
	 DcsMessage* getDcsMessage() const
	 {
	 	return m_pMsg;
	 }
		

protected:
	
	ImpersonService* m_parent;
	DcsMessage* m_pMsg;
	const ImpConfig& m_config;
};


#endif // __Include_OperationThread_h__



