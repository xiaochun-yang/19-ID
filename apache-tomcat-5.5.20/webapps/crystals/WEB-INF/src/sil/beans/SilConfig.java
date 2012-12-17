package sil.beans;

import java.util.StringTokenizer;
import java.util.Properties;
import java.util.Hashtable;
import java.util.Enumeration;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.FileNotFoundException;

public class SilConfig extends Properties
{
	private static SilConfig theConfig = null;

	private int authPort = -1;
	private int authSecurePort = -1;
	private int imgsrvPort = -1;
	private int impersonPort = -1;
	private int securedPort = -1;
	
	/**
	 * Beamline names
	 */
	Hashtable hash = new Hashtable();
	
	String crystalFields[] = null;
	String imageFields[] = null;

	/**
	 * Return the singleton.
	 */
	public static SilConfig getInstance()
	{
		return theConfig;
	}

	public static SilConfig createSilConfig(String filePath)
		throws IOException, FileNotFoundException
	{
		theConfig = new SilConfig();

		theConfig.load(filePath);

		return theConfig;

	}

	private SilConfig()
	{
		setProperty("rootDir", "");
		setProperty("templateDir", "");
		setProperty("cassetteDir", "");
		setProperty("beamlineDir", "");
		setProperty("getCassetteURL", "");
		setProperty("cassetteInfoURL", "");
		setProperty("authenticateURL", "");
		setProperty("excel2xmlMethod", "jexcel");
		setProperty("excel2XmlURL", "");

		setProperty("auth.host", "");
		setProperty("auth.port", "");
		setProperty("auth.gatewayUrl", "");
		setProperty("auth.loginUrl", "");

		setProperty("imgsrv.host", "");
		setProperty("imgsrv.port", "");
		setProperty("clearSrcCrystal", "false");

		hash.put("SMBDCSDEV", "SMBDCSDEV");
		hash.put("SMBLX6", "SMBLX6");
		hash.put("SMBLX4", "SMBLX4");
		hash.put("BL92SIM", "BL92SIM");
		hash.put("BLCTL113", "BL11-3");
		hash.put("BL113", "BL11-3");
		hash.put("BL13", "BL11-3");
		hash.put("BL11-3", "BL11-3");
		hash.put("11-3", "BL11-3");
		hash.put("113", "BL11-3");
		hash.put("13", "BL11-3");
		hash.put("BLCTL111", "BL11-1");
		hash.put("BL111", "BL11-1");
		hash.put("BL11", "BL11-1");
		hash.put("BL11-1", "BL11-1");
		hash.put("11-1", "BL11-1");
		hash.put("111", "BL11-1");
		hash.put("11", "BL11-1");
		hash.put("BLCTL92", "BL9-2");
		hash.put("BL92", "BL9-2");
		hash.put("BL9-2", "BL9-2");
		hash.put("9-2", "BL9-2");
		hash.put("92", "BL9-2");
		hash.put("BLCTL91", "BL9-1");
		hash.put("BL91", "BL9-1");
		hash.put("BL9-1", "BL9-1");
		hash.put("9-1", "BL9-1");
		hash.put("91", "BL9-1");
		hash.put("BLCTL15", "BL1-5");
		hash.put("BL1-5", "BL1-5");
		hash.put("BL15", "BL1-5");
		hash.put("1-5", "BL1-5");
		hash.put("15", "BL1-5");
		hash.put("BL-sim", "BL-SIM");
		hash.put("BL-SIM", "BL-SIM");
		hash.put("BL_simple1", "BL-SIMPLE1");
		hash.put("BL_SIMPLE1", "BL_SIMPLE1");

	}

	public void load(String filePath)
		throws IOException, FileNotFoundException
	{
		FileInputStream stream = new FileInputStream(filePath);
		
		SilLogger.info("SiLConfig: loading " + filePath);

		Properties prop = new Properties();

		try {
			load(stream);
			stream.close();
			stream = null;
		} catch (IOException e) {
			SilLogger.warn("SiLConfig: failed to load config file " + filePath);		
			if (stream != null)
				stream.close();
			stream = null;
			throw e;
		}
		
		String tt = getProperty("crystal.fields");
		if (tt != null) {
			StringTokenizer tok = new StringTokenizer(tt, ", ");
			crystalFields = new String[tok.countTokens()];
			int i = 0;
			while (tok.hasMoreTokens()) {
				crystalFields[i] = tok.nextToken();
				++i;
			}
		}
		tt = getProperty("crystal.image.fields");
		if (tt != null) {
			StringTokenizer tok = new StringTokenizer(tt, ", ");
			imageFields = new String[tok.countTokens()];
			int i = 0;
			while (tok.hasMoreTokens()) {
				imageFields[i] = tok.nextToken();
				++i;
			}
		}

		// Load additional properties from file specified as dbFile in config.prop
		try {
			Properties db = new Properties();
			int pos = filePath.lastIndexOf('/');
			String fname = (String)this.get("dbFile");
			if ((fname == null) || (fname.length() == 0))
				fname = "db.txt";
			fname = filePath.substring(0, pos) + "/" + fname;
			stream = new FileInputStream(fname);
			db.load(stream);
			stream.close();
			stream = null;
			Enumeration en = db.propertyNames();
     			for (;en.hasMoreElements();) {
				String pname = (String)en.nextElement();
        			this.setProperty(pname, (String)db.get(pname));
     			}
									
		} catch (IOException e) {
			SilLogger.warn("SiLConfig: caught IO Exception: " + e.getMessage());
			if (stream != null)
				stream.close();
			stream = null;
			throw e;
		}
		
		authPort = Integer.parseInt((String)get("auth.port"));
		authSecurePort = Integer.parseInt((String)get("auth.securePort"));
		imgsrvPort = Integer.parseInt((String)get("imgsrv.port"));
		impersonPort = Integer.parseInt((String)get("imperson.port"));
		securedPort = Integer.parseInt((String)get("securedPort"));		
		
		SilLogger.info("SiLConfig: auth.port = " + authPort + " auth.securePort = " + authSecurePort);
		
	}

