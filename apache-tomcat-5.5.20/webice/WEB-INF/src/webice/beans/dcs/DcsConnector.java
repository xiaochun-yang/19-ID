package webice.beans.dcs;

import org.apache.xerces.dom.DocumentImpl;
import org.apache.xerces.dom.DOMImplementationImpl;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.*;
import org.xml.sax.InputSource;
import org.xml.sax.EntityResolver;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import javax.net.ssl.SSLSocketFactory;
import javax.net.SocketFactory;
//import sun.misc.BASE64Encoder;
import org.apache.commons.codec.binary.Base64;
import java.security.cert.Certificate;
import java.security.*;
import javax.crypto.*;

import java.text.*;
import java.io.*;
import java.net.*;
import java.util.*;
import webice.beans.ServerConfig;
import webice.beans.WebiceLogger;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

/**
 * DcsConnector
 */
public class DcsConnector extends Thread
{
	private static final int MAX_WAIT = 1000;
	private static final int FIXED_LENGTH = 200;
	private static final int HEADER_LENGTH = 26;
	private static final int MAX_LOGS = 2000;
	public static final int MAX_RUNS = 16;

	private String userName = "";
	private String passwd = "";
	private String sessionId = "";
	private String beamline = "";
	private String dcssHost = "";
	private int dcssPort = 0;
	private String display = ":0.0";

	private boolean isStaff = false;
	private boolean isRoaming = false;
	private String location = "unknown";


	private boolean dcssReady = false;

	private int numRuns = -1;
	private int highestRunNumber = 0;
	private int highestRunLabelNumber = 0;

	private Hashtable devices = new Hashtable();
	/**
	 */
	private Hashtable listeners = new Hashtable();

	private MonitorThread monitor = null;

	private boolean dcssOnline = false;


	private static AuthGatewayBean auth = null;

	/**
	 * constructor
	 */
	DcsConnector(String user, String passwd, String beamline)
	{

		this.userName = user;
		this.passwd = passwd.trim();
		this.beamline = beamline;
		this.dcssHost = ServerConfig.getDcssHost(beamline);
		this.dcssPort = ServerConfig.getDcssPort(beamline);

		initDevices();

	}

	private void authenticate()
		throws Exception
	{
		// If auth has already been created
		// it means we already have a session id
		// Check if it is still valid.
		if (auth != null) {
			auth.updateSessionData(true);
			// If current session id is now invalid
			// set auth to null
			// so that we will create a new auth
			// and new session id from username and password
			if (!auth.isSessionValid())
				auth = null;
		}

		// Create a new session id from username and password
		if (auth == null) {
			auth = new AuthGatewayBean();
			auth.initialize(ServerConfig.getAuthAppName(), userName, passwd, 
					ServerConfig.getAuthMethod(),
					ServerConfig.getAuthServletHost());
			// Cannot authenticate this username and password
			if (!auth.isSessionValid()) {
				String err = auth.getUpdateError();
				auth = null;
				WebiceLogger.error("Authentication failed for user " + userName 
						+ " auth host:port = " + ServerConfig.getAuthServletHost()
						+ " auth method = " + ServerConfig.getAuthMethod());
				throw new Exception(err);
			}
		}

		this.sessionId = auth.getSessionID();
	}

	public void finalize()
	{
//		try {
			setStopFlag(true);
			WebiceLogger.info("DcsConnector::finalize: beamline = " + beamline);
//		} catch (Exception e) {
//			WebiceLogger.error("DcsConnector::finalize: "
//						+ this.toString()
//						+ " disconnect() failed because "
//						+ e.getMessage(), e);
//		}
	}

	public void initDevices()
	{
		devices.put("runs", new StringDevice("runs"));
		devices.put("run0", new StringDevice("run0"));
		devices.put("run1", new StringDevice("run1"));
		devices.put("run2", new StringDevice("run2"));
		devices.put("run3", new StringDevice("run3"));
		devices.put("run4", new StringDevice("run4"));
		devices.put("run5", new StringDevice("run5"));
		devices.put("run6", new StringDevice("run6"));
		devices.put("run7", new StringDevice("run7"));
		devices.put("run8", new StringDevice("run8"));
		devices.put("run9", new StringDevice("run9"));
		devices.put("run10", new StringDevice("run10"));
		devices.put("run11", new StringDevice("run11"));
		devices.put("run12", new StringDevice("run12"));
		devices.put("run13", new StringDevice("run13"));
		devices.put("run14", new StringDevice("run14"));
		devices.put("run15", new StringDevice("run15"));
		devices.put("run16", new StringDevice("run16"));

		devices.put("runExtra0", new StringDevice("runExtra0"));
		devices.put("runExtra1", new StringDevice("runExtra1"));
		devices.put("runExtra2", new StringDevice("runExtra2"));
		devices.put("runExtra3", new StringDevice("runExtra3"));
		devices.put("runExtra4", new StringDevice("runExtra4"));
		devices.put("runExtra5", new StringDevice("runExtra5"));
		devices.put("runExtra6", new StringDevice("runExtra6"));
		devices.put("runExtra7", new StringDevice("runExtra7"));
		devices.put("runExtra8", new StringDevice("runExtra8"));
		devices.put("runExtra9", new StringDevice("runExtra9"));
		devices.put("runExtra10", new StringDevice("runExtra10"));
		devices.put("runExtra11", new StringDevice("runExtra11"));
		devices.put("runExtra12", new StringDevice("runExtra12"));
		devices.put("runExtra13", new StringDevice("runExtra13"));
		devices.put("runExtra14", new StringDevice("runExtra14"));
		devices.put("runExtra15", new StringDevice("runExtra15"));
		devices.put("runExtra16", new StringDevice("runExtra16"));

		devices.put("lastImageCollected", new StringDevice("lastImageCollected"));
		devices.put("detectorType", new StringDevice("detectorType"));
		devices.put("robot_status", new StringDevice("robot_status"));
		devices.put("screeningActionList", new StringDevice("screeningActionList"));
		devices.put("robot_cassette", new StringDevice("robot_cassette"));
		devices.put("current_user_log", new StringDevice("current_user_log"));
		devices.put("sequenceDeviceState", new StringDevice("sequenceDeviceState"));
		devices.put("crystalSelectionList", new StringDevice("crystalSelectionList"));
		devices.put("screeningParameters", new StringDevice("screeningParameters"));
		devices.put("dose_data", new StringDevice("dose_data"));
		devices.put("sil_id", new StringDevice("sil_id"));
		devices.put("collect_msg", new StringDevice("collect_msg"));
		devices.put("collect_default", new StringDevice("collect_default"));
		devices.put("system_status", new StringDevice("system_status"));
		devices.put("scan_msg", new StringDevice("scan_msg"));
		devices.put("system_idle", new StringDevice("system_idle"));
		devices.put("sil_config", new StringDevice("sil_config"));

		devices.put("gonio_phi", new StepperMotorDevice("gonio_phi"));
		devices.put("beamstop_z", new StepperMotorDevice("energy"));
		devices.put("detector_z", new StepperMotorDevice("detector_z"));
		devices.put("energy", new PseudoMotorDevice("energy"));
//		devices.put("i2", new IonChamberDevice("i2"));
		devices.put("shutter", new ShutterDevice("shutter"));

	}


