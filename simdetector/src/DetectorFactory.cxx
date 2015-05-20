#include "xos.h"
#include "DetectorFactory.h"
#include "SimDetector.h"


/*****************************************************************
 * PUBLIC
 * newDetector
 * Create a detector for the given type.
 * Returns null for unknown type.
 *****************************************************************/
Detector* DetectorFactory::newDetector(const std::string& type)
{
		
	if (type == "simdetector")
		return new SimDetector();
		
	return NULL;
}

