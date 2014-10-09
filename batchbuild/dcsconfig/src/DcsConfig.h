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

#ifndef __Include_DcsConfig_h__
#define __Include_DcsConfig_h__

#include "XosConfig.h"
#include <string>

/**
 * @brief DcsConfig class.
 * 
 */
class DcsConfig
{

public:

	/**
	 * @brief Constructor. If DCS_ROOT_DIR env variable is set, the 
	 * config will be loaded from $DCS_ROOT_DIR/dcsconfig/data/default.config file.
	 * If the env variable is not set the config will be loaded from
	 * ./default.config.
	 */
	DcsConfig();
	
	/**
	 * @brief Constructor. Calls setConfigRoot()
	 * @param dcs_dir DCS directory which is parent of dcsconfig dir.
	 * @param config_root Name of the normal config file without file extension.
	 */
	DcsConfig(const std::string& dcs_dir, const std::string& config_root);
		
	/**
	 * @brief Destructor
	 */
	virtual ~DcsConfig();
	
	/**
	 */
	void setConfigDir(const std::string& dir);
		
	/**
	 */
	void setConfigRootName(const std::string& n);
	std::string getConfigRootName(  ) const { return name; }
	
	
	/**
	 */
	void setConfigFile(const std::string& f);
	
	/**
	 */
	void setDefaultConfigFile(const std::string& f);
				
	/**
	 * @brief Gets config file name
	 * @return Name of config file
	 */
	std::string getConfigFile() const
	{
		return config.getConfigFile();
	}
	
	/**
	 * @brief Gets config file name
	 * @return Name of config file
	 */
	std::string getDefaultConfigFile() const
	{
		return defConfig.getConfigFile();
	}

	/**
	 * @brief Sets useDefault flag. If useDefault flag is true,
	 * The default config will be returned from the get* methods
	 * when the normal config is not found.
	 * @param b True or false.
	 */
	void setUseDefaultConfig(bool b)
	{
		useDefault = b;
	}
	
	/**
	 * @brief Returns useDefault flag.
	 * @return useDefault flag.
	 */
	bool isUseDefault() const
	{
		return useDefault;
	}
	
		
	/**
	 * @brief Loads config from files.
	 * There are two sets of config: normal config and default config.
	 * @return True if the normal config is loaded ok. Still returns true
	 * even if fails to load default config.
	 */
	virtual bool load();
	
	// DCS
	std::string getDcsRootDir() const;

	std::string getUserLogDir() const;
	

	// DCSS
	std::string getDcssHost() const;
	int getDcssGuiPort() const;
	int getDcssScriptPort() const;
	int getDcssHardwarePort() const;
	int getDcssUseSSL() const;
   	std::string getDcssForcedDoor() const;
	StrList getDcssDisplays() const;

	
	// Authentication
	std::string getAuthHost() const;
	int getAuthPort() const;
	std::string getAuthSecureHost() const;
	int getAuthSecurePort() const;
	std::string getAuthMethod() const;
	std::string getAuthAppName() const;
	std::string getAuthTrustedCaFile() const;
	std::string getAuthTrustedCaDir() const;
	std::string getDcssCertificate() const;
	
	// Impersonation
	std::string getImpersonHost() const;
	int getImpersonPort() const;
	std::string getImpersonReadonlyHost() const;
	int getImpersonReadonlyPort() const;
	
	// Image server
	std::string getImgsrvHost() const;
	int getImgsrvWebPort() const;
	int getImgsrvGuiPort() const;
	int getImgsrvHttpPort() const;
	std::string getImgsrvTmpDir() const;
	int getImgsrvMaxIdleTime() const;
	
	
	/**
	 * @brief Generic method for getting config value.
	 * First look for the key in the normal config,
	 * If not found then look in the default config.
	 * If still not found then returns false.
	 * @param key Config name
	 * @param value Returned config value
	 * @return True if the config is found either in the normal config
	 *         or in the default config
	 */
	bool get(const std::string& key, std::string& value) const;	
	

	/**
	 * @brief Generic method for getting a list of config values
	 * for the given key.
	 * First look for the key in the normal config,
	 * If not found then look in the default config.
	 * If still not found then returns false.
	 * @param key Config name
	 * @param value Returned a list of config values
	 * @return True if the config is found either in the normal config
	 *         or in the default config
	 */
	bool getRange(const std::string& key, StrList& ret) const;
	
	
	/**
	 * @brief Generic method for getting config value.
	 * First look for the key in the normal config,
	 * If not found then look in the default config.
	 * If still not found then returns false.
	 * @param key Config name
	 * @param value Config value
	 * @return True if the config is set successfully
	 */
	bool set(const std::string& key, const std::string& value);

	/**
	 * @brief Returns the config value of the give 
	 * config name as string. If the key is not found in the normal config,
	 * search for it in default config. If neither is found, return 
	 * an empty string.
	 * @param key Config name.
	 * @return Config value.
	 */
	std::string getStr(const std::string& key) const;

	/**
	 * @brief Returns the config value as integer.
	 * config name as string. If the key is not found in the normal config,
	 * search for it in default config. If neither is found, return 
	 * the def integer passed in as second argument.
	 * @param key Config name.
	 * @param def Default integer value to be returned if 
	 * the config is not found.
	 * @return Config value.
	 */
	int getInt(const std::string& key, int def) const;
		
	/**
	 * @brief Replaces $(dcs.rootDir) with the value of dcs.rootDir config.
	 * Returns unchanged string if it does not contain $(dcs.rootDir).
	 * @param dir Directory path
	 * @return Resolved directory path.
	 */
	std::string resolveDir(const std::string& dir) const;

protected:

	/**
	 * @brief Normal config
	 */
	XosConfig config;

	/**
	 * @brief Normal config
	 */
	XosConfig defConfig;
	
	/**
	 * @brief Whether or not to use default config when 
	 * ormal config is not found. 
	 * 
	 */
	bool useDefault;
	
	/**
	 */
	std::string configDir;
	std::string name;
	
	static const std::string dcs;
	static const std::string dcss;
	static const std::string imgsrv;
	static const std::string auth;
	static const std::string imperson;
	
	/**
	 */
	void updateConfigFiles();
	
};

class DcsConfigSingleton {
public:
    static DcsConfig& GetDcsConfig( ) {
        return c_dcsConfig;
    }
private:

    DcsConfigSingleton( ) {
    }
    ~DcsConfigSingleton( ) {
    }

    static DcsConfig c_dcsConfig;
};


#endif // __Include_DcsConfig_h__

