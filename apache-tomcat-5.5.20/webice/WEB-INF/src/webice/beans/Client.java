/**
 * Javabean for SMB resources
 */
package webice.beans;

import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;
import java.util.*;
import java.net.*;
import java.io.*;
import webice.beans.strategy.*;
import webice.beans.image.*;
import webice.beans.process.*;
import webice.beans.screening.*;
import webice.beans.autoindex.*;
import webice.beans.collect.*;
import webice.beans.video.*;
import webice.beans.dcs.*;

/**
 * @class Client
 * Represents a client for each session.
 */
public class Client implements DcsConnectorListener, PropertyListener
{

	/**
	 * SMB session info including SMB session id
	 * This is webice.beans.SMBGatewaySession
	 */
	private AuthGatewayBean userInfo = null;

	/**
	 * Image viewer
	 *
	 */
	private ImageViewer imageViewer = null;

	/**
	 * Process viewer
	 */
	private ProcessViewer procViewer = null;

	/**
	 * Autoindex and strategy viewer
	 */
	private StrategyViewer strategyViewer = null;

	/**
	 * Screening viewer
	 */
	private ScreeningViewer screeningViewer = null;

	/**
	 * Autoindex viewer
	 */
	private AutoindexViewer autoindexViewer = null;
	
	/**
	 */
	private VideoViewer videoViewer = null;

	/**
	 */
	private CollectViewer collectViewer = null;


	/**
	 * Object for interfacing with the impersonation server
	 */
	private Imperson imperson = null;

	/**
	 * Users configuration data.
	 */
	private WebIceProperties config = null;

	/**
	 * Current tab
	 */
	private String tab = "";

	/**
	 */
	private DcsConnector dcsConnector = null;

	/**
	 * Location of the user's configuration file
	 */
	private String propertyDir = "";
	private String propertyFile = "";

	/**
	 * Directory where this client can write output
	 * and intermediate files.
	 */
	private String defWorkDir = "";

	/**
	 */
	private String defGlobalImageDir = "";

	/**
	 */
	private String defImageFilters = "*.img *.mar* *.tif *.mccd *summary";

	/**
	 */
	private String helpTopic = "";

	/**
	 */
	private String bookmark = "";

	/**
	 */
	private Vector availableBeamlines = new Vector();

	/**
	 */
	private FileBrowser fileBrowser = null;


	private long lastCheck = 0;
	private long maxLastAccessTime = 60000;

	private String prefView = "general";
	
	
	private Random random = new Random(); // not quite truely random but it's ok 
	
	private String beamlineView = "selections";
	private String beamlineStatusView = "msg";

	/**
	 * Bean constructor
	 */
	public Client()
	{
		WebiceLogger.info("in Client::constructor");
	}

	/**
	 * Called when the client is garbage collected
	 */
	public void finalize()
	{
		try {
			logout();
			WebiceLogger.info("in Client::finalize");
		} catch (Exception e) {
			WebiceLogger.error("Client::finalize : " + this.toString()
							+ " " + new Date().toString()
							+ ": " + e.getMessage(), e);
		}
	}
	
	public void login(String uname, String password)
		throws NoPermissionException, Exception
	{
		
		WebiceLogger.info("in Client::login with username " + uname);
		AuthGatewayBean gate = new AuthGatewayBean();
		gate.initialize(ServerConfig.getAuthAppName(), uname, password, 
					ServerConfig.getAuthMethod(),
					ServerConfig.getAuthServletHost());
		
		login(gate);
	}

	/**
	 * The viewers become available only after the
	 * user has logged in.
	 */
	public void login(String sessionId)
		throws NoPermissionException, Exception
	{

		// Connect to the authentication server
		// and validate this session id
		WebiceLogger.info("in Client logging in with sessionId: " + sessionId);
		AuthGatewayBean gate = new AuthGatewayBean();
		gate.initialize(sessionId, ServerConfig.getAuthAppName(), 
				ServerConfig.getAuthServletHost());
		
		login(gate);
		WebiceLogger.info("in Client logged in with sessionId: " + sessionId + " " + getUser());
	}
	
	private boolean isTrue(String v)
	{
		if (v == null)
			return false;
			
		return (v.equalsIgnoreCase("true") || v.equalsIgnoreCase("yes") || v.equalsIgnoreCase("y") || v.equals("1"));
	}
	
