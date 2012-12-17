/**
 * Javabean for SMB resources
 */
package webice.beans;

import java.util.*;
import java.io.*;


public class ServerConfig
{

	/**
	 * Authentication server host and port.
	 * Used to authenticate users before
	 * entering webice servlets
	 */
	static private String authHost = "";
	static private int authPort = 0;
	static private int authSecurePort = 0;

	/**
	 * Impersonsation server host and port.
	 * Used to access remote files
	 * on behalf of the user.
	 */
	static private String impServerHost = "";
	static private int impServerPort = 0;

	/**
	 * Image server host and port.
	 * Used to serve diffraction images to webice.
	 */
	static private String imgServerHost = "";
	static private int imgServerPort = 0;

	/**
	 * Impersonation server host and port.
	 * Used to run spotfinder. The server
	 * needs to be run on decunix
	 * where spotfinder is available.
	 */
	static private String spotServerHost = "";
	static private int spotServerPort = 0;

	static private String binDir = "";
	static private String scriptDir = "";

	static private String dcsDumpDir = "";
	static private int dcsUpdateRate = 0;

	static private String accessMode = "none";
	static private Hashtable include = new Hashtable();
	static private Hashtable exclude = new Hashtable();

	static private Vector beamlines = new Vector();

	static private Hashtable admin = new Hashtable();

	static private String silGetSilUrl = "";
	static private String silGetSilListUrl = "";
	static private String silSetCrystalUrl = "";
	static private String silDtdUrl = "";
	static private String silUrl = "";
	static private String silAnalyzeImageUrl = "";
	static private String silAutoindexUrl = "";
	static private String silDownloadSilUrl = "";
	static private String silDtd = "";
	static private String silIsEventCompletedUrl = "";
	static private String silGetCrystalUrl = "";
	static private String silClearCrystalUrl = "";
	static private String createDefaultSilUrl = "";
	static private String deleteCassetteUrl = "";
	static private String addRunDefinitionUrl = "";
	static private String setRunDefinitionUrl = "";

	static private int maxInactiveInterval = 10800; // 3 hours = 60*60*3 seconds = 10800 seconds


	static private String dcssHost = "";
	static private int dcssPort = 0;
	static private String analysisDhs = "";
	
	static private String userConfigDir = "/home/<user>";
	static private String userRootDir = "/data/<user>";
	static private String webiceRootDir = "";
	
	static private String autoindexHost = "";
	static private int autoindexPort = 16001;
	
	// Either silList or dirList
	static private String silListMode = "silList";
	
	static private String beamlineDir = "/home/www/templates";
	
	static private String silHost = "localhost";
	static private int silPort = 80;
		
	static private String caHost = "localhost";
	static private int caPort = 80;
	
	static private int webicePort = 80;
	static private int webicePortSecure = 80;
	
	static private int screeningDirDepth = 1;
	
	
	static private String importRunMode = "mountedCrystalOnly";
	
	static private Properties prop = null;
			
	static private Hashtable videoMappingPreset = new Hashtable();
	static private Hashtable videoMappingImage = new Hashtable();
	
	static private String periodicTableFile = "";
	
	static private String collectMonitorMode = "";
	static private String installation = "SSRL";
	
	static private String spotfinderVersion = "0.1";
	
	static private String defUserPropertiesFile = "";
	/**
	 * Constructor
	 */
	public ServerConfig()
	{
	}

	/**
	 * Replace variables ${xxx} with a value.
	 */
	static private void translateConfig(Properties prop)
	{
		Hashtable lookup = createLookupTable(prop);
		
		Enumeration e = prop.propertyNames();
		String nn = "";
		String str = "";
		String alias = "";
		String real = "";
		int pos1 = 0;
		int pos2 = 0;
		boolean changed = false;
		String old = "";
		int count = 10;
		while (e.hasMoreElements()) {
			nn = (String)e.nextElement();
			str = (String)prop.getProperty(nn);			
			changed = false;
			count = 0;
			old = str;
			while ((count < 10) && (pos1=str.indexOf("${")) >= 0) {
				++count;
				pos2 = str.indexOf("}", pos1);
				if (pos2 < str.length()) {
					alias = str.substring(pos1, pos2+1);
					real = (String)lookup.get(alias);
					if (real == null)
						real = "";
					str = str.replace(alias, real);
					changed = true;
				}
			}
			// Replace the config value
			if (changed) {
				prop.setProperty(nn, str);
				WebiceLogger.info("Replaced config (" + nn + "): from " 
						+ old + " to " + str);
			}
				
		}
		
			
	}
	
