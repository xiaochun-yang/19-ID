/**
 * Javabean for SMB resources
 */
package webice.beans.screening;

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

import webice.beans.*;
import webice.beans.image.ImageViewer;
import java.net.*;
import java.io.*;
import java.util.*;
import java.text.*;

import webice.beans.dcs.*;

/**
 * @class ImageViewer
 * Bean class that represents an image viewer. Holds parameters for setting
 * up a display for the image.
 */
public class ScreeningViewer implements EntityResolver, PropertyListener, ImageViewerController, ErrorListener
{
	static public int SSRL_CASSETTE = 1;
	static public int PUCK_CASSETTE = 2;
	static public int OTHER_CASSETTE = 3;
	
	static public String ONE_CRYSTAL = "one";
	static public String MULTI_CRYSTAL = "multi";
	 
	private Client client = null;
	private String silId = "";
	private Document silDoc = null;
	private String silOwner = null;
	private int silType = SSRL_CASSETTE;

	private int selectedRow = -1;
	private Element selectedCrystal = null;
	private Element selectedImages = null;
	private Element selectedGroup = null;
	private Element selectedImage = null;

	// overview or details.
	static public String DISPLAY_ALLSILS = "allSils";
	static public String DISPLAY_DETAILS = "silDetails";
	static public String DISPLAY_QUEUE = "silQueue";
	static public String DISPLAY_OVERVIEW = "silOverview";
	private String displayMode = DISPLAY_ALLSILS;
	
	static public String SILLIST_DIR = "dirList";
	static public String SILLIST_USER = "userList";
	static public String SILLIST_BEAMLINE = "beamlineList";

	private ImageViewer imgViewer = null;

	private String silList = "";

	private String displayTemplateDir = "";
	private String defDisplayTemplate = "display_result";
	private String defDisplayOption = "hide";
	private String displayRows = "all";
	
	private AnalysisMonitorThread aThread = null;
	
	private FileBrowser fileBrowser = null;
	private FileBrowser outputFileBrowser = null;
	
//	private String silListMode = SILLIST_USER;
	private String curSilListDisplay = SILLIST_USER;
	
	private int scrollX = 0;
	private int scrollY = 0;

	private String filterBy = null;
	private String wildcard = null;
	
	private String silListSortColumn = "CassetteID";
	private boolean silListSortAscending = true;
	private String silListSortType = "number";
	
	private String curSortColumn = "Port";
	private String curSortDirection = "ascending";
	
	private String selectionMode = ONE_CRYSTAL;
	
	/**
	 * Constructor
	 */
	public ScreeningViewer(Client c)
		throws Exception
	{
		client = c;

		fileBrowser = new FileBrowser(client);
		fileBrowser.changeDirectory(client.getUserImageRootDir());
		
		outputFileBrowser = new FileBrowser(client);
		outputFileBrowser.setShowImageFilesOnly(false);
		
		// Get silListMode from webice.properties 	
		String silListMode = ServerConfig.getSilListMode();
		if (silListMode.equals("both"))
			curSilListDisplay = SILLIST_USER;
		else
			curSilListDisplay = silListMode;
			
		// Add if the user does not exist
		// in the crystal server DB.
		addUserToCrystalDB();
		
		curSortColumn = getSortColumn();
		curSortDirection = getSortOrder();
		
	}
	
	private void addUserToCrystalDB()
		throws Exception
	{
		try {

		String tt = ServerConfig.getSilAddUserUrl()
					+ "?userName=" + client.getUser()
					+ "&accessID=" + client.getSessionId()
					+ "&Login_Name=" + client.getUser()
					+ "&format=text"
					+ "&Real_Name=" + client.getUserName();

		String urlStr = tt.replace(" ", "%20");
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to add user to crystals DB "
						+ " crystals server returns an error: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				buf.append(line);
		}
		
		String ret = buf.toString();
		WebiceLogger.info(ret);

		reader.close();
		con.disconnect();

		} catch (Exception e) {
			WebiceLogger.error(e.getMessage(), e);
//			throw e; // do not throw otherwise webice will not be able to start if crystals server is dead.
		}	
	}
	
	public String getSilListMode()
	{
		return ServerConfig.getSilListMode();
	}
	