	private void login(AuthGatewayBean gate)
		throws NoPermissionException, Exception
	{
		userInfo = gate;

		// Check if this user has a valid session id
		if (!getLoggedin())
			throw new Exception("Login failed for user + " + userInfo.getUserID()
								+ " sessionID "
								+ userInfo.getSessionID()
								+ ": " + userInfo.getUpdateError());
								
		Hashtable uProp = userInfo.getProperties();
		boolean userStaff = isTrue((String)uProp.get("Auth.UserStaff"));		

		// Disallow user for this webice instance
		if (!ServerConfig.isUserIncluded(getUser(), userStaff))
			throw new NoPermissionException();

		try {
			lastCheck = Long.parseLong(userInfo.getLastAccessTime());
		} catch (NumberFormatException e) {
			lastCheck = 0;
		}

		// This must be set before any remote
		// operation can be performed.
		// Setup the inpersonation server host and port
		imperson = new Imperson(userInfo, ServerConfig.getImpServerHost(), ServerConfig.getImpServerPort());

		WebiceLogger.info("Client logged in: user=" + getUser()
						+ " sessionId=" + getSessionId()
						+ " " + new Date().toString());

		// Setup the user's configuration file
		propertyDir = getUserConfigDir() + "/.webice";
		propertyFile = propertyDir + "/default.properties";

		WebiceLogger.info("Setting default properties for user " + getUser());
		setDefaultProperties();
		WebiceLogger.info("Loading user " + getUser() + " property file");
		
		try {

		// Load users info from remote property file
		// afterLoadProperties() callback of all listeners
		// will be call so that the viewers can update
		// their config.
		config = null;
		config = new WebIceProperties(getUser(), getUserRootDir(), getUserImageRootDir());
		config.load(imperson, propertyFile);
		
		} catch (Exception e) {
			WebiceLogger.error("Client login failed to load user's property file from " 
				+ propertyFile + ": " + e.getMessage(), e);
			throw e;
		}
		
		WebiceLogger.info("Loaded user " + getUser() + " property file");
		
		// Setup default tab for the display
		tab = getDefaultTab();
		setHelpTopic(tab);

		try {

		if (!imperson.dirExists(getWorkDir())) {
			imperson.createDirectory(getWorkDir());
		}
		
		} catch (Exception e) {
			WebiceLogger.error("Client login failed to find or create user's webice directory in " 
				+ getWorkDir() + ": " + e.getMessage(), e);
			throw e;
		}

		initBeamlines();
		WebiceLogger.info("Initialized beamlines for user " + getUser());

		// Create the viewers
		imageViewer = new ImageViewer(this);
		WebiceLogger.info("Created ImageViewer for user " + getUser());
		screeningViewer = new ScreeningViewer(this);
		WebiceLogger.info("Created ScreeningViewer for user " + getUser());
		autoindexViewer = new AutoindexViewer(this);
		WebiceLogger.info("Created AutoindexViewer for user " + getUser());
		ScreeningImageViewer anotherImageViewer = new ScreeningImageViewer(this, screeningViewer);
		WebiceLogger.info("Created ScreeningImageViewer for user " + getUser());
		screeningViewer.setImageViewer(anotherImageViewer);
		videoViewer = new VideoViewer(this);
		WebiceLogger.info("Created VideoViewer for user " + getUser());
		collectViewer = new CollectViewer(this);
		WebiceLogger.info("Created CollectViewer for user " + getUser());
		WebiceLogger.info("Created all views for user " + getUser());

		config.addListener(this);
		config.addListener(imageViewer);
		config.addListener(autoindexViewer);
		config.addListener(screeningViewer);
		config.addListener(videoViewer);
		config.addListener(collectViewer);

	}
	
	public Vector getAllRealBeamlines()
	{
		// List of all simulated beamlines
		// defined in webice.properties.
		Vector simBeamlines = getAllSimBeamlines();
		
		Hashtable uProp = userInfo.getProperties();
		String bb = (String)uProp.get("Auth.AllBeamlines");
		StringTokenizer tok = new StringTokenizer(bb, ";");
		Vector ret = new Vector();
		boolean found = false;
		while (tok.hasMoreTokens()) {
			found = false;
			String b = tok.nextToken();
			// Check if this beamline is defined as sim beamline
			// in webice.properties.
			for (int i = 0; i < simBeamlines.size(); ++i) {
				if (b.equals(simBeamlines.elementAt(i))) {	
					found = true;
					break;
				}
			}
			if (!found)
				ret.add(b);
		}
		
		return ret;
	}

