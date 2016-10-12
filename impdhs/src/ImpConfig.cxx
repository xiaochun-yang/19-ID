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

#include "ImpConfig.h"
#include "log_quick.h"
#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"
#include <vector>


#ifdef WIN32
#define snprintf _snprintf
#endif


/*******************************************************************
 *
 *
 *
 *******************************************************************/
ImpConfig::ImpConfig()
	: DcsConfig()
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
ImpConfig::~ImpConfig()
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool ImpConfig::load()
{
	if (!DcsConfig::load())
		return false;
	
		
	if (!get("impdhs.name", dhsName)) {
		LOG_SEVERE("Missing impdhs.name in property file");
		return false;
	}

	if (getDcssHost().empty()) {
		LOG_SEVERE("Missing dcss.host in property file");
		return false;
	}
	
	if (getDcssHardwarePort() == 0) {
		LOG_SEVERE("Missing dcss.hardwarePort in property file");
		return false;
	}
	
	if (!get("impdhs.impHost", impHost)) {
		impHost = getImpersonHost();			
	}
		
	std::string impPortStr = "";
	if (!get("impdhs.impPort", impPortStr) || impPortStr.empty()) {
		impPort = getImpersonPort();			
	} else {
		impPort = XosStringUtil::toInt(impPortStr, 0);
	}
	
	if (impHost.empty()) {
		LOG_SEVERE("Missing impdhs.impHost or imperson.host in property file");
		return false;
	}
	if (impPort <= 0) {
		LOG_SEVERE("Missing impdhs.impPort or imperson.port in property file");
		return false;
	}
	
	if (!config.get("impdhs.tmpDir", tmpDir)) {
		LOG_SEVERE("Missing impdhs.tmpDir in property file");
		return false;
	}
		
	if (!config.get("impdhs.choochBinDir", choochBinDir)) {
		LOG_SEVERE("Missing impdhs.choochBinDir in property file");
		return false;
	}
		
	if (!config.get("impdhs.choochDatDir", choochDataDir)) {
		LOG_SEVERE("Missing impdhs.choochDatDir in property file");
		return false;
	}
	
	if (!config.get("impdhs.cameraHost", cameraHost)) {
		LOG_SEVERE("Missing impdhs.cameraHost in property file");
		return false;
	}

	std::string tmp;
	if (!config.get("impdhs.cameraPort", tmp)) {
		LOG_SEVERE("Missing impdhs.cameraPort in property file");
		return false;
	}
	cameraPort = XosStringUtil::toInt(tmp, 0);
	
	if (cameraPort <= 0) {
		LOG_SEVERE("Invalid impdhs.cameraPort value in property file");
		return false;
	}
	
    imageHost = getImgsrvHost( );
    if (imageHost.length( ) <= 0 )
    {
        LOG_SEVERE( "Missing imgsrv.host in property file" );
        return false;
    }
    imagePort = getImgsrvHttpPort( );
    if (imagePort <= 0)
    {
        LOG_SEVERE( "Invalid imgsrv.httpPort in property file" );
		return false;
    }

    get( "screening.latestEventIdUrl", latestEventIdUrl );
	if (latestEventIdUrl.empty()) {
		LOG_SEVERE("screening.latestEventIdUrl is not defined in property file");
		return false;
	}
    get( "screening.cassetteDataUrl", cassetteDataUrl );
	if (cassetteDataUrl.empty()) {
		LOG_SEVERE("screening.cassetteDataUrl is not defined in property file");
		return false;
	}
    get( "screening.silIdAndEventIdUrl", silAndEventUrl );
	if (silAndEventUrl.empty()) {
		LOG_SEVERE("screening.silIdAndEventIdUrl is not defined in property file");
		return false;
	}

    get( "auth.trusted_ca_file", m_trustedCaFile );
    get( "auth.trusted_ca_directory", m_trustedCaDir );

	LOG_INFO2("SSL certificate file = %s, dir = %s", m_trustedCaFile.c_str(), m_trustedCaDir.c_str());
	

    get( "impdhs.smallImageParam", smallImageParam );
    get( "impdhs.mediumImageParam", mediumImageParam );
    get( "impdhs.largeImageParam", largeImageParam );
    get( "impdhs.ciphers", m_ciphers );
    LOG_INFO1( "small: {%s}",   smallImageParam.c_str( ) );
    LOG_INFO1( "medium: {%s}",  mediumImageParam.c_str( ) );
    LOG_INFO1( "large: {%s}",   largeImageParam.c_str( ) );

	return true;
}