	/**
	 * Connect to the dcss and become active if the
	 * beamline is idle.
	 */
	synchronized public void connect()
		throws Exception
	{

		if ((dcssHost == null) || (dcssHost.length() == 0))
			throw new Exception("Cannot find dcss host name config for beamline " + beamline + " in webice server config");
		if (dcssPort <= 0)
			throw new Exception("Cannot find dcss port config for beamline " + beamline + " in webice server config");

		if ((monitor != null) && monitor.isAlive())
			throw new Exception("Connection to dcss has already been made");

		// Start thread to connect to dcss via socket.
		monitor = new MonitorThread(this);
		monitor.start();

	}
	
	/**
	 * Read the latest dcss params
	 */
	private void readDumpFile()
	{
		// read the dump file
		try {

			// Parse the dump file and get the devices
			// whose type we registered to the parser.
			DBParser parser = new DBParser();
			parser.addDeviceType(DeviceType.STRING);
			parser.addDeviceType(DeviceType.STEPPER_MOTOR);
			parser.addDeviceType(DeviceType.PSEUDO_MOTOR);
			parser.addDeviceType(DeviceType.SHUTTER);
			parser.addDeviceType(DeviceType.ION_CHAMBER);
			parser.addDeviceType(DeviceType.RUN);
			parser.addDeviceType(DeviceType.RUNS);
			parser.parse(getDumpFile(), devices, false);

		} catch (Exception e) {
			// Ignore error
			WebiceLogger.debug("DcsConnector:beamline = " + beamline + " LoadDumpFile failed for "
					+ getDumpFile() + ": " + e.getMessage());
		}
	}

	/**
	 */
	public String getDumpFile()
	{
		return ServerConfig.getDcsDumpDir() + "/" + getBeamline() + ".dump";
	}

    	/**
	 * set thread stop flag
 	 */
	private void setStopFlag(boolean b)
	{
    		if (monitor != null) {
			WebiceLogger.info("DcsConnector: beamline = " + beamline + " calling monitor.setStopFlag(" + b + ")");
			monitor.setStopFlag(b);
		}
		monitor = null;
		
	}

    	/**
	 * Get thread stop flag
 	 */
	private boolean getStopFlag()
	{		
		if (monitor == null)
			return true;
		return monitor.getStopFlag();
		
	}

	/**
	 * Add listener
	 */
	synchronized public void addListener(Object lis)
		throws Exception
	{
		if (listeners.contains(lis))
			return;

		// Connect if this is the first
		// listener
		if (listeners.size() == 0)
			connect();

		listeners.put(lis, lis);

		WebiceLogger.info("DcsConnector: beamline = " + beamline + " added listener (total=" + listeners.size() + "): " + lis.toString());
	}

	/**
	 * Remove listener
	 */
	synchronized public void removeListener(Object lis)
		throws Exception
	{
		listeners.remove(lis);

		WebiceLogger.info("DcsConnector: beamline = " + beamline + " removed listener (total=" + listeners.size() + "): " + lis.toString());

		// Disconnect if there is no more listener
		if (listeners.size() == 0) {
			setStopFlag(true);
		}

	}

	synchronized public boolean isDcssReady()
	{
		return dcssReady;
	}

	synchronized private void setDcssReady(boolean s)
	{
		dcssReady = s;
	}


	/**
	 * Returns the currently connected beamline.
	 * Returns null if it is not connected.
	 */
	public String getBeamline()
	{
		return beamline;
	}
	
	public String getDcssStatus()
	{
		String dd = getSystemIdle();
		if (dd == null)
			return "";
			
		if (dd.startsWith("sequence"))
			return "screening";
		else if (dd.contains("collectRuns"))
			return "collecting";
		else if (dd.contains("collectRun"))
			return "collecting";
		else if (dd.contains("collectWeb"))
			return "collecting";
			
		return "";
			
	}

	synchronized public String getSystemIdle()
	{
		StringDevice dd = getStringDevice("system_idle");
		if (dd == null)
			return null;

		return dd.getContents();
	}

