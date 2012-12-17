/**
 * Javabean for SMB resources
 */
package webice.beans.autoindex;

import webice.beans.*;
import java.util.*;
import java.io.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import java.net.*;

import webice.beans.dcs.*;
/**
 * @class StrategyViewer
 * Bean class that represents a process viewer. Holds parameters for setting
 * up a display for data processing.
 */
public class RunController
{

	/**
	 * Status names for this node
	 * TODO: should we move this to NavNode?
	 */
	public static final int SETUP = 10;
	public static final int READY = 20;
	public static final int COLLECT_NOT_START = 21;
	public static final int COLLECT_START = 22;
	public static final int COLLECT_RUNNING = 23;
	public static final int COLLECT_FINISH = 24;
	public static final int AUTOINDEX_RUNNING = 25;
	public static final int LABELIT_RUNNING = 26;
	public static final int LABELIT_FINISH = 27;
	public static final int INTEGRATION_RUNNING = 28;
	public static final int INTEGRATION_FINISH = 29;
	public static final int STRATEGY_RUNNING = 30;
	public static final int STRATEGY_FINISH = 31;
	public static final int AUTOINDEX_FINISH = 40;
	public static final int ADDITONAL_INTEGRATION_RUNNING = 50;
	public static final int ADDITONAL_INTEGRATION_FINISH = 60;
	public static final int FINISH = 60;
	public static final int ERROR = 80;
	public static final int ABORT = 80;
		
	public static final int SETUP_START = 1;
	public static final int SETUP_CHOOSE_RUN_TYPE = 1;
	public static final int SETUP_CHOOSE_SAMPLE = 2;
	public static final int SETUP_CHOOSE_DIR = 3;
	public static final int SETUP_CHOOSE_STRATEGY_OPTION = 4;
	public static final int SETUP_CHOOSE_EXP = 5;
	public static final int SETUP_CHOOSE_OPTIONS = 6;
	public static final int SETUP_FINISH = 7;


	private int status = SETUP;
	private String statusString = "";
		
	/**
	 * AutoindexRun
	 */
	private AutoindexRun run = null;

	/**
	 * Client
	 */
	private Client client = null;


	/**
	 */
	private String definitionFile = "input.xml";

	/**
	 */
	private String log = "";

	/**
	 */
	private String runLog = "";


	private boolean aborted = false;

	/**
	 * Editable setup data. Used during setup
	 */
	private AutoindexSetupData setupData = new AutoindexSetupData();

	/**
 	 */
	private RunStatus autoindexRunStatus = new RunStatus();

	/**
	 */
	private boolean setupDone = false;

	/**
	 */
	private boolean hasAutoindexLog = false;

	/**
	 */
	private boolean supportOldVersion = true;

	/**
	 */
	private boolean isLoaded = false;

	/**
	 */
	private boolean labelitDone = false;

	/**
	 */
	private boolean integrationDone = false;

	/**
	 */
	private boolean strategyDone = false;

	/**
	 */
	private boolean autoindexDone = false;


	/**
	 */
	private boolean additionalIntegrationDone = false;


	private boolean useApplet = false;

	/**
	 */
	private MonitorThread runMonitor = null;
	
	private int setupStep = 1;
	
	private boolean collectFileLoaded = false;
	private boolean autoindexFileLoaded = false;
	
	private CollectMsgString collectMsg = new CollectMsgString();
	
	private ImageHeader header1 = null;
	private ImageHeader header2 = null;
	
	/**
	 * Constructor
	 */
	public RunController(AutoindexRun run, Client client)
		throws Exception
	{

		this.run = run;
		this.client = client;

		// Delay loading
		isLoaded = false;
		collectFileLoaded = false;
		autoindexFileLoaded = false;
		
	}

	/**
	 */
	public void finalize()
	{
		stopMonitoring();
	}


	/**
	 * Load if needed
	 */
	public void load()
		throws Exception
	{
		load(false);
	}

	private void load(boolean force)
		throws Exception
	{
		if (isLoaded && !force)
			return;

		log = "";
		runLog = "";
		aborted = false;
		isLoaded = true;
		hasAutoindexLog = false;
		labelitDone = false;
		integrationDone = false;
		strategyDone = false;
		autoindexDone = false;
		additionalIntegrationDone = false;
		setStatus(SETUP);
		setStatusString("");
		collectFileLoaded = false;
		autoindexFileLoaded = false;

		// Load definition file
		// And setup input
		loadSetup();
		
		try {
		
		// Get run status
		if (getStatus() >= READY)
			updateRunStatus();
		
		} catch (CollectOutNotFoundException e) {
			if (setupData.isCollectImages())
				setStatus(READY);	
		} catch (ControlTxtNotFoundException e) {
			if (!setupData.isCollectImages())
				setStatus(READY);
		} catch (Exception e) {
			setStatusString(e.getMessage());
			setStatus(ERROR);
		}

		// Somebody else has started this run.
		// We will just monitor it.
		if ((getStatus() == COLLECT_RUNNING) || autoindexRunStatus.isRunning()) {
			startMonitoring();
		}

	}
	

    /**
     */
    public boolean loadCollectFile()
    	throws LoadCollectXmlException
    {
	String collectFile = run.getWorkDir() + "/collect.xml";

	try {
	
	// Try to open collect.xml
	if (!client.getImperson().fileExists(collectFile)) {
	    throw new Exception("file does not exist");
	}

	String url = getRunDefinitionFileUrl(client.getImperson(), collectFile);
	AutoindexSetupSerializer.load(url, setupData);

	setupData.setCollectImages(true);
	
	// Check if we have all the required data
	if (setupData.validate()) {
	    setSetupStep(SETUP_FINISH);
	    setupDone = true;
	    setStatus(READY);
	} else {
	    setSetupStep(SETUP_CHOOSE_SAMPLE);
	    setStatus(SETUP);
	}

	collectFileLoaded = true;
	return true;

	} catch (Exception e) {
	    throw new LoadCollectXmlException("Cannot find or load " + collectFile + " because " + e.getMessage());
	}

    }
    
