#include "XosConfig.h"
#include "xos.h"
#include "XosStringUtil.h"

#define DEFAULT_CONFIG_FILE "./default.config"

/*******************************************************************
 *
 *
 *
 *******************************************************************/
XosConfig::XosConfig()
	: file(DEFAULT_CONFIG_FILE)
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
XosConfig::XosConfig(const std::string& s)
	: file(s)
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
XosConfig::~XosConfig()
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool XosConfig::load()
{
	FILE* is = fopen(file.c_str(), "r");
	
	if (is == NULL) {
//		xos_error("Error: failed to load config from file %s\n", file.c_str());
		return false;
	}
		
	char buf[500];
	std::string key;
	std::string value;
	while (!feof(is)) {
	
		if (fgets(buf, 500, is) == NULL)
			break;
		
		// ignore empty lines
		if (strlen(buf) < 2)
			continue;
		
		// ignore comment lines
		if (buf[0] == '#')
			continue;
		
		// Ignoring lines without =
    	if (!XosStringUtil::split(buf, "=", key, value))
    		continue;
    		    		
    	// Remove trailing white space
    	// and save the key and value in a hash table
		data.insert(StrMMap::value_type(XosStringUtil::trim(key), 
								XosStringUtil::trim(value)));
	
	}
	
	fclose(is);
	
	return true;
	
	
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool XosConfig::save(const std::string& file)
{
	return false;
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool XosConfig::get(const std::string& key, std::string& ret) const
{
	StrMMap::const_iterator i = data.find(key);
	
	if (i == data.end())
		return false;
				
	ret = i->second;
	
	return true;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool XosConfig::getRange(const std::string& key, StrList& ret) const
{
	StrMMap::const_iterator i = data.lower_bound(key);
	StrMMap::const_iterator j = data.upper_bound(key);
	
	if (i == j)
		return false;
				
	for (; i != j; ++i) {
		ret.push_back(i->second);
	}
	
	return true;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void XosConfig::set(const std::string& key, const std::string& value)
{

	data.insert(StrMMap::value_type(key, value));
}


