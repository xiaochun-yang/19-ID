#ifndef __Include_XosConfig_h__
#define __Include_XosConfig_h__

#include "xos.h"
#include <string>
#include <map>
#include <list>

typedef std::list<std::string> StrList;
typedef std::multimap<std::string, std::string> StrMMap;

/**
 * @brief XosConfig class that encapsulates the configuation parameters.
 */
class XosConfig
{
public:
	
	
	/**
	 * @brief Default constructor. Load config 
	 * from default config file
	 */
	XosConfig();
	
	/**
	 * @brief Default constructor. 
	 * @param f Name of config file
	 */
	XosConfig(const std::string& f);
	
	/**
	 * @brief Destructor. This class can be overriden.
	 */
	virtual ~XosConfig();

	/**
	 * @brief Load config from file
	 */
	virtual bool load();
	
	/**
	 * @brief Saves config to file.
	 * @param f Name of config file
	 * @return True if successfully saves the config. Else returns false.
	 */
	bool save(const std::string& file);
		
	/**
	 * @brief Gets a config value for the given config name.
	 * @param key Config name
	 * @param ret The returned value
	 * @return True if the config exists. Otherwise returns false.
	 */
	bool get(const std::string& key, std::string& ret) const;
	
	/**
	 * @brief Gets a list config values for the given config name.
	 * @param key Config name
	 * @param ret The returned list of config value
	 * @return True if the config exists. Otherwise returns false.
	 */
	bool getRange(const std::string& key, StrList& ret) const;
	/**
	 * @brief Sets config value for the given config name.
	 * @param key Config name
	 * @param ret The new value
	 * @return True the new value is set successfully.
	 */
	void set(const std::string& key, const std::string& value);
	
	
	/**
	 * @brief Gets config file name
	 * @return Name of config file
	 */
	std::string getConfigFile() const
	{
		return file;
	}
	
	
	/**
	 * @brief Sets config file name
	 * @param f Name of config file
	 */
	void setConfigFile(const std::string& f)
	{
		file = f;
	}


protected:

	/**
	 * @brief Repository name
	 */
	std::string file;
	
	/**
	 * @brief Hash table of the config systems.
	 */
	StrMMap data;
	
	
};


#endif // __Include_XosConfig_h__