    /**
     */
    public void validate(RunDefinition def, RunDefinition defOrg)
    	throws Exception
    {
	DcsConnector dcs = client.getDcsConnector();
	if (dcs == null)
		throw new Exception("Client is not connected to beamline " + setupData.getBeamline());
		
	if (!dcs.getBeamline().equals(setupData.getBeamline())) {
		if (setupData.getBeamline().equals("default"))
			throw new Exception("This strategy was generated off-line (with default beamline parameters) and cannot be used at beamline "
					+ dcs.getBeamline());
		else
			throw new Exception("This strategy was generated for beamline " + setupData.getBeamline() +
					" and cannot be used at beamline " + dcs.getBeamline());
	}
					
	// Check limits
	// Detector distance
	StepperMotorDevice dev = dcs.getDetectorDistanceDevice();
	if (dev == null)
		throw new Exception("Failed to get detector_z device from DCSS");
	
	if ((def.distance < dev.getLowerLimit()) || (def.distance > dev.getUpperLimit()))
		throw new Exception("Detector distance "+ def.distance + " is outside limits, lower=" + 
			dev.getLowerLimit() + ", upper=" + dev.getUpperLimit());
	
	// Energy	
	PseudoMotorDevice dev1 = dcs.getEnergyDevice();		
	if (dev1 == null)
		throw new Exception("Failed to get energy device from DCSS");
		
	if ((def.energy1 != 0.0) && (def.energy1 < dev1.getLowerLimit()) || (def.energy1 > dev1.getUpperLimit()))
		throw new Exception("Energy "+ def.energy1 + " is outside limits, lower=" + 
			dev1.getLowerLimit() + "eV, upper=" + dev1.getUpperLimit() + " eV.");
		
	if ((def.energy2 != 0.0) && (def.energy2 < dev1.getLowerLimit()) || (def.energy2 > dev1.getUpperLimit()))
		throw new Exception("Energy "+ def.energy2 + " is outside limits, lower=" + 
			dev1.getLowerLimit()+ "eV, upper=" + dev1.getUpperLimit() + " eV.");

	if ((def.energy3 != 0.0) && (def.energy3 < dev1.getLowerLimit()) || (def.energy3 > dev1.getUpperLimit()))
		throw new Exception("Energy "+ def.energy3 + " is outside limits, lower=" + 
			dev1.getLowerLimit() + "eV, upper=" + dev1.getUpperLimit() + " eV.");
		
	// Beamstop	
	dev = dcs.getBeamStopDevice();
	if (dev == null)
		throw new Exception("Failed to get beamstop device from DCSS");
		
	if ((def.beamStop < dev.getLowerLimit()) || (def.beamStop > dev.getUpperLimit()))
		throw new Exception("Beamstop "+ def.beamStop + " is outside limits, lower=" + 
			dev.getLowerLimit() + ", upper=" + dev.getUpperLimit());
	
	double oscRange = def.endAngle - def.startAngle;
	if (oscRange < 0.0)
		oscRange *= -1.0;
	if (oscRange == 0.0)
		throw new Exception("Total oscillation range is 0.");

	//Attenuation
	CollectDefault colDef = dcs.getCollectDefault();
	double attenuation = def.attenuation;
	if ((attenuation < 0.0) || (attenuation >= 100.0))
	    throw new Exception("Beam attenuation must be positive and less than 100%");
	if (attenuation < colDef.getMinAttenuation())
		throw new Exception("Attenuation (" + attenuation 
		+ " %) is lower than minimum attenuation allowed at the beamline ("
		+ colDef.getMinAttenuation() + "%).");
	if (attenuation > colDef.getMaxAttenuation())
		throw new Exception("Attenuation (" + attenuation 
		+ " %) is higher than maximum attenuation allowed at the beamline ("
		+ colDef.getMaxAttenuation() + " %).");	
	
	
	// Oscillation angle cannot be more than osc range or osc wedge.
	if (def.delta <= 0)
		throw new Exception("Oscillation angle " + def.delta + " is out of bound.");
	if (def.delta > oscRange)
		throw new Exception("Oscillation angle " + def.delta + " is bigger than total oscillation range (" + oscRange + ").");
	if (def.delta > def.wedgeSize)
		throw new Exception("Oscillation angle " + def.delta + " is bigger than oscillation wedge (" + def.wedgeSize + ").");
		
	// If delta is modified, then scale exposure time accordingly
	if (def.delta != defOrg.delta)
		def.exposureTime = defOrg.exposureTime*(def.delta/defOrg.delta);
	
	// Motor software limits and phi speed should be verified if the user edits the exposure time, 
	// detector distance, beamstop distance or energy
	StepperMotorDevice phi = dcs.getGonioPhiDevice();
	double expTimePerDegree = def.exposureTime/def.delta;
	double diff = expTimePerDegree - (phi.getScaleFactor()/phi.getSpeed());
	double min_phi_exposure = def.delta*phi.getScaleFactor()/phi.getSpeed();
	if (def.exposureTime < min_phi_exposure) {
		throw new Exception("The new exposure time " + def.exposureTime 
				+ " seconds is too short for gonio phi speed. Decrease oscillation angle to " 
				+ min_phi_exposure + " seconds.");
	}
	
	if (def.exposureTime < colDef.getMinExposureTime())
		throw new Exception("Exposure time (" + def.exposureTime 
		+ " seconds) is shorter than minimum exposure time allowed at the beamline (" 
		+ colDef.getMinExposureTime() + " seconds).");
	if (def.exposureTime > colDef.getMaxExposureTime())
		throw new Exception("Exposure time (" + def.exposureTime 
		+ " seconds) is longer than max exposure time allowed at the beamline (" 
		+ colDef.getMaxExposureTime() + " seconds).");
		
	// Calculate detector mode given the exposure time and current detector type
	def.detectorMode = dcs.getDetectorMode(def.exposureTime);
	
	
    }
    
    
    /**
     */
    public void loadAutoindexSetupFile()
    	throws LoadInputXmlException
    {
    
 	String runDefFile = run.getWorkDir() + "/" + definitionFile;

   	try {

		// Try to open input.xml. If not found then try to open autoindex.xml.
		// If neither can be found then throw an exception.
		// If only autoindex.xml can be found, then read it and
		// save it as to input.xml for next time.
		if (!client.getImperson().fileExists(runDefFile)) {
			throw new Exception("file does not exist");
		}

		String url = getRunDefinitionFileUrl(client.getImperson(), runDefFile);
		AutoindexSetupSerializer.load(url, setupData);

		// Check if we have all the required data
		if (setupData.validate()) {
	    		setSetupStep(SETUP_FINISH);
			setupDone = true;
			setStatus(READY);
		} else {
			setSetupStep(SETUP_CHOOSE_DIR);
			setStatus(SETUP);
		}
		
		autoindexFileLoaded = true;
			
 	} catch (Exception e) {
	    throw new LoadInputXmlException("Cannot find or load " + runDefFile + " because " + e.getMessage());
	}
   }

	/**
	 * Load up run definition and results if they exist.
	 * Need to set imageDir and list of images
	 */
	public void loadSetup()
		throws Exception
	{
		InputStream stream = null;
		try {

			setupDone = false;
			setStatus(SETUP);

			setupData.setRunName(run.getRunName());
			setupData.setImageDir(run.getDefaultImageDir());
			
			try {

			// Try to load collect.xml
			// If the file exists, it means setupData.isCollectImages is true.
			loadCollectFile();
			
			} catch (LoadCollectXmlException e) {
				setupData.setCollectImages(false);
			}
						
			// If collect.xml does not exist or cannot be loaded
			// then try to load input.xml
			if (!setupData.isCollectImages())
				loadAutoindexSetupFile();
			

		} catch (Exception e) {
			WebiceLogger.warn("Failed in loadSetup: " + e.getMessage());
			setLog("ERROR: " + e.getMessage() + "\n");
		}
	}
	
	/**
 	 */
	public static String getRunDefinitionFileUrl(Imperson imp, String runDefFile)
	{
		return "http://" + imp.getHost() + ":" + imp.getPort()
				+ "/readFile?impFilePath=" + runDefFile
				+ "&impUser=" + imp.getUser()
				+ "&impSessionID=" + imp.getSessionId();
	}
	
	/**
	 * If any one of the following condition is met:
	 * - collect is running
	 * - autoindex is running
	 * - Monitor thread is alive
	 */
	public boolean isRunning()
	{
		return (getStatus() == COLLECT_RUNNING) || autoindexRunStatus.isRunning() 
			|| ((runMonitor != null) && runMonitor.isAlive());
	}

	/**
	 * Is autoindex done?
	 */
	public boolean isAutoindexDone()
	{	
		return (getStatus() >= AUTOINDEX_FINISH);
//		return autoindexDone;
	}

	/**
	 * Return setup data
 	 */
	public AutoindexSetupData getSetupData()
	{
		return setupData;
	}
	
	/**
	 */
	public void changeRunType(String type)
		throws Exception
	{
		if (type.equals(AutoindexViewer.RUN_TYPE_COLLECT)) {
			setupData.setCollectImages(true);
			// Remove input.xml if exists
			String aFile = run.getWorkDir() + "/input.xml";
			if (client.getImperson().fileExists(aFile))
				client.getImperson().deleteFile(aFile);
		} else if (type.equals(AutoindexViewer.RUN_TYPE_AUTOINDEX)) {
			setupData.setCollectImages(false);
			// Remove collect.xml if exists
			String aFile = run.getWorkDir() + "/collect.xml";
			if (client.getImperson().fileExists(aFile))
				client.getImperson().deleteFile(aFile);
		} else {
			return;
		}
			
		saveSetup(setupData);
		
		// Force reload results and children
		load(true);
		
		setupDone = false;
		setStatus(SETUP);
		
		if (type.equals(AutoindexViewer.RUN_TYPE_COLLECT)) {
			setSetupStep(SETUP_CHOOSE_SAMPLE);
		} else if (type.equals(AutoindexViewer.RUN_TYPE_AUTOINDEX)) {
			setSetupStep(SETUP_CHOOSE_DIR);
		}
	}

	/**
	 * Check if this run setup can be modified.
	 * Setup can not be modified we it is currently running.
	 * If there are results then delete it first.
	 * Reload the run and change status of run to SETUP.
	 */
	public void editSetup()
		throws Exception
	{
	
		if (isRunning())
			return;

		// Delete previous results before
		// allow users to modify the setup.
		if (getStatus() > RunController.READY) {
			// Delete all files under this dir
			deleteResults();
			// Seems like there is a delay in the delete.
			// We need to pause before writing input.xml file
			// else the file will never appear (even though imp server returns no error)!!
			Thread.sleep(3000);
			
			// Save current setup data to input.xml			
			String f = run.getWorkDir() + "/" + definitionFile;
			// Reset beamline to empty string
			if (client.getBeamline() != null)
				setupData.setBeamline(client.getBeamline());
			else
				setupData.setBeamline("default");
			if (!client.getImperson().fileExists(f))
				saveSetup(setupData);
		}
				
		// Force reload results and children
		load(true);
		
		if (setupData.getStrategyMethod().equalsIgnoreCase("unknown"))
			setupData.setStrategyMethod(run.getDefaultStrategyMethod());

		setupDone = false;
		setStatus(SETUP);
		
		// If webice can collect data
		if (ServerConfig.canCollect()) {
		
			// Allow user to select whether to 
			// collect/autoindex or autoindex only.
			setSetupStep(SETUP_CHOOSE_RUN_TYPE);
			
		} else {
			setSetupStep(SETUP_CHOOSE_DIR);
		}
	}

	/**
	 * Reset setup 
	 */
	public void resetSetupData()
	{
		if (getStatus() > SETUP)
			return;

		setupData.reset();
		setupData.setImageDir(run.getDefaultImageDir());

	}

