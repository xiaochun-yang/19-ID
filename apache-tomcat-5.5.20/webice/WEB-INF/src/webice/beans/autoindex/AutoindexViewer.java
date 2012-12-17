/**
 * Javabean for SMB resources
 */
package webice.beans.autoindex;

import webice.beans.*;
import java.net.*;
import java.io.*;
import java.util.*;
import webice.beans.dcs.*;
import webice.beans.image.ImageViewer;

import org.apache.xerces.dom.DocumentImpl;
import org.apache.xerces.dom.DOMImplementationImpl;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.*;

/**
 * @class AutoindexViewer
 * Bean class that represents an autoindex viewer.
 */
public class AutoindexViewer implements PropertyListener
{
	public static String ALL_RUNS = "allRuns";
	public static String ONE_RUN = "oneRun";
	public static String CREATE_RUN = "createRun";
	
	public static String USER_RUNS = "user";
	public static String BEAMLINE_RUNS = "beamline";
	
	public static String RUN_TYPE_AUTOINDEX = "autoindex";
	public static String RUN_TYPE_COLLECT = "collect";
	
	public static String RUNDEF_EXPORT = "Export to Blu-Ice";
	public static String RUNDEF_RECOLLECT = "Recollect Test Images";
	public static String RUNDEF_COLLECT = "Collect Dataset";
	public static String RUNDEF_QUEUE = "Send to Queue";
	public static String RUNDEF_ADD = "Add";
	public static String RUNDEF_REPLACE = "Replace";

	private static final String allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890-_";

	/**
	 * Client
	 */
	private Client client = null;

	/**
	 * Last image dir
	 */
	private String defImageDir = "";

	private boolean defUseGlobalImageDir = true;
	private String defStrategyMethod = "best";

	private FileBrowser fileBrowser = null;

	private AutoindexRun selectedRun = null;

	private FileBrowser outputFileBrowser = null;

	private String displayMode = ALL_RUNS;

	private TreeMap<String, FileInfo> runDirs = null;
	private TreeMap<String, FileInfo> beamlineRunDirs = null;
	
	private boolean showMountedCrystal = false;
	
	private String prevCrystalRunName = "";
	
	private String runListType = USER_RUNS;
	
	private int runPage = 1;
	private int numPages = 0;
	private int defRunsPerPage = 10;
		
	private String silSortColumn = "Port";
	public String silSortDirection = "ascending";
	
	private PeriodicTable table = new PeriodicTable();
	
	static public String SORTBY_NAME = "name";
	static public String SORTBY_CTIME = "ctime";
	
	private boolean sortAscending = true;
	
	/**
	 * Bean constructor
	 */
	public AutoindexViewer()
		throws Exception
	{
		init();
	}

	/**
	 * Constructor
	 */
	public AutoindexViewer(Client c)
		throws Exception
	{
		client = c;

		init();
	}

	/**
	 * Initializes variables
	 */
	private void init()
		throws Exception
	{
		defImageDir = "/data/" + client.getUser();
		defUseGlobalImageDir = true;

		if (isUseGlobalImageDir())
			fileBrowser = client.getFileBrowser();
		else
			fileBrowser = new FileBrowser(client);

		Imperson imp = client.getImperson();
		if (!imp.dirExists(getWorkDir()))
			imp.createDirectory(getWorkDir());

		outputFileBrowser = new FileBrowser(client);
		outputFileBrowser.setShowImageFilesOnly(false);
		
		table.load(ServerConfig.getPeriodicTableFile());

	}

	/**
	 * Callback when a config value is changed
	 */
	public void propertyChanged(String name, String val)
		throws Exception
	{
		// Work dir has changed
		if (name.equals("top.workDir")) {
			// Create webice top dir
			if (!client.getImperson().dirExists(getWorkDir())) {
				client.getImperson().createDirectory(getWorkDir());
			}
		} else if (name.equals("top.imageDir") && isUseGlobalImageDir()) {
			setImageDir(val);
		}
/*		} else if (name.equals("autoindex.useGlobalImageDir")) {
			if (isUseGlobalImageDir())
				fileBrowser = client.getFileBrowser();
			else if (fileBrowser == client.getFileBrowser())
				fileBrowser = new FileBrowser(client);
		}*/
	}
	
	public PeriodicTable getPeriodicTable()
	{
		return table;
	}

	/**
	 * Return the top work dir of this viewer
	 */
	public String getWorkDir()
	{

		return client.getWorkDir() + "/autoindex";
	}
	

	/**
	 * Return the client this viewer is associated with
	 */
	public Client getClient()
	{
		return client;
	}

	/**
	 * Set the client
	 */
	public void setClient(Client c)
	{
		client = c;
	}