	public Vector getAllSimBeamlines()
	{
		return ServerConfig.getBeamlines();
	}

	/**
	 */
	private void initBeamlines()
	{
		availableBeamlines.clear();
		
		TreeSet<String> sortedSet = new TreeSet<String>();
		
		Hashtable uProp = userInfo.getProperties();

		// Real beamlines
		String allBls = (String)uProp.get("Auth.AllBeamlines");
		String bls = (String)uProp.get("Auth.Beamlines");
		boolean hasAll = false;
		if (bls.contains("ALL")) {
			bls = allBls;
			hasAll = true;
		} else if (bls.equals("NONE")) {
			bls = "";
		}
		
		String bl = "";
		StringTokenizer tok = new StringTokenizer(bls, ";");
		while (tok.hasMoreTokens()) {
			bl = (String)tok.nextToken();
			sortedSet.add(bl);
//			availableBeamlines.add(bl);
		}
		
		// Make sure the simulated beamlines are also accessible
		// by webice if user's beamlines are ALL.
		if (hasAll) {			
			Vector simBls = DcsConnectionManager.getBeamlines();
			String simBl = "";
			for (int i = 0; i < simBls.size(); ++i) {
				simBl = (String)simBls.elementAt(i);
				for (int j = 0; j < availableBeamlines.size(); ++j) {
					bl = (String)availableBeamlines.elementAt(i);
					if (!simBl.equals(bl)) {
//						availableBeamlines.add(simBl);
						sortedSet.add(simBl);
						break;
					}
				}
			}
		}
		
		Iterator<String> it = sortedSet.iterator();
		while (it.hasNext()) {
			availableBeamlines.add(it.next());
		}

	}

	/**
	 * Returns user's login name
	 * @return user login name
	 */
	synchronized public String getUser()
	{
		if (userInfo != null)
			return userInfo.getUserID();
			
		return null;
	}
	
	/**
	 * Returns SMB session id
	 * @return Session id
	 */
	synchronized public String getSessionId()
	{
		if (userInfo != null)
			return userInfo.getSessionID();
			
		return null;
	}

	synchronized public String getUserName()
	{
		return (String)userInfo.getProperties().get("Auth.UserName");
	}
	synchronized public String getUserCreationTime()
	{
		return userInfo.getCreationTime();
	}
	synchronized public boolean getUserEnabled()
	{
		return isTrue((String)userInfo.getProperties().get("Auth.Enabled"));

	}
	synchronized public boolean isStaff()
	{
		return getUserStaff();
	}
	synchronized public boolean getUserStaff()
	{
		return isTrue((String)userInfo.getProperties().get("Auth.UserStaff"));
	}
	synchronized public boolean getUserRemoteAccess()
	{
		return isTrue((String)userInfo.getProperties().get("Auth.RemoteAccess"));
	}
	synchronized public String getUserBeamlines()
	{
		return (String)userInfo.getProperties().get("Auth.Beamlines");
	}

	/**
	 * Set method for tab.
	 * @param s Tab name.
	 */
	public void setTab(String s)
	{
		tab = s;
		setHelpTopic(tab);
		if (!tab.equals("preference") && !tab.equals("welcome"))
			setPreferenceView(tab);
	}

	/**
	 * Get method for tab.
	 * @return tab name
	 */
	public String getTab()
	{
		return tab;
	}
	
	public DcsConnector getDcsConnector()
	{
		return dcsConnector;
	}

	/**
	 */
	public boolean isConnectedToBeamline()
	{
		return (dcsConnector != null);
	}

	/**
	 * Check if the user has access permission
	 * to the beamline
	 */
	public boolean canAccessBeamline(String bl)
	{
		for (int i = 0; i < availableBeamlines.size(); ++i) {
			if (bl.equals(availableBeamlines.elementAt(i)))
				return true;
		}

		return false;
	}

	/**
	 * Connect this client to a beamline
	 */
	public void connectToBeamline(String bl)
		throws Exception
	{
		// connect but don't wait until dcss is ready
		connectToBeamline(bl, false);
	}
	