	static private Hashtable createLookupTable(Properties prop)
	{
		Hashtable lookup = new Hashtable();
		
		// Setup a lookup table
		Enumeration e = prop.propertyNames();
		String nn = "";
		String vv = "";
		while (e.hasMoreElements()) {
			nn = (String)e.nextElement();
			vv = (String)prop.getProperty(nn);
			lookup.put("${" + nn + "}", vv);

		}
		lookup.put("${}", "");
		
		return lookup;
	}

	/**
	 * Load config from file
	 */
	public static void load(String fileName)
		throws Exception
	{
		WebiceLogger.info("Loading webice properties from " + fileName);
		prop = new Properties();
		FileInputStream stream = null;
		
		try {
		
		stream = new FileInputStream(fileName);

		prop.load(stream);

		stream.close();
		stream = null;
				
		translateConfig(prop);
				

		} catch (Exception e) {
			WebiceLogger.error("Failed to load server config from " + fileName, e);
		} finally {
			if (stream != null)
				stream.close();
			stream = null;
		}
		

		authHost = prop.getProperty("auth.host", "localhost");
		String tmp = prop.getProperty("auth.port", "80");
		authPort = Integer.parseInt(tmp);
		tmp = prop.getProperty("auth.securePort", "0");
		authSecurePort = Integer.parseInt(tmp);

		impServerHost = prop.getProperty("imperson.host", "");
		tmp = prop.getProperty("imperson.port", "0");
		impServerPort = Integer.parseInt(tmp);

		imgServerHost = prop.getProperty("imgsrv.host", "");
		tmp = prop.getProperty("imgsrv.port", "0");
		imgServerPort = Integer.parseInt(tmp);

		spotServerHost = prop.getProperty("spotfinder.impersonHost", "");
		tmp = prop.getProperty("spotfinder.impersonPort", "0");
		spotServerPort = Integer.parseInt(tmp);

		binDir = prop.getProperty("webice.binDir", "");
		scriptDir = prop.getProperty("webice.scriptDir", "");

		dcsDumpDir = prop.getProperty("dcs.dumpDir", "");
		tmp = prop.getProperty("dcs.updateRate", "0");
		dcsUpdateRate = Integer.parseInt(tmp);

		accessMode = prop.getProperty("webice.accessMode", "none");
		// Included users
		tmp = prop.getProperty("webice.includeUsers", "");
		StringTokenizer tokenizer = new StringTokenizer(tmp, ",");
		String token = "";
		while (tokenizer.hasMoreTokens()) {
			token = tokenizer.nextToken();
			include.put(token, token);
		}

		// Excluded users
		tmp = prop.getProperty("webice.excludeUsers", "");
		tokenizer = null;
		tokenizer = new StringTokenizer(tmp, ",");
		while (tokenizer.hasMoreTokens()) {
			token = tokenizer.nextToken();
			exclude.put(token, token);
		}

		// Beamlines
		beamlines.clear();
		tmp = prop.getProperty("webice.beamlines", "");
		tokenizer = null;
		tokenizer = new StringTokenizer(tmp, ",");
		while (tokenizer.hasMoreTokens()) {
			token = tokenizer.nextToken();
			beamlines.add(token);
		}


		// Admin list
		tmp = prop.getProperty("webice.admin", "");
		tokenizer = null;
		tokenizer = new StringTokenizer(tmp, ",");
		while (tokenizer.hasMoreTokens()) {
			token = tokenizer.nextToken();
			admin.put(token, token);
		}

		silGetSilUrl = prop.getProperty("sil.getSilUrl", "");
		silGetSilListUrl = prop.getProperty("sil.getSilListUrl", "");
		silDtdUrl = prop.getProperty("sil.dtdUrl", "");
		silAnalyzeImageUrl = prop.getProperty("sil.analyzeImageUrl", "");
		silAutoindexUrl = prop.getProperty("sil.autoindexUrl", "");
		silDownloadSilUrl = prop.getProperty("sil.downloadSilUrl", "");
		silDtd = prop.getProperty("sil.dtd", "");
		silSetCrystalUrl = prop.getProperty("sil.setCrystalUrl", "");
		silIsEventCompletedUrl = prop.getProperty("sil.isEventCompletedUrl", "");
		silUrl = prop.getProperty("sil.url", "");
		silGetCrystalUrl = prop.getProperty("sil.getCrystalUrl", "");
		silClearCrystalUrl = prop.getProperty("sil.clearCrystalUrl", "");
		createDefaultSilUrl = prop.getProperty("sil.createDefaultSilUrl", "");
		deleteCassetteUrl = prop.getProperty("sil.deleteCassetteUrl", "");
		addRunDefinitionUrl = prop.getProperty("sil.addRunDefinitionUrl", "");
		setRunDefinitionUrl = prop.getProperty("sil.setRunDefinitionUrl", "");

		maxInactiveInterval = getPropertyInt("webice.maxInactiveInterval", 10800);

		dcssHost = prop.getProperty("dcs.dcssHost", "localhost");
		dcssPort = getPropertyInt("dcs.dcssPort", 14342);

		analysisDhs = prop.getProperty("dcs.analysisDhs", "analysisdhs");
		
		userRootDir = prop.getProperty("webice.userRootDir", "/data/<user>");
		webiceRootDir = prop.getProperty("webice.rootDir", "");
		userConfigDir = prop.getProperty("webice.userConfigDir", "/home/<user>");
		
		autoindexHost = prop.getProperty("autoindex.host", "");
		autoindexPort = getPropertyInt("autoindex.port", 16001);
		
		silListMode = prop.getProperty("webice.silListMode", "silList");
		beamlineDir = prop.getProperty("webice.beamlineDir", "/home/www/templates");
		
		silHost = prop.getProperty("sil.host", "localhost");
		silPort = getPropertyInt("sil.port", 80);
		caHost = prop.getProperty("ca.host", "localhost");
		caPort = getPropertyInt("ca.port", 80);

		webicePort = getPropertyInt("webice.port", 80);
		webicePortSecure = getPropertyInt("webice.portSecure", 80);
		
		importRunMode = prop.getProperty("webice.importRunMode", "mountedCrystalOnly");
		
		screeningDirDepth = getPropertyInt("webice.screeningDirDepth", 1);
		
		tmp = prop.getProperty("video.mapping.preset");
		if (tmp != null) {
			StringTokenizer tok1 = new StringTokenizer(tmp, "()");
			while (tok1.hasMoreTokens()) {
				tmp = tok1.nextToken();
				int pos = tmp.indexOf(",");
				if (pos < 0)
					continue;
				videoMappingPreset.put(tmp.substring(0, pos), tmp.substring(pos+1));
			}
		}

		tmp = prop.getProperty("video.mapping.image");
		if (tmp != null) {
			StringTokenizer tok1 = new StringTokenizer(tmp, "()");
			while (tok1.hasMoreTokens()) {
				tmp = tok1.nextToken();
				int pos = tmp.indexOf(",");
				if (pos < 0)
					continue;
				videoMappingImage.put(tmp.substring(0, pos), tmp.substring(pos+1));
			}
		}

		periodicTableFile = prop.getProperty("webice.periodicTableFile", "");
		collectMonitorMode = prop.getProperty("collect.monitorMode", "all");
		installation = prop.getProperty("webice.installation", "SSRL");
		spotfinderVersion = prop.getProperty("spotfinder.version", "0.1");
		
		defUserPropertiesFile = prop.getProperty("webice.defUserPropertiesFile", 
					getWebiceRootDir() + "/WEB-INF/user.properties");
	}
	