	/**
	 */
	public FileBrowser getFileBrowser()
	{
		if (isUseGlobalImageDir())
			return client.getFileBrowser();
			
		return fileBrowser;
	}

	/**
	 */
	private boolean isUseGlobalImageDir()
	{
		return client.getProperties().getPropertyBoolean("autoindex.useGlobalImageDir", defUseGlobalImageDir);
	};

	/**
	 */
	public String getImageDir()
	{

		if (isUseGlobalImageDir())
			return client.getImageDir();

		return client.getProperties().getProperty("autoindex.imageDir", defImageDir);
	}

	/**
	 */
	public void setImageDir(String s)
	{

		client.getProperties().setProperty("autoindex.imageDir", s);
		if (!s.equals(client.getImageDir()) && isUseGlobalImageDir())
			client.setImageDir(s);

	}
	
	/**
	 */
	public String getDefaultStrategyMethod()
	{
		return client.getProperties().getProperty("autoindex.defaultStrategyMethod", defStrategyMethod);
	}
	
	/**
	 */
	synchronized public boolean isLoaded()
	{
		return (runDirs != null);
	}

	/**
	 * Remove run of the given name
	 * @param run name
	 */
	public void removeRun(String name)
		throws Exception
	{
		client.getImperson().deleteDirectory(getRunDir(name));

	}

	/**
	 * Do not select any run.
	 */
	public void unselectRun()
	{
		if (selectedRun != null)
			selectedRun.stopMonitoring();
		selectedRun = null;
		setDisplayMode(ALL_RUNS);

	}
	
	private String getRunDir(String name)
	{
		if ((getBeamlineRunDirs() != null) && client.isConnectedToBeamline() && getBeamlineRunDirs().containsKey(name))
			return ServerConfig.getDcsStrategyDir() + "/" + client.getBeamline() + "/" + name;
			
		return getWorkDir() + "/" + name;
	}

	/**
	 * Info for of only one run is loaded at a time.
	 * The previously selected run is unloaded.
	 * Cannot selected null run. Use unselectRun()
	 * to unselect a run.
	 */
	public void selectRun(String name)
		throws Exception
	{
		if (name == null)
			return;
			
		// Do nothing if selecting the same run.
		if ((selectedRun != null) && name.equals(selectedRun.getRunName())) {
			setDisplayMode(ONE_RUN);
			gotoPageOfSelectedRun();
			return;
		}
		

		if (selectedRun != null)
			selectedRun.stopMonitoring();
		selectedRun = null;

		selectedRun = new AutoindexRun(this, name, getRunDir(name));

		// Load status and results.
		selectedRun.load();

		outputFileBrowser.changeDirectory(selectedRun.getWorkDir(), null, true);
	
		setDisplayMode(ONE_RUN);
		gotoPageOfSelectedRun();

	}

	/**
	 */
	public AutoindexRun getSelectedRun()
	{
		return selectedRun;
	}

	/**
	 */
	public void setDisplayMode(String m)
	{
		displayMode = m;
	}


	/**
	 */
	public String getDisplayMode()
	{
		if ((selectedRun == null) && (displayMode == ONE_RUN)) {
			displayMode = ALL_RUNS;
		}

		return displayMode;
	}

	/**
	 */
	public String getSelectedRunTab()
	{
		if (selectedRun == null)
			return null;
		return selectedRun.getSelectedTab();
	}

	/**
	 */
	public void selectRunTab(String tab)
	{
		if (selectedRun != null)
			selectedRun.selectTab(tab);
	}

	
	/**
	 * Returns run names
	 * Each run is a sub directory under /data/<user>/webice/autoindex.
	 */
	public TreeSet<FileInfo> getRunList()
		throws Exception
	{
		return getRunList(getRunListType());
	}
		
	/**
	 * Returns run names
	 * Each run is a sub directory under /data/<user>/webice/autoindex.
	 */
	public TreeSet<FileInfo> getRunList(String type)
		throws Exception
	{
		TreeMap<String, FileInfo> map = null;
		if (type.equals(USER_RUNS))
			map = getRunDirs();
		else
			map = getBeamlineRunDirs();
						
		return sortRuns(map);
		
	}

	/**
	 * Returns run names
	 * Each run is a sub directory under /data/<user>/webice/autoindex.
	 */
	synchronized private TreeMap<String, FileInfo> getRunDirs()
		throws Exception
	{
		if (runDirs == null)
			loadRuns_();
			
		return runDirs;
	}

	/**
	 * Returns run names
	 * Each run is a sub directory under <dcsStrategyDir>/<beamline>.
	 */
	synchronized private TreeMap<String, FileInfo> getBeamlineRunDirs()
	{
		return beamlineRunDirs;
	}
	
