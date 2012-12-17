/************************************************************************
                        Copyright 2001
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

************************************************************************/



#ifndef __Include_XosFileUtil_h__
#define __Include_XosFileUtil_h__

/**
 * @file XosFileUtil.h
 * Header file for file utlity functions
 */

#include "xos.h"
#include "XosException.h"

/**
 * @class XosFileUtil
 * A collection of file utility functions.
 */

class XosFileUtil
{
public:

    /**
     * @brief Returns an error string for the given errno.
     *
     * If err does not match a valid errno, prefix string will be returned.
     * @param err Error number (errno)
     * @param prefix Prefix for the returned error string
     * @return An error string corresponding to the errno.
     * @todo This method should be moved to XosCUtil class instead.
     **/
    static std::string getErrorCode(int err);
	
	 /**
     * Default error string for errno.
 	  */
    static std::string getErrorString(int err, const std::string& prefix);
    static std::string getErrorString(int err);
    static std::string getFopenErrorString(int err);
    static std::string getAccessErrorString(int err);
    static std::string getChmodErrorString(int err);
    static std::string getStatErrorString(int err);
    static std::string getRenameErrorString(int err);
    static std::string getReaddirErrorString(int err);
    static std::string getLstatErrorString(int err);
    static std::string getReadlinkErrorString(int err);
    static std::string getCloseErrorString(int err);

    /**
     * @brief Copy file
     *
     * Opens read content of old file and write it to new file.
     * @param old File to be copied from.
     * @param new File to be copied to.
     * @exception Thrown when an error occurs.
     **/
    static void copyFile(const char* oldfile, const char* newfile)
    	throw (XosException);

private:

    /**
     * @brief No need to create an object of this class. All methods are static.
     */
    XosFileUtil() {}
};

#endif // __Include_XosFileUtil_h__
