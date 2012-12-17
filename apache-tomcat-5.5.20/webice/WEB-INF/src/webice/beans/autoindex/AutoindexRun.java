package webice.beans.autoindex;

import webice.beans.*;
import java.util.Hashtable;
import webice.beans.image.ImageViewer;
/**
 * Controls the run and contains the results.
 */
public class AutoindexRun
{

	private AutoindexViewer viewer = null;
	private RunController controller = null;
	private AutoindexImageViewer imageViewer = null;

	private String runName = "";
	private String workDir = "";
	
	private String silId = "";
	private int row = -1;
	private int repositionId = -1;
	private int runIndex = -1;
	private int runLabel = -1;

	private String selectedSolution = "";
	private String selectedSpaceGroup = "";

	private boolean showStrategyDetails = false;
	private boolean showAnomStrategyDetails = false;

	public static String STRATEGY_DC = "dcStrategy";
	public static String STRATEGY_UNIQUE = "uniqueData";
	public static String STRATEGY_ANOM = "anomData";
	public static String STRATEGY_TESTGEN = "testgen";

	private String strategyType = STRATEGY_DC;

	private int imageWidth = 700;

	public static String TAB_SETUP = "setup";
	public static String TAB_STATUS = "status";
	public static String TAB_AUTOINDEX = "autoindex";
	public static String TAB_SCAN = "scan";
	public static String TAB_SOLUTIONS = "solutions";
	public static String TAB_STRATEGY = "strategy";
	public static String TAB_PREDICTIONS = "predictions";
	public static String TAB_DETAILS = "details";
	public static String TAB_LOG = "log";
	public static String TAB_RELOAD = "reload";

	private String selectedTab = "setup";

	private boolean showFileBrowser = false;

	private boolean useApplet = false;
	
	public static String EXP_MONOCHROMATIC = "Native";
	public static String EXP_ANOMALOUS = "Anomalous";
	public static String EXP_MAD = "Mad";
	public static String EXP_SAD = "Sad";
	
	public static String PHI_STRATEGY_UNIQUE = "Native";
	public static String PHI_STRATEGY_ANOM = "Anomalous";
	
	private String phiStrategyType = "";
	private String expType = "";	

	private boolean showCassetteBrowser = false;
	
	private String scanFile = "";
	private String scanDir = "";
	
	// Which scan plot to show (raw scan or fpfpp)
	public static String SCANPLOT_RAW = "raw";
	public static String SCANPLOT_FPFPP = "fpfpp";
	private String scanPlotType = SCANPLOT_RAW;
	
	private String setupType = "autoindex";
	private String logType = "autoindex";
	
	/**
	 */
	public AutoindexRun(AutoindexViewer viewer, String runName)
		throws Exception
	{		
		this(viewer, runName, viewer.getWorkDir() + "/" + runName);

	}

	/**
	 */
	public AutoindexRun(AutoindexViewer viewer, String runName, String workDir)
		throws Exception
	{
		this.viewer = viewer;
		this.runName = runName;
		this.controller = new RunController(this, viewer.getClient());
		this.workDir = workDir;
		this.imageViewer = new AutoindexImageViewer(viewer.getClient(), this);
	}

	/**
	 */
	public RunController getRunController()
	{
		return controller;
	}

	public String getRunName()
	{
		return runName;
	}
	
	/**
	 */
	public String getWorkDir()
	{
		return workDir;
	}
	
	/**
	 */
	public String getDefaultStrategyMethod()
	{
		return viewer.getDefaultStrategyMethod();
	}
	
	/**
	 */
	public Imperson getImperson()
	{
		return viewer.getClient().getImperson();
	}

	/**
	 */
	public String getSesseionId()
	{
		return viewer.getClient().getSessionId();
	}

	/**
	 */
	public String getUser()
	{
		return viewer.getClient().getUser();
	}
	
	public String getSilId() {
		return silId;
	}
	public void setSilId(String silId) {
		this.silId = silId;
	}
	
	public int getRow() {
		return row;
	}
	
	public void setRow(int row) {
		this.row = row;
	}
	
	public int getRepositionId() {
		return repositionId;
	}
	
	public void setRepositionId(int repositionId) {
		this.repositionId = repositionId;
	}

	/**
	 */
	public void load()
		throws Exception
	{
		controller.load();
		
		selectImage(controller.getImageDir() + "/" + controller.getImage1());

	}
	public void stopMonitoring()
	{
		controller.stopMonitoring();
	}


	/**
	 */
	public String getAutoindexResultFile()
	{	
		if (controller.getSetupData().getVersion() > 1.0)
			return getWorkDir() + "/LABELIT/labelit.xml";
		else
			return getWorkDir() + "/labelit.xml";
	}