	synchronized public int getNumRuns()
		throws Exception
	{
		StringDevice dd = getStringDevice("runs");
		if (dd == null)
			throw new Exception("Cannot get string device runs");

		String cc = dd.getContents();

		if (cc.length() == 0)
			throw new Exception("String device runs is empty");

		StringTokenizer tok = new StringTokenizer(cc);
		if (tok.countTokens() < 2)
			throw new Exception("String device runs does not contain 3 numbers: " + dd.getContents());

		tok.nextToken(); // not used
		String tt = tok.nextToken();
		try {
			return Integer.parseInt(tt);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid content for string device runs: " + dd.getContents());
		}

	}

	synchronized public String getCollectMsg()
	{
		StringDevice dd = getStringDevice("collect_msg");
		if (dd == null)
			return null;

		return dd.getContents();
	}

	/**
	 * Get current energy
	 */
	public double getEnergy()
	{
		PseudoMotorDevice dd = getPseudoMotorDevice("energy");
		if (dd == null)
			return 0.0;
		return dd.getPosition();
	}

	public PseudoMotorDevice getEnergyDevice()
	{
		return getPseudoMotorDevice("energy");
	}
	
/*	public IonChamberDevice getIonChamberDevice(String name)
	{
		Device d = (Device)devices.get(name); // name == i2 for example

		if ((d != null) && (d instanceof IonChamberDevice))
			return (IonChamberDevice)d;

		return null;
	}*/

	public ShutterDevice getShutterDevice()
	{
		Device d = (Device)devices.get("shutter");

		if ((d != null) && (d instanceof ShutterDevice))
			return (ShutterDevice)d;

		return null;
	}

	/**
	 * Get current beamstop
	 */
	public double getBeamStop()
	{
		StepperMotorDevice dd = getStepperMotorDevice("beamstop_z");
		if (dd == null)
			return 0.0;
		return dd.getPosition();
	}

	public StepperMotorDevice getBeamStopDevice()
	{
		return getStepperMotorDevice("beamstop_z");
	}

	/**
	 * Calculate detector mode based on detector type and exposure time.
	 */
	public int getDetectorMode(double time)
	{
		int mode = 0;
		String type = getDetectorType();
		if (type.equals("Q4CCD")) {
			if (time > 30.0) {
				mode = 4; // unbinned slow_dezing
			} else {
				mode = 0; // unbinned slow
			}
		} else if (type.equals("Q315CCD")) {
			if (time > 30) {
				mode = 6; // binned dezinger
			} else {
				mode = 2; // binned
			}
		} else if (type.equals("MAR165") || type.equals("MAR325")) {
			if (time > 30) {
				mode = 1; // dezinger
			} else {
				mode = 0; // normal
			}
		} else if (type.equals("MAR345")) {
			return 2;
		}

		return mode;
	}


	/**
	 * Return detector mode name for the given mode
	 */
	public String getDetectorModeString(int mode)
	{
		return getDetectorModeString(getDetectorType(), mode);
	}

	static public String getDetectorModeString(String type, int mode)
	{
		if (type.equals("Q4CCD")) {
			if (mode == 6)
				return "binned slow dezinger";
			else if (mode == 2)
				return "binned slow";
		} else if (type.equals("Q315CCD")) {
			if (mode == 6)
				return "binned dezinger";
			else if (mode == 2)
				return "binned";
		} else if (type.equals("MAR165") || type.equals("MAR325")) {
			if (mode == 1)
				return "dezinger";
			else if (mode == 0)
				return "normal";
		} else if (type.equals("MAR345")) {
			switch (mode) {
				case 0:
					return "345mmx150um";
				case 1:
					return "300mmx150um";
				case 2:
					return "240mmx150um";
				case 3:
					return "180mmx150um";
				case 4:
					return "345mmx100um";
				case 5:
					return "300mmx100um";
				case 6:
					return "240mmx100um";
				case 7:
					return "180mmx100um";
			}
		} else if (type.equals("PILATUS6")) {
			return "normal";
		}

		return String.valueOf(mode);
	}

	public double getDetectorDistance()
	{
		StepperMotorDevice dd = getStepperMotorDevice("detector_z");
		if (dd == null)
			return 0.0;
		return dd.getPosition();
	}

	public double getAttenuation()
	{
		PseudoMotorDevice dd = getPseudoMotorDevice("attenuation");
		if (dd == null)
			return 0.0;
		return dd.getPosition();
	}

	public StepperMotorDevice getDetectorDistanceDevice()
	{
		return getStepperMotorDevice("detector_z");
	}

	public StepperMotorDevice getGonioPhiDevice()
	{
		return getStepperMotorDevice("gonio_phi");
	}

	public SystemStatusString getSystemStatus()
		throws Exception
	{
		StringDevice dd = getStringDevice("system_status");

		if (dd == null)
			return null;

		return new SystemStatusString(dd.getContents());
	}

	public String getScanMsg()
		throws Exception
	{
		StringDevice dd = getStringDevice("scan_msg");

		if (dd == null)
			return null;

		return dd.getContents();
	}

	/**
	 * Return detector radius for the current detector type
	 */
	public double getDetectorRadius()
	{
		String type = getDetectorType();
		if (type.equals("Q4CCD")) {
			return 192.0/2.0;
		} else if (type.equals("Q315CCD")) {
			return 315/2.0;
		} else if (type.equals("MAR345")) {
			// Assuming that we use the default detector mode which is 2.
			// 240xx x 150 um (format 1600)
			return 240/2.0;
//			return 345/2.0;
		} else if (type.equals("MAR165")) {
			return 165/2.0;
		} else if (type.equals("MAR325")) {
			return 325/2.0;
		} else if (type.equals("PILATUS6")) {
			return 211.218; // returns the shortest distance from the center to the edge of the detector, assumming that the user is collecting from the center.
		}

		return 0.0;

	}

