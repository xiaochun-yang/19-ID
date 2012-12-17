/**
 * Javabean for SMB resources
 */
package webice.beans;

import java.util.*;
import java.io.*;


public class WebIceProperties extends Properties
{
	Vector listeners = new Vector();

	/**
	 * Constructor
	 */
	public WebIceProperties(String user, String userRootDir, String userImageDir)
	{		
		// Set default properties
		
		// top
		setProperty("top.imageDir", userImageDir);
		setProperty("top.imageFilters", "*.img *.mar* *.tif *.mccd *summary *.cbf");
		setProperty("top.showDataCollectionViewer", "true");
		setProperty("top.showImageViewer", "true");
		setProperty("top.showScreeningViewer", "true");
		setProperty("top.showStrategyViewer", "true");
		setProperty("top.showVideoViewer", "true");
		setProperty("top.simBeamlines", "");
		setProperty("top.showWelcomePage", "true");
		setProperty("top.defaultTab", "welcome");

		// image
		setProperty("image.centerX", "0.5");
		setProperty("image.centerY", "0.5");
		setProperty("image.gray", "400");
		setProperty("image.height", "400");
		setProperty("image.imageDir", userImageDir);
		setProperty("image.imageFile", "");
		setProperty("image.infoTab", "");
		setProperty("image.useGlobalImageDir", "true");
		setProperty("image.width", "400");
		setProperty("image.zoom", "1.0");
		setProperty("image.showSpots", "false");
		setProperty("image.autoAnalyzeImage", "false");

		// strategy
		setProperty("strategy.imageDir", userImageDir);
		setProperty("strategy.useGlobalImageDir", "true");

		// autoindex
		setProperty("autoindex.imageDir", userImageDir);
		setProperty("autoindex.useGlobalImageDir", "true");
		setProperty("autoindex.numRunsPerPage", "10");
		setProperty("autoindex.reverseAutoindexLog", "true");
		setProperty("autoindex.reverseDCSSLog", "false");
		setProperty("autoindex.scanUpdateRate", 4);
		setProperty("autoindex.runsSortBy", "name");
		setProperty("autoindex.runsSortAscending", "true");
		setProperty("autoindex.autoUpdateLog", "true");
		setProperty("autoindex.defaultStrategyMethod", "best");

		// screening
		setProperty("screening.centerX", "0.5");
		setProperty("screening.centerY", "0.5");
		setProperty("screening.gray", "400");
		setProperty("screening.height", "400");
		setProperty("screening.imageDir", userImageDir);
		setProperty("screening.imageFile", "");
		setProperty("screening.infoTab", "");
		setProperty("screening.useGlobalImageDir", "true");
		setProperty("screening.width", "400");
		setProperty("screening.zoom", "1.0");
		setProperty("screening.silId", "");
		setProperty("screening.displayMode", "details");
		// Either silList or dirList
		setProperty("screening.silListMode", "silList");
		setProperty("screening.displayTemplate", "display_result");
		setProperty("screening.displayOption", "hide");
		setProperty("screening.sortColumn", "Port");
		setProperty("screening.sortDirection", "ascending");
		setProperty("screening.autoUpdate", "true");
		setProperty("screening.autoUpdateRate", "10");
		
		// Video
		setProperty("video.currentCamera", "all"); // show all cameras
		setProperty("video.hutch.updateRate", 5); // update rate for hutch camera is 5 seconds	
		setProperty("video.control.updateRate", 5); // update rate for control panel camera is 5 seconds	
		setProperty("video.sample.updateRate", 5); // update rate for sample camera is 5 seconds	
		setProperty("video.fixed.updateRate", 5); // update rate for robot camera is 5 seconds

		// Beamline
		setProperty("beamline.autoUpdateLog", "true");
		setProperty("beamline.autoUpdateLogRate", "5");
		setProperty("beamline.statusUpdateRate", "5");
				
		// Override default properties with the ones
		// from file on the server. This allows 
		// setting different default properties
		// per webice installation site.
		loadDefaultProperties();
		
	}
	

	/**
	 * Load property from default file on the server.
	 * Ignore errors.
	 */
	public void loadDefaultProperties()
	{
		String propFile = ServerConfig.getDefaultUserPropertiesFile();
		try {

		// Load default properties from file
		FileInputStream stream = new FileInputStream(propFile);
		this.load(stream);
		stream.close();
		
		} catch (Exception e) {
			WebiceLogger.warn("WebiceProperties failed to load property file from " 
				+ propFile + " because " + e.getMessage());
		}
	}

	public void finalize()
	{
		// Remove all listeners
		listeners.clear();
	}

	/**
	 * Return sorted property keys
	 */
	public List getSortedKeys()
	{
		Enumeration en = super.propertyNames();
		Vector ret = new Vector();
		while (en.hasMoreElements()) {
			ret.add((String)en.nextElement());
		}
		Collections.sort(ret);

		return ret;
	}

	/**
	 * Convenient method for returning int property
	 */
	public int getPropertyInt(String name, int def)
	{
		try {
			return Integer.parseInt(getProperty(name, String.valueOf(def)));
		} catch (NumberFormatException e) {
			return def;
		}
	}

	/**
	 * Convenient method for returning double property
	 */
	public double getPropertyDouble(String name, double def)
	{
		try {
			return Double.parseDouble(getProperty(name, String.valueOf(def)));
		} catch (NumberFormatException e) {
			return def;
		}
	}

	/**
	 * Convenient method for returning boolean property
	 */
	public boolean getPropertyBoolean(String name, boolean def)
	{
		String s = getProperty(name, String.valueOf(def));
		return (s.equalsIgnoreCase("true") || s.equalsIgnoreCase("t")
			|| s.equalsIgnoreCase("yes") || s.equalsIgnoreCase("y")
			|| s.equalsIgnoreCase("1"));
	}

