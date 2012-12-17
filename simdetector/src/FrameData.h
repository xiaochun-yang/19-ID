#ifndef __FRAMEDATA_H__
#define __FRAMEDATA_H__


#define MAX_PATHNAME 255
#include <string>

class FrameData
{
public:

	/**
	 * Constructor
	 */
	FrameData();
	
	/**
	 * toString
	 */
	std::string toString() const;

public:

	char           	operationHandle[20];
	int				runIndex;
	char			fileName[MAX_PATHNAME];
	char			directory[MAX_PATHNAME];
	char			userName[200];
	int            	detectorMode;
	char			axisName[20];
	double			oscillationStart;
	double			oscillationRange; 
	double			oscillationTime;
	double			exposureTime;
	double			distance;
	double			wavelength; 
	double			detectorX;
	double			detectorY;
	bool			reuseDark;
	char			sessionId[MAX_PATHNAME];
	
};

#endif // __FRAMEDATA_H__


