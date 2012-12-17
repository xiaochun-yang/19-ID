#include "xos.h"
#include "XosStringUtil.h"
#include "DcssConfig.h"

/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/
DcssConfig::DcssConfig()
{
		guiPort = 0;
		scriptPort = 0;
		hardwarePort = 0;
		
		authHost = "";
		authPort = 0;
}

/****************************************************************
 *
 * load
 *
 ****************************************************************/
bool DcssConfig::load(const std::string& filename)
{
	FILE* is = fopen(filename.c_str(), "r");
	
	if (!is)
		return false;
		
	char buf[500];
	std::string name;
	std::string value;
	while (!feof(is)) {
	
		fgets(buf, 500, is);
		
		if (strlen(buf) < 2)
			continue;
		
		if (buf[0] == '#')
			continue;
		
    	if (!XosStringUtil::split(buf, "=", name, value))
    		continue;
    		
    	// Remove trailing white space
    	value = XosStringUtil::trim(value);
    		
		if (name == "scriptPort") {
			scriptPort = XosStringUtil::toInt(value, 0);
		} else if (name == "guiPort") {
			guiPort = XosStringUtil::toInt(value, 0);
		} else if (name == "hardwarePort") {
			hardwarePort = XosStringUtil::toInt(value, 0);
		} else if (name == "authHost") {
			authHost = value;
		} else if (name == "authPort") {
			authPort = XosStringUtil::toInt(value, 0);
		}
	
	}
	
	if (scriptPort <= 0)
		return false;
	if (guiPort <= 0)
		return false;
	if (hardwarePort <= 0)
		return false;
	if (authHost.empty())
		return false;
	if (authPort <= 0)
		return false;
	
	
	return true;
	
}