	/**
	 */
	public String getRootDir()
	{
		return (String)get("rootDir");
	}

	public String getTemplateDir()
	{
		return (String)get("templateDir");
	}

	public String getCassetteDir()
	{
		return (String)get("cassetteDir");
	}

	public String getBeamlineDir()
	{
		return (String)get("beamlineDir");
	}

	public String getCassetteURL()
	{
		return (String)get("getCassetteURL");
	}

	public String getCassetteInfoURL()
	{
		return (String)get("cassetteInfoURL");
	}

	public String getAuthenticateURL()
	{
		return (String)get("authenticateURL");
	}

	public String getExcel2xmlMethod()
	{
		return (String)get("excel2xmlMethod");
	}


	public String getExcel2xmlURL()
	{
		return (String)get("excel2xmlURL");
	}

	/**
	 * Get authentication mthod name
	 */
	public String getAuthMethodName()
	{
		return (String)get("auth.method");
	}

	/**
	 * Get authentication server host
	 */
	public String getAuthServerHost()
	{
		return (String)get("auth.host");
	}

	/**
	 * Get authentication server port
	 */
	public int getAuthServerPort()
	{
		return authPort;

	}

	/**
	 * Get authentication server secure port
	 */
	public int getAuthServerSecurePort()
	{
		return authSecurePort;

	}

	/**
	 * Get secured port of this server
	 */
	public int getSecuredPort()
	{
		return securedPort;

	}

	/**
	 * Get image server host
	 */
	public String getImgServerHost()
	{
		return (String)get("imgsrv.host");
	}

	/**
	 * Get image server port
	 */
	public int getImgServerPort()
	{
		return imgsrvPort;

	}

	/**
	 * Get imperson server host
	 */
	public String getImpServerHost()
	{
		return (String)get("imperson.host");
	}

	/**
	 * Get imperson server port
	 */
	public int getImpServerPort()
	{
		return impersonPort;

	}

	/**
	 * Get authentication servletHost
	 */
	public String getAuthServletHost()
	{
		String scheme = "http";
		String p = "";
		if (getAuthServerPort() > 0)
			p = ":" + String.valueOf(getAuthServerPort());
		if (getAuthServerSecurePort() > 0) {
			scheme = "https";
			p = ":" + String.valueOf(getAuthServerSecurePort());
		}
		return scheme + "://" + getAuthServerHost() + p;
	}

	/**
	 * Get authentication gateway url
	 */
	public String getAuthGatewayUrl()
	{
		return (String)get("auth.gatewayUrl");
	}
	/**
	 * Get authentication gateway url
	 */
	public String getAuthLoginUrl()
	{
		return (String)get("auth.loginUrl");
	}

	/**
	 */
	public String getBeamlineName(String alias)
	{
		if (alias == null)
			return "";

		if (alias.length() == 0)
			return "";

		String ret = (String)hash.get(alias.toUpperCase());
		
		if (ret != null)
			return ret;
			
		return alias;

	}

	/**
	 */
	public String getSilDtdUrl()
	{
		return (String)get("silDtdURL");
	}

	/**
	 */
	public String getSilDtd()
	{
		return (String)get("silDtd");
	}
	
	public String[] getCrystalFields()
	{
		return crystalFields;
	}
	
	public String[] getImageFields()
	{
		return imageFields;
	}
	
	public String getBadXlsDir()
	{
		return (String)get("badXlsDir");
	}
	
	public String getAdminEmails()
	{
		return (String)get("adminEmails");
	}
	
	public boolean getClearSrcCrystal()
	{
		return Boolean.parseBoolean((String)get("moveCrystal.clearSrcCrystal"));
	}

}