	/**
	 * Save setup data
	 */
	public void finishSetup()
		throws Exception
	{

			setupDone = false;
			setStatus(SETUP);
			
			// If we are collecting test images then expect image root name in setup data			
			if (setupData.isCollectImages()) {
				if ((setupData.getImageRootName() == null) || (setupData.getImageRootName().length() == 0)) {
					setLog("Invalid image root name\n");
					throw new Exception("Invalid image root name");
				}

			} else { // if isCollectImages()
			
				// We we are only autoindex without collecting
				// then expect filenames for image1 and image2.
				if ((setupData.getImage1().length() == 0) ||
					(setupData.getImage2().length() == 0)) {
					setLog("No image has been selected. Autoindex requires 2 images.\n");
					throw new Exception("No image has been selected. Autoindex requires 2 images");
				}
						
			
				// Beamline name must be supplied 
				// if we are to generate data collection strategy.
				String beamline = setupData.getBeamline();
				if (setupData.isGenerateStrategy()) {
			    
					if ((beamline == null) || (beamline.length() == 0))
						throw new Exception("A beamline must be selected in order to generate data collection strategy or "
							+ " use the \"Generate strategy offline\" option.");
				
					if (!beamline.equals("default")) {
			    	  		if (!client.isConnectedToBeamline())
			    				throw new Exception("Client must be connected to a beamline in order to generate data collection strategy "
							+ " or use the \"Generate strategy offline\" option.");
				
			   	 		 if (!client.getBeamline().equals(beamline))
			    				throw new Exception("The selected beamline (" + client.getBeamline()
								+ ") is not the same as the beamline ("
								+ beamline + ") in autoindex setup data. Please select a new beamline "
								+ " or use the \"Generate strategy offline\" option.");
							
				  		// Make sure beamline's detector type is the same
				  		// as the detector type found in the image header.
				 		String imgDetectorType = setupData.getDetector();
				  		// Translate detector name from image header to dcs detector
				 		// naming convention
				 		String dcsDetectorName = Detector.getDcsDetectorType(imgDetectorType); 
				 		String bDetectorType = client.getDcsConnector().getDetectorType();
						WebiceLogger.info("finsihSetup: image detector type = " + imgDetectorType
								+ " dcs detector type = " + bDetectorType
								+ " dcs detector name = " + dcsDetectorName);
				  		if ((bDetectorType == null) || !bDetectorType.equalsIgnoreCase(dcsDetectorName))
							throw new Exception("The images were collected from " + imgDetectorType
								+ " detector but the selected beamline (" + beamline + ") has " 
								+ bDetectorType + " detector. Please select a new beamline "
								+ " or use the \"Generate strategy offline\" option.");

					}
				}

				// Save the beamline dump file if we are generating data
				// collection strategy.
				setupData.setDcsDumpFile(ServerConfig.getDcsDumpDir() + "/" + beamline + ".dump");

				// Save the beamline properties file if we are generating data
				// collection strategy.
				setupData.setBeamlineFile(ServerConfig.getBeamlineDir() + "/" + beamline + ".properties");

			} // if isCollectImages
			
			// In case we are editing an old run.
			if (setupData.getStrategyMethod().equalsIgnoreCase("unknown"))
				setupData.setStrategyMethod(run.getDefaultStrategyMethod());
			
			saveSetup(setupData);
			
			// Save image header to files
			// These files will be moved to PARAMETERS dir by run_autoindex.csh script.
			if (!setupData.isCollectImages()) {
				Imperson imperson = client.getImperson();
				imperson.saveFile(run.getWorkDir() + "/image1.txt", header1.toString());
				imperson.saveFile(run.getWorkDir() + "/image2.txt", header2.toString());
			}
						
			run.setDefaultImageDir(setupData.getImageDir());
								
			// ready to run
			setupDone = true;
			setStatus(READY);
	
	}

	
	private void saveSetup(AutoindexSetupData data)
		throws Exception
	{
		String file = "";
		StringBuffer buf = new StringBuffer();
		if (setupData.isCollectImages()) {
			file = run.getWorkDir() + "/collect.xml";
			AutoindexSetupSerializer.saveCollect(buf, data);
		} else {
			file = run.getWorkDir() + "/" + definitionFile;
			data.setVersion(AutoindexSetupData.CURRENT_VERSION);
			AutoindexSetupSerializer.save(buf, data);
		}
		
		client.getImperson().saveFile(file, buf.toString());
	}
	
	/**
	 * Extract inflection, peak and remote energies 
	 * from scan summary file.
	 */
	public void parseScanSummaryFile(String fname)
		throws Exception
	{
		String content = client.getImperson().readFile(fname);
		StringTokenizer tok = new StringTokenizer(content, "\n\r");
		String line = null;
		String words[] = null;
		String key = null;
		String atom_ = null;
		String edge_ = null;
		double inflectionE_ = 0.0;
		double peakE_ = 0.0;
		double remoteE_ = 0.0;
		while (tok.hasMoreTokens()) {
			line = tok.nextToken();
			words = line.split("=");
			if (words.length != 2)
				continue;
			key = words[0];
			if (key.equals("atom")) {
				atom_ = words[1];
			} else if (key.equals("edge")) {
				edge_ = words[1];
			} else if (key.equals("inflectionE")) {
				try {
					inflectionE_ = Double.parseDouble(words[1]);
				} catch (NumberFormatException e) {
					throw new Exception("inflectionE in " + fname + " file is not a number");
				}
			} else if (key.equals("peakE")) {
				try {
					peakE_ = Double.parseDouble(words[1]);
				} catch (NumberFormatException e) {
					throw new Exception("peakE in " + fname + " file is not a number");
				}
			} else if (key.equals("remoteE")) {
				try {
					remoteE_ = Double.parseDouble(words[1]);
				} catch (NumberFormatException e) {
					throw new Exception("remoteE in " + fname + " file is not a number");
				}
			}
		}
		
		
		setupData.setEdge(atom_ + "-" + edge_, 0.0, 0.0);
		setupData.setInflectionEn(inflectionE_);
		setupData.setPeakEn(peakE_);
		setupData.setRemoteEn(remoteE_);
				
	}
	
	private ImageHeader getImageHeader(String img) throws Exception {
		
		if (ServerConfig.getUseImgsrvCommand())
			return getImageHeaderFromImperson(img);
	
		return getImageHeaderFromImgsrv(img);		
	}
	
/*	private ImageHeader getImageHeaderFromImpersonUsingHttp(String img)
		throws Exception
	{

		String urlStr = "http://" + ServerConfig.getImgsrvCommandHost()
				+ ":" + String.valueOf(ServerConfig.getImgsrvCommandPort())
				+ "/runScript";
				
		String commandline = ServerConfig.getImgsrvCommand() + " " + img;
		
		WebiceLogger.info("getImageHeader URL: " + urlStr + "?impCommandLine" + commandline);
			
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impUser", client.getUser());
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impSessionID", client.getSessionId());


		int response = con.getResponseCode();
		if (response != 200) {
			WebiceLogger.error("Failed to get image header "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");
			con.disconnect();
			throw new Exception(con.getResponseMessage());
		}
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line = null;
		Vector lines = new Vector<String>();
		while ((line=reader.readLine()) != null) {
			lines.add(line);
		}		
		reader.close();
		con.disconnect();
				
		ImageHeader header = new ImageHeader();

		header.parse(lines);
		
		return header;
		
	}
*/	
	// Use socket instead of http so that we can set read timeout in case
	// the image server hangs. 
	private ImageHeader getImageHeaderFromImperson(String img)
		throws Exception
	{

		String commandline = ServerConfig.getImgsrvCommand() + " " + img;
		String urlStr = "/runScript";
		String httpStr = "GET " + urlStr + " HTTP/1.1\n"
				+ "Host: " + ServerConfig.getImgsrvCommandHost() + ":" + String.valueOf(ServerConfig.getImgsrvCommandPort())
				+ "impShell: /bin/tcsh\n"
				+ "impCommandLine: " + commandline + "\n"
				+ "impUser: " + client.getUser() + "\n"
				+ "impEnv1: " + "HOME=" + client.getUserConfigDir() + "\n"
				+ "impSessionID: " + client.getSessionId() + "\n\n";				
		
		WebiceLogger.info("getImageHeader URL: " + urlStr + "?impCommandLine" + commandline);
			
		Socket sock = new Socket(ServerConfig.getImgsrvCommandHost(), ServerConfig.getImgsrvCommandPort());
		sock.setSoTimeout(10000); // wait on read for 10 seconds before giving up.
	
		// Send request
		OutputStream out = sock.getOutputStream();
		out.write(httpStr.getBytes());
		out.flush();
		sock.shutdownOutput();

		BufferedReader reader = new BufferedReader(new InputStreamReader(sock.getInputStream()));
		String line = reader.readLine();
		if (!line.startsWith("HTTP/1.1 200 OK")) {
			WebiceLogger.error("Image server returns error: " + line);
			sock.close();
			throw new Exception(line);
		}
		
		// Read response header
		while ((line=reader.readLine()) != null) {
			if (line.trim().length() == 0)
				break;
		}
		
		// Read response body
		Vector lines = new Vector<String>();
		while ((line=reader.readLine()) != null) {
			lines.add(line);
		}		
		reader.close();
		sock.close();
						
		ImageHeader header = new ImageHeader();
		header.parse(lines);
		
		return header;
		
	}

	private ImageHeader getImageHeaderFromImgsrv(String img)
		throws Exception
	{
		String oneTimeSessionId = client.getOneTimeSession(ServerConfig.getImpServerHost());

		String urlStr = "/getHeader?fileName=" + img
					+ "&userName=" + client.getUser()
					+ "&sessionId=" + oneTimeSessionId;


		String httpStr = "GET " + urlStr + " HTTP/1.1\n"
				+ "Host: " + ServerConfig.getImgServerHost() + ":" + String.valueOf(ServerConfig.getImgServerPort()) + "\n"
				+ "Connection: close\n\n";

		Socket sock = new Socket(ServerConfig.getImgServerHost(), ServerConfig.getImgServerPort());
		sock.setSoTimeout(10000); // wait on read for 10 seconds before giving up.
		OutputStream out = sock.getOutputStream();
		out.write(httpStr.getBytes());
		out.flush();
		sock.shutdownOutput();
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(sock.getInputStream()));