	/**
	 */
	public String getLabelitOutFile()
	{	
		if (controller.getSetupData().getVersion() > 1.0)
			return getWorkDir() + "/LABELIT/labelit.out";
		else
			return getWorkDir() + "/labelit.out";
	}

	/**
	 */
	public void selectSolution(String sol)
	{
		if (sol == null)
			return;

		selectedSolution = sol;
		selectedSpaceGroup = "";
	}

	/**
	 */
	public String getSelectedSolution()
	{
		return selectedSolution;
	}

	/**
	 */
	public String getSelectedSpaceGroup()
	{
		if ((selectedSpaceGroup == null) || (selectedSpaceGroup.length() == 0))
			return getDefaultSpaceGroup();
			
		return selectedSpaceGroup;
	}
	
	public String getDefaultSpaceGroup()
	{
		if (controller != null) {
			return controller.getSetupData().getLaueGroup();
		}
		
		return "";
	}

	/**
	 */
	public void selectSpaceGroup(String sp)
	{
		if (sp == null)
			return;

		selectedSpaceGroup = sp;
	}
	
	public String getDefaultSp()
	{
		if (controller != null)
			return controller.getSetupData().getLaueGroup();
			
		return "";
	}

	/**
	 */
	public boolean getShowStrategyDetails()
	{
		return showStrategyDetails;
	}

	/**
	 */
	public void setShowStrategyDetails(boolean b)
	{
		showStrategyDetails = b;
	}

	/**
	 */
	public boolean getShowAnomStrategyDetails()
	{
		return showAnomStrategyDetails;
	}

	/**
	 */
	public void setShowAnomStrategyDetails(boolean b)
	{
		showAnomStrategyDetails = b;
	}

	/**
	 */
	public void selectSolutionAndSpaceGroup(String sol, String sp)
	{
		selectSolution(sol);
		selectSpaceGroup(sp);
	}

	/**
	 */
	public String getSelectedImage()
	{
		return imageViewer.getImageFile();
	}

	/**
	 */
	public void selectImage(String s)
	{
		try {
		imageViewer.setImageFile(s);
		
		} catch (Exception e) {
			// ignore
		}
	}

	/**
	 */
	public int getImageWidth()
	{
		return imageWidth;
	}

	/**
	 */
	public void setImageWidth(int w)
	{
		if (w < 100)
			w = 100;

		imageWidth = w;
	}

	/**
	 * Return url location to image file generated by labelit
	 * For backward compatability.
	 */
	public String getImageUrl()
	{
		String selectedImage = getSelectedImage();
		if ((selectedImage == null) || (selectedImage.length() == 0))
			return "";

		String file = getWorkDir() + "/" + getBaseName(selectedImage) + "_overlay_mosflm.png";

		String url = "servlet/loader/readPngFile?impUser=" + viewer.getClient().getUser()
						+ "&impSessionID=" + viewer.getClient().getSessionId()
						+ "&impFilePath=" + file;

		return url;
	}


	private String getBaseName(String filename)
	{
		int pos = filename.lastIndexOf('.');
		if (pos > -1)
			filename = filename.substring(0, pos);
		
		pos = filename.lastIndexOf('/');
		if (pos > -1)
			filename = filename.substring(pos+1);

		return filename;
	}

	/**
	 */
	public String getDefaultImageDir()
	{
		return viewer.getImageDir();
	}

	/**
	 */
	public void setDefaultImageDir(String s)
		throws Exception
	{
		viewer.setImageDir(s);
	}

	/**
	 * Override NavNode method.
	 */
	public boolean isTabViewable(String tabName)
	{
		if (tabName.equals(TAB_SETUP)) {
			return true;
		} else if (tabName.equals(TAB_SOLUTIONS)) {
//			return (controller.isStrategyDone() || controller.isAutoindexDone());
			return (controller.isIntegrationDone() || controller.isAutoindexDone());
		} else if (tabName.equals(TAB_AUTOINDEX)) {
			return (controller.isIntegrationDone() || controller.isAutoindexDone());
		} else if (tabName.equals(TAB_DETAILS)) {
			return ((controller.getStatus() != RunController.AUTOINDEX_RUNNING)
					|| controller.isIntegrationDone()
					|| controller.isAutoindexDone());
		} else if (tabName.equals(TAB_SCAN)) {
			return (controller.getSetupData().getExpType().equals("MAD")
				|| controller.getSetupData().getExpType().equals("SAD"));
		} else if (tabName.equals(TAB_PREDICTIONS)) {
			return controller.isAutoindexDone();
		} else if (tabName.equals(TAB_STRATEGY)) {
			return (controller.isStrategyDone() || controller.isAutoindexDone());
		} else if (tabName.equals(TAB_RELOAD)) {
			return true;
		} else if (tabName.equals(TAB_LOG)) {
			return true;
		} else if (tabName.equals(TAB_STATUS)) {
			return true;
		}

		return false;
	}