	/**
	 * Default osc range for data collection
	 */
/*	public double getDefaultOscRange()
	{
		StringDevice device = getStringDevice("collect_default");

		if (device == null)
			return 1.0;

		try {

			StringTokenizer tok = new StringTokenizer(device.getContents(), " ");
			if (tok.countTokens() < 3)
				return 1.0;

			return Double.parseDouble(tok.nextToken());

		} catch (NumberFormatException e) {
			return 1.0;
		}
	}*/
	
	public double getDefaultOscRange()
		throws Exception
	{
		return getCollectDefault().getDefOscRange();
	}

	/**
	 * Default exposure time for data collection
	 * collect_default:
	 * Delta_default exposure_time_default attenuation_default min_exposure_time max_exposure_time min_attenuation max_attenuation
	 */
	public double getDefaultExposureTime()
		throws Exception
	{
		return getCollectDefault().getDefExposureTime();
	}

	/**
	 * Default attenuation for data collection
	 */
	public double getDefaultAttenuation()
		throws Exception
	{		
		return getCollectDefault().getDefAttenuation();
	}
	
	public CollectDefault getCollectDefault()
		throws Exception
	{
		Device d = (Device)devices.get("collect_default");
		
		if (d == null)
			throw new Exception("Cannot find collect_default device");

		if (!(d instanceof StringDevice))
			throw new Exception("collect_default is not string device");

		WebiceLogger.info("DcsConnector getCollectDefault: collect_default content = " + ((StringDevice)d).getContents());
		return new CollectDefault(((StringDevice)d).getContents());

	}

	/**
	 */
	public Runs getRuns()
	{
		try {
		StringDevice dev = getStringDevice("runs");

		if (dev == null)
			return null;

		return new Runs("runs", dev.getContents());

		} catch (Exception e) {
			WebiceLogger.error("Failed to get runs device: " + e.getMessage(), e);
		}

		return null;
	}

	/**
	 * Get current run definition
	 */
	public RunDefinition getRunDefinition()
	{
		Runs r = getRuns();
		if (r == null)
			return null;

		int curRun = r.current;
		return getRunDefinition(curRun);
	}

	/**
	 */
	public double getDetectorResolution()
	{
		return getDetectorResolution(getEnergy(), getDetectorDistance(), getDetectorRadius());
	}

	/**
	 */
	static public double getDetectorResolution(double en, double d, double radius)
	{
		// resolution = wavelength / ( 2 * sin(atan(radius/d) / 2 ) )
		double wavelength = 12398.0/en;
		double res = wavelength / ( 2.0 * Math.sin(Math.atan(radius/d) / 2.0 ) );
		WebiceLogger.info("getDetectorResolution: en = " + en + ", radius = " + radius
				+ ", d = " + d
				+ ",  wavelength = " + wavelength
				+ ", res = " + res);
		return res;
	}


	/**
	 * Current exposure time from collect_default
	 * "<delta> <exposure time>"
	 */
	public double getOscRange()
		throws Exception
	{
		return getCollectDefault().getDefOscRange();
	}

	/**
	 * Current exposure time from collect_default
	 * "<delta> <exposure time>"
	 */
	public double getExposureTime()
		throws Exception
	{
		return getCollectDefault().getDefExposureTime();
	}


	/**
	 * Get current run definition
	 */
	public RunDefinition getRunDefinition(int which)
	{
		String n = "run" + String.valueOf(which);
		try {
		StringDevice dev = getStringDevice(n);

		if (dev == null)
			return null;

		return new RunDefinition(n, dev.getContents());

		} catch (Exception e) {
			WebiceLogger.warn("Failed to get getRunDefinition device " + n + ": " + e.getMessage());
		}

		return null;
	}
	
	public boolean isQueueEnabled() {
		StringDevice dev = getStringDevice("sil_config");
		if (dev == null)
			return false;
		String contents = dev.getContents();
		WebiceLogger.info("DcsConnector: sil_config = " + contents);
		StringTokenizer tok = new StringTokenizer(contents, " ");
		if (tok.countTokens() < 4)
			return false;
		tok.nextToken(); tok.nextToken(); tok.nextToken();
		String queueFlag = tok.nextToken(); // 4th token
		return queueFlag.equals("2");
	}


	/**
	 * Returns a string device if found in database dump file
	 */
	synchronized public StringDevice getStringDevice(String name)
	{
		Device d = (Device)devices.get(name);

		if ((d != null) && (d instanceof StringDevice))
			return (StringDevice)d;

		return null;
	}

	synchronized public StepperMotorDevice getStepperMotorDevice(String name)
	{
		Device d = (Device)devices.get(name);

		if ((d != null) && (d instanceof StepperMotorDevice))
			return (StepperMotorDevice)d;

		return null;
	}

	synchronized public PseudoMotorDevice getPseudoMotorDevice(String name)
	{
		Device d = (Device)devices.get(name);

		if ((d != null) && (d instanceof PseudoMotorDevice))
			return (PseudoMotorDevice)d;

		return null;
	}

	/**
	 * Returns content of lastImageCollected string device.
	 */
	public String getLastImageCollected()
	{
		StringDevice device = getStringDevice("lastImageCollected");

		if (device == null)
			return "";

		if (device.getContents().equals("{}"))
			return "";

		return device.getContents();
	}

	/**
	 * Returns content of detectorType string device.
	 */
	public String getDetectorType()
	{
		StringDevice device = getStringDevice("detectorType");

		if (device == null)
			return "";

		String content = device.getContents();

		if (content.equals("{}"))
			return "";

		if (content.startsWith("{") && content.endsWith("}"))
			return content.substring(1, content.length() - 1);

		return content;
	}

