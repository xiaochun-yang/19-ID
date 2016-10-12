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

#ifndef __Include_ImpConfig_h__
#define __Include_ImpConfig_h__

#include "DcsConfig.h"

/**
 * # imperson dhs
 * impdhs.name=imperson
 * impdhs.tmpDir=/tmp
 * impdhs.choochBinDir=/tmp/autochooch/bin
 * impdhs.choochDatDir=/tmp/autochooch/data
 * impdhs.cameraHost=smb.slac.stanford.edu
 * impdhs.cameraPort=80
 * impdhs.impHost=blcpu3.slac.stanford.edu
 * impdhs.impPort=61001

 * # impersonation server
 * imperson.host=smb.slac.stanford.edu
 * imperson.port=61001
 */
class ImpConfig : public DcsConfig
{
	
public:

    /**
     * @brief Constructor.
     *
     **/
	ImpConfig();

	
    /**
     * @brief Destructor.
     *
     * Terminates the thread if it is still running and frees up the resources.
     **/
	virtual ~ImpConfig();
	
	/**
	 * @brief Sets name of this DHS
	 * @param ImpConfigation name
	 */
	void setDhsName(const std::string& s)
	{
		dhsName = s;
	}

	/**
	 * @brief Returns Name of this dhs
	 * @return name of this dhs instance
	 */
	std::string getDhsName() const
	{
		return dhsName;
	}
	
	/**
	 * @brief Sets ImpConfigation host name
	 * @param ImpConfigation host
	 */
	void setImpHost(const std::string& host)
	{
		impHost = host;
	}
	
	/**
	 * @brief Returns impersonation host name
	 * @return impersonation server host name
	 */
	std::string getImpHost() const
	{
		return impHost;
	}
	
	/**
	 * @brief Sets ImpConfigation port number
	 * @param port Imperonsation port number
	 */
	void setImpPort(int port)
	{
		impPort = port;
	}
	
	/**
	 * @brief Returns Impersonation server port number
	 * @return Impersonation server port number
	 */
	int getImpPort() const
	{
		return impPort;
	}
		
	void setChoochTmpDir(const std::string& s)
	{
		tmpDir = s;
	}
	
	std::string getChoochTmpDir() const
	{
		return tmpDir;
	}
	
	void setChoochBinDir(const std::string& s)
	{
		choochBinDir = s;
	}
	
	std::string getChoochBinDir() const
	{
		return choochBinDir;
	}
	
	void setChoochDataDir(const std::string& s)
	{
		choochBinDir = s;
	}
	
	std::string getChoochDataDir() const
	{
		return choochDataDir;
	}

	void setCameraHost(const std::string& s)
	{
		cameraHost = s;
	}
	
	std::string getCameraHost() const
	{
		return cameraHost;
	}


	/**
	 * @brief Sets Camera server port number
	 * @param port Camera server port number
	 */
	void setCameraPort(int port)
	{
		cameraPort = port;
	}
	
	/**
	 * @brief Returns Camera server port number
	 * @return Camera server port number
	 */
	int getCameraPort() const
	{
		return cameraPort;
	}
	
	/**
	 * @brief Returns Image Server url
	 * @return Image Server url
	 */
    std::string getImageHost( ) const
    {
        return imageHost;
    }
    int getImagePort( ) const
    {
        return imagePort;
    }
    std::string getSmallImageParam( ) const
    {
        return smallImageParam;
    }
    std::string getMediumImageParam( ) const
    {
        return mediumImageParam;
    }
    std::string getLargeImageParam( ) const
    {
        return largeImageParam;
    }

    std::string getLatestEventIdUrl( ) const
    {
        return latestEventIdUrl;
    }
    std::string getCassetteDataUrl( ) const
    {
        return cassetteDataUrl;
    }
    std::string getSilAndEventUrl( ) const
    {
        return silAndEventUrl;
    }

    std::string getTrustedCaFile( ) const
    {
        return m_trustedCaFile;
    }

    std::string getTrustedCaDir( ) const
    {
        return m_trustedCaDir;
    }

	 std::string getCiphers() const
	 {
         return m_ciphers;
	 }

	/**
	 * @brief Loads config from files.
	 * There are two sets of config: normal config and default config.
	 * @return True if the normal config is loaded ok. Still returns true
	 * even if fails to load default config.
	 */
	virtual bool load();
	

private:
	
	/**
	 * @brief Name of this dhs instance
	 */
	std::string dhsName;

	/**
	 * @brief Host name of the ImpConfigation server.
	 */
	std::string impHost;
	
	/** 
	 * Port number of the ImpConfigation server.
	 */
	int impPort;
	
	/**
	 * autochooch tmp directory
	 */
	std::string tmpDir;
	
	/**
	 * autochooch bin directory
	 */
	std::string choochBinDir;
	
	/**
	 * autochooch data directory
	 */
	std::string choochDataDir;
	
	/**
	 * Host name for camera server
	 */
	std::string cameraHost;
	
	/**
	 * Port number for camera server
	 */
	int cameraPort;
	
    std::string latestEventIdUrl;
    std::string cassetteDataUrl;
    std::string silAndEventUrl;

    std::string imageHost;
    int         imagePort;
    std::string smallImageParam;
    std::string mediumImageParam;
    std::string largeImageParam;
	std::string m_trustedCaFile;
	std::string m_trustedCaDir;
	std::string m_ciphers;
};


#endif // __Include_ImpConfig_h__