	/**
	 * Connect this client to a beamline
	 */
	public void connectToBeamline(String bl, boolean waitUntilReady)
		throws Exception
	{
		if (bl.length() == 0)
			return;

		// Make sure the user
		// has access permission for
		// the requested beamline
		if (!canAccessBeamline(bl))
			return;

		// If the user is already connected to
		// another beamline then disconnect.
		if (isConnectedToBeamline()) {
			if (getBeamline().equals(bl)) {
				// Do nothing if we are
				// already connected to the
				// requested beamline
				return;
			} else {
				// Disconnect from the current beamline
				// before connecting to the requested
				// beamline
				disconnect();
			}
		}
		
		try {

		// Get the connector for this beamline
		dcsConnector = DcsConnectionManager.getDcsConnector(bl);
		
		// Add this client as listener
		// Connect
		dcsConnector.addListener(this);

/*		if (waitUntilReady) {
			// Wait until dcss is ready
			int timeout = 15000;
			int timepassed = 0;
			int interval = 200;
			while (!dcsConnector.isDcssReady()) {
				if (timepassed > timeout) {
					WebiceLogger.info("Client " + getUser() + " connecting to beamline " + bl
							+ ": timeout before dcss is ready");
					break;
				}
				Thread.sleep(interval);
				timepassed += interval;
			}
		}*/
		
		WebiceLogger.info("Client " + getUser() + " connected to beamline " + bl);
		
		} catch (Exception e) {
			WebiceLogger.info("Client " + getUser() + " failed to connect to beamline " + bl + " because " + e.getMessage());
			dcsConnector = null;
			throw e;
		}


	}

	/**
	 */
	public String getLastImageCollected()
	{
		if (dcsConnector == null)
			return "";

		return dcsConnector.getLastImageCollected();
	}

	/**
	 */
	public boolean isScreening()
	{
		if (dcsConnector == null)
			return false;

		return dcsConnector.isScreening();
	}

	/**
	 */
	public String getScreeningSilId()
	{
		if (dcsConnector == null)
			return null;

		return dcsConnector.getSilId();
	}
	
	/**
	 */
	public ScreeningStatus getScreeningStatus()
		throws Exception
	{
		if (dcsConnector == null)
			return null;
			
		return dcsConnector.getScreeningStatus();
	}

	/**
	 * Get method for loggedin.
	 * @return True if user is logged in.
	 */
	synchronized public boolean getLoggedin()
	{
		return userInfo.isSessionValid();
	}

	/**
	 * Set method for beamline.
	 * @return Beamline name.
	 */
	public String getBeamline()
	{
		if (dcsConnector == null)
			return "";

		return dcsConnector.getBeamline();
	}

	/**
	 * Returns a list of beamlines available
	 * to this user, including the simulated
	 * beamlines.
	 */
	public Vector getAvailableBeamlines()
	{
		return availableBeamlines;
	}
	
	// DcsConnectorListener
	public void dcsUpdate()
	{
	}


	/**
	 * Returns ImageViewer
	 * @return ImageViewer
	 */
	public ImageViewer getImageViewer()
	{
		if (tab.equals("screening") && (screeningViewer != null))
			return screeningViewer.getImageViewer();

		if (tab.equals("image") && (imageViewer != null))
			 return imageViewer;

		if (tab.equals("collect") && (imageViewer != null))
			 return imageViewer;

		if (tab.equals("beamline") && (imageViewer != null))
			 return imageViewer;

		if (tab.equals("autoindex") && (imageViewer != null))
			 return autoindexViewer.getImageViewer();

		return null;
	}

	/**
	 * Returnsn ProcessViewer
	 * @return ProcessViewer
	 */
	public ProcessViewer getProcessViewer()
	{
		return procViewer;
	}

	/**
	 * Returns StrategyViewer
	 */
	public StrategyViewer getStrategyViewer()
	{
		return strategyViewer;
	}

	/**
	 * Returns AutoindexViewer
	 */
	public AutoindexViewer getAutoindexViewer()
	{
		return autoindexViewer;
	}

	/**
	 * Returns VideoViewer
	 */
	public VideoViewer getVideoViewer()
	{
		return videoViewer;
	}

	/**
	 * Returns ScreeningViewer
	 */
	public ScreeningViewer getScreeningViewer()
	{
		return screeningViewer;
	}
	