	public static String getSpotfinderVersion()
	{
		return spotfinderVersion;
	}
	
	public static boolean isNewSpotfinderVersion()
	{
		return spotfinderVersion.equals("0.1") ? false : true;
	}
	
	static boolean getPropertyBoolean(String name, boolean def)
	{
		String tmp = prop.getProperty(name, String.valueOf(def));
		if (tmp != null) {
			try {
				return Boolean.parseBoolean(tmp);
			} catch (NumberFormatException e) {
			}
		}
		return def;
	}

	static int getPropertyInt(String name, int def)
	{
		String tmp = prop.getProperty(name, String.valueOf(def));
		if (tmp != null) {
			try {
				return Integer.parseInt(tmp);
			} catch (NumberFormatException e) {
			}
		}
		return def;
	}

	/**
	 * Get authentication server host
	 */
	static public String getAuthHost()
	{
		return authHost;
	}

	/**
	 * Get authentication server port
	 */
	static public int getAuthPort()
	{
		return authPort;
	}

	/**
	 * Get authentication server secure port
	 */
	static public int getAuthSecurePort()
	{
		return authSecurePort;
	}

	/**
	 * Get authentication server method
	 */
	static public String getAuthMethod()
	{
		return getProperty("auth.method");
	}
	
	/**
	 * Get authentication server app name
	 */
	static public String getAuthAppName()
	{
		String m = getProperty("auth.appName");
		if ((m == null) || (m.length() == 0))
			m = "WebIce";
			
		return m;
	}
	