	/**
	 * Set int property
	 */
	public void setProperty(String name, int value)
	{
		setProperty(name, String.valueOf(value));
	}

	/**
	 * Set double property
	 */
	public void setProperty(String name, double value)
	{
		setProperty(name, String.valueOf(value));
	}

	/**
	 * Set boolean property
	 */
	public void setProperty(String name, boolean value)
	{
		setProperty(name, String.valueOf(value));
	}

	/**
	 * Override getProperty
	 */
	public String getProperty(String name, String def)
	{
		String ret = super.getProperty(name, def);

		boolean done = false;

		int pos1 = -1;
		int pos2 = -1;
		String sub = "";

		// Replace ${xxx} with property value of xxx
		while ((pos1=ret.indexOf("${")) >= 0) {

			pos2 = ret.indexOf("}", pos1+2);

			if (pos2 < 0)
				return ret;

			sub = super.getProperty(ret.substring(pos1+2, pos2), "");

			ret = ret.substring(0, pos1) + sub + ret.substring(pos2+1);
		}

		return ret;
	}

	/**
	 * Add listener
	 */
	void addListener(PropertyListener listener)
	{
		listeners.add(listener);
	}


	/**
	 * Load user's config from file
	 * If file does not already exist
	 * then create one from the current
	 * config.
	 */
	public void load(Imperson imperson, String propertyFile)
		throws Exception
	{

		// Make sure file name is set
		if ((propertyFile == null) || (propertyFile.length() == 0))
			throw new Exception("Invalid property file");

		// Check if property file exists
		// If not then create one
		if (!imperson.fileExists(propertyFile)) {
			// Save them to file
			save(imperson, propertyFile);
			return;
		}

		// File already exists then load it

//		InputStream stream = imperson.readFileStream(propertyFile);
//		if (stream == null)
//			throw new Exception("Failed to load config: null input stream");
		String content = imperson.readFile(propertyFile);
		ByteArrayInputStream stream = new ByteArrayInputStream(content.getBytes());

		this.load(stream);
		
		String filter = getProperty("top.imageFilters");
		if (filter != null)
			if (!filter.contains("*.mccd"))
				filter += " *.mccd";
			if (!filter.contains("*.cbf"))
				filter += " *.cbf";
			if (!filter.contains("*summary"))
				filter += " *summary";
		setProperty("top.imageFilters", filter);
		
		
		stream.close();
		stream = null;

	}


	/**
	 * Load config from map.
	 */
	public void load(Map newProp, boolean ignoreUnknown)
		throws Exception
	{
		Set keys = newProp.keySet();
		Iterator it = keys.iterator();
		String key = "";
		while (it.hasNext()) {
			key = (String)it.next();
			// Ignore the config we don't already have
			if (ignoreUnknown && (this.getProperty(key) == null))
				continue;
			this.setProperty(key, (String)newProp.get(key));
		}

	}

	/**
	 * Override Properties::setProperty
	 */
	public Object setProperty(String name, String val)
	{
		try {

		// Do nothing if the value is the same
		if (val.equals(getProperty(name)))
			return getProperty(name);

		Object ret = super.setProperty(name, val);

		notifyPropertyChanged(name, val);

		return ret;

		} catch (Exception e) {
			WebiceLogger.error("setProperty [name=" + name
								+ " value=" + val + "]: "
								+ e.getMessage());
			return null;
		}

	}


	/**
	 * Save the current config to file
	 */
	public void save(Imperson imperson, String propertyFile)
		throws Exception
	{

		// Only allow full path
		if (propertyFile.indexOf("./") == 0)
			throw new Exception("Failed to save webice config: relative file path not allowed");

		String propertyDir = "";
		int pos = propertyFile.lastIndexOf('/');
		if (pos > 0)
			propertyDir = propertyFile.substring(0, pos);

		// Make sure dir exists before saving the file
		if ((propertyDir.length() > 0) && !imperson.fileExists(propertyDir)) {
			imperson.createDirectory(propertyDir);
		}


		String str = "";

		// Sort the property names alphabetically
		Enumeration en = this.propertyNames();
		TreeSet sortedKeys = new TreeSet();
		while (en.hasMoreElements()) {
			sortedKeys.add((String)en.nextElement());
		}

		// List them out
		Iterator it = sortedKeys.iterator();
		String name = "";
		String prev = "";
		String group = "";
		pos = -1;
		while (it.hasNext()) {

			name = (String)it.next();

			// Check if this prop name is in
			// a different group as the previous one.
			pos = name.indexOf('.');
			if (pos > 0) {
				group = name.substring(0, pos);
			} else {
				group = name;
			}
			// add a comment line for the new group
			if (!prev.equals(group))
				str += "\n# " + group + " config group\n";

			// add the property
			str += name + "=" + (String)this.getProperty(name, "") + "\n";

			prev = group;
		}


		imperson.saveFile(propertyFile, str);


	}

	/**
	 * Notify listeners that the properties have been loaded from file.
	 */
	private void notifyPropertyChanged(String name, String val)
		throws Exception
	{
		for (int i = 0; i < listeners.size(); ++i) {
			PropertyListener listener = (PropertyListener)listeners.elementAt(i);
			listener.propertyChanged(name, val);
		}
	}

	static public boolean isTrue(String v)
	{
		if (v == null)
			return false;
			
		return (v.equalsIgnoreCase("true") || v.equalsIgnoreCase("t")
			|| v.equalsIgnoreCase("yes") || v.equalsIgnoreCase("y") 
			|| v.equals("1"));
	}
}