	public String getRunRootDir(String type)
	{
		if (type.equals(USER_RUNS))
			return getWorkDir();
			
		String bl = client.getBeamline();
		if (bl == null)
			bl = "";
		return ServerConfig.getDcsStrategyDir() + "/" + bl;
	}
	
	public String getRunRootDir()
	{
		return getRunRootDir(getRunListType());
	}
	

	/**
	 */
	synchronized public void loadRuns()
		throws Exception
	{
		loadRuns_();
	}
	
	/**
	 */
	public void loadRuns_()
		throws Exception
	{
		if (runDirs == null)
			runDirs = new TreeMap<String, FileInfo>();

		runDirs.clear();

		// Include symbolic link dir
		boolean includeSymlinks = true;
		client.getImperson().listDirectory(getWorkDir(), null, runDirs, null, includeSymlinks);
				
		if (beamlineRunDirs == null)
			beamlineRunDirs = new TreeMap<String, FileInfo>();

		beamlineRunDirs.clear();
		
		if (client.isConnectedToBeamline()) {
			String bdir = "";
			try {
			// Include symbolic link dir
			includeSymlinks = true;
			bdir = ServerConfig.getDcsStrategyDir() + "/" + client.getBeamline();
			client.getImperson().listDirectory(bdir, null, beamlineRunDirs, null, includeSymlinks);
			} catch (Exception e) {
				WebiceLogger.error("Failed list runs from " + bdir + ": " + e.getMessage());
				beamlineRunDirs.clear();
			}
		}
		
		if (selectedRun != null) {
			String nn = selectedRun.getRunName();
			if ((runDirs.get(nn) == null) &&
			    (beamlineRunDirs.get(nn) == null)) {
			    unselectRun();
			}
		}
	}


	/**
	 */
	public FileBrowser getOutputFileBrowser()
	{
		return outputFileBrowser;
	}


	/**
	 */
	private boolean runExists(String runName)
		throws Exception
	{
		boolean ret = getRunDirs().containsKey(runName);
		
		if (!ret && (getBeamlineRunDirs() != null) && client.isConnectedToBeamline())
			return getBeamlineRunDirs().containsKey(runName);
			
		return ret;
	}
	
	public void setRunListType(String s)
	{
		String prev = runListType;
		
		if (s.equals(USER_RUNS))
			runListType = s;
		else if (s.equals(BEAMLINE_RUNS) && client.isConnectedToBeamline())
			runListType = s;
		else
			runListType = USER_RUNS;
			
//		if (!prev.equals(runListType))
//			setRunPage(1);
		
	}
	
	public String getRunListType()
	{	
		if (!client.isConnectedToBeamline())
			runListType = USER_RUNS;
		return runListType;
	}


	/**
	 * Create a new run
	 */
	synchronized public void createRun(String s, String t)
		throws Exception
	{

		if ((s == null) || (s.length() == 0))
			throw new Exception("invalid run name");
			
		if ((t == null) || (t.length() == 0))
			t = RUN_TYPE_AUTOINDEX;
			
		if (!t.equals(RUN_TYPE_AUTOINDEX) && !t.equals(RUN_TYPE_COLLECT))
			t = RUN_TYPE_AUTOINDEX;

		for (int i = 0; i < s.length(); ++i) {
			if (allowed.indexOf(s.charAt(i)) < 0) {
				throw new Exception("name contains invalid characters");
			}
		}

		// Create subdir
		String subdir = getWorkDir() + "/" + s;

		// Check if dir already exists
		// Don't mess up with it
		if (client.getImperson().dirExists(subdir))
			throw new Exception("dir " + subdir + " already exists");
			
		WebiceLogger.info("Client " + client.getUser() + " creating autoindex run " + s);

		// Create the dir
		client.getImperson().createDirectory(subdir);
		
		String input_file = "";
		String output_file = "";
		if (t.equals(RUN_TYPE_COLLECT)) {
			input_file = ServerConfig.getScriptDir() + "/collect_input.xml";
			output_file = subdir + "/collect.xml";
		} else {
		        input_file = ServerConfig.getScriptDir() + "/autoindex_input.xml";
			output_file = subdir + "/input.xml";
		}

	        // Copy input file fromt emplate
		client.getImperson().copyFile(input_file, output_file);

		// Select the run
		selectRun(s);
		
		AutoindexRun rr = getSelectedRun();
		RunController cc = rr.getRunController();
		AutoindexSetupData dd = rr.getRunController().getSetupData();
		
		// Set strategy method to the one in the user's preferences.
		dd.setStrategyMethod(getDefaultStrategyMethod());

		if (t.equals(RUN_TYPE_COLLECT)) {
			dd.setCollectImages(true);
			dd.setBeamline(client.getBeamline());
		} else {
			dd.setCollectImages(false);
			cc.setSetupStep(RunController.SETUP_CHOOSE_DIR);
		}

		loadRuns();
				
	}
	