	/**
	 * Get authentication gateway url
	 */
	static public String getAuthServletHost()
	{
		String scheme = "http";
		int port = authPort;
		if (authSecurePort > 0) {
			scheme = "https";
			port = authSecurePort;
		}
		return scheme + "://" + authHost + ":" + port;
	}

	/**
	 * Get impersonation server host
	 */
	static public String getImpServerHost()
	{
		return impServerHost;
	}

	/**
	 * Get impersonation server port
	 */
	static public int getImpServerPort()
	{
		return impServerPort;
	}


	/**
	 * Get image server host
	 */
	static public String getImgServerHost()
	{
		return imgServerHost;
	}

	/**
	 * Get image server port
	 */
	static public int getImgServerPort()
	{
		return imgServerPort;
	}

	/**
	 * Get impersonation server host for running spotfinder
	 */
	static public String getSpotServerHost()
	{
		return spotServerHost;
	}

	/**
	 * Get impersonation server port for running spotfinder
	 */
	static public int getSpotServerPort()
	{
		return spotServerPort;
	}

	/**
	 */
	static public String getBinDir()
	{
		return binDir;
	}


	/**
	 */
	static public String getScriptDir()
	{
		return scriptDir;
	}

	/**
	 */
	static public String getDcsDumpDir()
	{
		return dcsDumpDir;
	}

	/**
	 */
	static public int getDcsUpdateRate()
	{
		return dcsUpdateRate;
	}

	/**
	 */
	static public boolean isUserIncluded(String user, boolean isStaff)
	{

		if (accessMode.equals("all")) {

			// Allow all except those on exclude list
			return !exclude.contains(user);

		} else if (accessMode.equals("some")) {

			// Allow only those on include list
			// and NOT on exclude list
			return (include.contains(user) && !exclude.contains(user));

		} else if (accessMode.equals("staff")) {

			// Allow all staff
			if (isStaff)
				return true;

			// Plus those on include list
			// and NOT on exclude list
			return (include.contains(user) && !exclude.contains(user));

		} else if (accessMode.equals("none")) {

			// Allow none except those on include list
			return include.contains(user);
		}

		// Unknown access mode, allow none.
		return false;
	}

	/**
	 * Returns a list of beamlines accessible by WebIce.
	 */
	static public Vector getBeamlines()
	{
		return beamlines;
	}

	/**
	 */
	static public String getInclude()
	{
		return hashToString(include);

	}

	/**
	 */
	static public void setInclude(String s)
	{
		stringToHash(s, include);
	}

	/**
	 */
	static public String getExclude()
	{
		return hashToString(exclude);

	}

	/**
	 */
	static public void setExclude(String s)
	{
		stringToHash(s, exclude);
	}

	/**
	 */
	static public String hashToString(Hashtable hash)
	{
		Enumeration e = hash.elements();

		String ret = "";

		if (e.hasMoreElements())
			ret += e.nextElement();

		 for (; e.hasMoreElements() ;) {
			 ret += " " + e.nextElement();
		 }

		 return ret;

	}

	/**
	 */
	static public void stringToHash(String s, Hashtable hash)
	{
		hash.clear();

		if (s == null)
			return;

		StringTokenizer token = new StringTokenizer(s, " ,");

		include.clear();
		while (token.hasMoreTokens()) {
			String n = token.nextToken();
			hash.put(n, n);
		}

	}

	/**
	 */
	static public boolean isAdmin(String n)
	{
		return admin.contains(n);
	}

	/**
	 */
	static public String getSilGetSilUrl()
	{
		return silGetSilUrl;
	}
	
	static public String getAddRunDefinitionUrl()
	{
		return addRunDefinitionUrl;
	}
	
	static public String getSetRunDefinitionUrl()
	{
		return setRunDefinitionUrl;
	}

	/**
	 */
	static public String getSilGetSilListUrl()
	{
		return silGetSilListUrl;
	}