/*	public void setSilListMode(String s)
	{
		silListMode = s;
	}*/
	
	public void setCurSilListDisplay(String s)
	{
		curSilListDisplay = s;
	}
	
	public String getCurSilListDisplay()
	{
		return curSilListDisplay;
	}

	/**
	 * Returns FileBrowser
	 * Used by viewers to get files/dirs
	 */
	public FileBrowser getFileBrowser()
	{
		return fileBrowser;
	}

	public FileBrowser getOutputFileBrowser()
	{
		return outputFileBrowser;
	}

	/**
	 */
	public void setImageViewer(ImageViewer i)
	{
		imgViewer = i;
	}

	/**
	 * ImageViewerController method
	 * 1. Try to get dir from spreadsheet field spotfinderDir for the given image.
	 * 2. if (1) fails, assumes default spotfinder dir
	 */
	public String getSpotDir()
	{
		if (selectedImage == null)
			return "";
			
		// Find spotfinderDir attribute in the image node.
		// This attribute should be recorded by the crystal-analysis 
		// server.
		String dir = selectedImage.getAttribute("spotfinderDir");
		
		if ((dir != null) && (dir.length() > 0))
			return dir;
			
		String crystalId = getCrystalField(selectedCrystal, "CrystalID");
		return getDefaultSpotfinderDir(silId, crystalId);
	}

	private String getDefaultSpotfinderDir(String sil_id, String crystal_id)
	{
		return client.getUserRootDir()
				+ "/webice/screening/" + sil_id
				+ "/" + crystal_id + "/spotfinder";
	}

	/**
	 */
	private String getCrystalField(Element crystal, String fieldName)
	{
		if (crystal == null)
			return null;

		NodeList nodes = crystal.getElementsByTagName(fieldName);

		if ((nodes == null) || (nodes.getLength() == 0))
			return null;

		Node child = nodes.item(0);
		Node grandChild = child.getFirstChild();

		if (grandChild == null)
			return null;

		if (!(grandChild instanceof Text))
			return null;

		return grandChild.getNodeValue();

	}

	/**
	 * ImageViewerController method
	 */
	public String getSpotFile()
	{
		if (selectedImage == null)
			return "";

		String dir = getSpotDir();
		String fileName = selectedImage.getAttribute("name");

		if ((dir == null) || (fileName == null))
			return "";

		int pos = fileName.lastIndexOf('.');
		if (pos < 0)
			return "";

		return dir + "/" + fileName.substring(0, pos) + ".spt.img";

	}

	/**
	 * ImageViewerController method
	 */
	public String getPredictionFile()
	{
		if (selectedImage == null)
			return "";
			
		String dir = getAutoindexDir();
		String fileName = selectedImage.getAttribute("name");

		if ((dir == null) || (fileName == null))
			return "";

		int pos = fileName.lastIndexOf('.');
		if (pos < 0)
			return "";

		return dir + File.separator + "/LABELIT/" + fileName.substring(0, pos) + ".spt.img";		
	}
	
	public boolean predictionFileExists()
	{
		String f = getPredictionFile();
		try {
				
		if (f.length() == 0)
			return false;
		
		Imperson imperson = client.getImperson();
		if (imperson.fileExists(f))
			return true;
		
		} catch (Exception e) {
			WebiceLogger.warn("Failed to check if " + f + " exists or not because " + e.getMessage());
		}
		
		return false;
	}
	

	/**
	 * ImageViewerController method
	 */
	public String getSpotLogFile()
	{
		if (selectedImage == null)
			return "";

		String dir = getSpotDir();
		String fileName = selectedImage.getAttribute("name");

		if ((dir == null) || (fileName == null))
			return "";

		int pos = fileName.lastIndexOf('.');
		if (pos < 0)
			return "";

		return dir + "/" + fileName.substring(0, pos) + ".log";

	}

	/**
	 * ImageViewerController method
	 */
	public String getCrystalJpegFile()
	{
		if (selectedImage == null)
			return "";

		String dir = selectedImage.getAttribute("dir");
		String fileName = selectedImage.getAttribute("jpeg");

		if ((dir == null) || (fileName == null))
			return "";

		return dir + File.separator + fileName;

	}

	/**
	 * Returns last image of the given group of the
	 * currently selected crystal.
	 */
	public String getCrystalImage(Element el, String group)
	{
		if (el == null)
			return null;

		Element groupNode = null;
		Element imageNode = null;

		NodeList nodes = selectedCrystal.getElementsByTagName("Images");
		if ((nodes == null) || (nodes.getLength() == 0)) {
			System.out.println("getCrystalImage cannot find 'Images' node");
			return null;
		}
		Element images = (Element)nodes.item(0);

		// loop over Group elements
		NodeList children = images.getElementsByTagName("Group");
		if ((children == null) || (children.getLength() == 0)) {
			System.out.println("getCrystalImage cannot find 'Group' node");
			return null;
		}

		for (int j = 0; j < children.getLength(); ++j) {
			groupNode = (Element)children.item(j);
			if (!group.equals(groupNode.getAttribute("name")))
				continue;
			NodeList ll = groupNode.getElementsByTagName("Image");
			if ((ll == null) || (ll.getLength() == 0))
				return null;
			// get last image of this group
			imageNode = (Element)ll.item(ll.getLength()-1);
			if (imageNode == null)
				continue;
			return imageNode.getAttribute("dir") + "/"
					+ imageNode.getAttribute("name");

		}

		System.out.println("getCrystalImage cannot find 'Group' node name " + group);
		return null;
	}


	/**
	 * Returns last image of the given group of the
	 * currently selected crystal.
	 */
	public String getSelectedCrystalImage(String group)
	{
		if (selectedCrystal == null)
			return null;

		Element groupNode = null;
		Element imageNode = null;

		// loop over Group elements
		NodeList children = selectedImages.getElementsByTagName("Group");
		if ((children == null) || (children.getLength() == 0))
			return null;

		for (int j = 0; j < children.getLength(); ++j) {
			groupNode = (Element)children.item(j);
			if (!group.equals(groupNode.getAttribute("name")))
				continue;
			NodeList ll = groupNode.getElementsByTagName("Image");
			if ((ll == null) || (ll.getLength() == 0))
				return null;
			// get last image of this group
			imageNode = (Element)ll.item(ll.getLength()-1);
			if (imageNode == null)
				continue;
			return imageNode.getAttribute("dir") + "/"
					+ imageNode.getAttribute("name");

		}

		return null;
	}

	public String getSelectedCrystalImageDir(String group)
	{
		if (selectedCrystal == null)
			return null;

		Element groupNode = null;
		Element imageNode = null;

		// loop over Group elements
		NodeList children = selectedImages.getElementsByTagName("Group");
		if ((children == null) || (children.getLength() == 0))
			return null;

		for (int j = 0; j < children.getLength(); ++j) {
			groupNode = (Element)children.item(j);
			if (!group.equals(groupNode.getAttribute("name")))
				continue;
			NodeList ll = groupNode.getElementsByTagName("Image");
			if (ll == null)
				return null;
			// get last image of this group
			imageNode = (Element)ll.item(ll.getLength()-1);
			if (imageNode == null)
				continue;
			return imageNode.getAttribute("dir");

		}

		return null;
	}

	public String getSelectedCrystalImageName(String group)
	{
		if (selectedCrystal == null)
			return null;

		Element groupNode = null;
		Element imageNode = null;

		// loop over Group elements
		NodeList children = selectedImages.getElementsByTagName("Group");
		if ((children == null) || (children.getLength() == 0))
			return null;

		for (int j = 0; j < children.getLength(); ++j) {
			groupNode = (Element)children.item(j);
			if (!group.equals(groupNode.getAttribute("name")))
				continue;
			NodeList ll = groupNode.getElementsByTagName("Image");
			if (ll == null)
				return null;
			// get last image of this group
			imageNode = (Element)ll.item(ll.getLength()-1);
			if (imageNode == null)
				continue;
			return imageNode.getAttribute("name");
		}

		return null;
	}

	/**
	 */
	public String getSelectedCrystalPort()
	{
		if (selectedCrystal == null)
			return "";

		NodeList nodes = selectedCrystal.getElementsByTagName("Port");
		if ((nodes == null) || (nodes.getLength() == 0))
			return "";

		Element node = (Element)nodes.item(0);

		return ((Text)node.getFirstChild()).getNodeValue();
	}

	/**
	 */
	public String getSelectedCrystalID()
	{
		if (selectedCrystal == null)
			return "";

		NodeList nodes = selectedCrystal.getElementsByTagName("CrystalID");
		if ((nodes == null) || (nodes.getLength() == 0))
			return "";

		Element node = (Element)nodes.item(0);

		return ((Text)node.getFirstChild()).getNodeValue();
	}

	/**
	 */
	public String getLabelitOutputFile()
	{
		return getLabelitOutputFile(false);
	}
	
	/**
	 */
	public String getLabelitOutputFile(boolean oldVersion)
	{
		if (selectedImage == null)
			return "";

		String dir = getAutoindexDir();

		if ((dir == null) || (dir.length() == 0))
			return "";

		if (oldVersion)
			return dir + File.separator + "labelit.out";
			
		return dir + File.separator + "/LABELIT/labelit.out";

	}
	
	/**
	 */
	public String getLabelitHTMLFile()
	{
		if (selectedImage == null)
			return "";

		String dir = getAutoindexDir();

		if ((dir == null) || (dir.length() == 0))
			return "";

		return dir + File.separator + "/LABELIT/labelit.html";

	}

	/**
	 */
	public String getAutoindexDir()
	{
		if (selectedImage == null)
			return "";
			
		String dir = getCrystalField(selectedCrystal, "AutoindexDir");
		
		if ((dir != null) && (dir.length() > 0))
			return dir;

		// Default autoindex result dir is 
		// crystal-analysis/<crystalID> 
		// under image dir.
		dir = selectedImage.getAttribute("dir");
		if ((dir == null) || (dir.length() == 0))
			return "";

		return getDefaultAutoindexDir(silId, getSelectedCrystalID());
//		return dir + File.separator + "crystal-analysis"
//				+ File.separator + getSelectedCrystalID();

	}

	public String getDefaultSilDir(String sil_id)
	{
		return client.getUserRootDir() + "/webice/screening/" + sil_id;
	}
	
	private String getDefaultAutoindexDir(String sil_id, String crystal_id)
	{
		return getDefaultSilDir(sil_id) + "/" + crystal_id + "/autoindex";
	}
	
	/**
	 * Check if cassette at active position at the beamline
	 */
	public boolean isCassetteAtBeamlineViewable()
		throws Exception
	{
		// Ok if this user is staff
		if (client.getUserStaff())
			return true;
			

		if (!client.isConnectedToBeamline())
			throw new Exception("User not connected to a beamline");
			
		DcsConnector dcs = client.getDcsConnector();
		
		if (dcs == null)
			throw new Exception("DcsConnector is null");
													
		SequenceDeviceState state = dcs.getSequenceDeviceState();
		// Currently active cassette position: no_cassette, left, middle, right
		int activePos = state.cassetteIndex;
		
		if ((activePos < 0) || (activePos > 3))
			throw new Exception("Invalid active cassette position (" + activePos + ")");
			
		// Spreadsheet id, owner
		CassetteInfo spreadsheetInfo = state.cassette[activePos];	
		String spreadsheetOwner = spreadsheetInfo.owner;
		
		// Ok if this user is the spreadsheet owner
		if (spreadsheetOwner.equals(client.getUser()))
			return true;
		
		// Get cassette_owner string
		CassetteOwner cassetteOwner = dcs.getCassetteOwner();
		// Owner of the active cassette position
		String activeOwner = cassetteOwner.owner[activePos];
		// Ok if this user is the current owner of the cassette position 
		// at the beamline
		if (cassetteOwner.equals(client.getUser()))
			return true;
			
		return false;
	}
	
	/**
	 * Check if this user is allowed to view currently selected spreadsheet
	 */
	public boolean isCassetteViewable()
		throws Exception
	{
		if ((silId == null) || (silId.length() == 0))
			return false;

		// Ok if this user is staff
		if (client.getUserStaff()) {
			return true;
		}
			
		// OK if this user is the owner if the spreadsheet
		if (client.getUser().equals(getSilOwner())) {
			return true;
		}
			
		// If this user is not connected to a beamline
		// then that is it.
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			return false;
				
		// But if the user is connected to a beamline
		// then check if the selected spreadsheet is loaded
		// to a beamline position or not.
		// If it is loaded to the beamline and this user
		// owns the cassette position then this user
		// can view the cassette, even if he is not
		// the spreadsheet owner.									
		SequenceDeviceState state = dcs.getSequenceDeviceState();
		CassetteOwner co = dcs.getCassetteOwner();
		for (int i = 0; i < 4; ++i) {
			CassetteInfo cas = state.cassette[i];
			if (silId.equals(cas.silId) && (co != null)) {
				// This cassette position has no owner
				// therefore anyone who has access
				// to this beamline can view the
				// spreadsheet assigned to this position.
				if ((co.owner[i].length() == 0) || co.owner[i].equals("{}"))
					return true;
				else if (co.owner[i].equals(client.getUser())
					|| co.owner[i].equals("{" + client.getUser() + "}"))
					return true;
			}
		}
			
		return false;
	}

	/**
	 * Returns true if the currently selected crystal (for viewing)
	 * is mounted at the beamline
         */
	public boolean isSelectedCrystalMounted()
	{
		try {
		if (client.isConnectedToBeamline()) {
			DcsConnector dcs = client.getDcsConnector();
			if (dcs != null) {
				ScreeningStatus screening = dcs.getScreeningStatus();
				if (screening == null)
					return false;
				if (screening.silId == null)
					return false;
/*				WebiceLogger.info("isSelectedCrystalMounted: screening silId = " + screening.silId
						+ " selected silId = " + silId
						+ " screening row = " + screening.row
						+ " selected row = " + selectedRow);*/
				if (screening.silId.equals(silId) && (screening.row == selectedRow)) {
					return true;
				}
			}
		}
		
		} catch (Exception e) {
			WebiceLogger.error("ScreeningViewer isSelectedCrystalMounted failed", e);
		}
		
		return false;
	}
	
	public String getSelectedCrystalField(String field)
	{
		if (selectedCrystal == null)
			return null;
		return getCrystalField(selectedCrystal, field);
	}
	
	/**
	 * Analyze multiple crystals
 	 */
	synchronized public void analyzeMultiCrystals(Vector rows)
		throws Exception
	{
	}
	
	/**
	 */
	synchronized public void analyzeCrystal(int row)
		throws Exception
	{
		if (row < 0)
			throw new Exception("Invalid row: " + row);
		Element el = getCrystalElement(row);
		if (el == null)
			throw new Exception("Cannot find crystal in row " + row);
		
		// clear spotfinder and autoindex results in the sil
		// and delete analysis dirs
		String crystalId = getCrystalField(el, "CrystalID");
		WebiceLogger.info("Client " + client.getUser() + " analyzing a crystal: SIL ID = " + silId
					+ " crystal ID = " + crystalId);
		String autoindexDir = getCrystalField(selectedCrystal, "AutoindexDir");
		if ((autoindexDir == null) || autoindexDir.equals(""))
			autoindexDir = getDefaultAutoindexDir(silId, crystalId);
		
		// Run autoindex
		String image1 = getCrystalImage(el, "1"); // full path
		String image2 = getCrystalImage(el, "2"); // full path
		
		System.out.println("analyzeCrystal row = " + row + " crystalId = " 
				+ crystalId + " image1 = " + image1 + " image2 = " + image2);

		// Clear crystal Results
//		clearCrystalResults(row, autoindexDir);

		// Run spotfinder
		if ((image1 != null) && (image1.length() > 0)) {
//			analyzeImage(row, crystalId, "1", image1);
			System.out.println("Analyzing row = " + row + " crystalId = " + crystalId + " image1 = " + image1);
		}
			
		if ((image2 != null) && (image2.length() > 0)) {
//			analyzeImage(row, crystalId, "2", image2);
			System.out.println("Analyzing row = " + row + " crystalId = " + crystalId + " image2 = " + image1);
		}

		if ((image1 == null) || (image1.length() == 0) || (image2 == null) || (image2.length() == 0))
			throw new Exception("Row " + row + " does not have two images");

		// Always generate strategy
		boolean strategy = true;
		// Autoindex and strategy			
//		autoindexCrystal(row, image1, image2, autoindexDir, crystalId, strategy);
		System.out.println("Autoindexing row = " + row + " crystalId = " + crystalId + " image1 = " + image1 + " image2 = " + image1);
		
		// The above only submit jobs to the crystal analysis server. 
		// Do not monitor the jobs.
	}

	/**
	 * Analyze currently selected crystal
 	 */
	synchronized public void analyzeSelectedCrystal()
		throws Exception
	{
		if ((selectedRow < 0) || (selectedCrystal == null))
			throw new Exception("No crystal currently selected");
			
		// Allow one at a time
		if (isAnalyzingCrystal1())
			throw new Exception("Analysis of another crystal is still in progress.");
						
		// clear spotfinder and autoindex results in the sil
		// and delete analysis dirs
		String crystalId = getCrystalField(selectedCrystal, "CrystalID");
		WebiceLogger.info("Client " + client.getUser() + " analyzing a crystal: SIL ID = " + silId
					+ " crystal ID = " + crystalId);
		String autoindexDir = getCrystalField(selectedCrystal, "AutoindexDir");
		if ((autoindexDir == null) || autoindexDir.equals(""))
			autoindexDir = getDefaultAutoindexDir(silId, crystalId);
		
		// Run autoindex
		String image1 = getSelectedCrystalImage("1"); // full path
		String image2 = getSelectedCrystalImage("2"); // full path
		if ((image1 == null) || (image1.length() == 0) || (image2 == null) || (image2.length() == 0))
			throw new Exception("Row " + selectedRow + " does not have two images");
						
		// Clear crystal Results
		clearCrystalResults(selectedRow, autoindexDir);

		// Run spotfinder
		analyzeImage(selectedRow, crystalId, "1", image1);
		analyzeImage(selectedRow, crystalId, "2", image2);
		
		// Do strategy if we are connected to a beamline
		// and the selected silid is the same as the 
		// sil id at the beamline, and the mounted
		// crystal row number is the same as our 
		// selected row number.
/*		boolean strategy = false;
		if (isSelectedCrystalMounted())
			strategy = true;
*/

		// Always generate strategy
		boolean strategy = true;
					
		autoindexCrystal(selectedRow, image1, image2, autoindexDir, crystalId, strategy);

		// Wait in a separate thread until the job is done
		// by looking at the control file.		
		aThread = new AnalysisMonitorThread(ServerConfig.getAutoindexHost(),
						ServerConfig.getAutoindexPort(),
						client.getUser(),
						client.getSessionId(),
						autoindexDir,
						silId,
						selectedRow,
						crystalId);
		aThread.start();
		
		// wait until the monitor thread has started.
		int waitTime = 0;
		while (!aThread.isAlive() && !aThread.isDone() && waitTime < 5000) {
			Thread.sleep(1000);
			waitTime += 1000;
		}
		
		if (!aThread.isAlive() && !aThread.isDone())
			throw new Exception("AnalysisMonitorThread failed to start after " + waitTime/1000 + " seconds");
		
			
		
	}
	
	/**
	 * Is there an analysis job running? Sync with analyzeCrystal().
 	 */
	synchronized public boolean isAnalyzingCrystal()
	{
		return isAnalyzingCrystal1();
	}
	
	/**
	 * Find out if there is an analysis job running.
 	 */
	private boolean isAnalyzingCrystal1()
	{
		if (aThread == null) {
			return false;
		}

		// a monitor thread was created for the
		// previous run but it's finished. 
		// So set it to null now.
		if (!aThread.isAlive()) {
			if (aThread.isDone()) {
				return false;
			}
			aThread = null;
			return false;
		}
		
			
		return true;
	}
	
	/**
	 * Remove crystal results in spreadsheet
	 * Only clear autoindex result (clearImages, clearSpot, clearAutoindex)
 	 */
	private void clearCrystalResults(int row, String autoindexDir)
		throws Exception
	{
		// Remove analysis result fields in spreadsheet
		String urlStr = ServerConfig.getSilClearCrystalUrl()
					+ "?userName=" + client.getUser()
					+ "&accessID=" + client.getSessionId()
					+ "&silId=" + silId
					+ "&row=" + row
					+ "&clearImages=false"
					+ "&clearSpot=true"
					+ "&clearAutoindex=true"
					+ "&clearSystemWarning=true";
					
		System.out.println("clearCrystalResults: url = " + urlStr);
					
		submitJob("clearCrystal", urlStr);
		
		// Remove result dirs, but test first if it exists
                if (client.getImperson().dirExists(autoindexDir))
		client.getImperson().deleteDirectory(autoindexDir);
	}
	
	/**
	 * Manual autoindex of the selected crystal
 	 */
	private void autoindexCrystal(int row,
					String image1, String image2,
					String workDir,
					String crystalId,
					boolean strategy)
		throws Exception
	{
		String doStrategy = "false";
		if (strategy)
			doStrategy = "true";
			
		String forBeamLine = client.getBeamline();
		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine = "default";
		String autoindexUrl = ServerConfig.getSilAutoindexUrl()
					+ "?userName=" + client.getUser()
					+ "&accessID=" + client.getSessionId()
					+ "&silId=" + silId
					+ "&row=" + row
					+ "&image1=" + image1
					+ "&image2=" + image2
					+ "&uniqueID=" + crystalId
					+ "&forBeamLine=" + forBeamLine
					+ "&strategy=" + doStrategy;
		// Send HTTP request to crystal-analysis server
		// to autoindex the images
		submitJob("autoindex", autoindexUrl);
	}
	
	private void analyzeImage(int row, String crystalId, String group, String image)
		throws Exception
	{
		String forBeamLine = client.getBeamline();
		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine = "default";
		String url = ServerConfig.getSilAnalyzeImageUrl()
					+ "?userName=" + client.getUser()
					+ "&accessID=" + client.getSessionId()
					+ "&silId=" + silId
					+ "&row=" + row
					+ "&crystalId=" + crystalId
					+ "&imageGroup=" + group
					+ "&imagePath=" + image
					+ "&forBeamLine=" + forBeamLine;
		
		submitJob("spotfinder",url);
	}

	private void submitJob(String jobName, String urlStr)
		throws Exception
	{

		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception(jobName + " failed: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				buf.append(line);
		}

		// Set silList xml
		String res = buf.toString();

		reader.close();
		con.disconnect();

		int pos = res.indexOf("OK ");
		if (pos < 0)
			throw new Exception(jobName + " failed: " + res);

		// Return eventId
		WebiceLogger.info("Re-autoindex crystal: crystal-analysis jobName = " + jobName 
			+ " event id = " 
			+ res.substring(pos+3).trim());


	}
	
	/**
	 */
	public String getSilId()
	{
		return silId;
	}

	/**
	 */
	public ImageViewer getImageViewer()
	{
		return imgViewer;
	}

	/**
	 * Called after the property value has changed
	 */
	public void propertyChanged(String name, String val)
		throws Exception
	{
		imgViewer.propertyChanged(name, val);
	}

	/**
	 * Load sil from crystals server
	 */
	public void reloadSil()
		throws Exception
	{
		loadSil(this.silId, true);
	}

	/**
	 * Load sil from crystals server
	 */
	public void loadSil(String id)
		throws Exception
	{
		loadSil(id, false);
	}
	
	/**
	 * Load sil from crystals server
	 */
	public void loadSil(String id, boolean keepSelection)
		throws Exception
	{
		loadSil(id, keepSelection, null);
	}

	/**
	 * Load sil from crystals server
	 */
	synchronized public void loadSil(String id, boolean keepSelection, String owner)
		throws Exception
	{
		try {

		this.silId = id;
		this.silOwner = owner;
		if ((this.silOwner == null) || (this.silOwner.length() == 0))
			this.silOwner = client.getUser();

		String urlStr = ServerConfig.getSilGetSilUrl()
							+ "?silId=" + silId
							+ "&userName=" + client.getUser()
							+ "&accessID=" + client.getSessionId();
									
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to load sil " + silId
						+ " crystals server returns an error: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		//Instantiate a DocumentBuilderFactory.
/*		javax.xml.parsers.DocumentBuilderFactory dFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();

		//Use the DocumentBuilderFactory to create a DocumentBuilder.
		javax.xml.parsers.DocumentBuilder dBuilder = dFactory.newDocumentBuilder();
		dBuilder.setEntityResolver(this);

		//Use the DocumentBuilder to parse the XML input.
		silDoc = dBuilder.parse(con.getInputStream());*/
		
		curSortColumn = getSortColumn();
		curSortDirection = getSortOrder();
		
		BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
		StringBuffer content = new StringBuffer();
		String line = in.readLine();
		while ((line=in.readLine()) != null) {
			line = line.replaceAll("&", "&amp;");
			line = line.replaceAll("'", "&apos;");
			if (content.length() > 0)
				content.append("\n");
			content.append(line);
		}
		
//		WebiceLogger.info("sil = " + content);
					
		ByteArrayInputStream bIn = new ByteArrayInputStream(content.toString().getBytes());
		
		// Load and sort crystal
		String templateDir = ServerConfig.getWebiceRootDir() + "/templates";
		String xsltFile = templateDir + "/sortSil.xsl";
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer(new StreamSource(xsltFile));
		StreamSource source = new StreamSource(bIn);
		DOMResult result = new DOMResult();

		transformer.setParameter("param1", templateDir + "/display_result.xml");
		transformer.setParameter("param2", getSortColumn());
		transformer.setParameter("param3", getSortOrder());
		transformer.transform(source, result);
		
		silDoc = (Document)result.getNode();
		
		con.disconnect();


		if (keepSelection) {
		
			int prevSelectedRow = selectedRow;
			// clear crystal selection
			unselectCrystal();
			// select the same row
			selectCrystal(prevSelectedRow);
			
		} else {

			// clear crystal selection
			unselectCrystal();
			// Select the first image of the first group of
			// the first crystal in the sil.
			moveToNextCrystal();
		}
		
		// ssrl, puck or other
		silType = getSilType_();

		} catch (Exception e) {
			silId = "";
			silDoc = null;
			unselectCrystal();
			WebiceLogger.error(e.getMessage(), e);
			throw e;
		}

	}
	
	/**
	 */
	synchronized public void sortSil(String column, String direction)
		throws Exception
	{
		if (silDoc == null)
			return;
		
		setSortColumn(column);
		setSortOrder(direction);
		
		sortSil();
			
	}
	/**
	 */
	synchronized public void sortSil()
		throws Exception
	{
		if (silDoc == null)
			return;
					
		Document oldDoc = silDoc;
		
		// Load and sort crystal
		String templateDir = ServerConfig.getWebiceRootDir() + "/templates";
		String xsltFile = templateDir + "/sortSil.xsl";
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer(new StreamSource(xsltFile));
		DOMSource source = new DOMSource(oldDoc.getDocumentElement());
		DOMResult result = new DOMResult();

		transformer.setParameter("param1", templateDir + "/display_result.xml");
		transformer.setParameter("param2", getSortColumn());
		transformer.setParameter("param3", getSortOrder());
		transformer.transform(source, result);
		
		silDoc = (Document)result.getNode();		
		
		// Reselect the crystal since 
		// the Crystal Element object 
		// and sil doc may be newly created objects
		// after sorting.
		if (selectedRow > -1) {
		
			int prevSelectedRow = selectedRow;
			// clear crystal selection
			unselectCrystal();
			// select the same row
			selectCrystal(prevSelectedRow);
			
		} else {

			// clear crystal selection
			unselectCrystal();
			// Select the first image of the first group of
			// the first crystal in the sil.
			moveToNextCrystal();
		}
	}
	
	/**
	 */
	public void deleteSil(String silid)
		throws Exception
	{
		String urlStr = ServerConfig.getDeleteCassetteUrl()
							+ "?forCassetteID=" + silid
							+ "&userName=" + client.getUser()
							+ "&accessID=" + client.getSessionId();

		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to delete sil " + silid
						+ " crystals server returns an error: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");
	}

	/**
	 * Save sil in cache to file
	 */
	private void saveSil(String silFileName)
		throws Exception
	{
		try
		{
			Properties silProp = new Properties();
			silProp.setProperty(OutputKeys.DOCTYPE_SYSTEM, ServerConfig.getSilDtd());

			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer();
			transformer.setErrorListener(this);
			transformer.setOutputProperties(silProp);
			String systemId = ServerConfig.getSilDtdUrl();
			DOMSource source = new DOMSource(silDoc.getDocumentElement(), systemId);
			StreamResult result = new StreamResult(new FileOutputStream(silFileName));
			transformer.transform( source, result);

		} catch (Exception e) {
			throw new Exception("Failed to save sil because " + e.getMessage());
		}

	}

	/**
	 * EntityResolver method
	 */
	public InputSource resolveEntity(String publicId, String systemId)
	{
		if (systemId.endsWith("sil.dtd")) {
			return new InputSource(ServerConfig.getSilDtdUrl());
		} else if (systemId.endsWith(ServerConfig.getSilDtd())) {
			return new InputSource(ServerConfig.getSilDtdUrl());
		}

		// use the default behaviour
		return null;
	}

	/**
	 * return info of the crystal on the selected row.
	 */
	public Hashtable getSelectedCrystal()
		throws Exception
	{
		if (selectedCrystal == null)
			return null;

		Hashtable info = new Hashtable();

		NodeList children = selectedCrystal.getChildNodes();
		if (children == null)
			return info;

		Node grandChild = null;
		for (int i = 0; i < children.getLength(); ++i) {
			if (!(children.item(i) instanceof Element))
				continue;
			Element child = (Element)children.item(i);
			if (!child.hasChildNodes())
				continue;
			grandChild = child.getFirstChild();
			if (!(grandChild instanceof Text))
				continue;
			if (grandChild.getNodeValue() != null)
				info.put(child.getNodeName(), grandChild.getNodeValue());

		}

		return info;

	}

	/**
	 */
	public void selectCrystal(int row)
		throws Exception
	{
		Element crystal = getCrystalElement(row);
		
		selectCrystal(crystal, true);

		imgViewer.setImageFile(getSelectedImageFile());

	}

	/**
	 */
	public void selectCrystal(String port)
		throws Exception
	{
		Element crystal = getCrystalElement(port);
		
		selectCrystal(crystal, true);

		imgViewer.setImageFile(getSelectedImageFile());

	}

	/**
	 */
	private void unselectCrystal()
	{
		selectedRow = -1;
		selectedCrystal = null;
		selectedImages = null;
		selectedGroup = null;
		selectedImage = null;

	}
	
	public boolean isSilLocked()
	{
		if (silDoc == null)
			return false;
		Element silElement = silDoc.getDocumentElement();
		if (silElement == null)
			return false;
			
		String locked = silElement.getAttribute("lock");
		
		return locked.equals("true");
 				
	}


	/**
	 * Returns crystal element whose attribute row equals the given row
	 * number. Throws an error if row is not found.
	 */
	private Element getCrystalElement(int row)
		throws Exception
	{
        // get elements that match
		if (silDoc == null)
			return null;

		Element silElement = silDoc.getDocumentElement();
        NodeList crystals = silElement.getElementsByTagName("Crystal");

        // is there anything to do?
        if ((crystals == null) || (crystals.getLength() == 0))
        	throw new Exception("Sil " + silId + " contains no crystal");

		int crystalCount = crystals.getLength();
		if (row >= crystals.getLength())
			throw new Exception("Invalid row: " + row);

		String rowStr = String.valueOf(row);
		for (int i = 0; i < crystalCount; i++) {
			Element crystal = (Element)crystals.item(i);

			// Find the right row
			if (crystal.getAttribute("row").equals(rowStr)) {
				return crystal;
			}
		}

		throw new Exception("Invalid row number: row=" + row);

	}

	/**
	 * Returns crystal element that contains child node Port
	 * with value equals the given port. Throws an error if
	 * port is not found.
	 */
	private Element getCrystalElement(String port)
		throws Exception
	{
        // get elements that match
		if (silDoc == null)
			return null;

		Element silElement = silDoc.getDocumentElement();
        NodeList crystals = silElement.getElementsByTagName("Crystal");

        // is there anything to do?
        if ((crystals == null) || (crystals.getLength() == 0))
        	return null;

		int crystalCount = crystals.getLength();

		Element crystal = null;
		NodeList children = null;
		Element portNode = null;
		Text textNode = null;
		for (int i = 0; i < crystalCount; i++) {

			crystal = (Element)crystals.item(i);
			children = crystal.getElementsByTagName("Port");
			if ((children == null) || (children.getLength() == 0))
				return null;

			portNode = (Element)children.item(0);

			textNode = (Text)portNode.getFirstChild();

			// Find the right row
			if (textNode.getNodeValue().trim().equals(port))
				return crystal;

		}

		return null;

	}
	
	/**
	 */
	public String getDisplayMode()
	{
		return displayMode;
	}

	/**
	 */
	public void setDisplayMode(String s)
	{
		if (s.equals(DISPLAY_DETAILS))
			displayMode = DISPLAY_DETAILS;
		else if (s.equals(DISPLAY_OVERVIEW))
			displayMode = DISPLAY_OVERVIEW;
		else if (s.equals(DISPLAY_QUEUE))
			displayMode = DISPLAY_QUEUE;
		else
			displayMode = DISPLAY_ALLSILS;

	}

	/**
	 * Move
	 */
	public void moveToFirstImage()
		throws Exception
	{
		unselectCrystal();

		nextImage();

		imgViewer.setImageFile(getSelectedImageFile());
	}

	/**
	 * Move
	 */
	public void moveToPreviousImage()
		throws Exception
	{
		previousImage();

		imgViewer.setImageFile(getSelectedImageFile());
	}

	/**
	 * Move
	 */
	public void moveToNextImage()
		throws Exception
	{
		nextImage();

		imgViewer.setImageFile(getSelectedImageFile());
	}

	/**
	 * Move to first image of next crystal
	 */
	public void moveToPreviousCrystal()
		throws Exception
	{
		previousCrystal();

		imgViewer.setImageFile(getSelectedImageFile());
	}

	/**
	 * Move to first image of next crystal
	 */
	public void moveToNextCrystal()
		throws Exception
	{
		nextCrystal();

		imgViewer.setImageFile(getSelectedImageFile());
	}

	/**
	 * Move cursor to previous image.
	 * Move to first image of previous crystal.
	 * Move to first image of the previous crystal
	 * if the current image is first for this crystal.
	 */
	private void previousImage()
		throws Exception
	{
		if (selectedGroup == null) {
			previousGroup();
			return;
		}

//		NodeList nodes = selectedGroup.getChildNodes();
		NodeList nodes = selectedGroup.getElementsByTagName("Image");

		// Go to prev group or prev crystal
		// if this group has no children
		if ((nodes == null) || (nodes.getLength() == 0)) {
			previousGroup();
			return;
		}

		// If no image is currently selected
		// then select the first image in this group.
		if (selectedImage == null) {
			selectedImage = (Element)nodes.item(0);
			return;
		}

		// Find the currently selected image in this group
		// then select the image before it.
		Element node = null;
		for (int i = 0; i < nodes.getLength(); ++i) {
			node = (Element)nodes.item(i);
			if (node == selectedImage) {
				// Return next image of this group
				// if it's not last in the group.
				// If image is last in the group
				// then move to next group.
				if (i > 0) {
					selectedImage = (Element)nodes.item(i-1);
					return;
				} else {
					previousGroup();
					return;
				}
			}
		}
	}

	/**
	 * Move cursor to next image.
	 * Move to first image of next crystal
	 * if current image is last
	 * image of the current crystal.
	 */
	private void nextImage()
		throws Exception
	{

		if (selectedGroup == null) {
			nextGroup();
			return;
		}

//		NodeList nodes = selectedGroup.getChildNodes();
		NodeList nodes = selectedGroup.getElementsByTagName("Image");

		// Go to next group or next crystal
		// if this group has no children
		if ((nodes == null) || (nodes.getLength() == 0)) {
			nextGroup();
			return;
		}

		// If no image is currently selected
		// then select the first image in this group.
		if (selectedImage == null) {
			selectedImage = (Element)nodes.item(0);
			return;
		}
		// Find the currently selected image in this group
		// then select the image below it.
		Element node = null;
		for (int i = 0; i < nodes.getLength(); ++i) {
			node = (Element)nodes.item(i);
			if (nodes.item(i) == selectedImage) {
				// Return next image of this group
				// if it's not last in the group.
				// If image is last in the group
				// then move to next group.
				if (i < nodes.getLength()-1) {
					selectedImage = (Element)nodes.item(i+1);
					return;
				} else {
					nextGroup();
					return;
				}
			}
		}
	}


	/**
	 * Go to last image of the prev group
	 */
	private void previousGroup()
		throws Exception
	{
		if ((selectedImages == null) || (selectedCrystal == null)) {
			previousCrystal();
			return;
		}

//		NodeList nodes = selectedImages.getChildNodes();
		NodeList nodes = selectedImages.getElementsByTagName("Group");

		// Go to prev group or prev crystal
		// if this group has no children
		if ((nodes == null) || (nodes.getLength() == 0)) {
			previousCrystal();
			return;
		}

		for (int i = 0; i < nodes.getLength(); ++i) {
			if (nodes.item(i) == selectedGroup) {
				// Return next image of this group
				// if it's not last in the group.
				// If image is last in the group
				// then move to next group.
				if (i > 0) {
					selectGroup((Element)nodes.item(i-1), false);
					if (selectedImage == null) {
						previousGroup();
					}
					return;
				} else {
					previousCrystal();
					return;
				}
			}
		}
	}

	/**
	 * Go to first image of the next group
	 */
	private void nextGroup()
		throws Exception
	{
		if ((selectedImages == null) || (selectedCrystal == null)) {
			nextCrystal();
			return;
		}

//		NodeList nodes = selectedImages.getChildNodes();
		NodeList nodes = selectedImages.getElementsByTagName("Group");
		for (int i = 0; i < nodes.getLength(); ++i) {
			if (nodes.item(i) == selectedGroup) {
				// Return next image of this group
				// if it's not last in the group.
				// If image is last in the group
				// then move to next group.
				if (i < nodes.getLength()-1) {
					selectGroup((Element)nodes.item(i+1), true);
					if (selectedImage == null) {
						nextGroup();
					}
					return;
				} else {
					nextCrystal();
					return;
				}
			}
		}
	}

	/**
	 */
	private void previousCrystal()
		throws Exception
	{

        // get elements that match
		if (silDoc == null)
			return;

		Element silElement = silDoc.getDocumentElement();
		NodeList crystals = silElement.getElementsByTagName("Crystal");

        	// is there anything to do?
        	if ((crystals == null) || (crystals.getLength() == 0))
        		return;

		int crystalCount = crystals.getLength();
		if (selectedCrystal == null) {
			selectCrystal((Element)crystals.item(0), false);
			return;
		}
		for (int i = 0; i < crystalCount; i++) {
			Element crystal = (Element)crystals.item(i);
			if ((crystal == selectedCrystal) && (i > 0)) {
				selectCrystal((Element)crystals.item(i-1), false);
				return;
			}
		}
	}

	/**
	 */
	private void nextCrystal()
		throws Exception
	{

        	// get elements that match
		if (silDoc == null)
			return;
			
		Element silElement = silDoc.getDocumentElement();
		if (silElement == null)
			throw new Exception("Cannot find Sil element in xml");
        	NodeList crystals = silElement.getElementsByTagName("Crystal");

       	 	// is there anything to do?
       	 	if ((crystals == null) || (crystals.getLength() == 0))
        		return;

		int crystalCount = crystals.getLength();

		if (selectedCrystal == null) {
			selectCrystal((Element)crystals.item(0), true);
			return;
		}

		for (int i = 0; i < crystalCount; i++) {
			Element crystal = (Element)crystals.item(i);

			if ((crystal == selectedCrystal) && (i < crystalCount-1)) {
				selectCrystal((Element)crystals.item(i+1), true);
				return;
			}
		}
	}

	/**
	 */
	public int getSelectedRow()
	{
		return selectedRow;
	}

	/**
	 */
	public void selectCrystal(Element crystal, boolean firstImage)
		throws Exception
	{
		unselectCrystal();

		if (crystal == null)
			return;

		selectedCrystal = crystal;
		selectedRow = Integer.parseInt(crystal.getAttribute("row"));

		NodeList nodes = selectedCrystal.getElementsByTagName("Images");
		if ((nodes == null) || (nodes.getLength() == 0))
			return;
		selectedImages = (Element)nodes.item(0);
		nodes = selectedImages.getElementsByTagName("Group");
		if ((nodes == null) || (nodes.getLength() == 0))
			return;

		NodeList children = null;
		Element aGroup = null;
		// First group or last group
		if (firstImage) {
			// Find first image that is not null in all groups.
			// Loop over all groups
			for (int i = 0; i < nodes.getLength(); ++i) {
				aGroup = (Element)nodes.item(i);
				// For each group, find all Image nodes
				children = aGroup.getElementsByTagName("Image");
				// If this group has no Image nodes then skip to next group
				if ((children != null) && (children.getLength() > 0)) {
					// Find the first non null Image
					for (int j = 0; j < children.getLength(); ++j) {
						if (children.item(j) != null) {
							selectedImage = (Element)children.item(j);
							selectedGroup = aGroup;
							break;
						}
					}
					break;
				}
			}
			// Cannot find non null image in all groups
			// Then select the first group and set the image to null.
			if (selectedGroup == null) {
				selectedGroup = (Element)nodes.item(0);
				selectedImage = null;
			}
		} else {
			// Find last image that is not null in all groups.
			// Loop over all groups backward
			for (int i = nodes.getLength()-1; i >= 0; --i) {
				aGroup = (Element)nodes.item(i);
				// For each group, find all Image nodes
				children = aGroup.getElementsByTagName("Image");
				// If this group has no Image nodes then skip to next group
				if ((children != null) && (children.getLength() > 0)) {
					// Find the last non null Image
					for (int j = children.getLength(); j >= 0; --j) {
						if (children.item(j) != null) {
							selectedImage = (Element)children.item(j);
							selectedGroup = aGroup;
							break;
						}
					}
					break;
				}
			}
			if (selectedGroup == null) {
				selectedGroup = (Element)nodes.item(nodes.getLength()-1);
				selectedImage = null;
			}
		}

		nodes = selectedGroup.getElementsByTagName("Image");
		if ((nodes == null) || (nodes.getLength() == 0))
			return;

		// First image or last image
		if (firstImage)
			selectedImage = (Element)nodes.item(0);
		else
			selectedImage = (Element)nodes.item(nodes.getLength()-1);
			
		
	}

	/**
	 */
	private void selectGroup(Element group, boolean firstImage)
		throws Exception
	{
		selectedGroup = null;
		selectedImage = null;

		selectedGroup = group;

		NodeList nodes = selectedGroup.getElementsByTagName("Image");
		if ((nodes == null) || (nodes.getLength() == 0)) {
			selectedImage = null;
		} else {
			if (firstImage)
				selectedImage = (Element)nodes.item(0);
			else
				selectedImage = (Element)nodes.item(nodes.getLength()-1);
		}
	}
	
	public String getImageFile()
	{
		return imgViewer.getImageFile();
	}

	/**
	 */
	private String getSelectedImageFile()
	{
		if (selectedImage == null)
			return "";

		String dir = selectedImage.getAttribute("dir");
		String file = selectedImage.getAttribute("name");
		return dir + File.separator + file;
	}
	
	public int getSilType()
		throws Exception
	{
		if (silDoc == null)
			throw new Exception("Sil is null");
			
		return silType;
	}
	
	private int getSilType_()
		throws Exception
	{
		if (silDoc == null)
			throw new Exception("Sil is null");
			
		Element silElement = silDoc.getDocumentElement();
		if (silElement == null)
			throw new Exception("Cannot find Sil element in xml");
        	NodeList crystals = silElement.getElementsByTagName("Crystal");

		// is there anything to do?
		if ((crystals == null) || (crystals.getLength() == 0))
        		throw new Exception("No crystal in sil");

		int crystalCount = crystals.getLength();

		Element crystal = null;
		NodeList children = null;
		Element portNode = null;
		Text textNode = null;
		String portName = "";
		int portNum = 0;
		char ch1 = 'a';
		for (int i = 0; i < crystalCount; i++) {
			if (!(crystals.item(i) instanceof Element))
				continue;
			crystal = (Element)crystals.item(i);
			children = crystal.getElementsByTagName("Port");
			if ((children == null) || (children.getLength() == 0))
				continue;
			portNode = (Element)children.item(0);
			textNode =  (Text)portNode.getFirstChild();
			portName = (String)textNode.getNodeValue();
			if ((portName == null) || (portName.length() == 0))
				continue;
			ch1 = portName.charAt(0);
			// ssrl or puck must start with A -> L
			if ((ch1 < 'A') || (ch1 > 'L'))
				return OTHER_CASSETTE;
			if (portName.length() > 1) {
				portNum = Integer.parseInt(portName.substring(1));
				if (portNum > 8)
					return PUCK_CASSETTE;
			}
		}

		return SSRL_CASSETTE;
		
	}
		
	private String getTextValue(Element e)
	{	
		Text tt =  (Text)e.getFirstChild();
		if (tt == null)
			return null;
		return (String)tt.getNodeValue();
	}

	/**
	 */
	public String[] getCrystalPorts()
		throws Exception
	{
        	// get elements that match
		if (silDoc == null)
			return null;


		Element silElement = silDoc.getDocumentElement();
        	NodeList crystals = silElement.getElementsByTagName("Crystal");

        	// is there anything to do?
        	if ((crystals == null) || (crystals.getLength() == 0))
        		return null;

		int crystalCount = crystals.getLength();

		String ret[] = new String[crystalCount];

		Element crystal = null;
		NodeList children = null;
		Element portNode = null;
		Text textNode = null;
		for (int i = 0; i < crystalCount; i++) {
			if (!(crystals.item(i) instanceof Element))
				continue;
			crystal = (Element)crystals.item(i);
			children = crystal.getElementsByTagName("Port");
			if ((children == null) || (children.getLength() == 0))
				continue;
			if (!crystalHasImage(crystal))
				continue;
			portNode = (Element)children.item(0);
			textNode =  (Text)portNode.getFirstChild();
			ret[i] = (String)textNode.getNodeValue();
		}

		return ret;

	}
	
	public String getRunDefFileRoot(int runIndex)
		throws Exception
	{
		return getRunDefProperty(runIndex, "fileRoot");			
	}
	
	public int getRunDefRepositionId(int runIndex)
		throws Exception
	{
		String str = getRunDefProperty(runIndex, "repositionId");
		try {
			return Integer.parseInt(str);
		} catch (NumberFormatException e) {
			WebiceLogger.info("Invalid repositionId for this run def: '" + str + "'");
			return -1;
		}
					
	}
	
	public int getRunDefLabel(int runIndex)
		throws Exception
	{
		String str = getRunDefProperty(runIndex, "runLabel");
		try {
			return Integer.parseInt(str);
		} catch (NumberFormatException e) {
			WebiceLogger.info("Invalid runLabel for this run def: '" + str + "'");
			return -1;
		}
			
	}
	
	public String getRunDefProperty(int runIndex, String propName)
		throws Exception
	{
		if (silDoc == null)
			return null;
			
		if (selectedCrystal == null)
			return null;

		NodeList runDefs = selectedCrystal.getElementsByTagName("RunDefs");
		if ((runDefs == null) || (runDefs.getLength() == 0)) {
			WebiceLogger.info("Cannot find RunDefs element in Crystal element");
        		return null;
		}
		Element runDefParent = (Element)runDefs.item(0);
		NodeList runDefsChildren = runDefParent.getElementsByTagName("RunDef");
		if (runDefsChildren == null) {
			WebiceLogger.info("Cannot find RunDef element in RunDefs");
			return null;
		}
		for (int i = 0; i < runDefsChildren.getLength(); ++i) {
		
			if (!(runDefsChildren.item(i) instanceof Element))
				continue;
				
			Element runDef = (Element)runDefsChildren.item(i);
			String runIndexStr = runDef.getAttribute("runIndex");
			if ((runIndexStr != null) && !runIndexStr.equals(String.valueOf(runIndex)))
				continue;
			String str = runDef.getAttribute(propName);
			if (str == null) {
				WebiceLogger.info("RunDef does not have " + propName + " property");
				return null;
			}
			return str;
		}
		
		return null;			
	}
	
	public String getRepositionDataAutoindexDir(int repositionId)
		throws Exception
	{
		if (silDoc == null)
			return null;
			
		if (selectedCrystal == null)
			return null;

		NodeList reposList = selectedCrystal.getElementsByTagName("Repositions");
		if ((reposList == null) || (reposList.getLength() == 0))
        		return null;
		Element parentNode = (Element)reposList.item(0);
		NodeList allReposNodes = parentNode.getElementsByTagName("Reposition");
		Element repos = null;
		for (int i = 0; i < allReposNodes.getLength(); ++i) {
			if (!(allReposNodes.item(i) instanceof Element))
				continue;
			repos = (Element)allReposNodes.item(i);
			String repositionIdStr = repos.getAttribute("repositionId");
			if (!repositionIdStr.equals(String.valueOf(repositionId)))
				continue;
			return repos.getAttribute("dir");				
		}
		return null;
	}
		
	/**
	 * Does this crystal have image?
 	 */
	static public boolean crystalHasImage(Element crystal)
		throws Exception
	{

		Element groupNode = null;
		Element imageNode = null;
		
		NodeList nl = crystal.getElementsByTagName("Images");
		if ((nl == null) || (nl.getLength() == 0))
			return false;
			
		Element images = (Element)nl.item(0);
		
		// loop over Group elements
		NodeList children = images.getElementsByTagName("Group");
		if ((children == null) || (children.getLength() == 0))
			return false;

		String nn = "";
		for (int j = 0; j < children.getLength(); ++j) {
			groupNode = (Element)children.item(j);
			nl = groupNode.getElementsByTagName("Image");
			if (nl == null)
				return false;
			imageNode = (Element)nl.item(0);
			if (imageNode == null)
				continue;
				
			nn = imageNode.getAttribute("name");
			if ((nn != null) && (nn.length() > 0))
				return true;
				
		}

		return false;
	}
	
	/**
	 */
	public void loadSilList()
		throws Exception
	{
		try {

		String urlStr = ServerConfig.getSilGetSilListUrl()
							+ "?userName=" + client.getUser()
							+ "&accessID=" + client.getSessionId();

		if ((filterBy != null) && (wildcard != null)) {
			// Convert wildcard style into regex
			// which means replacing "*" with ".*".
			String reg = wildcard.replaceAll("[\\x2A]", ".*");
			urlStr += "&filterBy=" + URLEncoder.encode(filterBy, "UTF-8")
					+ "&wildcard=" + URLEncoder.encode(reg, "UTF-8");
		}
		
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to load sil list "
						+ " crystals server returns an error: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				buf.append(line);
		}

		// Set silList xml
		silList = buf.toString();

		reader.close();
		con.disconnect();

		} catch (Exception e) {
			WebiceLogger.error(e.getMessage(), e);
			throw e;
		}
	}

	/**
	 */
	public String getSilList()
	{
		return silList;
	}

	/**
	 */
	public Document getSilDocument()
		throws Exception
	{
		if (!curSortColumn.equals(getSortColumn()) || !curSortDirection.equals(getSortOrder())) {
			curSortColumn = getSortColumn();
			curSortDirection = getSortOrder();
			sortSil();
		}
		return silDoc;
	}

	/**
	 */
	public String getSilOwner()
	{
		return silOwner;
	}

	/**
	 */
	public void setSilOverviewTemplate(String template)
	{
		if (template == null)
			return;

		client.getProperties().setProperty("screening.displayTemplate", template);
	}

	/**
	 */
	public String getSilOverviewTemplate()
	{
		return client.getProperties().getProperty("screening.displayTemplate", defDisplayTemplate);
	}

	/**
	 */
	public void setSilOverviewOption(String option)
	{
		if (option == null)
			return;

		client.getProperties().setProperty("screening.displayOption", option);
	}

	/**
	 */
	public String getSilOverviewOption()
	{
		return client.getProperties().getProperty("screening.displayOption", defDisplayOption);
	}

	/**
	 */
	public void setSilOverviewNumRows(String rowOption)
	{
		if (rowOption == null)
			return;

		displayRows = rowOption;
	}

	/**
	 */
	public String getSilOverviewNumRows()
	{
		return displayRows;
	}

	/**
	 */
	public String getAutoindexResult()
	{
		String file = "";
		String err1 = "";
		String err2 = "";
		
		// try to find labelit.out in <runname>/LABELIT
		try {

		Imperson imperson = client.getImperson();

		file = getLabelitOutputFile();

		if ((file == null) || (file.length() == 0))
			return "";

		String result = imperson.readFile(file);

		return result;

		} catch (Exception e) {
			WebiceLogger.error("Failed to read file " + file + ": " + e.getMessage());
			err1 = e.getMessage();
		}
		
		String file1 = file;
		
		// try old version
		try {

		Imperson imperson = client.getImperson();

		file = getLabelitOutputFile(true);

		if ((file == null) || (file.length() == 0))
			return "";

		String result = imperson.readFile(file);

		return result;

		} catch (Exception e) {
			WebiceLogger.error("Failed to read file " + file + ": " + e.getMessage());
			err2 = e.getMessage();
		}
		
		return "Failed to read labelit.out from " + file1 + " or " + file;


	}

	/**
	 */
	public String getAutoindexHTML()
	{
		String file = "";
		String err1 = "";
		
		// try to find labelit.html in <runname>/LABELIT
		try {

		Imperson imperson = client.getImperson();

		file = getLabelitHTMLFile();

		if ((file == null) || (file.length() == 0))
			return "";

		String result = imperson.readFile(file);

		return result;

		} catch (Exception e) {
			WebiceLogger.error("Failed to read file " + file + ": " + e.getMessage());
			err1 = e.getMessage();
		}
		
		// legacy: jsp will default to labelit.out if empty string is returned
		return "";

	}
	/**
	 */
	public Object[] getAutoindexFiles()
		throws Exception
	{

		String aDir = getAutoindexDir();

		if ((aDir == null) || (aDir.length() == 0))
			return null;

		Imperson imperson = client.getImperson();

		TreeMap files = new TreeMap();
		imperson.listDirectory(aDir, null, null, files);

		// Get result files
		Object values[] = files.values().toArray();
		TreeMap resultFiles = new TreeMap();
		// Filter files of the known types
		if (values != null) {
			for (int i = 0; i < values.length; ++i) {
				FileInfo info = (FileInfo)values[i];
				info.type = FileHelper.getFileType(info.name);
//				if (info.type != FileHelper.UNKNOWN) {
					resultFiles.put(info.name, info);
//				}
			}
		}

		return resultFiles.values().toArray();

	}

	/**
	 */
	public void setSortColumn(String col)
	{
		if ((col == null) || (col.length() == 0))
			return;

		client.getProperties().setProperty("screening.sortColumn", col);
		curSortColumn = col;

	}

	/**
	 */
	public String getSortColumn()
	{
		return client.getProperties().getProperty("screening.sortColumn");
	}

	/**
	 */
	public String getSortOrder()
	{
		return client.getProperties().getProperty("screening.sortDirection");
	}
	
	public void setSortOrder(String s)
	{
		if (s == null)
			return;
			
		if (s.equals("ascending") || s.equals("descending")) {
			client.getProperties().setProperty("screening.sortDirection", s);
			curSortDirection = s;
		}
	}
		
	/**
	 * Create a default sil for the give dir
	 */
	public String createDefaultSil(String dir)
		throws Exception
	{
		String urlStr = ServerConfig.getCreateDefaultSilUrl() + "?userName=" + client.getUser()
				+ "&accessID=" + client.getSessionId()
				+ "&cassettePin=unknown_pin&forFileName=" + dir;
						
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("cannot create default sil "
						+ " crystals server returns an error: "
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

		// Get sil id
		String s = buf.toString();
		StringTokenizer tok = new StringTokenizer(s, " ");
		if (tok.countTokens() != 2)
			throw new Exception("cannot get sil ID from http response from crystals server: " + s);

		tok.nextToken();
		String ss = tok.nextToken();
		return ss;
	}
	
	/**
	 * Thread to monitor the run
	 */
	private class AnalysisMonitorThread extends Thread
	{
		private int STATUS_UNKNOWN = 1;
		private int STATUS_RUNNING = 2;
		private int STATUS_NOT_RUNNING = 3;
		private int STATUS_NOT_STARTED = 4;

		private boolean stopped = false;
		private int interval = 5;
		
		String host = "";
		int port = 0;
		String user = "";
		String sessionId = "";
		String workDir = "";
		String silId = "";
		int row = 0;
		String crystalId = "";
		
		boolean done = true;
		
		AnalysisMonitorThread(String host, int port,
					String user,
					String sessionId, 
					String workDir,
					String silId,
					int row,
					String crystalId)
		{
			this.host = host;
			this.port = port;
			this.user = user;
			this.sessionId = sessionId;
			this.workDir = workDir;
			this.silId = silId;
			this.row = row;
			this.crystalId = crystalId;
		}

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
		
		synchronized public boolean isDone()
		{
			return done;
		}

		/**
		 * Get the latest run status from the control file
 		 */
		private int updateJobStatus()
			throws Exception
		{
			HttpURLConnection con = null;
			BufferedReader reader = null;
			try {

			int jobStatus = STATUS_UNKNOWN;

			String commandline = ServerConfig.getScriptDir()
						+ "/updateJobStatus.csh " 
						+ workDir + "/control.txt";

			String urlStr = "http://" + host + ":" + String.valueOf(port) + "/runScript";

		
			URL url = new URL(urlStr);

			con = (HttpURLConnection)url.openConnection();

			con.setRequestMethod("GET");
			con.setRequestProperty("impShell", "/bin/tcsh");
			con.setRequestProperty("impCommandLine", commandline);
			con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
			con.setRequestProperty("impUser", user);
			con.setRequestProperty("impSessionID", sessionId);


			int response = con.getResponseCode();
			if (response != 200)
				throw new Exception("Failed to run labelit: impserson server returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");


			reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

			String line = reader.readLine();
			
//			WebiceLogger.debug("AnalysisMonitoringThread: job status = " + line);
		
			if (line.startsWith("running")) {
				jobStatus = STATUS_RUNNING;
			} else if (line.startsWith("not running")) {
				jobStatus = STATUS_NOT_RUNNING;
			} else if (line.startsWith("not started")) {
				jobStatus = STATUS_NOT_STARTED;
			} else {
				jobStatus = STATUS_UNKNOWN;
			}


			return jobStatus;

			} catch (Exception e) {
				throw new Exception("Error in updateJobStatus: " + e.getMessage());
			} finally {
				if (reader != null)
					reader.close();
				if (con != null)
					con.disconnect();
					
				reader = null;
				con = null;
			}

		}


		public void run()
		{
			try {
				WebiceLogger.info("AnalysisMonitorThread: start monitoring");

				// Wait until the job is done
				int waitToStart = 5*60000; // 5 minutes
				int timePassed = 0;
				int sleepTime = 5000;
				while ((timePassed < waitToStart) &&
				   	(updateJobStatus() == STATUS_NOT_STARTED)) {
					sleep(sleepTime);
					timePassed += sleepTime;
				}

				// Should we give up?
				if (timePassed >= waitToStart) {

					WebiceLogger.info("AnalysisMonitorThread: autoindex process did not started after "
						+ timePassed/1000 + " seconds");

				} else {
				
					timePassed = 0;
					int maxTime = 10*60000; // monitor for 10 mins max.

					// Wait until the job is done
					while ((timePassed < maxTime) && 
						(updateJobStatus() == STATUS_RUNNING)) {
						if (stopped) {
							break;
						}
						sleep(sleepTime);
						timePassed += sleepTime;
					}
					
					if (timePassed >= maxTime) {
						WebiceLogger.info("AnalysisMonitorThread: autoindex process did not finish after "
							+ timePassed/1000 + " seconds");
					}
				
				}

			} catch (Exception e) {
				WebiceLogger.error("Error in AnalysisMonitorThread stopped for sil = " + getSilId() 
						+ " row = " + row
						+ " crystalId = " + crystalId
						+ ": " + e.getMessage(), e);
			}
			
			done = true;
			WebiceLogger.info("AnalysisMonitorThread: stop monitoring");
		
		}
	}
	
	/**
	 */
	private boolean isUseGlobalImageDir()
	{
		return client.getProperties().getPropertyBoolean("screening.useGlobalImageDir", true);
	};

	/**
	 * ErrorListener method.
	 * Only throws TransformerException if it chooses to discontinue the transformation.
	*/
	public void warning(TransformerException e)
		throws TransformerException
	{
		WebiceLogger.warn("XmlContentLoader " + e.getMessage());
	}
    
	public void error(TransformerException e)
		throws TransformerException
	{
		WebiceLogger.error("XmlContentLoader " + e.getMessage());
	}
    
	public void fatalError(TransformerException e)
 		throws TransformerException
	{
		WebiceLogger.fatal("XmlContentLoader " + e.getMessage());
	}
	
	public void setScroll(int x, int y)
	{
		if (x > -1)
			scrollX = x;
		if (y > -1)
			scrollY = y;
	}
	
	public int getScrollX()
	{
		return scrollX;
	}
	
	public int getScrollY()
	{
		return scrollY;
	}
    
    	public void setFilter(String filterBy, String wildcard)
	{
		this.filterBy = filterBy;
		this.wildcard = wildcard;
	}
	
	public String getFilterBy()
	{
		return filterBy;
	}
	
	public String getWildcard()
	{
		return wildcard;
	}
	
	public String getSilListSortColumn()
	{
		return silListSortColumn;
	}
	
	public void setSilListSortColumn(String c)
	{
		if ((c != null) && (c.length() > 0))
			silListSortColumn = c;
	}
	
	public boolean isSilListSortAscending()
	{
		return silListSortAscending;
	}
	
	public void setSilListSortAscending(boolean b)
	{
		silListSortAscending = b;
	}
	
	public String getSilListSortType()
	{
		return silListSortType;
	}
	
	public void setSilListSortType(String t)
	{
		if ((t != null) && (t.length() > 0))
			silListSortType = t;
	}
	
	public void setSelectionMode(String m)
	{
		if (m == null)
			return;
			
		if (m.equals(MULTI_CRYSTAL))
			selectionMode = MULTI_CRYSTAL;
		else
			selectionMode = ONE_CRYSTAL;
	}
	
	public String getSelectionMode()
	{
		return selectionMode;
	}
	
	/**
	 * Automatically update "Cassette Summary" and "Cassette Details" Pages.
	 */
	public boolean isAutoUpdate()
	{
		return client.getProperties().getPropertyBoolean("screening.autoUpdate", true);
	}
	
	/**
	 *
	 */
	public void setAutoUpdate(boolean s)
	{
		if (s)
			client.getProperties().setProperty("screening.autoUpdate", "true");
		else
			client.getProperties().setProperty("screening.autoUpdate", "false");
	}
	
	public int getAutoUpdateRate()
	{
		return client.getProperties().getPropertyInt("screening.autoUpdateRate", 5);
	}
	
	public void setAutoUpdateRate(int s)
	{
		if (s < 5)
			return;
		client.getProperties().setProperty("screening.autoUpdate", s);
	}

}

