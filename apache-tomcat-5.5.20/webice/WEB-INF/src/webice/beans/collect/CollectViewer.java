/**
 * Javabean for SMB resources
 */
package webice.beans.collect;

import webice.beans.*;
import java.net.*;
import java.io.*;
import java.util.*;
import webice.beans.dcs.*;

/**
 * @class CollectViewer
 * Bean class that represents an autoindex viewer.
 */
public class CollectViewer implements PropertyListener
{
	private Client client = null;
	
	public static String SHOW_CURRENT_RUN = "curRun";
	public static String SHOW_MY_RUNS = "myRuns";
	public static String SHOW_BEAMLINE_LOG = "beamlineLog";
	
	private String viewType = SHOW_CURRENT_RUN;
	
	static public int NOT_COLLECTING = 1;
	static public int COLLECTRUNS = 2;
	static public int COLLECTRUN = 3;
	static public int COLLECTWEB = 4;
	
	private int selectedRunDef = 0;

	/**
	 * Default constructor
	 */
	public CollectViewer()
		throws Exception
	{
		init();
	}
	
	/**
	 * Constructor
	 */
	public CollectViewer(Client c)
		throws Exception
	{
		client = c;
		
		init();
	}
	
	private void init()
		throws Exception
	{
		Imperson imp = client.getImperson();
		if (!imp.dirExists(getWorkDir()))
			imp.createDirectory(getWorkDir());

	}
	
	/**
	 * Callback when a config value is changed
	 */
	public void propertyChanged(String name, String val)
		throws Exception
	{
	}
		
	/**
	 */
	public String getWorkDir()
	{
		return client.getWorkDir() + "/collect";
	}
	
	/**
	 */
	public boolean isConnectedToBeamline()
	{
		return client.isConnectedToBeamline();
	}
	
	/**
	 */
	public String getLastImageCollected()
		throws Exception
	{
		DcsConnector dcs = getDcsConnector();
		
		return dcs.getLastImageCollected();
	}
	
	/**
	 *
	 */
	public String getLastImageUrl()
		throws Exception
	{
		
		String lastImage = getLastImageCollected();
		int width = 200;
		int height = 200;
		double centerX = 0.5;
		double centerY = 0.5;
		int gray = 400;
		int zoom = 1;
		
		String url = "servlet/loader/getImage?fileName=" + lastImage
					+ "&sizeX=" + String.valueOf(width)
					+ "&sizeY=" + String.valueOf(height)
					+ "&percentX=" + String.valueOf(centerX)
					+ "&percentY=" + String.valueOf(centerY)
					+ "&gray=" + String.valueOf(gray)
					+ "&zoom=" + String.valueOf(zoom)
					+ "&userName=" + client.getUser()
					+ "&sessionId=" + client.getSessionId();

		return url;
		
		
	}
	
	/**
	 */
	public String getViewType()
	{
		return viewType;
	}
	
	/**
	 *
	 */
	public void setViewType(String t)
	{
		if (viewType == null)
			return;
			
		if (t.equals(SHOW_CURRENT_RUN))
			viewType = SHOW_CURRENT_RUN;
		else if (t.equals(SHOW_BEAMLINE_LOG))
			viewType = SHOW_BEAMLINE_LOG;
		else if (t.equals(SHOW_MY_RUNS))
			viewType = SHOW_MY_RUNS;
	}
	
	/** 
	 *
	 */
	private DcsConnector getDcsConnector()
		throws Exception
	{
		if (!isConnectedToBeamline())
			throw new Exception("Not connected to a beamline");
			
		DcsConnector dcs = client.getDcsConnector();
		
		if (dcs == null)
			throw new Exception("Got null DcsConnector");
			
		return dcs;
	}
	
	/**
	 */
	public RunDefinition getCurRunDefinition()
		throws Exception
	{	
		DcsConnector dcs = getDcsConnector();
		
		return dcs.getRunDefinition();			
	}
	
	public RunDefinition getRunDefinition(int runNum)
		throws Exception
	{	
		DcsConnector dcs = getDcsConnector();
		
		return dcs.getRunDefinition(runNum);			
	}
	
	public int getCurRunNumber()
		throws Exception
	{	
		DcsConnector dcs = getDcsConnector();
		
		Runs runs = dcs.getRuns();
		if (runs != null)
			return runs.current;
			
		return 0;	
	}
	
	/**
	 */
	public String getDetectorModeString(int mode)
		throws Exception
	{
		DcsConnector dcs = getDcsConnector();
			
		return dcs.getDetectorModeString(mode);
		
	}
	
	/**
	 * collect_msg string is updated for all types of 
	 * data collection operations including collectWeb, collectRuns
	 * and collectRun.
	 */
	public String getCollectMsg()
		throws Exception
	{
		
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			return "Not connected to a beamline";
			
		CollectMsgString msg = new CollectMsgString(dcs.getCollectMsg());
		if (msg == null)
			return "Data collection not running";
		// TODO: check if this run is the same as the
		// currently selected autoindex run in the autoindex tab.
		// If not returns an error.
		//if (!msg.runName.)
		return msg.msg;
		
	}
	
	
	/**
	 * Returns: NOT_COLLECTING, COLLECTRUNS, COLLECTRUN, COLLECTWEB
	 */
	public int getCollectStatus()
		throws Exception
	{
		
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			throw new Exception("Not connected to a beamline");
			
		// collectWeb operation is active.
		String systemIdle = dcs.getSystemIdle();

		if ((systemIdle == null) || (systemIdle.length() == 0))
			return NOT_COLLECTING;
			
		if (systemIdle.contains("collectRuns"))
			return COLLECTRUNS;
			
		if (systemIdle.contains("collectRun"))
			return COLLECTRUN;
			
		if (systemIdle.contains("collectWeb"))
			return COLLECTWEB;
					
		return NOT_COLLECTING;
		
	}
	
	/**
	 * This is the string displayed on the status bar of bluice.
	 */
	public SystemStatusString getSystemStatus()
		throws Exception
	{
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			throw new Exception("Not connected to a beamline");
			
		return dcs.getSystemStatus();
		
	}
	
	/**
	 * Connect to dcss, check if our run is the current run
	 * and send abortCollectWeb operation.
	 * Will throw an exception if abortCollectWeb fails.
	 */
	public void abortCollectWeb()
		throws Exception
	{
		if (!client.isConnectedToBeamline())
			throw new Exception("Not connected to a beamline");
		
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
				
	}
	
	public Runs getRuns()
		throws Exception
	{
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			throw new Exception("Not connected to a beamline");
			
		return dcs.getRuns();
		
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
	
	public void selectRunDef(int which)
	{
		if ((which > -1) && (which < 17))
			selectedRunDef = which;
	}
	
	public int getSelectedRunDef()
	{		
		return selectedRunDef;
	}

}