	/**
	 */
	static public String getSilDtdUrl()
	{
		return silDtdUrl;
	}

	/**
	 */
	static public String getSilAnalyzeImageUrl()
	{
		return silAnalyzeImageUrl;
	}

	/**
	 */
	static public String getSilAutoindexUrl()
	{
		return silAutoindexUrl;
	}

	/**
	 */
	static public String getSilDownloadSilUrl()
	{
		return silDownloadSilUrl;
	}

	/**
	 */
	static public String getSilAddUserUrl()
	{
		return prop.getProperty("sil.addUserUrl");
	}

	/**
	 */
	static public String getSilDtd()
	{
		return silDtd;
	}

	/**
	 */
	static public String getSilSetCrystalUrl()
	{
		return silSetCrystalUrl;
	}

	/**
	 */
	static public String getSilIsEventCompletedUrl()
	{
		return silIsEventCompletedUrl;
	}

	/**
	 */
	static public String getSilGetCrystalUrl()
	{
		return silGetCrystalUrl;
	}

	/**
	 */
	static public String getSilClearCrystalUrl()
	{
		return silClearCrystalUrl;
	}
	
	/**
	 */
	static public String getDeleteCassetteUrl()
	{
		return deleteCassetteUrl;
	}

	/**
	 */
	static public String getSilUrl()
	{
		return silUrl;
	}

	/**
	 */
	static public int getMaxInactiveInterval()
	{
		return maxInactiveInterval;
	}

	/**
	 */
	static public String getDcssHost()
	{
		return dcssHost;
	}

	/**
	 */
	static public int getDcssPort()
	{
		return dcssPort;
	}

	/**
	 */
	static public String getAnalysisDhs()
	{
		return analysisDhs;
	}
	
	/**
	 * Returns user root dir which is the parent 
	 * of webice dir.
	 * webice.userRootDir in the config file may contain 
	 * <user> string which is to be replaced by the 
	 * user name passed in as the argument to this func.
	 * Only allowed class from this package to use 
	 * this method. Other classes should use method
	 * of the same name in Client class.
 	 */
	static String getUserRootDir(String user_name)
	{
		return userRootDir.replace("<user>", user_name);
	}


	static public String getRawUserRootDir(String user_name)
	{
		return userRootDir;
		
	}

	static public String getWebiceRootDir()
	{
		return webiceRootDir;
		
	}
	
	static public String getAutoindexHost()
	{
		return autoindexHost;
	}
	
	static public int getAutoindexPort()
	{
		return autoindexPort;
	}
	
	/*
	 * This is where .webice file is located.
	 * Only allowed class from this package to use 
	 * this method. Other classes should use method
	 * of the same name in Client class.
	 */
	static public String getUserConfigDir(String user_name)
	{
		return userConfigDir.replace("<user>", user_name);
	}
	
	static public String getRawUserConfigDir()
	{
		return userConfigDir;
	}
	
	static public String getSilListMode()
	{
		return silListMode;
	}
	
	static public String getCreateDefaultSilUrl()
	{
		return createDefaultSilUrl;
	}
	
	static public String getBeamlineDir()
	{
		return beamlineDir;
	}
	
	static public String getSilHost()
	{
		return silHost;
	}
	
	static public int getSilPort()
	{
		return silPort;
	}
	
	static public String getCaHost()
	{
		return caHost;
	}
	
	static public int getCaPort()
	{
		return caPort;
	}
		
	static public int getWebicePort()
	{
		return webicePort;
	}
	
	static public int getWebicePortSecure()
	{
		return webicePortSecure;
	}
	
	static public String getImportRunMode()
	{
		return importRunMode;
	}
	static public int getScreeningDirDepth()
	{
		return screeningDirDepth;
	}
	
	static public String getDcssHost(String beamline)
	{
		return prop.getProperty(beamline + ".dcssHost");
	}
	
	static public int getDcssPort(String beamline)
	{
		try {
			String x = prop.getProperty(beamline + ".dcssPort");
			if (x == null)
				return -1;
			if (x.length() == 0)
				return -1;
			return Integer.parseInt(x.trim());
		} catch (NumberFormatException e) {
			return -1;
		}
	}
	
	/*
	 * Only allowed class from this package to use 
	 * this method. Other classes should use method
	 * of the same name in Client class.
	 */
	static public String getUserImageRootDir(String u)
	{
		String tt = prop.getProperty("webice.userImageRootDir");
		if (tt == null)
			tt = "";
		return tt.replace("<user>", u);
	}
		