	/**
	 * Find out if the crystal has been mounted by the robot. If so,
	 * return "<cassette_position> <port_number> <port_letter>", if manual mount
	 * then returns an empty String.
	 * If the device is not found then returns null.
	 * status: 0
	 * need_reset: 0
	 * need_cal: 0
	 * state: idle
	 * warning: {}
	 * cal_msg: {Gonio Cal: Done}
	 * cal_step: {100 of 100}
	 * mounted: {m 2 A}
	 * pin_lost: 0
	 * pin_mounted: 213
	 * manual_mode: 0
	 * need_mag_cal: 0
	 * need_cas_cal: 0
	 * need_clear: 0
	 */
	public String getRobotMountStatus()
	{
		StringDevice device = getStringDevice("robot_status");
		String content = device.getContents();

		if (device == null)
			return null;

		int pos1 = content.indexOf("mounted: {");
		if (pos1 > 0) {
			int pos2 = content.indexOf("}", pos1);
			if (pos2 > pos1)
				return content.substring(pos1+10, pos2);
		}
		return null;
	}

	public RobotStatus getRobotStatus()
		throws Exception
	{
		StringDevice device = getStringDevice("robot_status");
		if (device == null)
			return null;

		String content = device.getContents();

		return new RobotStatus(content);
	}

	public StepperMotorDevice getGonioPhi()
	{
		return getStepperMotorDevice("gonio_phi");
	}
	
	public ScreeningParameters getScreeningParameters()
		throws Exception
	{
		StringDevice device = getStringDevice("screeningParameters");
		if (device == null)
			return null;
			
		String content = device.getContents();
		return new ScreeningParameters(content);
	}

	/**
	 */
	synchronized public ScreeningStatus getScreeningStatus()
		throws Exception
	{
		String str = getCrystalSelectionListString();

		if (str == null) {
			WebiceLogger.info("in getScreeningStatus: null crystalSelectionList");
			return null;
		}

		int pos = str.indexOf(" ");
		int row = -1;
		if (pos > 0) {
			try {
				row = Integer.parseInt(str.substring(0, pos));
			} catch (NumberFormatException e) {
				throw new Exception("Invalid crystal row number from crystalSelectionList string: " + str);
			}
		}


		SequenceDeviceState info = getSequenceDeviceState();

		if (str == null) {
			WebiceLogger.info("in getScreeningStatus: null sequenceDeviceState");
			throw new Exception("Null sequenceDeviceState string");
		}

		if (info.cassetteIndex < 0)
			throw new Exception("Invalid current cassette index from sequenceDeviceState string");

		CassetteInfo cassette = info.cassette[info.cassetteIndex];

		if (cassette == null)
			throw new Exception("null cassette info from sequenceDeviceState string for position: " + info.cassetteIndex);

		ScreeningStatus stat = new ScreeningStatus();
		stat.screening = isScreening();
		stat.cassettePosition = info.getCassettePosition();
		stat.silId = cassette.silId;
		stat.row = row;

		return stat;

	}

	/**
	 * Return the owner of the cassette position
 	 */
	public CassetteOwner getCassetteOwner()
		throws Exception
	{
		StringDevice dev = getStringDevice("cassette_owner");

		if (dev == null)
			throw new Exception("Cannot get string device cassette_owner");

		return new CassetteOwner(dev.getContents());
	}

	/**
	 * screeningActionList
	 * <running or not: 1/0> <current action: 0->13> <next action: 0->13> <{action list: 0...13}>
	 */
	public boolean isScreening()
	{
		StringDevice device = getStringDevice("screeningActionList");

		if (device == null)
			return false;

		String content = device.getContents();

		if (content.startsWith("1"))
			return true;

		return false;

	}

	/**
	 * robot_cassette
	 * Updated when port status changes. Can be used to tell if there is port jam
	 * <1: left position status> <2-97: port status from A1 to L8> <98: middle position status> <99-195: port status from A1 to L8> <196: right position status> <197-293: port status from A1 to L8>
	 * Cassette status:
	 *	0: No cassette
	 *	1: Normal cassette
	 *	2: Calibration cassette
	 *	3: Puck adapter
	 *	u: Unknown status
	 * Port status:
	 *	0: Empty
	 *	1: Containing a sample
	 *	j: Port jammed
	 *	b: Bad
	 *	u: Unknown status
	 *	m: Mounted
	 *	-: Not exists
	 *
	 * For example:
	 * u 1 1 1 1 1 u u u 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ....
	 */
	public String getRobotCassetteString()
	{
		StringDevice device = getStringDevice("robot_cassette");

		if (device != null)
			return device.getContents();

		return null;
	}

	public RobotCassette getRobotCassette()
		throws Exception
	{
		StringDevice device = getStringDevice("robot_cassette");

		if (device == null)
			throw new Exception("Failed get to robot_cassette string from dump file");

		String str = device.getContents();

		return RobotCassette.parse(str);

	}

	public String getCurrentUserLog()
	{
		StringDevice dev = getStringDevice("current_user_log");
		if (dev == null)
			return null;
		return dev.getContents().trim();
	}


	/**
	 * sequenceDeviceState
	 * Updated when cassette is changed (assigned/unassigned) at the beamline.
	 * <user> <active casette status> {(<owner>|<cassette id>|<silId>)*4}
	 * Active assette position:
	 *	0: No cassette
	 *	1: Left
	 *	2: Middle
	 * 	3: Right
	 * For example:
	 * jsong 1 { undefined  cassette_91l.xls(penjitk|UNKNOWN|2931)  undefined  undefined  }
	 */
	public String getSequenceDeviceStateString()
	{
		StringDevice device = getStringDevice("sequenceDeviceState");

		if (device != null)
			return device.getContents();

		return null;
	}