	private TreeSet<FileInfo> sortRuns(TreeMap<String, FileInfo> map)
	{
		String sortBy = getSortBy();
		boolean ascending = isSortAscending();
		TreeSet<FileInfo> ret = new TreeSet<FileInfo>(new FileInfoComparator(sortBy, ascending));
		Iterator it = map.values().iterator();
		while (it.hasNext()) {
			FileInfo run = (FileInfo)it.next();
			ret.add(run);
		}
		
		return ret;
	}
	
	public void gotoPageOfSelectedRun()
		throws Exception
	{
	
		if (selectedRun == null)
			return;
			
						
		String run_name = selectedRun.getRunName();
				
		// Find it in user's run list
		TreeMap<String, FileInfo> map = getRunDirs();
		if (map.get(run_name) != null) {
		
		TreeSet<FileInfo> sortedSet = sortRuns(map);
		
		// Select run page that contains this new run
		// Find the run in  user's run list	
		Iterator it = sortedSet.iterator();
		int count = 0;
		while (it.hasNext()) {
			++count;
			FileInfo run = (FileInfo)it.next();
			if (run_name.equals(run.name)) {
				int which_page = count/getRunsPerPage();
				int remaining = count % getRunsPerPage();
				if (remaining > 0)
					which_page++;
				setRunPage(which_page);
				runListType = USER_RUNS;
				return;
			}
		}
		
		}
			
		// Select run page that contains this new run
		// Find the run in  user's run list
		map = getBeamlineRunDirs();
		if ((map != null) && (map.get(run_name) != null)) {
		
		TreeSet<FileInfo> sortedSet = sortRuns(map);
		Iterator it = sortedSet.iterator();
		int count = 0;
		while (it.hasNext()) {
			++count;
			FileInfo run = (FileInfo)it.next();
			if (run_name.equals(run.name)) {
				int which_page = count/getRunsPerPage();
				int remaining = count % getRunsPerPage();
				if (remaining > 0)
					which_page++;
				setRunPage(which_page);
				runListType = BEAMLINE_RUNS;
				return;
			}
		}
		
		}	
				
	}
	/**
	 * Delete a run
	 */
	public void deleteRun(String s)
		throws Exception
	{
		deleteRun(s, true);
	}

	/**
	 * Delete a run
	 */
	public void deleteRun(String s, boolean checkStatus)
		throws Exception
	{
		try {
		String subdir = getWorkDir() + "/" + s;

		Hashtable stat = client.getImperson().getFileStatus(subdir);
		String impFileExists = (String)stat.get("impFileExists");
		
		if ((impFileExists != null) && impFileExists.equals("true")) {
		
			if (checkStatus) {
			
			String impFilePathReal = (String)stat.get("impFilePathReal");
			boolean isSymlink = (impFilePathReal != null);
			// It's symlink if impFilePathReal is valid.
			if (!isSymlink) {
				boolean running = false;
				try {
					// Check if the script is running
					running = isRunning(s);
				} catch (Exception e) {
					throw new Exception("failed to check run status: " + e.getMessage());
				}
				if (running)
					throw new Exception(s + " is running.");
			
			} else {
				WebiceLogger.info("deleteRun: unlink dir " + s);
			}
			
			} // checkStatus
		
		}
				
		// Unselect this run if it has been selected.
		String ss = null;
		if (getSelectedRun() != null)
			ss = getSelectedRun().getRunName();
		if (s.equals(ss)) {
			unselectRun();
		}

		// If the dir is a symlink then simply unlink it.
		// The actual dir will not be deleted.


		// delete the dir
		client.getImperson().deleteDirectory(subdir);

		// Reload all runs
		loadRuns();
		
		} catch (Exception e) {
			WebiceLogger.error("Failed in deleteRun: " + e.getMessage());
			throw e;
		}


	}
	
	/**
	 * Create a new run with the info of the currently mounted crystal.
 	 */
	public void loadMountedCrystal()
		throws Exception
	{
		// throw an error if the user is not connected to the beamline.
		
		// Throw an error if currently there is no mounted crystal
		
		// Find the mounted crystal's silId, and row.
		
		// Get crystal info from the crystal server
		// Extract directory info
		
		// Create symbolic link in webice/autoindex/<silId>_<crystalId> 
		// to the actual dir of the crystal.
		
		// reload the run list
		
		// Select this new run.
		
	}

	/**
	 */
	private boolean isRunning(String aRun)
		throws Exception
	{
		RunStatus st = RunController.getRunStatus(client.getImperson(),
				getWorkDir() + "/" + aRun,
				client.getUserConfigDir());

		return st.isRunning();
	}
	