	/**
	 * Returns CollectViewer
	 */
	public CollectViewer getCollectViewer()
	{
		return collectViewer;
	}
	
	public String toString()
	{
		return "name=" + getUser() + ",session=" + getSessionId();
	}

	/**
	 * Disconnect from the beamline (if connected) and log out.
	 */
	public void logout()
		throws Exception
	{

		// Disconnect from the beamline
		disconnect();

		// Set tab to default
//		tab = getDefaultTab();

		WebiceLogger.info("Client logged out: user=" + getUser()
							+ " sessionId=" + getSessionId()
							+ " " + new Date().toString());
	}

	/**
	 * Disconnects from the beamline
	 */
	public void disconnect()
		throws Exception
	{
		if (dcsConnector == null)
			return;
			
		String bl = getBeamline();

		// Remove this client as listener
		dcsConnector.removeListener(this);
		dcsConnector = null;
		WebiceLogger.info("Client " + getUser() + " disconnected from beamline " + bl);
	}

	/**
	 * Returns the user's config file path
	 */
	public String getPropertyFile()
	{
		return propertyFile;
	}

	/**
	 * Returns the user's config
	 */
	public WebIceProperties getProperties()
	{
		return config;
	}

	/**
	 */
	private void setDefaultProperties()
	{
		defWorkDir = getUserRootDir() + "/webice";
		defGlobalImageDir = getUserImageRootDir();
		defImageFilters = "*.img *.mar* *.tif *.mccd *summary";
	}
	
	public String getUserRootDir()
	{
		String tt = (String)userInfo.getProperties().get("Auth.UserRootDir");
		if ((tt != null) && (tt.length() > 0))
			return tt;
			
		return ServerConfig.getUserRootDir(getUser());
	}

	public String getUserConfigDir()
	{
		String tt = (String)userInfo.getProperties().get("Auth.UserConfigDir");
		if ((tt != null) && (tt.length() > 0))
			return tt;
			
		return ServerConfig.getUserConfigDir(getUser());
	}

	public String getUserImageRootDir()
	{
		String tt = (String)userInfo.getProperties().get("Auth.UserImageRootDir");
		if ((tt != null) && (tt.length() > 0))
			return tt;
			
		return ServerConfig.getUserImageRootDir(getUser());
	}

	/**
	 */
	public void propertyChanged(String name, String val)
		throws Exception
	{
		if (name.equals("top.simBeamlines")) {
			// Reinitialize beamline list
			initBeamlines();
		}
	}

	/**
	 * Copy properties
	 */
	public void saveProperties(Map newProp)
		throws Exception
	{
		// Load config from map
		// All listeners will be notified
		// of the new config.
		config.load(newProp, true /*ignoreUnknown*/);
		
		// Save the current config
		// from all viewers.
		config.save(imperson, propertyFile);
	}

	/**
	 * Save the current config to file
	 */
	public void saveProperties()
		throws Exception
	{

		// Make sure dir exists before saving the file
		if (!imperson.fileExists(propertyDir)) {
			imperson.createDirectory(propertyDir);
		}


		String str = "";

		// Sort the property names alphabetically
		Enumeration en = config.propertyNames();
		TreeSet sortedKeys = new TreeSet();
		while (en.hasMoreElements()) {
			sortedKeys.add((String)en.nextElement());
		}

		// List them out
		Iterator it = sortedKeys.iterator();
		String name = "";
		String prev = "";
		String group = "";
		int pos = -1;
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
			str += name + "=" + (String)config.getProperty(name, "") + "\n";
			
			prev = group;
		}