	public SequenceDeviceState getSequenceDeviceState()
		throws Exception
	{
		SequenceDeviceState ret = null;
		try {

		StringDevice device = getStringDevice("sequenceDeviceState");

		if (device == null)
			return null;

		ret = SequenceDeviceState.parse(device.getContents());

		} catch (Exception e) {
			WebiceLogger.error("error in DcsConnector::getCassetteInfo: " + e.getMessage(), e);
			throw e;
		}

		return ret;

	}

	 /**
	  * crystalSelectionList
	  * Updated when crystal selection has changed. Shows status of crystal
	  * at each port for the active cassette. See sequenceDeviceState to
	  * find out which is the active cassette.
	  * <row of current crystal> <row of next crystal> {<crystal status>*96}
	  * crystal status:
	  * 0: not selected
	  * 1: selected
	  * For example:
	  * -1 -1 {1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1....}
 	  */
	 public String getCrystalSelectionListString()
	 {
		StringDevice device = getStringDevice("crystalSelectionList");

		if (device != null)
			return device.getContents();

		return null;
	 }

	 /**
	  * crystalStatus
	  * Updated during screening.
	  * <currently mounted crystal id> <next crystal id> <mode: rebot/manual> <mounted: 0/1> <current subdir> <robot sync: yes/no>
	  *
	  * For example:
	  * {} A1 robot 0 {} yes
	  */

	 /**
	  * sil_id
	  * Current silId being screened.
	  * This string is not reliable when
	  * the cassette is undefined in the active cassette position.
	  * In this case, sil_id
	  * may still be the sil previously screened
	  * at this cassette position.
	  * Must be used in conjunction with sequenceDeviceState and rebot_cassette.
	  */
	public String getSilId()
	{
		StringDevice device = getStringDevice("sil_id");

		if (device == null)
			return "";

		if (device.getContents().equals("{}"))
			return "";

		return device.getContents();
	}

	/**
	 * Cassette position: left, middle, right
	 */
	public Document getSilDocument(int pos, String owner, String sessionId)
		throws Exception
	{
		SequenceDeviceState st = this.getSequenceDeviceState();

		if ((pos < 1) || (pos > 3))
			return null;

		CassetteInfo cinfo = st.cassette[pos];

		// No sil associated with the cassette at this position.
		if ((cinfo.silId == null) || (cinfo.silId.length() == 0))
			return null;

		// Do not allow user to view cassettes that they don't own.
		if (!cinfo.owner.equals(owner))
			throw new Exception(owner + " is not the owner of cassette " + cinfo.silId
				+ ". Owner is " + cinfo.owner);

		String urlStr = ServerConfig.getSilGetSilUrl()
				+ "?silId=" + cinfo.silId
				+ "&userName=" + owner
				+ "&accessID=" + sessionId;


		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to load sil " + cinfo.silId
						+ " crystals server returns an error: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		//Instantiate a DocumentBuilderFactory.
		javax.xml.parsers.DocumentBuilderFactory dFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();

		//Use the DocumentBuilderFactory to create a DocumentBuilder.
		javax.xml.parsers.DocumentBuilder dBuilder = dFactory.newDocumentBuilder();
//		dBuilder.setEntityResolver(this);

		//Use the DocumentBuilder to parse the XML input.
		Document doc = dBuilder.parse(con.getInputStream());

		con.disconnect();

		return doc;

	}

	synchronized private void setDcssOnline(boolean s)
	{
		dcssOnline = s;
	}

	synchronized public boolean isDcssOnline()
	{
		return dcssOnline;
	}

	/**
	 */
	synchronized private void broadcast()
	{
		DcsConnectorListener lis = null;
		for (Enumeration e=listeners.keys(); e.hasMoreElements();) {
			lis = (DcsConnectorListener)e.nextElement();
			lis.dcsUpdate();
		}

	}

	/**
	 * Encrypt a string with public key and then encode it with 64-bit encoding.
	 */
	static public String encrypt(String keystoreName, String password, String alias, String raw)
		throws Exception
	{	 		
		if (keystoreName == null)
			throw new Exception("DcsConnector failed to encrypt session id: null keystore filename, check dcs.keystoreFile");
				
		if (password == null)
			throw new Exception("DcsConnector failed to encrypt session id: null keystore password, check dcs.keystorePassword");
			
		if (alias == null)
			throw new Exception("DcsConnector failed to encrypt session id: null certificate entry name");
			
		// Load keystore file with a password
		File keystoreFile = new File(keystoreName);
		if (keystoreFile == null)
			throw new Exception("Failed to find keystore file " + keystoreName);
						
		FileInputStream stream = new FileInputStream(keystoreFile);
		if (stream == null)
			throw new Exception("Failed to open keystore file " + keystoreName);
			
		KeyStore ks = KeyStore.getInstance("JKS");
		char[] passPhrase = password.toCharArray();
		ks.load(stream, passPhrase);
				
                // Get certificate of public key
                Certificate cert = ks.getCertificate(alias);
    
                // Get public key
                PublicKey publicKey = cert.getPublicKey();
		
		// Encrypt it with a public key
		Cipher cipher = Cipher.getInstance("RSA");
		cipher.init(Cipher.ENCRYPT_MODE, publicKey);
		byte[] encrypted = cipher.doFinal(raw.getBytes());
		
		// Do base-64 encoding on the encrypted data
//		BASE64Encoder encoder = new BASE64Encoder();		
//		return encoder.encode(encrypted);
		return Base64.encodeBase64String(encrypted); // apache commons
	}

	/*********************************************************************
	 * PRIVATE THREAD CLASS
	 *********************************************************************/
	private class MonitorThread extends Thread
	{

		private char[] inBuf = null;
		private int inLen = 0;

		private boolean stopFlag = false;
		private DcsConnector dcs = null;