	public void importRun(String silId, String port, String crystalId, int repositionId,
				String autoindexDir)
		throws Exception
	{
		WebiceLogger.info("Client " + client.getUser() + " importing autoindex run from screening SIL ID = " + silId
					+ " port = " + port + " crystalId = " + crystalId
					+ " repositionId = " + repositionId
					+ " autoindexDir = " + autoindexDir);
		
		String rName = "_" + silId + "_" + port + "_" + crystalId + "_position" + String.valueOf(repositionId);
		
		importRun(rName, autoindexDir);
		
	}
		/**
	 * Create a symbolic link for dir under webice/autoindex refering to 
	 * realDir, which contains autoindex results.
 	 */
	public void importRun(String silId, String port, String crystalId,
				String autoindexDir)
		throws Exception
	{
		String rName = "unknown";
		
		WebiceLogger.info("Client " + client.getUser() + " importing autoindex run from screening SIL ID = " + silId
					+ " port = " + port + " crysyalId = " + crystalId);
		
		// Check if we only allow importing run from
		// mounted crystal only.
		// If so, check if the requested crystal is mounted
		// to the selected beamline
		if (ServerConfig.getImportRunMode().equals("all")) {

		rName = "_" + silId + "_" + port + "_" + crystalId;

		} else {
		
 		if (!client.isConnectedToBeamline()) 
			throw new Exception("Client not connected to a beamline");
    		DcsConnector dcs = client.getDcsConnector();
     		if (dcs == null)
 			throw new Exception("Client not connected to a beamline");
    			
		String cassetteOwner = "";
 		ScreeningStatus stat = dcs.getScreeningStatus();
		if (stat.row < 0)
			throw new Exception("Cannot get screening status from dcs");
		
		SequenceDeviceState ss = dcs.getSequenceDeviceState();
		int curCassetteIndex = ss.cassetteIndex;
		CassetteInfo info = ss.cassette[curCassetteIndex];
		cassetteOwner = info.owner;
		if (!cassetteOwner.equals(client.getUser()))
			throw new Exception("User " + client.getUser()
					+ " is not the cassette owner (" 
					+ cassetteOwner + ")");
					
		rName = stat.silId + "_" + port + "_" + crystalId;
				
		}
		
		importRun(rName, autoindexDir);
		
	}
	
	public void importRun(String aRun, String realDir)
		throws Exception
	{
		if ((aRun == null) || (aRun.length() == 0))
			throw new Exception("invalid run name");
		if ((realDir == null) || (realDir.length() == 0))
			throw new Exception("invalid import directory name");

		for (int i = 0; i < aRun.length(); ++i) {
			if (allowed.indexOf(aRun.charAt(i)) < 0) {
				throw new Exception("run name contains invalid characters");
			}
		}

		if (!client.getImperson().dirExists(realDir))
			throw new Exception("screening result dir " + realDir + " does not exist");

		// Create subdir
		String symlinkDir = getWorkDir() + "/" + aRun;
		String prevSymlnkDir = getWorkDir() + "/" + prevCrystalRunName;
		
		Imperson imp = client.getImperson();

		if (ServerConfig.getImportRunMode().equals("all")
			&& (prevCrystalRunName.length() > 0)
			&& !aRun.equals(prevCrystalRunName)) {
			try {
			WebiceLogger.info("Deleting dir " + prevSymlnkDir);
			imp.deleteDirectory(prevSymlnkDir);
			} catch (Exception e) {
				WebiceLogger.warn("Failed to delete symbolic link dir of previously viewed run (" 
						+ prevCrystalRunName + "): " 
						+ prevSymlnkDir); 
			}
		}
		
		WebiceLogger.info("in importRun: run name + " + aRun
				+ " real dir = " + realDir
				+ " symlink dir = " + symlinkDir);

		// Check if dir already exists
		if (!imp.dirExists(symlinkDir)) {
			// Create a symbolic link to the actual screening
			// result dir.
			imp.createSymLink(realDir, symlinkDir);
			prevCrystalRunName = aRun;
			
			// Wait for the symlink to appear, in case there is 
			// a delay in the file system
			int waitTotal = 0;
			int waitMax = 30000; // 30 seconds
			int waitInterval = 2000; // 2 seconds
			while (waitTotal < waitMax) {
				if (imp.dirExists(symlinkDir))
					break;
				WebiceLogger.info("AutoindexViewer: importRun waiting for symlink " 
						+ symlinkDir + " to become available");
				Thread.sleep(waitInterval);
				waitTotal += waitInterval;
			}
			
			if (waitTotal > waitMax)
				throw new Exception("Cannot find symbolic link dir " 
						+ symlinkDir
						+ " for " + realDir
						+ " after " + (waitTotal/1000) + " seconds");
		}


		// Select the run
		selectRun(aRun);
		// Display strategy tab
		selectRunTab("strategy");

		loadRuns();
	}
	
