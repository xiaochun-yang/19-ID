#include "xos.h"
#include "XosStringUtil.h"
#include "FrameData.h"
#include <string>

/*****************************************************************
 * PUBLIC
 * Constructor
 *****************************************************************/
FrameData::FrameData()
{
	strcpy(operationHandle, "");
	runIndex = 0;
	strcpy(fileName, "");
	strcpy(directory, "");
	strcpy(userName, "");
	detectorMode = 0;
	strcpy(axisName, "");
	oscillationStart = 0.0;
	oscillationRange = 0.0;
	oscillationTime = 0.0;
	exposureTime = 0.0;
	distance = 0.0;
	wavelength = 0.0;
	detectorX = 0.0;
	detectorY = 0.0;
	reuseDark = false;

}

/*****************************************************************
 * PUBLIC
 * toString
 *****************************************************************/
std::string FrameData::toString() const
{	
	std::string ret("");
	
	ret += std::string("operationHandle=") + operationHandle;
	ret += std::string("runIndex=") + XosStringUtil::fromInt(runIndex);
	ret += std::string("fileName=") + fileName;
	ret += std::string("directory=") + directory;
	ret += std::string("userName=") + userName;
	ret += std::string("detectorMode=") + XosStringUtil::fromInt(detectorMode);
	ret += std::string("axisName=") + axisName;
	ret += std::string("oscillationStart=") + XosStringUtil::fromDouble(oscillationStart);
	ret += std::string("oscillationRange=") + XosStringUtil::fromDouble(oscillationRange); 
	ret += std::string("oscillationTime=") + XosStringUtil::fromDouble(oscillationTime);
	ret += std::string("exposureTime=") + XosStringUtil::fromDouble(exposureTime);
	ret += std::string("distance=") + XosStringUtil::fromDouble(distance);
	ret += std::string("wavelength=") + XosStringUtil::fromDouble(wavelength); 
	ret += std::string("detectorX=") + XosStringUtil::fromDouble(detectorX);
	ret += std::string("detectorY=") + XosStringUtil::fromDouble(detectorY);
	ret += std::string("reuseDark=") + XosStringUtil::fromInt(reuseDark);
	
	return ret;
}