	public MonitorThread(DcsConnector d)
	{
		dcs = d;
	}
	
	public void finalize()
	{
		setStopFlag(false);
	}

	synchronized public boolean getStopFlag()
	{
		return stopFlag;
	}

	synchronized public void setStopFlag(boolean s)
	{
		WebiceLogger.info("MonitorThread for beamline " + beamline + " setting stop flag to " + s);
		stopFlag = s;
	}

 	/**
	 * Called only by run().
	 * Read dcs message. Expect 26 char for header.
	 */
	private String readMessage(InputStreamReader in)
		throws Exception
	{
		if (in == null)
			throw new Exception("readMessage failed: null InputStreamReader");

		char[] header = readFixedLength(in, HEADER_LENGTH);
		inLen = parseHeader(header);
		inBuf = readFixedLength(in, inLen);

		String str = new String(inBuf).trim();
//		if (!str.contains("hutchDoorStatus") && !str.contains("update_motor_position") && !str.contains("robot_attribute"))
//			WebiceLogger.info("DcsConnector <== " + str);

		return str;

	}


	/**
	 * Called only by readMessage().
	 * Read a fixed length message
 	 */
	char[] readFixedLength(InputStreamReader in, int max)
		throws Exception
	{
		if (in == null)
			throw new Exception("readFixedLength failed: null InputStreamReader");

 		char[] arr = new char[max];
		int len = 0;
		int chunk_size = 0;
		while (len < max) {
			chunk_size = in.read(arr, len,  max-len);
			if (chunk_size < 0)
				break;
			len += chunk_size;
		}

		if (len != max)
			throw new Exception("Expected to read " + max + " from socket but got " + len);

		return arr;
	}

	/**
	 * Called by readMessage().
	 * Parse dcs message header. Expect a number.
	 */
	private int parseHeader( char[] header )
		throws Exception
	{
		NumberFormat nf = NumberFormat.getInstance();
		nf.setParseIntegerOnly(true);

		String strHeader = new String(header).trim();

        	try {
            		return nf.parse(strHeader).intValue();
        	} catch (ParseException e) {
            		throw new Exception("Invalid dcs message header");
        	}
	}

	/**
	 * Called only by run().
	 * Send a dcs message.
	 */
	private void sendMessage(OutputStreamWriter out, char buf[])
		throws Exception
	{
		if (out == null)
			throw new Exception("sendMessage failed: null OutputStreamWriter");

		out.write(buf);
		out.flush( );
//		WebiceLogger.info("==> " + new String(buf));
	}

	/**
	 * Create a message of any length. Header is 
	 * always 26 chars.
	 */
	private char[] createMessage(String content)
		throws Exception
	{
		// Construct a dcs message from a string
		String header = Integer.toString(content.length());
		header += " 0";

		int total_length = content.length() + HEADER_LENGTH;
		CharArrayWriter myWriter = new CharArrayWriter(total_length);

		myWriter.write(header, 0, header.length());

		//fill other with 00000
		int pad_length = HEADER_LENGTH - header.length();
		for (int i= 0; i < pad_length; ++i) {
			myWriter.write(0);
		}

		myWriter.write(content, 0,  content.length());
		return myWriter.toCharArray();
		
	}

	/**
	 */
	private char[] createFixedLengthMessage(String string, int total_length)
	{
		CharArrayWriter myWriter = new CharArrayWriter(total_length);
		myWriter.write( string, 0, string.length() );

		//fill other with 00000
		total_length -= string.length();
		for (int i= 0; i < total_length; ++i) {
			myWriter.write(0);
		}
		return myWriter.toCharArray();
	}