	/**
	 * Used to get data of the mounted crystal
	 * Crystal data is used when importing a mounted crystal as autoindex run.
 	 */
	public Hashtable getCrystalData(String silId, int row)
		throws Exception
	{
		if (row < 0)
			throw new Exception("Invalid row " + row);
			
		// Read the log file generated by the
		// spot finder program
		String urlStr = ServerConfig.getSilGetCrystalUrl()
					+ "?userName=" + client.getUser()
					+ "&SMBSessionID=" + client.getSessionId()
					+ "&silId=" + silId
					+ "&row=" + row
					+ "&format=xml";


		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200) {
			con.disconnect();
			if (response == 551) {
				con.disconnect();
				throw new NullClientException("getCrystalData failed for silId "
						+ silId + " row = " + row + ": " 
						+ String.valueOf(response) + " "
						+ con.getResponseMessage());
			} else {
				con.disconnect();
				throw new Exception("getCrystalData failed for silId "
						+ silId + " row = " + row + ": " 
						+ con.getResponseMessage()
						+ " (for " + urlStr + ")\n");
			}
		}

/*		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		char buf[] = new char[5000];
		int num = 0;
		StringBuffer strBuf = new StringBuffer();
		while ((num=reader.read(buf, 0, 5000)) >= 0) {
			if (num > 0)
				strBuf.append(buf, 0, num);
		}
		buf = null;
		
		reader.close();
		con.disconnect();*/

		//Instantiate a DocumentBuilderFactory.
		javax.xml.parsers.DocumentBuilderFactory dFactory =
					javax.xml.parsers.DocumentBuilderFactory.newInstance();
		dFactory.setValidating(false);
	
		//Use the DocumentBuilderFactory to create a DocumentBuilder.
		javax.xml.parsers.DocumentBuilder dBuilder = dFactory.newDocumentBuilder();
		
		Document doc = null;
		try {
			//Use the DocumentBuilder to parse the XML input.
			doc = dBuilder.parse(con.getInputStream());
		} catch (Exception e) {
			WebiceLogger.error("Failed to parse xml data: url = " + urlStr, e);
			con.disconnect();
			throw e;
		}
		con.disconnect();
		
		/////////////////////////////////////////
				
		Hashtable ret = new Hashtable();
		ret.put("Port", "unknown");
		ret.put("CrystalID", "unknown");
		ret.put("AutoindexDir", "unknown");

		// Get crystal data from the crystal server.
		Element crystalEl = doc.getDocumentElement();				
		
		Element node = getFirstChildElement(crystalEl, "Port");
		if (node == null)
			throw new Exception("cannot find Port for current crystal data: " + crystalEl.toString());
			
		String port = node.getFirstChild().getNodeValue();
		ret.put("Port", port);
		
		node = getFirstChildElement(crystalEl, "CrystalID");
		if (node == null)
			throw new Exception("cannot find CrystalID for current crystal data: " + crystalEl.toString());
		String crystalId = node.getFirstChild().getNodeValue();
		ret.put("CrystalID", crystalId);
		
		String autoindexDir = "";
		node = getFirstChildElement(crystalEl, "AutoindexDir");
		if (node != null) {
			Node child = node.getFirstChild();
			if (child != null) {
				autoindexDir = child.getNodeValue();
				ret.put("AutoindexDir", autoindexDir);
			}
		} 
		
		if (autoindexDir.length() == 0) {
			autoindexDir = getDefaultAutoindexDir(silId, crystalId);
			ret.put("AutoindexDir", autoindexDir);
			
		}
				
