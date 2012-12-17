#ifndef __imgsrv_validation_h__
#define __imgsrv_validation_h__

#include "SessionInfo.h"

bool isFileReadable(SessionInfo& session,
					  const std::string& fileName,
					  std::string& reason);
					  
					  
#endif // __imgsrv_validation_h__



