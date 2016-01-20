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


// ******************************************************

#ifndef IMP_FILEPATH_H
#define IMP_FILEPATH_H

#define MAX_PATHNAME 255

class ImpFileAccess
{
   private:
      std::string mImpHost;
      int mImpPort;
      std::string mUserName;
      std::string mSessionId;
   public:
      ImpFileAccess(std::string impHost, std::string userName,std::string sessionId);

      xos_result_t createWritableDirectory(std::string directory);
      xos_result_t backupExistingFile( std::string directory, std::string filename,	std::string backupDir, bool & movedTheFile );
      bool fileWritable ( std::string directory );
      std::string queryFileType ( std::string directory );
      xos_result_t createDirectory ( std::string directory );
      xos_result_t renameFile ( std::string oldPath, std::string newPath );
      xos_result_t deleteFile ( std::string fullPath );
      std::string getUserName();
      xos_result_t sendStreamToFile( std::string fullPath,  FILE * stream);
};


#endif