	static public String getProperty(String n)
	{
		return (String)prop.getProperty(n);
	}
		
	static public String getRequestPresetUrl(String bl, String cam)
	{
		return prop.getProperty(bl + ".video." + cam + ".presetRequestUrl");
	}
	
	static public String getMovePresetUrl(String bl, String cam)
	{

		return prop.getProperty(bl + ".video." + cam + ".moveRequestUrl");

	}
		
	static public String getVideoTextUrl(String bl, String cam)
	{

		return prop.getProperty(bl + ".video." + cam + ".textUrl");

	}
	
	
	static public String getVideoImageUrl(String bl, String cam)
	{
		System.out.println("getVideoImageUrl = " + bl + ".video." + cam + ".imageUrl");
		return prop.getProperty(bl + ".video." + cam + ".imageUrl");
	}
	
	static public String getDcsStrategyDir()
	{
		return (String)prop.getProperty("webice.dcsStrategyDir");
	}
	
	static public String getVideoHost(String bl)
	{
		String ret = prop.getProperty(bl + ".video.host");
		
		if (ret == null)
			return "localhost";
			
		return prop.getProperty("video.host");
	}
	
	static public int getVideoPort(String bl)
	{
		String ret = prop.getProperty(bl + ".video.port");
		
		if (ret == null)
			ret = prop.getProperty("video.port");
			
		if (ret == null)
			return 80;
			
		try {
			return Integer.parseInt(ret.trim());
		} catch (NumberFormatException e) {
			return 80;
		}
	}
	
	/**
	 * Weather or not to show collect 2-images option in autoindex run setup.
	 */
	static public boolean canCollect()
	{
		String tt = (String)prop.getProperty("webice.canCollect");
		if ((tt != null) && tt.equals("true"))
			return true;
			
		return false;
	}
	
	/**
	 * Webice user name. Used to connect to dcss to monitor beamline activities.
 	 */
	static public String getWebiceUser()
	{
		return (String)prop.getProperty("webice.user");
	}
	
	/**
	 * File containing webice session id. Used to connect to dcss to monitor beamline activities.
 	 */
	static public String getWebiceSessionFile()
	{
		return (String)prop.getProperty("webice.sessionFile");
	}
	
	/**
	 * File containing webice username and password in 64-bit encoding.
	 * username:passwd
 	 */
	static public String getWebicePasswdFile()
	{
		return (String)prop.getProperty("webice.passwdFile");
	}
	
	static public String getPeriodicTableFile()
	{
		return periodicTableFile;
	}
	
	static public String getCollectMonitorMode()
	{
		return collectMonitorMode;
	}
	
	static public String getInstallation()
	{
		return installation;
	}
		
	static public String getHelpUrl()
	{
		return (String)prop.getProperty("help.rootUrl");
	}
	
	static public String getDefaultUserPropertiesFile()
	{
		return defUserPropertiesFile;
	}
	
	/**
	 * Encrypt dcs connection?
	 */
	static public boolean isDcsUseSSL()
	{
		return getPropertyBoolean("dcs.useSSL", false);
	}
	
	static public String getDcsKeystoreFile()
	{
		return getProperty("dcs.keystoreFile");
	}
	
	static public String getDcsKeystorePassword()
	{
		return getProperty("dcs.keystorePassword");
	}
	
	static public String getTomcatHost()
	{
		return getProperty("webice.tomcatHost");
	}
	
	static public int getTomcatPort()
	{
		return getPropertyInt("webice.tomcatPort", 8080);
	}
	
	static public int getTomcatSecurePort()
	{
		return  getPropertyInt("webice.tomcatSecurePort", 8443);
	}
		
	static public int getOneTimeSessionMode()
	{
		return getPropertyInt("auth.oneTimeSessionMode", 0);
	}
	
	static public boolean getUseImgsrvCommand()
	{
		return getPropertyBoolean("imgsrv.useCommand", false);
	}

	static public String getImgsrvCommand()
	{
		return getProperty("imgsrv.command");
	}

	static public String getImgsrvCommandHost()
	{
		return getProperty("imgsrv.command.impHost");
	}

	static public int getImgsrvCommandPort()
	{
		return getPropertyInt("imgsrv.command.impPort", 0);
	}
}


