#include "xos.h"
#include "XosStringUtil.h"
#include "DcsConfig.h"
#include "XosConfig.h"

DcsConfig DcsConfigSingleton::c_dcsConfig;

/****************************************************************
 *
 * Class constants
 *
 ****************************************************************/
const std::string DcsConfig::dcs = "dcs";
const std::string DcsConfig::dcss = "dcss";
const std::string DcsConfig::imgsrv = "imgsrv";
const std::string DcsConfig::auth = "auth";
const std::string DcsConfig::imperson = "imperson";

/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/
DcsConfig::DcsConfig()
	: useDefault(true), configDir("../../dcsconfig/data"), name("default")
{
	
	updateConfigFiles();
}

/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/
DcsConfig::DcsConfig(const std::string& config_dir, const std::string& root_name)
	: useDefault(true), configDir(config_dir), name(root_name)
{	
	updateConfigFiles();
}


/****************************************************************
 *
 * Destructor
 *
 ****************************************************************/
DcsConfig::~DcsConfig()
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void DcsConfig::setConfigDir(const std::string& dir)
{
	configDir = dir;
	
	updateConfigFiles();
	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void DcsConfig::setConfigFile(const std::string& f)
{
	config.setConfigFile(f);
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void DcsConfig::setDefaultConfigFile(const std::string& f)
{
	defConfig.setConfigFile(f);
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void DcsConfig::updateConfigFiles()
{
	
	config.setConfigFile(configDir + "/" + name + ".config");
	defConfig.setConfigFile(configDir + "/default.config");
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void DcsConfig::setConfigRootName(const std::string& n)
{
	name = n;
	
	updateConfigFiles();
	
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool DcsConfig::load()
{

	if (!config.load())
		return false;
		
	defConfig.load();
	
	return true;
}

/****************************************************************
 *
 * set
 *
 ****************************************************************/
bool DcsConfig::set(const std::string& key, const std::string& value)
{
	if (key.empty())
		return false;
		
	config.set(key, value);
	
	return true;
}


/****************************************************************
 *
 * get
 *
 ****************************************************************/
bool DcsConfig::get(const std::string& key, std::string& value) const
{
	if (config.get(key, value))
	
		return true;
		
	if (useDefault && defConfig.get(key, value))
		return true;
		
	return false;
}

/****************************************************************
 *
 * getStr
 *
 ****************************************************************/
std::string DcsConfig::getStr(const std::string& key) const
{
	std::string value;
	
	if (get(key, value))
		return value;
		
	return "";
}

/****************************************************************
 *
 * resolveDir
 * Replaces $(dcs.rootDir) with the value of dcs.rootDir.
 *
 ****************************************************************/
std::string DcsConfig::resolveDir(const std::string& dir) const
{	
	size_t pos = 0;
	if ((pos=dir.find("$(dcs.rootDir)")) != std::string::npos)
		return getDcsRootDir() + dir.substr(pos);
		
	return dir;
}


/****************************************************************
 *
 * getInt
 *
 ****************************************************************/
int DcsConfig::getInt(const std::string& key, int def) const
{
	std::string value;
	
	if (get(key, value))
		return XosStringUtil::toInt(value, def);

	return def;
	
}

/****************************************************************
 *
 * getRange
 *
 ****************************************************************/
bool DcsConfig::getRange(const std::string& key, StrList& ret) const
{
	
	if (config.getRange(key, ret))
		return true;
		
	if (useDefault && defConfig.getRange(key, ret))
		return true;
		
	return false;
	
}


/****************************************************************
 *
 * Convenient methods
 *
 ****************************************************************/

std::string DcsConfig::getDcsRootDir() const
{
	return getStr(dcs + ".rootDir");
}
std::string DcsConfig::getUserLogDir() const
{
	return getStr("userLog.directory");
}

std::string DcsConfig::getDcssHost() const
{
	return getStr(dcss + ".host");
}

int DcsConfig::getDcssGuiPort() const
{
	return getInt(dcss + ".guiPort", 0);
}

int DcsConfig::getDcssScriptPort() const
{
	return getInt(dcss + ".scriptPort", 0);
}

int DcsConfig::getDcssUseSSL() const
{
	return getInt(dcss + ".ssl", 0);
}

int DcsConfig::getDcssHardwarePort() const
{
	return getInt(dcss + ".hardwarePort", 0);
}

std::string DcsConfig::getDcssForcedDoor() const
{
	return getStr(dcss + ".forcedDoor");
}


StrList DcsConfig::getDcssDisplays() const
{
	StrList ret;
	
	if (getRange(dcss + ".display", ret))
		return ret;
		
	ret.clear();
	
	return ret;
}


// Authentication
std::string DcsConfig::getAuthHost() const
{
	return getStr(auth + ".host");
}

int DcsConfig::getAuthPort() const
{
	return getInt(auth + ".port", 0);
}

// Authentication via SSL
std::string DcsConfig::getAuthSecureHost() const
{
	return getStr(auth + ".secureHost");
}

int DcsConfig::getAuthSecurePort() const
{
	return getInt(auth + ".securePort", 0);
}

std::string DcsConfig::getAuthMethod() const
{
	return getStr(auth + ".method");
}

std::string DcsConfig::getAuthAppName() const
{
	return getStr(auth + ".method");
}

std::string DcsConfig::getDcssCertificate() const
{
	return getStr(dcss + ".certificate");
}
std::string DcsConfig::getAuthTrustedCaDir() const
{
	return getStr(auth + ".trusted_ca_directory");
}

std::string DcsConfig::getAuthTrustedCaFile() const
{
	return getStr(auth + ".trusted_ca_file");
}

// Impersonation
std::string DcsConfig::getImpersonHost() const
{
	return getStr(imperson + ".host");
}

int DcsConfig::getImpersonPort() const
{
	return getInt(imperson + ".port", 0);
}

// Readonly version of the Impersonation server
// Supports only readFile, listDirectory, 
// getFilePermissions and getFileStatus
std::string DcsConfig::getImpersonReadonlyHost() const
{
	return getStr(imperson + ".readonlyHost");
}

int DcsConfig::getImpersonReadonlyPort() const
{
	return getInt(imperson + ".readonlyPort", 0);
}


// Image server
std::string DcsConfig::getImgsrvHost() const
{
	return getStr(imgsrv + ".host");
}

int DcsConfig::getImgsrvWebPort() const
{
	return getInt(imgsrv + ".webPort", 0);
}

int DcsConfig::getImgsrvGuiPort() const
{
	return getInt(imgsrv + ".guiPort", 0);
}

int DcsConfig::getImgsrvHttpPort() const
{
	return getInt(imgsrv + ".httpPort", 0);
}

std::string DcsConfig::getImgsrvTmpDir() const
{
	return getStr(imgsrv + ".tmpDir");
}

int DcsConfig::getImgsrvMaxIdleTime() const
{
	return getInt(imgsrv + ".maxIdleTime", 0);
}



