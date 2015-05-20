#ifndef __DETECTORFACTORY_H__
#define __DETECTORFACTORY_H__

#include "xos.h"
#include "Detector.h"
#include <string>

class DetectorFactory
{
public:

	DetectorFactory() {}
	~DetectorFactory() {}
	
	static Detector* newDetector(const std::string& type);

};

#endif //   #ifndef __DETECTORFACTORY_H__
