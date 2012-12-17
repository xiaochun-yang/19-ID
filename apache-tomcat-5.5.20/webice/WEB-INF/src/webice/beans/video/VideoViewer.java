package webice.beans.video;

import java.util.*;
import java.io.*;
import java.net.*;

import webice.beans.*;

public class VideoViewer implements PropertyListener
{
	private String hutchPreset = "";
	private String robotPreset = "";
	private String controlPreset = "";
		
	private Client client = null;
		
	private Hashtable hutchPresetList = null;
	private Hashtable controlPresetList = null;
	private Hashtable robotPresetList = null;
	
	
	static public String SAMPLE_CAMERA = "sample";
	static public String HUTCH_CAMERA = "hutch";
	static public String ROBOT_CAMERA = "robot";
	static public String PANEL_CAMERA = "panel";
	static public String ALL_CAMERAS = "all";
			
	public VideoViewer(Client c)
	{		
		client = c;
	}
		
	public String getHutchPreset()
	{
		return hutchPreset;
	}
	
	public String getRobotPreset()
	{
		return robotPreset;
	}
	
	public String getControlPreset()
	{
		return controlPreset;
	}
	
	
	/**
	 */
	public Hashtable getHutchPresetList()
	{			
		hutchPresetList = getPresetList(HUTCH_CAMERA);
		
		return hutchPresetList;
	}

	/**
	 */
	public Hashtable getRobotPresetList()
	{
		robotPresetList = getPresetList(ROBOT_CAMERA);
		
		return robotPresetList;
	}

	/**
	 */
	public Hashtable getControlPresetList()
	{
		controlPresetList = getPresetList(PANEL_CAMERA);
		
		return controlPresetList;
	}

	/**
	 */
	public Hashtable getPresetList(String camera)
	{
		Hashtable ret = new Hashtable();
		
		try {
		
		String beamline = client.getBeamline();
		
		String urlStr = ServerConfig.getRequestPresetUrl(beamline, camera);
		
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("failed to get preset for camera " + camera + " at beamline " + beamline + ": "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		int pos = 0;
		String presetName = "";
		String realName = "";
		while ((line=reader.readLine()) != null) {
			if (line.length() < 1)
				continue;
			pos = line.indexOf("=");
			if (pos < 1)
				continue;
			
			realName = line.substring(pos+1).trim();
			if (realName.charAt(0) == '0') {
				presetName = realName.substring(1);
				ret.put(presetName, realName);
			} else {
				// if preset is not prefixed 
				// with 0, only staff can see it.
				if (client.getUserStaff()) {
					presetName = realName;
					ret.put(presetName, realName);
				}
			}
			
								
		}

		reader.close();
		con.disconnect();
		
		} catch (Exception e) {
			WebiceLogger.error("VideoViewer failed to get preset list for hutch camera", e);
		}
		
		return ret;
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
	public void changePreset(String camera, String preset)
		throws Exception
	{
		
		if (!client.isConnectedToBeamline())
			return;
		String beamline = client.getBeamline();
		String realPresetName = null;
		if (camera.equals(HUTCH_CAMERA))
			realPresetName = (String)hutchPresetList.get(preset);
		else if (camera.equals(PANEL_CAMERA))
			realPresetName = (String)controlPresetList.get(preset);
		else if (camera.equals(ROBOT_CAMERA))
			realPresetName = (String)robotPresetList.get(preset);
		else
			return;
			
		WebiceLogger.info("VideoViewer: changePreset camera = " + camera
					+ " preset = " + preset
					+ " real preset = " + realPresetName);
			
		if (realPresetName == null)
			throw new Exception("Invalid preset: " + preset);
			
		String urlStr = ServerConfig.getMovePresetUrl(beamline, camera)
				+ "&gotoserverpresetname=" + realPresetName;
				
		
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		int response = con.getResponseCode();
		// Could return 204 No Content
		if ((response < 200) || (response > 299))
			throw new Exception("failed to move preset to " + preset 
				+ " for camera " + camera + " at beamline " + beamline + ": "
				+ String.valueOf(response) + " " + con.getResponseMessage()
				+ " (for " + urlStr + ")");


		con.disconnect();
		
		if (camera.equals(HUTCH_CAMERA))
			hutchPreset = preset;
		else if (camera.equals(PANEL_CAMERA))
			controlPreset = preset;
		else if (camera.equals(ROBOT_CAMERA))
			robotPreset = preset;
		
		
	}
	
	/**
	 */
	public void changeVideoText(String camera, String preset)
		throws Exception
	{
		if (!client.isConnectedToBeamline())
			return;
		String beamline = client.getBeamline();
		String realPresetName = null;
		if (camera.equals(HUTCH_CAMERA))
			realPresetName = (String)hutchPresetList.get(preset);
		else if (camera.equals(PANEL_CAMERA))
			realPresetName = (String)controlPresetList.get(preset);
		else if (camera.equals(ROBOT_CAMERA))
			realPresetName = (String)robotPresetList.get(preset);
			
		if (realPresetName == null)
			throw new Exception("Invalid preset: " + preset);
			
		String urlStr = ServerConfig.getVideoTextUrl(beamline, camera)
				+ "&text=" + preset;
				
		
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		int response = con.getResponseCode();
		// Could return 204 No Content
		if ((response < 200) || (response > 299))
			throw new Exception("failed to change video text to " + preset 
				+ " for camera " + camera + " at beamline " + beamline + ": "
				+ String.valueOf(response) + " " + con.getResponseMessage()
				+ " (for " + urlStr + ")");


		con.disconnect();
		
	}
	
	/**
	 * Select a camera to display.
	 */
	public void setCurrentCamera(String name)
	{
		client.getProperties().setProperty(getViewerName() + ".currentCamera", name);

	}
	
	/**
	 * Return camera being displayed.
	 */
	public String getCurrentCamera()
	{
		return client.getProperties().getProperty(getViewerName() + ".currentCamera", "all");

	}
		
	/**
	 */
	public int getCameraUpdateRate(String cam)
	{
		return client.getProperties().getPropertyInt(getViewerName() + "." + cam + ".updateRate", 5);	
	}
		
	/**
	 */
	public void setCameraUpdateRate(String cam, int seconds)
	{
		if (seconds < 1)
			seconds = 1;
		client.getProperties().setProperty(getViewerName() + "." + cam + ".updateRate", seconds);
	}
		
	public String getViewerName()
	{
		return "video";
	}
	
}