   	/**
	 * Thread routine
	 */
	public void run()
	{
	
		int maxReportedErrors = 5;
		int numReportedErrors = 0;
		
		// Loop in case dcss is restarted
		while (!getStopFlag()) {

		Socket sock = null;
		InputStreamReader in = null;
		OutputStreamWriter out = null;
		InputStream inStream = null;
		
		// Before we really get connected to the dcss, 
		// read the latest dcss params dump into a file.
		readDumpFile();

		setDcssOnline(false);

		// Authenticate webice user here
		// Create a new session id if needed.
		try {
			authenticate();
		} catch (Exception e) {
			WebiceLogger.error("DcsConnector cannot connect to beamline " + beamline 
					+ " because authentication failed for webice user: " 
					+ e.getMessage());
			try {
				Thread.sleep(1000); // sleep 1 second before trying again.
			} catch (InterruptedException ee) {
				WebiceLogger.error("Sleep failed in DcsConnector main loop because " + ee.getMessage());
			}
			
			continue;
		}

		try {

		// #####################################
		// Create socket and io
		// #####################################
		
		// Create a socket with or without SSL
		if (ServerConfig.isDcsUseSSL()) {
			if (numReportedErrors <= maxReportedErrors)
				WebiceLogger.info("DcsConnector connecting with SSL to beamline " + beamline
				+ ": host=" + dcssHost + " port=" + dcssPort 
				+ " num listeners=" + listeners.size());		
			// server certificate must be in the trusted store 
			// specified by -Djavax.net.ssl.trustStore commandline argument.
			SocketFactory socketFactory = SSLSocketFactory.getDefault();
        		sock = socketFactory.createSocket(dcssHost, dcssPort);
		} else {
			if (numReportedErrors <= maxReportedErrors)
				WebiceLogger.info("DcsConnector connecting to beamline " + beamline
							+ ": host=" + dcssHost + " port=" + dcssPort 
							+ " num listeners=" + listeners.size());		
			sock = new Socket(dcssHost, dcssPort);
		}
		
	    	out = new OutputStreamWriter(sock.getOutputStream());
		inStream = sock.getInputStream();
	    	in = new InputStreamReader(inStream);

		setDcssOnline(true);

		// #####################################
		// Connect to dcss
		// #####################################
		// Wait for stoc_send_client_type message from dcss
		String str = readMessage(in);
		if (!str.startsWith("stoc_send_client_type"))
			throw new Exception("Expected stoc_send_client_type from dcss but got "
						+ str);

		// Get unique client id assigned by dcss
		String clientId = "";
		if (str.length() > 21) {
			clientId = str.substring(21).trim();
		}
		
		// If dcss gives us a client id then we
		// need to encrypt the session id as
		// clientId:timestamp:sessionId with 
		// a public key and send it to dcss
		// after gtos_client_is_gui.
		String cipherString = sessionId;
		if (clientId.length() > 0) {
			cipherString = "DCS_CYPHER";
		}

		String hostname = ServerConfig.getTomcatHost();		
		if (hostname == null)
			hostname = "unknown";
			
		// Send "htos_client_is_gui userName sessionId hostname display"
		str = "gtos_client_is_gui " + userName
				+ " " + cipherString
				+ " " + hostname
				+ " " + display;
		char[] buf = createFixedLengthMessage(str, FIXED_LENGTH);
		sendMessage(out, buf);

		// If we only send DCS_CIPHER in gtos_client_is_gui
		// then here we need to send the encrypted 
		// clientId:timestamp:sessionId as a dcss message.
		if (cipherString.equals("DCS_CYPHER")) {
			// Time since January 1, 1970, 00:00:00 GMT in seconds
			long timestamp = new Date().getTime()/1000;
			String rawTxt = clientId + ":" + timestamp + ":" + sessionId;
			// Keystore password
			String password = ServerConfig.getDcsKeystorePassword();
			String keystoreName = ServerConfig.getDcsKeystoreFile();
			// The certificate is saved in the keystore with beamline name
			// as the certificate entry name 
			String alias = beamline;
			// Encrypt the string with public key
			// and encode the bytes with base64 encoding.
			String encryptedTxt = encrypt(keystoreName, password, alias, rawTxt);
			char[] msg = createMessage(encryptedTxt);
			sendMessage(out, msg);
		}

		// Wait for stog_respond_to_challenge from dcss
		str = readMessage(in);
		if (str.indexOf("stog_login_complete") == 0) {
			WebiceLogger.info("Got stog_login_complete: " + str);
		} else {
			throw new Exception("Expected stog_login_complete from dcss but got " + str);
		}

		// #####################################
		// Send and receive dcs messages
		// #####################################
		StringTokenizer tok = null;
		String command = "";
		String device = "";
		int numArgs = 0;
		setDcssReady(false);
		while (!getStopFlag()) {

			// Read the next message
			// We don't call inStream.available() since
			// it always returns 0 for InputStream from 
			// SSLSocket.
			// Socket read will yield to other threads
			// if there is nothing to read.			
			str = readMessage(in);

			// Don't parse log messages
			// Save it in a list
			if (str.startsWith("stog_log")) {
//				addLog(str);
				continue;
			}

			tok = new StringTokenizer(str, " ");
			numArgs = tok.countTokens();
			command = tok.nextToken();
			device = "";
			if (numArgs > 1)
				device = tok.nextToken();

			if (command.equals("stog_dcss_end_update_all_device")) {
				// We can start sending messages to dcss
				// after this.
				setDcssReady(true);
				WebiceLogger.info("DCSS is now ready to receive messages from gui");
			} else if (command.equals("stog_configure_string") ||
					command.equals("stog_set_string_completed") ||
					command.equals("stog_configure_real_motor") ||
					command.equals("stog_motor_move_completed") ||
					command.equals("stog_configure_shutter") ||
					command.equals("stog_configure_pseudo_motor")) {

				try {
				Device s = (Device)devices.get(device);
				if (s != null) {
					s.parseDcsMsg(str);
				}

				} catch (Exception e) {
					WebiceLogger.warn("Failed to parse dcs msg for device " + device + ": " + e.getMessage());
				}
			}
		} // while loop
		
		WebiceLogger.info("DcsConnector thread for beamline " + beamline + " exiting message loop.");

		} catch (InterruptedException e) {
			++numReportedErrors;
			if (numReportedErrors <= maxReportedErrors)
				WebiceLogger.debug("DcsConnector thread " + beamline + ": InterruptedException" + e.getMessage());
		} catch (Exception e) {
			++numReportedErrors;
			if (numReportedErrors <= maxReportedErrors)
				WebiceLogger.debug("DcsConnector thread " + beamline + ": Exception " + e.getMessage());
		}

		setDcssOnline(false);

		// #####################################
		// Close socket and io
		// #####################################
		try {
			if (in != null)
				in.close();
		} catch (Exception e) {
			WebiceLogger.error("Error in closeConnectionNoThrow: " + e.getMessage());
		}

		try {
			if (out != null)
				out.close();
		} catch (Exception e) {
			WebiceLogger.error("Error in closeConnectionNoThrow: " + e.getMessage());
		}

		try {
			if (sock != null)
				sock.close();
		} catch (Exception e) {
			WebiceLogger.error("Error in closeConnectionNoThrow: " + e.getMessage());
		}

		in = null;
		inStream = null;
		out = null;
		sock = null;

		if (!getStopFlag()) {
			try {
			// sleep for 1 second before trying to reconnect
			// to dcss again.
			Thread.sleep(1000);
			} catch (InterruptedException e) {
				WebiceLogger.error("Sleep failed in DcsConnector main loop because " + e.getMessage());
			}
		}

		} // while loop

		WebiceLogger.info("DcsConnector thread for beamline " + beamline + " exited");

	} // end run() method

	} // end MonitorThread class
}