		return ret;
		
				
	}
	

	private String getDefaultAutoindexDir(String sil_id, String crystal_id)
	{
		return client.getUserRootDir() 
				+ "/webice/screening/" + sil_id
				+ "/" + crystal_id + "/autoindex";
	}
	
	private Element getFirstChildElement(Element parent, String childName)
	{
		NodeList ll = parent.getElementsByTagName(childName);
		if ((ll == null) || (ll.getLength() == 0))
			return null;
		
		return (Element)ll.item(0);
	}
	
	public void setShowMountedCrystal(boolean b)
	{
		showMountedCrystal = b;
	}
	
	public boolean isShowMountedCrystal()
	{
		return showMountedCrystal;
	}
	
	/**
	 * Send run definition to dcss
	 */
	public void exportDcsRunDefinition(RunDefinition def)
		throws Exception
	{
		selectedRun.getRunController().exportDcsRunDefinition(def);
		
	}
	
	// Called from ExportRunDefinition.java
	public void sendRunDefToQueue(AutoindexSetupData data, RunDefinition def, boolean replace) throws Exception {
	
		if (selectedRun == null)
			throw new Exception("No run is selected");
		if ((selectedRun.getSilId() == null) || (selectedRun.getSilId().length() == 0))
			throw new Exception("This run is not associated with a sil");
		if (selectedRun.getRow() < 0)
			throw new Exception("This run is not associated with a row in a sil");
		if (selectedRun.getRepositionId() < 0)
			throw new Exception("This run is not associated with a reposition id");
//		AutoindexSetupData data = viewer.getSelectedRun().getRunController().getSetupData();
		// Make sure that this run is from a sil.
/*		if ((data.getSilId() == null) || (data.getSilId().length() == 0))
			throw new Exception("No sil data associated with this run");
		if ((data.getCrystalPort() == null) || (data.getCrystalPort().length() == 0))
			throw new Exception("No crystal port associated with this run");
		if ((data.getCrystalId() == null) || (data.getCrystalId().length() == 0))
			throw new Exception("No crystal ID associated with this run");*/
		// Send a request to the crystals server
		// to add this run def to the list of 
		// run definition for the crystal.
		
		StringBuffer form = new StringBuffer();
		form.append("userName=" + client.getUser());
		form.append("&SMBSessionID=" + client.getSessionId());
		form.append("&silId=" + selectedRun.getSilId());
		form.append("&row=" + selectedRun.getRow());
		form.append("&file_root=" + def.fileRoot);
		form.append("&directory=" + def.directory);
		form.append("&start_frame=" + def.startFrame);
		form.append("&axis_motor=" + def.axisMotorName);
		form.append("&start_angle=" + def.startAngle);
		form.append("&end_angle=" + def.endAngle);
		form.append("&delta=" + def.delta);
		form.append("&wedge_size=" + def.wedgeSize);
//		form.append("&dose_mode=" + def.doseMode);
		form.append("&attenuation=" + def.attenuation);
		form.append("&exposure_time=" + def.exposureTime);
		form.append("&distance=" + def.distance);
		form.append("&beam_stop=" + def.beamStop);
		form.append("&num_energy=" + def.numEnergy);
		form.append("&energy1=" + def.energy1);
		form.append("&energy2=" + def.energy2);
		form.append("&energy3=" + def.energy3);
		form.append("&energy4=" + def.energy4);
		form.append("&energy5=" + def.energy5);
		form.append("&detector_mode=" + def.detectorMode);
		form.append("&inverse_on=" + def.inverse);
		form.append("&repositionId=" + selectedRun.getRepositionId());
		
		String urlStr;
		if (replace) {
			urlStr = ServerConfig.getSetRunDefinitionUrl();
			form.append("&runIndex=" + selectedRun.getRunIndex());
		} else {
			urlStr = ServerConfig.getAddRunDefinitionUrl();
		}		
		
		String content = form.toString();
		
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setDoOutput(true);
		con.setRequestMethod("POST");
		con.setRequestProperty("Content-Length", String.valueOf(content.length()));
		con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");


		OutputStreamWriter writer = new OutputStreamWriter(con.getOutputStream());
		writer.write(content, 0, content.length());
		writer.flush();
		writer.close();
		
		int response = con.getResponseCode();
		if (response != 200) {
			con.disconnect();
			if (response == 551) {
				con.disconnect();
				throw new NullClientException("addRunDefinition failed for silId "
						+ selectedRun.getSilId() + " row = " + selectedRun.getRow() + ": " 
						+ String.valueOf(response) + " "
						+ con.getResponseMessage());
			} else {
				con.disconnect();
				throw new Exception("addRunDefinition failed for silId "
						+ selectedRun.getSilId() + " row = " + selectedRun.getRow() + ": " 
						+ con.getResponseMessage()
						+ " (for " + urlStr + ")\n");
			}
		}
	}
	
	/**
	 * Send run definition to dcss
	 */
	public void recollectTestImages(CollectWebParam param)
		throws Exception
	{
		selectedRun.getRunController().recollectTestImages(param);
		selectedRun.selectTab(AutoindexRun.TAB_SETUP);
	}
	
	/**
	 * Send run definition to dcss
	 */
	public void collectDataset(CollectWebParam param)
		throws Exception
	{
		selectedRun.getRunController().collectDataset(param);	
	}
	
	public int getRunPage()
	{
		return runPage;
	}
	
	public void setRunPage(int p)
	{
		runPage = p;
		
		if (runPage <= 0)
			runPage = 1;
	}
	
	public int getRunsPerPage()
	{
		return client.getProperties().getPropertyInt("autoindex.numRunsPerPage", defRunsPerPage);
	}
	
	public void setRunPerPage(int i)
	{		
		if (i < 1)
			i = 20;
			
		client.getProperties().setProperty("autoindex.numRunsPerPage", String.valueOf(i));
	}
	
	public int getNumPages()
		throws Exception
	{
		int total = 0;
		if (runListType.equals(USER_RUNS)) 
			total = getRunDirs().size();
		else
			total = getBeamlineRunDirs().size();
			
		int num = total/getRunsPerPage();
		int remaining = total % getRunsPerPage();
		
		if (remaining >  0)
			num++;
			
		return num;
	}
	
	public void setReverseAutoindexLog(boolean s)
	{
		client.getProperties().setProperty("autoindex.reverseAutoindexLog", s);
	}
	
	public boolean isReverseAutoindexLog()
	{
		return WebIceProperties.isTrue(client.getProperties().getProperty("autoindex.reverseAutoindexLog"));
	}
	
	public void setReverseDCSSLog(boolean s)
	{
		client.getProperties().setProperty("autoindex.reverseDCSSLog", s);
	}
	
	public boolean isReverseDcssLog()
	{
		return WebIceProperties.isTrue(client.getProperties().getProperty("autoindex.reverseDCSSLog"));
	}
	
	public String getSilSortColumn()
	{
		return silSortColumn;
	}
	
	/**
	 * Toggle between ascending/decending
	 */
	public void setSilSortColumn(String s)
	{
		if (s == null)
			return;
			
		if (silSortColumn.length() == 0)
			silSortColumn = "Port";

		if (!s.equals(silSortColumn)) {	
			silSortColumn = s;	
			silSortDirection = "ascending";
		} else {
			if (silSortDirection.equals("descending"))
				silSortDirection = "ascending";
			else
				silSortDirection = "descending";
		}
	}
	
	public String getSilSortDirection()
	{
		return silSortDirection;
	}
	
	/**
	 */
	public void validate(RunDefinition def, RunDefinition defOrg)
		throws Exception
	{
		if (selectedRun == null)
			throw new Exception("No run has been selected");
			
		selectedRun.getRunController().validate(def, defOrg);
	}
	
	public ImageViewer getImageViewer()
	{
		if (selectedRun == null)
			return null;
			
		return selectedRun.getImageViewer();
	}
	
	public String getSortBy()
	{
		return client.getProperties().getProperty("autoindex.runsSortBy", SORTBY_NAME);
	}
	
	public void setSortBy(String sortBy)
	{		
		if (sortBy.equals(SORTBY_NAME))
			client.getProperties().setProperty("autoindex.runsSortBy", SORTBY_NAME);
		else if (sortBy.equals(SORTBY_CTIME))
			client.getProperties().setProperty("autoindex.runsSortBy", SORTBY_CTIME);
	}
	
	public boolean isSortAscending()
	{
		return client.getProperties().getPropertyBoolean("autoindex.runsSortAscending", true);
	}
	
	public void setSortAscending(boolean s)
	{
		client.getProperties().setProperty("autoindex.runsSortAscending", s);
	}
	
	public boolean isAutoUpdateLog()
	{
		return client.getProperties().getPropertyBoolean("autoindex.autoUpdateLog", true);
	}
	
	// Whether to automatically update autoindex log
	public void setAutoUpdateLog(boolean s)
	{
		client.getProperties().setProperty("autoindex.autoUpdateLog", s);
	}
	
	private class FileInfoComparator implements Comparator
	{
		// 1 = by name
		// 2 = by ctime
		private int sortBy = 1;
		private boolean ascending = true;
		public FileInfoComparator(String s, boolean a)
		{
			if (s.equals("name"))
				sortBy = 1;
			else if (s.equals("ctime"))
				sortBy = 2;
			else
				sortBy = 1;
				
			ascending = a;
		}
		
		public int compare(Object l, Object r)
		{
			FileInfo left = (FileInfo)l;
			FileInfo right = (FileInfo)r;
			if (sortBy == 2) {
				int ret = compareByCtime(left, right);
				if (ret != 0)
					return ret;
				return compareByName(left, right);
			} else { // default is sort by name
				return compareByName(left, right);
			}
		}
		
		private int compareByName(FileInfo left, FileInfo right)
		{
			if (ascending)
				return left.name.compareTo(right.name);
			else
				return (-1)*left.name.compareTo(right.name);
		}
		
		private int compareByCtime(FileInfo left, FileInfo right)
		{
			if (ascending)
				return (int)(left.ctime - right.ctime);
			else
				return (int)(right.ctime - left.ctime);
		}
		
		public boolean equals(Object other)
		{
			return (other instanceof FileInfoComparator);
		}
	}
	
}