		String line = reader.readLine();
		if (!line.startsWith("HTTP/1.1 200 OK")) {
			WebiceLogger.error("Image server returns error: " + line);
			sock.close();
			throw new Exception(line);
		}
		
		// Read response header
		while ((line=reader.readLine()) != null) {
			if (line.trim().length() == 0)
				break;
		}

		Vector lines = new Vector();
		while ((line=reader.readLine()) != null) {
			lines.add(line);
		}

		reader.close();
		sock.close();

		ImageHeader header = new ImageHeader();

		header.parse(lines);

		lines = null;

		return header;
	}


	/**
	 */
	private void checkDeltaPhi(String im1,
					ImageHeader header1,
					String im2,
					ImageHeader header2)
		throws Exception
	{

		double deltaPhi = (double)(header1.phi-header2.phi);
		if (deltaPhi < 0.0)
			deltaPhi *= -1.0;

		if (deltaPhi < 5.0)
			throw new Exception("Delta phi between " + im1
							+ " and " + im2 + " is too small ("
							+ deltaPhi + " deg). At least 5 deg is required."
							+ " Oscillation range is " + header1.oscRange + " deg). ");

		header1 = null;
		header2 = null;

	}

	/**
	 * Detector center
	 * Q4 CCD: 94, 94
	 * Q315 CCD: 157.5, 157.5
	 * MAR345 1200 and 1800 : 90, 90
	 * MAR345 1600 and 2400 : 120, 120
	 * MAR345 2000 and 3000 : 150, 150
	 * MAR345 2300 and 3450 : 172.5, 172.5
	 *
	 * Mosflm center
	 * x = Cy
	 * y = detectorWidth - Cx
	 */
	private void correctBeamCenter(AutoindexSetupData setupData,
									ImageHeader header)
		throws Exception
	{
		// Beam center used by labelit and mosflm scripts.
		setupData.setCenterX(header.detectorWidth - header.beamCenterY);
		setupData.setCenterY(header.beamCenterX);

	}

	/**
	 */
	private int getImageIndex(String im)
		throws Exception
	{


		int pos1 = im.lastIndexOf('_');

		if (pos1 < 0)
			throw new Exception("Failed to parse image file: " + im);

		int pos2 = im.indexOf('.', pos1+1);

		if (pos2 < 0)
			throw new Exception("Failed to parse image file: " + im);

		return Integer.parseInt(im.substring(pos1+1, pos2));

	}

	/**
	 */
	public String getImageDir()
	{
		return setupData.getImageDir();
	}

	/**
	 */
	public void setImageDir(String s)
	{

		setupData.setImageDir(s);

	}

	/**
	 */
	public void clearImages()
	{
		setupData.clearImages();
	}
	
	/**
	 */
	public void setImages(String im1, String im2)
		throws Exception
	{
		try {

			header1 = getImageHeader(setupData.getImageDir() + "/" + im1);
			header2 = getImageHeader(setupData.getImageDir() + "/" + im2);

			// Will throw an exception if phi of image1 and image2
			// are not at least than 5 degrees.
			checkDeltaPhi(im1, header1, im2, header2);


			setupData.setImages(im1, im2);

			setupData.setBeamCenterX(header1.beamCenterX);
			setupData.setBeamCenterY(header1.beamCenterY);
			setupData.setDistance(header1.distance);
			setupData.setWavelength(header1.wavelength);
			setupData.setDetector(header1.detector);
			setupData.setDetectorFormat(header1.format);
			setupData.setDetectorWidth(header1.detectorWidth);
			setupData.setDetectorResolution(header1.detectorResolution);
			setupData.setExposureTime(header1.expTime);
			setupData.setOscRange(header1.oscRange);
			
			// Correct beam center for
			// labelit and mosflm scripts
			correctBeamCenter(setupData, header1);

		} catch (Exception e) {
			e.printStackTrace();
			throw new Exception("Failed to set images " + im1 + " and " + im2 + ": " + e.getMessage());
		}

	}

	/**
	 */
	public String getImage1()
	{
		return setupData.getImage1();
	}

	/**
	 */
	public String getImage2()
	{
		return setupData.getImage2();
	}

	/**
	 */
	public void setImageFilter(String s)
	{
		setupData.setImageFilter(s);
	}

	/**
	 */
	public String getIntegrate()
	{
		return setupData.getIntegrate();
	}

	/**
	 */
	public boolean isGenerateStrategy()
	{
		return setupData.isGenerateStrategy();
	}
	
	/**
	 * Check if laue group and unit cell parameters are valid
	 */
	public void validateUnitCell()
		throws Exception
	{
		String laueGroup = setupData.getLaueGroup();
		double a = setupData.getUnitCellA();
		double b = setupData.getUnitCellB();
		double c = setupData.getUnitCellC();
		double alpha = setupData.getUnitCellAlpha();
		double beta = setupData.getUnitCellBeta();
		double gamma = setupData.getUnitCellGamma();
		
		// If unit cell is not specified
		// then there is nothing to do
		if ((a == 0.0) && (b == 0.0) && (c == 0.0)
			&& (alpha == 0.0) && (beta == 0.0) && (gamma == 0.0))
			return;
			
		
		if (laueGroup.length() == 0)
			throw new Exception("Laue group must be specified if unit cell parameters are given.");


		String commandline = ServerConfig.getScriptDir() + "/run_labelit_compatible_cell.csh";

		commandline +=   " " + laueGroup
				+ " " + String.valueOf(a)
				+ " " + String.valueOf(b)
				+ " " + String.valueOf(c)
				+ " " + String.valueOf(alpha)
				+ " " + String.valueOf(beta)
				+ " " + String.valueOf(gamma);

		String runHost = setupData.getHost();
		int runPort = setupData.getPort();
		if ((runHost == null) || (runHost.length() == 0) || (runPort <= 0)) {
			runHost = ServerConfig.getAutoindexHost();
			runPort = ServerConfig.getAutoindexPort();
		}

		String urlStr = "http://" + runHost + ":" + String.valueOf(runPort) + "/runScript";

		// Use one-time session for this call to imp daemon
		// for security because imp daemon is not on localhost
		String oneTimeSession = getOneTimeSession(runHost);

		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impUser", client.getUser());
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impSessionID", oneTimeSession);


		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to run labelit.compatible_cell: impserson server returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");


		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				buf.append(line);
		}

		reader.close();
		con.disconnect();	
	
		// Parse output from the script
		String str = buf.toString();
		if (str.contains("INCOMPATIBLE"))
			throw new Exception("Cell parameters and Laue group are not compatible.");
		else if (str.contains("UNDETERMINED"))
			throw new Exception("Cell parameter values out of bound for edges in Angstrom and angles in degree.");
			
	}

	/**
	 * Start collecting or autoindexing
	 */
	public void run()
		throws Exception
	{
		try {
		
		if (setupData.isCollectImages()) {
			runCollect();
		} else { 
			runAutoindex();
		}
		
		} catch (Exception e) {
			appendLog(e.getMessage());
			throw e;
		}
	}
	
	/**
	 * collect a dataset with the given strategy and options.
	 * Do not monitor this collectWeb operation
	 */
	public void newBeamlineLog()
		throws Exception
	{
				
		// This client can become master
		DcsActiveClient dcsActiveClient = new DcsActiveClient(client.getUser(), 
						client.getSessionId(), 
						client.getBeamline());
						
		dcsActiveClient.newUserLog();
				
		// Free the client
		dcsActiveClient = null;
		
	}
	

	/**
	 * collect a dataset with the given strategy and options.
	 * Do not monitor this collectWeb operation
	 */
	public void collectDataset(CollectWebParam param)
		throws Exception
	{
		DcsConnector dcs = client.getDcsConnector();
		if (!client.isConnectedToBeamline() || (dcs == null))
			throw new Exception("runCollect failed because user is not connected to beamline.");
			
		if (dcs.getNumRuns() >= DcsConnector.MAX_RUNS)
			throw new Exception("There are already too many runs.");

		
		param.op.autoindex = false;
		param.op.stop = false;
		param.op.scan = false;
		
		aborted = false;

		setLog("Started collecting a dataset\n");
		
				
		// This client can become master
		DcsActiveClient dcsActiveClient = new DcsActiveClient(client.getUser(), 
						client.getSessionId(), 
						client.getBeamline());
		// Connect to DCSS, wait until DCSS is ready
		// then start collectWeb operation.
		// Wait until we receive stog_start_operation collectWeb
		// as a confirmation before disconnecting
		// from dcss.
		dcsActiveClient.collectWeb(param);
				
		// Free the client
		dcsActiveClient = null;
		
	}
	
	/**
	 * Recollect 2 images with new settings, autoindex and stop
	 */
	public void recollectTestImages(CollectWebParam param)
		throws Exception
	{
		setupData.clearImages();
	
		WebiceLogger.info("Client " + client.getUser() + " collecting test image at beamline " 
				+ client.getBeamline() + " for run " + setupData.getRunName());
		
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			throw new Exception("Client is not connected to beamline");
			
		if (dcs.getNumRuns() >= DcsConnector.MAX_RUNS)
			throw new Exception("There are already too many runs.");

		// Set setup data
		RunDefinition def = setupData.getTestRunDefinition();
				
		// For collecting 2 test images, we only need one energy.
		// And set attenuation to the beamline currect value.
		param.def.energy2 = 0.0;
		param.def.energy3 = 0.0;
		param.def.energy4 = 0.0;
		param.def.energy5 = 0.0;
		param.def.numEnergy = 1;
		// param.def.attenuation = 0.0; // always collect test images with without attenuation.
		param.def.wedgeSize = 180.0;

		def.copy(param.def);
		
		RunExtra extra = param.extra;
		extra.laueGroup = setupData.getLaueGroup();
		extra.cellA = setupData.getUnitCellA();
		extra.cellB = setupData.getUnitCellB();
		extra.cellC = setupData.getUnitCellC();
		extra.cellAlpha = setupData.getUnitCellAlpha();
		extra.cellBeta = setupData.getUnitCellBeta();
		extra.cellGamma = setupData.getUnitCellGamma();
		extra.runName = setupData.getRunName();
		extra.cassetteIndex = setupData.getCassetteIndex();
		extra.crystalPort = setupData.getCrystalPort();
		extra.expType = setupData.getExpType();
		extra.workDir = run.getWorkDir();
		extra.inflectionEn = setupData.getInflectionEn();
		extra.peakEn = setupData.getPeakEn();
		extra.remoteEn = setupData.getRemoteEn();
		extra.numHeavyAtoms = setupData.getNumHeavyAtoms();
		extra.numResidues = setupData.getNumResidues();
		extra.strategyMethod = setupData.getStrategyMethod();

		param.op.autoindex = true;
		param.op.stop = true;
		param.op.scan = false;

		// Clear old results
		editSetup();
		
		setStatus(READY);
		setSetupStep(SETUP_FINISH);
		
		
		// This is the file in which DCSS will write collect status.
		param.statusFile = run.getWorkDir() + "/collect.out";

		runCollect(param);
	}
	
	public void exportDcsRunDefinition(RunDefinition def)
		throws Exception
	{
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			throw new Exception("Client is not connected to beamline");
			
		if (dcs.getNumRuns() >= DcsConnector.MAX_RUNS)
			throw new Exception("There are already too many runs.");
			
			
		WebiceLogger.info("Client " + client.getUser() + " exporting run definition to beamline " 
				+ client.getBeamline());

		// This client can become master
		DcsActiveClient dcsActiveClient = new DcsActiveClient(client.getUser(), 
						client.getSessionId(), 
						client.getBeamline());
				
		// Send configure_run message to dcss.
		// Pick an unused run number.
		// Throw an error if all runs have been used.
		dcsActiveClient.configureRun(def);
		
		String defStr = def.toString();
		
		WebiceLogger.info("Exported run definition to " + client.getBeamline() + ": " + defStr);
				
		// Free the client
		dcsActiveClient = null;	}
	
	/**
	 * Start collectWeb operation at the beamline
	 */
	public void runCollect()
		throws Exception
	{		
		setupData.clearImages();

		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			throw new Exception("Client is not connected to beamline");
			
		if (dcs.getNumRuns() >= DcsConnector.MAX_RUNS)
			throw new Exception("Already too many runs.");

		WebiceLogger.info("Client " + client.getUser() + " collecting data at beamline " 
				+ client.getBeamline());

		// Construct collectWeb operation
		// Username sessionID
		// RunDefinition: {directory ......, inverseOn}
		// RunExtra: {spacegroupName {} runname port}
		// RunOptions: {mount center autoindex stop} using 1 or 0 as values
		CollectWebParam param = new CollectWebParam();
		param.def.copy(setupData.getTestRunDefinition());
		
		WebiceLogger.info("RunController: rundef = " + param.def.toString(false));
		
		RunExtra extra = param.extra;
		extra.laueGroup = setupData.getLaueGroup();
		extra.cellA = setupData.getUnitCellA();
		extra.cellB = setupData.getUnitCellB();
		extra.cellC = setupData.getUnitCellC();
		extra.cellAlpha = setupData.getUnitCellAlpha();
		extra.cellBeta = setupData.getUnitCellBeta();
		extra.cellGamma = setupData.getUnitCellGamma();
		extra.runName = setupData.getRunName();
		extra.cassetteIndex = setupData.getCassetteIndex();
		extra.crystalPort = setupData.getCrystalPort();
		extra.expType = setupData.getExpType();
		extra.workDir = run.getWorkDir();
		extra.numHeavyAtoms = setupData.getNumHeavyAtoms();
		extra.numResidues = setupData.getNumResidues();
		extra.strategyMethod = setupData.getStrategyMethod();
		
		WebiceLogger.info("runCollect " + setupData.getRunName() + " numHeavyAtoms = " + extra.numHeavyAtoms
					+ " numResidues = " + extra.numResidues
					+ " strategy method = " + extra.strategyMethod);
				
		RunOptions op = param.op;
		op.mount = setupData.isMountSample();
		op.center = false;
		op.autoindex = true;
		op.stop = true;
		
		extra.mad.reset();
		if (setupData.getExpType().equals("MAD") || setupData.getExpType().equals("SAD")) {
		
			// If we are doing a scan then we need edge enegy.
			if (setupData.isDoScan()) {
		
			op.scan = true;
			
			MadScan mad = extra.mad;
			mad.setDir(param.def.directory); // scan output are saved in the same dir as the images
			mad.setRootName(param.def.fileRoot); // use the same file root as the images
			mad.setEdge(setupData.getEdge());
			mad.setTime(1.0); // scan time is 1 second by default
			
			} else {
			
			// If we don't do scan then we need to set all three energies.
			// Set mad scan edge name.
			extra.mad.setEdge(setupData.getEdge());
			
			extra.inflectionEn = setupData.getInflectionEn();
			extra.peakEn = setupData.getPeakEn();
			extra.remoteEn = setupData.getRemoteEn();
			
			}
		}
		
		// This is the file in which DCSS will write collect status.
		param.statusFile = run.getWorkDir() + "/collect.out";
		
		runCollect(param);
		
	}

	/**
	 * Start collectWeb operation at the beamline
	 */
	private void runCollect(CollectWebParam param)
		throws Exception
	{
		try {
		
		DcsConnector dcs = client.getDcsConnector();
		if (!client.isConnectedToBeamline() || (dcs == null))
			throw new Exception("runCollect failed because user is not connected to a beamline");
		
		aborted = false;

		setLog("Started collecting test images and autoindex\n");
		
				
		// This client can become master
		DcsActiveClient dcsActiveClient = new DcsActiveClient(client.getUser(), 
						client.getSessionId(), 
						client.getBeamline());
												
		// Connect to DCSS, wait until DCSS is ready
		// then start collectWeb operation.
		// Wait until we receive stog_start_operation collectWeb
		// as a confirmation before disconnecting
		// from dcss.
		dcsActiveClient.collectWeb(param);
				
		// Free the client
		dcsActiveClient = null;
		
		setStatus(COLLECT_START);
		setStatusString("Waiting for collect status from DCSS");
		
		this.startMonitoring();


		} catch (Exception e) {
			setStatusString("ERROR: " + e.getMessage());
			appendLog("ERROR: " + e.getMessage() + "\n");
			WebiceLogger.warn("Error in RunController.collectWeb: " + e.getMessage());
			setStatus(COLLECT_FINISH);
		}
	}
	
	private void updateAutoindexHostPort()
		throws Exception
	{
		// Update host and port info in input.xml
		if (!setupData.getHost().equals(ServerConfig.getAutoindexHost()) ||
			(setupData.getPort() != ServerConfig.getAutoindexPort())) {
			setupData.setHost(ServerConfig.getAutoindexHost());
			setupData.setPort(ServerConfig.getAutoindexPort());
			saveSetup(setupData);
		}
	}
	
	/**
	 * Run con_autoindex.csh script
	 */
	public void runAutoindex()
		throws Exception
	{
		try {
		
		// If we are generating strategy for a beamline
		// then check if the user is currently connected to the beamline
		// if not then report an error.
		String s_beamline = setupData.getBeamline();
		String c_beamline = client.getBeamline();
		if (setupData.isGenerateStrategy() 
			&& !s_beamline.equals("default")
			&& (!client.isConnectedToBeamline() || !s_beamline.equals(c_beamline) ) )
			throw new Exception("Cannot generate strategy for beamline " + s_beamline
					+ ". User is not connected to the beamline");

		WebiceLogger.info("Client " + client.getUser() + " autoindexing images at beamline " 
					+ client.getBeamline());

		aborted = false;

		// Update host and port info in input.xml
		updateAutoindexHostPort();

		setLog("Started running autoindex\n");
		
		// Check the control file to see if it's already running.

		// Check if the input.xml file is ready

		// Delete old results

		// Run the script via the impersonation server.

		String commandline = ServerConfig.getScriptDir() + "/con_autoindex.csh ";

		commandline +=   " " + run.getWorkDir() + "/input.xml";

		String urlStr = "http://" + setupData.getHost() + ":" + String.valueOf(setupData.getPort()) + "/runScript";
		
		// Use one-time session for this call to imp daemon
		// for security because imp daemon is not on localhost
		String oneTimeSession = getOneTimeSession(setupData.getHost());

		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impUser", client.getUser());
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impSessionID", oneTimeSession);


		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to run labelit: impserson server returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");


		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				appendLog(line + "\n");
		}

		reader.close();
		con.disconnect();
		
		setStatusString("Autoindex starting");

		// Start monitoring the run
		this.startMonitoring();


		} catch (Exception e) {
			appendLog("ERROR: " + e.getMessage() + "\n");
			throw new Exception(e.getMessage());
		}

	}


	/**
	 * Delete all output generated by this node.
	 */
	public void deleteResults()
		throws Exception
	{
		// Delete all files
		client.getImperson().deleteFiles(run.getWorkDir(), "*");

	}

	private String getBaseName(String filename)
	{
		int pos = filename.lastIndexOf('.');
		if (pos < 0)
			return filename;

		return filename.substring(0, pos);
	}

	public String getLog()
	{
		return log;
	}

	public void setLog(String s)
	{
		log = s;
	}

	public String getRunLog()
	{
		return runLog;
	}

	public void resetLog()
	{
		log = "";
	}

	public void appendLog(String s)
	{
		log += s;
	}
	
	/**
	 * Connect to dcss, check if our run is the current run
	 * and send abortCollectWeb operation.
	 * Will throw an exception if abortCollectWeb fails.
	 */
	public void abortCollect()
		throws Exception
	{
		
		// This client can become master
		DcsActiveClient dcsActiveClient = new DcsActiveClient(client.getUser(), 
						client.getSessionId(), 
						client.getBeamline());
		// Connect to DCSS, wait until DCSS is ready
		// then start collectWeb operation.
		// Wait until we receive stog_start_operation collectWeb
		// as a confirmation before disconnecting
		// from dcss.
		dcsActiveClient.abortCollectWeb();
				
		// Free the client
		dcsActiveClient = null;
		
		// If no error is thrown then we can
		// assume that abortCollectWeb is successful.
		// Wait until our main thread updates collect.out
		// and notice that collectWeb is now inactive.
		int timeout = 10000; // 10 seconds
		int count = 0;
		while (getStatus() <= COLLECT_FINISH) {
		 	Thread.sleep(500);
			count += 500;
			if (count > timeout)
				throw new Exception("Timeout while waiting for collect_msg to indicate that collectWeb has stopped");
		}
		
	}

	public void abortRun()
		throws Exception
	{

		resetLog();
		
		if (setupData.isCollectImages() && (getStatus() >= COLLECT_RUNNING))
			abortCollect();
			

		try {
		
		String cFile = run.getWorkDir() + "/control.txt";
		
		// Autoindex has not started
		if (!client.getImperson().fileExists(cFile))
			return;

		String commandline = ServerConfig.getScriptDir() + "/kill_autoindex.csh " + cFile;
		
		String runHost = setupData.getHost();
		int runPort = setupData.getPort();
		if ((runHost == null) || (runHost.length() == 0))
			throw new Exception("Failed to abort run because autoindex host is invalid in " + run.getWorkDir() + "/input.xml");
			
		if (runPort <= 0)
			throw new Exception("Failed to abort run because autoindex port is invalid in " + run.getWorkDir() + "/input.xml");
			
		String urlStr = "http://" + runHost + ":" + String.valueOf(runPort) + "/runScript";

		// Use one-time session for this call to imp daemon
		// for security because imp daemon is not on localhost
		String oneTimeSession = getOneTimeSession(runHost);

		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impUser", client.getUser());
		con.setRequestProperty("impSessionID", oneTimeSession);


		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to abort run because impserson server returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");


		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = "";
		String content = "";
		while ((line = reader.readLine()) != null) {
			if (line.length() > 0)
				content += line + "\n";
		}


		reader.close();
		con.disconnect();

		while (runMonitor.isAlive()) { 
			Thread.currentThread().sleep(50); 
		}
		
		appendLog(content);
		


		} catch (Exception e) {
			appendLog("ERROR: " + e.getMessage() + "\n");
		}
	}

	public boolean isRunAborted()
	{
		return aborted;
	}

	public boolean isAdditionalIntegrationDone()
	{
		return (getStatus() >= ADDITONAL_INTEGRATION_FINISH);
	}

	/**
	 * Used by AutoindexViewer when deleteRun is called. 
	 * This is to make sure that we don't delete a run 
	 * while the scripts are still running.
 	 */
	public static RunStatus getRunStatus(Imperson imperson, String workDir, String homeDir)
		throws Exception
	{
		// Need to reconstruct setupdata from input.xml
		// so that we can find out on which host the script is run.
		AutoindexSetupData setupData = new AutoindexSetupData();
		String runDefFile = workDir + "/input.xml";
		try {
			// Read remote file either input.xml or autoindex.xml.
			String url = getRunDefinitionFileUrl(imperson, runDefFile);
			AutoindexSetupSerializer.load(url, setupData);
			
		} catch (Exception e) {
			// Failed to load input.xml
			WebiceLogger.error("Failed to load run definition file " + runDefFile);
		}
		
		HttpURLConnection con = null;
		try {
		
		// The setup data (from input.xml in the run dir) tells us 
		// where the script is run.
		String runHost = setupData.getHost();
		int runPort = setupData.getPort();
		if ((runHost == null) || (runHost.length() == 0) || (runPort <= 0)) {
			// Assume that it is not running
			return new RunStatus();
		}
			

		String commandline = ServerConfig.getScriptDir()
						+ "/con_autoindex_updatestatus.csh " 
						+ workDir + "/control.txt";

		String urlStr = "http://" + runHost + ":" + String.valueOf(runPort) + "/runScript";
		
		// Use one-time session for this call to imp daemon
		// for security because imp daemon is not on localhost
		String oneTimeSession = imperson.getSessionId();
//		if (!runHost.equals("localhost"))
//			oneTimeSession = client.getOneTimeSession();

//		System.out.println("in RunController.getRunStatus: url = " + urlStr);
//		System.out.println("in RunController.getRunStatus: commandline = " + commandline);
				
		URL url = new URL(urlStr);

		con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impEnv1", "HOME=" + homeDir);
		con.setRequestProperty("impUser", imperson.getUser());
		con.setRequestProperty("impSessionID", oneTimeSession);


		int response = con.getResponseCode();
		if (response != 200) {
			con.disconnect(); con = null;
			throw new Exception("Failed to get run status: impserson server returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");
		}

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = reader.readLine();
		RunStatus ret = new RunStatus();
		ret.parseStatus(line);
		
		reader.close();
		con.disconnect();
		con = null;

		return ret;

		} catch (Exception e) {
			if (con != null)
				con.disconnect();
			throw e;
		}

	}
	
	synchronized private void setStatus(int s)
	{
		status = s;
	}

	synchronized public int getStatus()
	{
		return status;
	}

	/**
	 * String to display while collecting and/or autoindexing
	 */
	synchronized public String getStatusString()
	{
		return statusString;
	}
	
	synchronized private void setStatusString(String s)
	{
		statusString = s;
	}
	
	/**
	 */
	private boolean hasAutoindexSetupFile()
	{
 		String runDefFile = run.getWorkDir() + "/" + definitionFile;

   		try {

			// Try to open input.xml. If not found then try to open autoindex.xml.
			// If neither can be found then throw an exception.
			// If only autoindex.xml can be found, then read it and
			// save it as to input.xml for next time.
			if (client.getImperson().fileExists(runDefFile))
				return true;
				
			return false;
			
		} catch (Exception e) {
			return false;
		}
	}

	/**
	 * Get the latest run status from the control file
 	 */
	public void updateRunStatus()
		throws Exception
	{
		// Check data collection status first
		if (setupData.isCollectImages()) {
		
			if (getStatus() < COLLECT_FINISH)
				updateCollectStatus();
														
			if (hasAutoindexSetupFile()) {
				if (!autoindexFileLoaded) {
					loadAutoindexSetupFile();
				}
				if (getStatus() < FINISH) {
					updateAutoindexStatus();
				}
			}
						
		} else {
				
			// Check autoindex status even if status < COLLECT_FINISH
			// in case, collect monitoring failed.
			if (getStatus() < FINISH) {
				updateAutoindexStatus();
			}
		}
		
	}
	
	
	/**
	 * Get the latest test data collection status
 	 */
	public void updateCollectStatus()
		throws Exception
	{		
		// Get status from collect.out in work dir
		String f = run.getWorkDir() + "/collect.out";
		String msg = "";
		
		if (!client.getImperson().fileExists(f))
			throw new CollectOutNotFoundException(f + " does not exist");

		try {
								
			// Read collect.out file					
			msg = client.getImperson().readFile(f);
					
		} catch (Exception e) {
			WebiceLogger.warn("Failed to load collect status from " + f + " because " + e.getMessage());
			setStatusString("Failed get collect status from file " + f + " because " + e.getMessage());
			appendLog("Failed get collect status from file " + f + " because " + e.getMessage() + "\n");
			throw new LoadCollectOutException("Failed get collect status from file " + f + " because " + e.getMessage());
		}
		
		
		try {
		
			// Parse output
			collectMsg.parse(msg);
		
		} catch (Exception e) {
			WebiceLogger.warn("Failed to parse collect_msg string: " + msg);
			setStatusString("Failedparse collect_msg from file " + f + " because " + e.getMessage());
			appendLog("Failed get collect status from file " + f + " because " + e.getMessage() + "\n");
			throw new LoadCollectOutException("Failed collect_msg from file " + f + " because " + e.getMessage());
		}
						
		if (collectMsg.runName.equals(setupData.getRunName())) {
			if (collectMsg.active == 1) {
				setStatus(COLLECT_RUNNING);
				// autoindex has started
				// We will not get status from dcss any more
				// Instead, we will monitor autoindex status
				// using control.txt and autoindnex.out directly.
				if (collectMsg.status >= CollectMsgString.COLLECTWEB_AUTOINDEXING) {
					setStatus(AUTOINDEX_RUNNING);				
				}
			} else {
				if (collectMsg.hasError) {
					setStatus(ERROR);
				} else {
					setStatus(COLLECT_FINISH);
				}
			}
			setStatusString(collectMsg.msg);
		}
		
		// User must be connected to the beamline to monitor this run.
		if (getStatus() == COLLECT_RUNNING) {
			DcsConnector dcs = client.getDcsConnector();
			String sBeamline = setupData.getBeamline();
			if ((dcs == null) || !dcs.getBeamline().equals(sBeamline)) {
				setStatus(FINISH);
				throw new Exception("Cannot get collect status becuase user is not connected to beamline " 
							+ sBeamline + ". Please connect to the beamline and reload run.");
			}
			
			// Make sure that dcss is not offline
			if (!dcs.isDcssOnline()) {
				WebiceLogger.info("Cannot get collect status because DCSS for beamline " + sBeamline 
					+ " is offline. Please reload the run.");
				setStatus(ERROR);
				setStatusString("Cannot get collect status because DCSS for beamline " + sBeamline 
					+ " is offline. Please reload the run.");
				throw new Exception("Cannot get collect status because DCSS for beamline " + sBeamline 
					+ " is offline. Please reload the run.");
			}
							
			String content = dcs.getCollectMsg();
			
			if (content == null)
				content = "";
				
			// Parse collect_msg
			CollectMsgString col = new CollectMsgString(content);
				
			// Check if the current collect at dcss is still our run
			if (!col.runName.equals(setupData.getRunName())) {
						
				// Current dcss run is not our run anymore.
				// Perhaps the dcss has been restarted
				// and our collect.out did not get updated 
				// properly.
				setStatus(ERROR);
				setStatusString("Run " + run.getRunName() + " is no longer active at beamline " + sBeamline);
				// Change collect status to inactive
				// and write out collect.out manually
				// so that we no longer have to connect
				// to dcss to check the status of this run again.
				col.active = 0;
				col.msg = getStatusString();
				String collectFile = run.getWorkDir() + "/collect.out";
				client.getImperson().saveFile(collectFile,col.toString());

			} else {
				// We we are doing flouresence scan in this run
				// then check if scan operation reports an error
				// This is a workaround since scan error does
				// not get propagated to collect_msg.
				if (setupData.isDoScan() && (setupData.getExpType().equals("MAD") || setupData.getExpType().equals("SAD")) ) {
					if ((col.active == 1) && col.msg.startsWith("madScan")) {
						String scanMsg = dcs.getScanMsg();
						if ((scanMsg != null) && scanMsg.contains("error")) {
							// Current dcss run is not our run anymore.
							// Perhaps the dcss has been restarted
							// and our collect.out did not get updated 
							// properly.
							setStatus(ERROR);
							setStatusString(scanMsg);
							// Change collect status to inactive
							// and write out collect.out manually
							// so that we no longer have to connect
							// to dcss to check the status of this run again.
							col.active = 0;
							col.msg = getStatusString();
							String collectFile = run.getWorkDir() + "/collect.out";
							client.getImperson().saveFile(collectFile, col.toString());
						}
					}
				}
			}
			
			// Current dcss run is still our run
			// update collect status
			collectMsg.copy(col);
			
		}
		

	}
		
	/**
	 * Get the latest run status from the control file
 	 */
	public void updateAutoindexStatus()
		throws Exception
	{		
		String stFile = run.getWorkDir() + "/control.txt";

		if (!client.getImperson().fileExists(stFile))
			throw new ControlTxtNotFoundException(stFile + " does not exist");


		HttpURLConnection con = null;
		try {

		resetLog();

		hasAutoindexLog = false;

		// The setup date (from input.xml in the run dir) tells us 
		// where the script is run.
		String runHost = setupData.getHost();
		int runPort = setupData.getPort();
		if ((runHost == null) || (runHost.length() == 0) || (runPort <= 0)) {
			runHost = ServerConfig.getSpotServerHost();
			runPort = ServerConfig.getSpotServerPort();
		}

		String commandline = ServerConfig.getScriptDir()
						+ "/con_autoindex_updatestatus.csh " 
						+ stFile;

		String urlStr = "http://" + runHost + ":" + String.valueOf(runPort) + "/runScript";

		// Use one-time session for this call to imp daemon
		// for security because imp daemon is not on localhost
		String oneTimeSession = getOneTimeSession(runHost);

		URL url = new URL(urlStr);

		con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impUser", client.getUser());
		con.setRequestProperty("impSessionID", oneTimeSession);


		int response = con.getResponseCode();
		if (response != 200) {
			con.disconnect(); con = null;
			throw new Exception("Failed to get autoindex status from file " + stFile + " because "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (" + urlStr + ")");
		}

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String firstLine = "";
		String line = "";
		String content = "";
		while ((line = reader.readLine()) != null) {
			if (content.length() == 0)
				firstLine = line;
			if (line.length() > 0)
				content += line + "\n";
		}
		// runStatus can tell us whether the autoindex process is running or not
		// by parsing info in the control file.
		autoindexRunStatus.parseStatus(firstLine); 
		
		reader.close();
		con.disconnect();
		con = null;
		
		if (!autoindexRunStatus.isRunning()) {
			if (content.indexOf("Aborted") > -1) {
				setStatus(ABORT);
				setStatusString("Autoindex aborted");
				return;
			}
		}
		

		} catch (Exception e) {
			WebiceLogger.error("Exception updateAutoindexStatus: " + e.getMessage(), e);
			if (con != null)
				con.disconnect();
			appendLog("Failed to get autoindex status becuase " + e.getMessage() + "\n");
			throw new LoadControlTxtException("Failed to get autoindex status from file " 
					+ stFile + " because " + e.getMessage());
		}
		
		// Update the log displayed in setup tab
		updateRunLog();
		

	}

	/**
	 */
	public boolean isLabelitDone()
	{
		return (getStatus() >= LABELIT_FINISH);
	}

	/**
	 */
	public boolean isIntegrationDone()
	{
		return (getStatus() >= INTEGRATION_FINISH);
	}

	/**
	 */
	public boolean isStrategyDone()
	{
		return (getStatus() >= STRATEGY_FINISH);
	}


	/**
	 */
	public boolean hasAutoindexLog()
	{
		return hasAutoindexLog;
	}
	
	/**
	 */
	public int getSetupStep()
	{
		return setupStep;
	}
	
	public void setSetupStep(int s)
	{
		if (s < SETUP_START)
			s = SETUP_START;
		
		if (s > SETUP_FINISH)
			s = SETUP_FINISH;
			
		setupStep = s;
	}

	/**
	 * Check autoindex.out and look for "Finished running autoindex" line.
	 */
	private void updateRunLog()
		throws Exception
	{
	
		String auFile = run.getWorkDir() + "/autoindex.out";
		try {

		int pos = 0;
		int pos1 = 0;

		if (autoindexRunStatus.isRunning()) {
		    	setStatusString("Autoindex starting");
		}

		if (!hasAutoindexLog)
			hasAutoindexLog = client.getImperson().fileExists(auFile);

		if (!hasAutoindexLog)
			throw new Exception("file does not exist");
		    
		runLog = client.getImperson().readFile(auFile);
		  
		// Check if the run has been aborted  
		pos1 = runLog.indexOf("autoindex aborted");
		if (pos1 > 0) {
			aborted = true;
			setStatus(ABORT);
			setStatusString("Autoindex aborted");
			pos = pos1;
		}

		// Has autoindex script started?
		pos1 = runLog.indexOf("Started running autoindex", pos);
		if (pos1 < 0)
			return;
		if (autoindexRunStatus.isRunning()) {
			setStatusString("Autoindexing");
			setStatus(AUTOINDEX_RUNNING);
			pos = pos1;
		}

		// Has labelit started?
		pos1 = runLog.indexOf("Started running labelit", pos);
		if (pos1 < 0)
			return;
		if (autoindexRunStatus.isRunning()) {
			setStatusString("Running labelit");
			setStatus(LABELIT_RUNNING);
			pos = pos1;
		}

		// Finished running labelit
		pos1 = runLog.indexOf("Finished running labelit", pos);
		if (pos1 > 0) {
		    	labelitDone = true;
		    	setStatus(LABELIT_FINISH);
			setStatusString("Labelit done");
			pos = pos1;
		}

		// Has autoindex started?
		pos1 = runLog.indexOf("Started integrating solutions", pos);
		if (pos1 >= 0) {
		
		if (autoindexRunStatus.isRunning()) {
			setStatusString("Integrating");
			setStatus(INTEGRATION_RUNNING);
			pos = pos1;
		}

		// Finished the first round of integration
		pos1 = runLog.indexOf("Finished integrating solutions", pos);
		if (pos1 > 0) {
		    	integrationDone = true;
			setStatus(INTEGRATION_FINISH);
			setStatusString("Integration done");
			pos = pos1;
		}

		if (getStatus() >= INTEGRATION_FINISH) {

			// Has autoindex started?
			pos1 = runLog.indexOf("Started generating strategy", pos);
		    	if ((pos1 > 0) && autoindexRunStatus.isRunning()) {
				setStatusString("Generating strategy");
				setStatus(STRATEGY_RUNNING);
				pos = pos1;
		    	}

			// Finished strategy
			if (!setupData.isGenerateStrategy()) {
				strategyDone = true;
				setStatus(STRATEGY_FINISH);
//				setStatusString("Strategy done");
			} else {
				pos1 = runLog.indexOf("Finished generating strategies", pos);
				if (pos1 > 0) {
					strategyDone = true;
					setStatus(STRATEGY_FINISH);
					pos = pos1;
					setStatusString("Strategy done");
				}
			}

		}
		
		} // found "Started integrating solutions"

		// Finished autoindexing
		pos1 = runLog.indexOf("Finished running autoindex", pos);
		if (pos1 > 0) {
			autoindexDone = true;
			setStatus(AUTOINDEX_FINISH);
			setStatusString("Autoindex done");
			pos = pos1;
		}
		    
		if (getStatus() >= AUTOINDEX_FINISH) {
			// Default prediction image
			run.selectImage(getImageDir() + "/" + getImage1());

			// Find a pair of start and finish
			pos1 = runLog.lastIndexOf("Started integrating additional solutions");

			// Finished additional integration
			// Find the last line. There is a matching "Started" and "Finished"
			// when a task is done.
			int pos2 = runLog.lastIndexOf("Finished integrating additional solutions");			

			// run log ends with "start". It means integration has not finished.
			if ((pos1 > 0) && (pos1 > pos) && (pos1 > pos2)) {
				pos = pos1;
				if (autoindexRunStatus.isRunning()) {
					setStatusString("Integrating additional solutions");
					setStatus(ADDITONAL_INTEGRATION_RUNNING);
				}
			}

			// Found a pair of start followed by finish
			if ((pos2 > 0) && (pos2 > pos1)) {
				// Still running, it means start and finish may not be
				// the pair we are looking for.
				if (autoindexRunStatus.isRunning()) {
					setStatusString("Integrating additional solutions");
					setStatus(ADDITONAL_INTEGRATION_RUNNING);
				} else {
					additionalIntegrationDone = true;
					setStatus(ADDITONAL_INTEGRATION_FINISH);
					setStatusString("Integrate additional solution done");
					pos = pos2;
				}
			}

		}


		} catch (Exception e) {
			throw new LoadAutoindexOutException("Failed to get autoindex log from file " 
					+ auFile + " because " + e.getMessage());
		}
	}


	/**
	 */
	public void integrateAdditionalSolutions(Vector solVec)
		throws Exception
	{
		try {

		resetLog();

		if (this.isRunning())
			throw new Exception("Cannot start integrating additional solutions: other process is still running");

		if (!autoindexDone)
			throw new Exception("Cannot integrate additional solutions: autoindex must be run first");


		// Update host and port info in input.xml
		updateAutoindexHostPort();


		additionalIntegrationDone = false;
		aborted = false;
		setStatus(AUTOINDEX_FINISH);
		setStatusString("Integration starting");

		setLog("Started integrating\n");

		String sol = "";
		String sols = "";
		for (int i = 0; i < solVec.size(); ++i) {
			Integer solInt = (Integer)solVec.elementAt(i);
			sol = solInt.toString();
			if (sols.length() > 0)
				sols += " ";
			if (solInt.doubleValue() < 10)
				sols += "0";
			sols += sol;
		}

		String commandline = ServerConfig.getScriptDir() + "/con_integrate_additional_solutions.csh ";

		commandline +=   " " + run.getWorkDir() + " " + sols;

		String urlStr = "http://" + setupData.getHost()
				+ ":" + String.valueOf(setupData.getPort())
				+ "/runScript";

		// Use one-time session for this call to imp daemon
		// for security because imp daemon is not on localhost
		String oneTimeSession = getOneTimeSession(setupData.getHost());

		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impUser", client.getUser());
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impSessionID", oneTimeSession);


		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to run labelit: impserson server returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");


		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				appendLog(line + "\n");
		}

		reader.close();
		con.disconnect();
		

		// Start monitoring the run
		this.startMonitoring();


		} catch (Exception e) {
			appendLog("ERROR: " + e.getMessage() + "\n");
		}

	}

	/**
	 */
	private void startMonitoring()
		throws Exception
	{
		if ((runMonitor != null) && runMonitor.isAlive())
			throw new Exception("Already monitoring the run");

		runMonitor = null;

		// Assume that it's running
		// updateStatus should be called
		// to get the latest status.
		autoindexRunStatus.setStartTime("");

		runMonitor = new MonitorThread();
		runMonitor.startMonitoring();
	}

	/**
	 */
	void stopMonitoring()
	{
		if ((runMonitor != null) && runMonitor.isAlive()) {
			runMonitor.stopMonitoring();
		}
	}

	/**
	 * Thread to monitor the run
	 */
	private class MonitorThread extends Thread
	{
		private boolean stopped = false;
		private int interval = 5;
		
		// How many times to retry loading 
		// these files
		private int numLoadCollectXml = 0;
		private int numLoadCollectOut = 0;
		private int numLoadInputXml = 0;
		private int numLoadAutoindexOut = 0;
		private int numControlTxt = 0;
		
		private int maxTry = 15;

		synchronized public void startMonitoring()
		{
			if (isAlive())
				return;
			stopped = false;

			super.start();
		}

		synchronized public void stopMonitoring()
		{
			stopped = true;
		}
		
		synchronized private boolean isStopped()
		{
			return stopped;
		}

		public void run()
		{
			try {
				// Reset number of tries
				numLoadCollectXml = 0;
				numLoadCollectOut = 0;
				numLoadInputXml = 0;
				numLoadAutoindexOut = 0;
				numControlTxt = 0;

				while (!isStopped()) {
										
					try {

					// Update run status
					updateRunStatus();
						
/*					WebiceLogger.info("in run: status = " + status 
						+ ", autoindexRunStatus isRunning = " 
						+ autoindexRunStatus.isRunning());*/
						
						
					} catch (LoadCollectOutException e) {
						WebiceLogger.info("LoadCollectOutException (try " + numLoadCollectOut + "): " + e.getMessage());
						// Failed to load collect.out
						++numLoadCollectOut;
						if (numLoadCollectOut > maxTry)
							throw e;
					} catch (LoadCollectXmlException e) {
						WebiceLogger.info("LoadCollectXmlException (try " + numLoadCollectXml + "): " + e.getMessage());
						// Failed to load collect.xml
						++numLoadCollectXml;
						if (numLoadCollectXml > maxTry)
							throw e;
					} catch (CollectOutNotFoundException e) {
						WebiceLogger.info("CollectOutNotFoundException (try " + numLoadCollectOut + "): " + e.getMessage());
						// Failed to load collect.out
						++numLoadCollectOut;
						if (numLoadCollectOut > maxTry)
							throw e;
					} catch (LoadInputXmlException e) {
						WebiceLogger.info("LoadInputXmlException (try " + numLoadInputXml + "): " + e.getMessage());
						// Failed to load input.xml
						++numLoadInputXml;
						if (numLoadInputXml > maxTry)
							throw e;
					} catch (ControlTxtNotFoundException e) {
						WebiceLogger.info("ControlTextNotFoundException (try " + numControlTxt + "): " + e.getMessage());
						// Failed to load control.txt
						++numControlTxt;
						if (numControlTxt > maxTry)
								throw e;
					} catch (LoadAutoindexOutException e) {
						WebiceLogger.info("LoadAutoindexOutException (try " + numLoadAutoindexOut + "): " + e.getMessage());
						// Failed to load autoindex.out
						++numLoadAutoindexOut;
						if (numLoadAutoindexOut > maxTry)
							throw e;
					} catch (Exception e) {
						WebiceLogger.error("updateRunStatus Failed: " + e.getMessage(), e);
						throw e;
					}

					if ((getStatus() > AUTOINDEX_RUNNING) && !autoindexRunStatus.isRunning()) {
						stopMonitoring();
					}
							
					if ((getStatus() >= ERROR) && !isStopped()) {
						stopMonitoring();
					}

					if (isStopped())
						break;

					// sleep
					sleep(interval*1000);

				}

			} catch (InterruptedException e) {
				WebiceLogger.error("RunController: MonitorThread stopped: " + e.getMessage());
				stopped = true;
			} catch (Exception e) {
				WebiceLogger.error("RunController: MonitorThread stopped: " + e.getMessage());
				stopped = true;
			}
			WebiceLogger.info("run " + run.getRunName() + " monitoring thread stopped");
		}
		
	}
	
	/**
	 * Get a one-time session to be used in a request sent to an impersonation daemon
	 * Ask auth server for a one-time session if the imp daemon host is NOT localhost.
	 * If imp daemon host is localhost then assume that it is safe enough to send
	 * normal session id via http.
	 */
	private String getOneTimeSession(String impHost)
		throws Exception
	{
		return client.getOneTimeSession(impHost);
	}

}