		imperson.saveFile(propertyFile, str);


	}

	/**
	 * Returns work dir
	 */
	public String getWorkDir()
	{
		return getUserRootDir() + "/webice";
	}


	/**
	 */
	public String getImageDir()
	{
		String ret = config.getProperty("top.imageDir", "");
		if ((ret == null) || (ret.length() == 0))
			return defGlobalImageDir;

		return ret;
	}

	/**
	 */
	public void setImageDir(String s)
	{
		config.setProperty("top.imageDir", s);
	}

	/**
	 */
	public String getImageFilters()
	{
		return config.getProperty("top.imageFilters", defImageFilters);
	}

	/**
	 */
	public String getImageFiltersRegex()
	{
		String tmp = getImageFilters();
		StringTokenizer tok = new StringTokenizer(tmp, " ");
		// No filter
		if (tok.countTokens() == 0)
			return "";

		String regex = "";
		String s = "";
		String s1 = "";
		while (tok.hasMoreTokens()) {
			s = tok.nextToken(); s1 = "";
			for (int c = 0; c < s.length(); ++c) {
				if (s.charAt(c) == '*')
					s1 += ".*";
				else if (s.charAt(c) == '.')
					s1 += "\\.";
				else
					s1 += s.charAt(c);
			}
			if (regex.length() != 0)
				regex += "|";
			regex += "(" + s1 + ")";
		}

		return regex;

	}

	/**
	 */
	public void setImageFilters(String s)
	{
		config.setProperty("top.imageFilters", s);
	}


	/**
	 * Returns interface to impersonation server.
	 */
	public Imperson getImperson()
	{
		return imperson;
	}

	/**
	 */
	public String getHelpTopic()
	{
		return helpTopic;
	}

	/**
	 */
	public String getHelpBookmark()
	{
		return bookmark;
	}

	/**
	 */
	public void setHelpTopic(String s)
	{
		setHelpTopic(s, null);
	}

	/**
	 */
	public void setHelpTopic(String s, String b)
	{
		helpTopic = s;
		bookmark = b;

		if ((helpTopic == null) || (helpTopic.length() == 0)) {
			helpTopic = "general";
			bookmark = null;
		}


	}

	public FileBrowser getFileBrowser()
	{
		if (fileBrowser == null)
			fileBrowser = new FileBrowser(this);

		return fileBrowser;
	}

	/**
	 */
	synchronized public boolean validateSMBSession()
	{
		try {

			long curTime = (new Date()).getTime();
			// Only revalidate the session id with the authentication
			// server if the time passed is longer than
			// the maxLastAccessTime (1 minute).
			// Otherwise returns the latest status.
			long at = curTime - lastCheck;
			if (at < maxLastAccessTime)
				return true;

			lastCheck = new Date().getTime();

			// Save current beamline
			String curBl = getBeamline();

			String ss = userInfo.getSessionID();

			userInfo.updateSessionData(true);

			// SMB session id becomes invalid.
			// Need to log the user out of webice.
			if (!getLoggedin()) {
				WebiceLogger.info("validateSMBSession: SMB session "
						+ ss + " is invalid, logging user out of webice: idle time = "
						+ at/60000 + " minutes");
				logout();
				return false;
			}


			// Reinitialize list if beamlines
			// accessible by this user.
			initBeamlines();

			// Do nothing if this user is not
			// connected to a beamline
			if (!isConnectedToBeamline())
				return true;
			if ((curBl == null) || (curBl.length() == 0))
				return true;

			// Check if the user still has access
			// permission to current beamline.
			// If not then disconnect the current
			// beamline connection
			if (!canAccessBeamline(curBl))
				disconnect();

			return true;

		} catch (Exception e) {
			WebiceLogger.error("Exception in validateSMBSession: " + e.getMessage(), e);
			return false;
		}
	}
	
	public boolean showWelcomePage()
	{
		String p = config.getProperty("top.showWelcomePage", "true");
		if (p == null)
			return true;
			
		return isTrue(p);
	}

	public String getDefaultTab()
	{
		String def = config.getProperty("top.defaultTab", "welcome");
		if (def == null)
			def = "welcome";
			
		if (!showWelcomePage() && def.equals("welcome"))
			 return "preference";
			
		return def;
	}
	
	public String getPreferenceView()
	{
		return prefView;
	}
	
	public void setPreferenceView(String v)
	{
		if (v != null)
			prefView = v;
	}
	
	public int getRandomInt(int max)
	{
		if (max < 1)
			return random.nextInt(1);
			
		return random.nextInt(max);
	}
	
	public void setBeamlineView(String s)
	{
		if (s != null)
			beamlineView = s;
	}
	
	public String getBeamlineView()
	{
		return beamlineView;
	}
	
	public void setBeamlineStatusView(String s)
	{
		if (s != null)
			beamlineStatusView = s;
	}
	
	public String getBeamlineStatusView()
	{
		return beamlineStatusView;
	}
		
	/**
	 * Ask auth server to create a one-time session 
	 * from our existing session id.
	 */
	public String getOneTimeSession(String host)
		throws Exception
	{
		return imperson.getOneTimeSession(host);
	}

}