	/**
	 */
	public String getSelectedTab()
	{
		return selectedTab;
	}

	/**
	 */
	public void selectTab(String s)
	{
		selectedTab = s;
	}

	/**
 	 */
	public void setShowFileBrowser(boolean s)
	{
	 	showFileBrowser = s;
	}

	/**
	 */
	public boolean getShowFileBrowser()
	{
		return showFileBrowser;
	}

	/**
	 */
	public boolean isUseApplet()
	{
		return useApplet;
	}

	/**
	 */
	public void setUseApplet(boolean t)
	{
		useApplet = t;
	}
	
	/**
	 */
	public String getStrategyType()
	{
		return strategyType;
	}

	/**
	 */
	public void setStrategyType(String s)
	{
		if (s == null)
			return;

		strategyType = s;

		if (strategyType.equals(STRATEGY_UNIQUE) ||
			strategyType.equals(STRATEGY_ANOM) ||
			strategyType.equals(STRATEGY_TESTGEN) ||
			strategyType.equals(STRATEGY_DC))
				return;

		strategyType = STRATEGY_DC;
	}
	
	public String getExpType()
	{
		return controller.getSetupData().getExpType();
	}
	
	
	public String getPhiStrategyType()
	{	
		if  ((phiStrategyType == null) || (phiStrategyType.length() == 0))
			phiStrategyType = getDefaultPhiStrategyType();
			
		return phiStrategyType;
	}
	
	public String getDefaultPhiStrategyType()
	{			
		String ex = getExpType();
		if (ex.equals("Native"))
			return PHI_STRATEGY_UNIQUE;
		else if (ex.equals("MAD") || ex.equals("SAD"))
			return PHI_STRATEGY_ANOM;
			
		return PHI_STRATEGY_UNIQUE;
	}
	
	public void setPhiStrategyType(String s)
	{
		if (s == null)
			return;
		phiStrategyType = s;
		
		if (phiStrategyType.equals(PHI_STRATEGY_UNIQUE) ||
			phiStrategyType.equals(PHI_STRATEGY_ANOM))
			return;
			
		phiStrategyType = PHI_STRATEGY_UNIQUE;
	}
	
	public String getLabelitXmlString()
		throws Exception
	{		
		if (controller.getSetupData().getVersion() > 1.0)
			return getImperson().readFile(getWorkDir() + "/LABELIT/labelit.xml");
		else
			return getImperson().readFile(getWorkDir() + "/labelit.xml");
		
	}
	
	public void setShowCassetteBrowser(boolean s)
	{
		showCassetteBrowser = s;
	}
	
	public boolean isShowCassetteBrowser()
	{
		return showCassetteBrowser;
	}
		
	public String getScanFile()
	{
		return scanFile;
	}
	
	public void setScanFile(String s)
	{
		if (s == null)
			return;
		scanFile = s;
	}
	
	public String getScanDir()
	{
		return scanDir;
	}
	
	public void setScanDir(String s)
	{
		scanDir = s;
		
		if ((scanDir == null) || (scanDir.length() == 0))
			scanDir = controller.getSetupData().getImageDir();
			
	}
	
	public String getScanPlotType()
	{
		return scanPlotType;
	}
	
	public void setScanPlotType(String s)
	{
		scanPlotType = s;
		
		if ((scanPlotType == null) || (scanPlotType.length() ==  0))
			scanPlotType = SCANPLOT_RAW;
			
		if (scanPlotType.equals(SCANPLOT_RAW) && scanPlotType.equals(SCANPLOT_FPFPP))
			scanPlotType = SCANPLOT_RAW;
			
		
	}
	
	public ImageViewer getImageViewer()
	{
		return imageViewer;
	}

	public void gotoNextImage()
	{
		selectImage(controller.getImageDir() + "/" + controller.getImage2());
	}
	
	public void gotoPrevImage()
	{
		selectImage(controller.getImageDir() + "/" + controller.getImage1());
	}
	
	public String getSetupType()
	{
		return setupType;
	}
	
	public void setSetupType(String s)
	{
		if ((s != null) && (s.length() > 0))
			setupType = s;
	}
	
	public String getLogType()
	{
		return logType;
	}
	
	public void setLogType(String s)
	{
		if ((s != null) && (s.length() > 0))
			logType = s;
	}
	
	public int getRunIndex() {
		return runIndex;
	}
	
	public void setRunIndex(int runIndex) {
		this.runIndex = runIndex;
	}
	
	public int getRunLabel() {
		return runLabel;
	}
	
	public void setRunLabel(int runLabel) {
		this.runLabel = runLabel;
	}
}
