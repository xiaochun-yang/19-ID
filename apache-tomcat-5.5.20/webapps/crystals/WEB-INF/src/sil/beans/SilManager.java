package sil.beans;

import sil.beans.*;
import cts.CassetteDB;
import cts.CassetteIO;
import java.io.*;
import java.util.Hashtable;
import org.w3c.dom.*;
import org.xml.sax.InputSource;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.apache.xerces.dom.DocumentImpl;
import org.apache.xerces.dom.DOMImplementationImpl;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

/**
 * A helper class for creating a sil
 */
public class SilManager
{
	private CassetteDB ctsdb = null;
	private CassetteIO ctsio = null;

	private String templatePrefix = "cassette_template";
	private String filePrefix = "excelData";
	private String fileCrystalData2Sil = "xsltCrystalData2Sil.xsl";

	String portFirstChar = "ABCDEFGHIJKL";
	int maxPort = 16;
	String directoryChars = "_-\\/";
	String crystalIdChars = "_-";
	
	/**
	 * Default constructor
	 */
	public SilManager()
		throws Exception
	{
		this.ctsdb = SilUtil.getCassetteDB();
		this.ctsio = SilUtil.getCassetteIO();
	}

	/**
	 */
	public SilManager(CassetteDB ctsdb, CassetteIO ctsio)
	{
		this.ctsdb = ctsdb;
		this.ctsio = ctsio;
	}

	/**
	 */
	public void upgrade(int silId, String owner)
		throws Exception
	{
		String fileName = ctsdb.getCassetteFileName(silId);
		if (SilUtil.isError(fileName))
			throw new Exception(SilUtil.parseError(fileName));

		String dest = SilConfig.getInstance().getCassetteDir()
							+ File.separator + owner
							+ File.separator + fileName + "_sil.xml";
		File destFile = new File(dest);

		if (destFile.exists())
			return;

		String src = SilConfig.getInstance().getCassetteDir()
							+ File.separator + owner
							+ File.separator + fileName + ".xml";

		createSilFile(silId, "unknown", src, dest);
	}

	/**
	 * Creates a default sil and returns the sil id.
	 */
	public int createDefaultSil(String userName, String cassettePin)
		throws Exception
	{
		return createDefaultSil(userName, cassettePin, null, null);
	}
	
	public int createDefaultSil(String userName, String cassettePin, String userFileName)
		throws Exception
	{
		return createDefaultSil(userName, cassettePin, userFileName, null);
	}
	
	public int createDefaultSil(String userName, String cassettePin, String userFileName, String whichTemplate)
		throws Exception
	{
		if ((cassettePin == null) || (cassettePin.length() == 0))
			cassettePin = "unknown";
			
		// Create a entry in DB for the new sil
		int silId = createSilInDB(userName, cassettePin);

		// Copy default files from template dir for the new sil.
		createDefaultSilFiles(silId, cassettePin, userFileName, whichTemplate);

		return silId;
	}

	/**
	 * Returns cassette info assigned to the given cassette position
	 * at the given beamline.
	 */
	private boolean isSilLocked(String forBeamLine, String beamlinePosition)
		throws Exception
	{
		Hashtable info = ctsdb.getCassetteInfoAtBeamline(forBeamLine, beamlinePosition);
		
		String silId = (String)info.get("CassetteID");
		if (silId == null)
			return false;
		if (silId.length() == 0)
			return false;

		String userName = (String)info.get("UserName");
		String fileName = (String)info.get("FileName");
		if (userName == null)
			return false;

		if ((userName.length() == 0) || userName.equals("null"))
			return false;

		if (fileName == null)
			return false;

		if ((fileName.length() == 0) || fileName.equals("null"))
			return false;
			
		// Get sil file
		String path = SilConfig.getInstance().getCassetteDir()
							+ File.separator
							+ userName + File.separator
							+ fileName + "_sil.xml";

		String xslt = SilConfig.getInstance().getTemplateDir()
							+ File.separator + "getSilLock.xsl";

		// Extract lock attribute of sil node from sil file
		StringWriter writer = new StringWriter();
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer( new StreamSource(xslt));
		String systemId = SilConfig.getInstance().getSilDtdUrl();
		StreamSource source = new StreamSource(new FileReader(path), systemId);
		StreamResult result = new StreamResult(writer);
		transformer.transform(source, result);

		String lock = writer.toString().trim();

		if (lock.equals("true"))
			return true;
		else if (lock.equals("false"))
			return false;

		throw new Exception("isSilLocked failed to get lock attribute of sil " + silId);

	}

	/**
	 */
	public void unassignSil(int silId)
		throws Exception
	{
		Hashtable info = ctsdb.getAssignedBeamline(silId);

		// Sil is not assigned to a beamline
		if (info.size() == 0)
			return;

		String beamlineID = (String)info.get("BEAMLINE_ID");
		String forBeamLine = (String)info.get("BEAMLINE_NAME");
		String beamlinePosition = (String)info.get("BEAMLINE_POSITION");

		SilLogger.info("unassignSil: silId = " + silId
						+ " current bid = " + beamlineID
						+ " beamline = " + forBeamLine
						+ " position = " + beamlinePosition);

		// Not a valid beamline
		if ((beamlineID == null) || (beamlineID.length() == 0)
			|| (forBeamLine == null) || (forBeamLine.length() == 0)
			|| (beamlinePosition == null) || (beamlinePosition.length() == 0))
			return;

		// beamline id 0 means no assignment or unmount
		int bid = 0;
		if ((beamlineID != null) && (beamlineID.length() > 0))
			bid = Integer.parseInt(beamlineID);

		// Make sure the sil at this cassette position at the beamline
		// is not locked
		if (bid > 0) {
			try {
				if (isSilLocked(forBeamLine, beamlinePosition))
					throw new Exception("Cannot unassign cassette " + silId
						+ " at " + forBeamLine
						+ " " + beamlinePosition
						+ ". Sil is locked (for crystal screening or sorting).");

			} catch (Exception e) {
				SilLogger.error("in UnassignSil: "  + e.getMessage());
				// Ignore error. There are probably problems withthe sil xml file
				// that caused error in isSilLocked().
			}
		}
		

		SilLogger.info("Unmounting casstte = " + silId  + " bid = " + bid);

		// Mount or unmount cassette
		String x = ctsdb.mountCassette(silId, 0);
		if (SilUtil.isError(x))
			throw new Exception(SilUtil.parseError(x));

		// update data/beamlines/<BLXXX>cassettes.*
		createBeamlineInfo(forBeamLine);
		
		SilLogger.info("Update beamline info for beamline " + forBeamLine);

	}


	/**
	 * Assign user's cassette to one of the cassette positions at the beamline.
	 * Copy sil files from user's dir to beamline dir and update
	 * beamline info.
	 * Before doing that we make sure that the sil at the cassette position
	 * is not locked (if it is locked, it means that the dcss is screening
	 * the cassette at the moment).
	 */
	public void assignSilToBeamline(int silId,
					String forBeamLine,
					String beamlinePosition)
		throws Exception
	{

		// If this sil is currently assigned to a beamline
		// then unassin it first
		unassignSil(silId);

		// beamline id 0 means no assignment or unmount
		int bid = 0;
		String beamlineId = ctsdb.getBeamlineID(forBeamLine, beamlinePosition);

		if (beamlineId.length() > 0)
			bid = Integer.parseInt(beamlineId);
			
		SilLogger.info("assignSilToBeamline:" 
				+ " silId = " + silId
				+ " beamline = '" + forBeamLine
				+ "' cassette position = '" + beamlinePosition
				+ "' bid = " + bid);

		// Nothing to do
		if (bid == 0) {
			SilLogger.info("Beamline " + forBeamLine + " position " + beamlinePosition
						+ " does not exist in DB");
			return;
		}

		// Make sure the sil at this cassette position at the beamline
		// is not locked
		if (isSilLocked(forBeamLine, beamlinePosition)) {
				throw new Exception("Cassette mounted at " + forBeamLine
									+ " " + beamlinePosition
									+ " is currently locked by dcss for screening.");
		}
		
		// Mount this cassette
		String x = ctsdb.mountCassette(silId, bid);
		if (SilUtil.isError(x))
			throw new Exception(SilUtil.parseError(x));

		if (bid > 0) {

			// Create cassettes.xml in beamline dir
			createBeamlineInfo(forBeamLine);
		}
	}
	
	/**
	 * Check if this user is the owner of the sil
	 */
	public boolean isSilOwner(String userName, int silId)
		throws Exception
	{
		String owner = ctsdb.getCassetteOwner(silId);
		if (SilUtil.isError(owner))
			throw new Exception(SilUtil.parseError(owner));	
		
		if (userName.equals(owner))
			return true;
			
		return false;
	}
	
	/**
	 */
	public void deleteSil(int silId)
		throws Exception
	{
		// First unassign the sil
		// in case it is assigned to a beamline
		unassignSil(silId);
		
		// Remove cassette from db
		String owner = ctsdb.getCassetteOwner(silId);
		if (SilUtil.isError(owner))
			throw new Exception(SilUtil.parseError(owner));
			
		String x = ctsdb.removeCassette(silId);		
		if (SilUtil.isError(x))
			throw new Exception(SilUtil.parseError(x));
			
		// Delete cassette files
		String dir = SilConfig.getInstance().getCassetteDir() + "/" + owner;
		File fso = new File(dir);
		MyFilenameFilter filter = new MyFilenameFilter();
		String prefix = filePrefix + silId +"_";
		filter.setFilePrefix(prefix);

		String[] fileList= fso.list(filter);
		int i, n;
		n= fileList.length;
		for (i=0; i<n; i++) {
			SilLogger.info( "delete "+ fileList[i]);
			File f= new File(fso, fileList[i]);
			f.delete();
		}
		
		
	}


	/**
	 * Create a sil entry in DB
	 */
	public int createSilInDB(String userName, String cassettePin)
		throws Exception
	{
		if ((cassettePin == null) || (cassettePin.length() == 0))
			cassettePin = "unknown";

		// Add cassette to db
		int userID= ctsdb.getUserID( userName);
		int[] retCassetteID = new int[1];
		String x = ctsdb.addCassette(userID, cassettePin);
		if (SilUtil.isError(x)) {
			String err = "Failed to add cassette for userName=";
			err += userName + " because " + SilUtil.parseError(x);
			SilLogger.error(err);
			throw new Exception(err);
		}

		// Set sil id
		int silId = Integer.valueOf(x.trim()).intValue();


		// Delete unused cassette files
		ctsdb.deleteUnusedCassetteFiles(userName);

		return silId;

	}


	/**
	 * Copy files from template for the new sil
	 */
	private void createDefaultSilFiles(int silId, String cassettePin, String userFileName, String whichTemplate)
		throws Exception
	{
		 if ((whichTemplate == null) || (whichTemplate.length() == 0))
			whichTemplate = templatePrefix;
			

		// Original filename for this spreadsheet
		if (userFileName == null)
			userFileName = whichTemplate + ".xls";

		// baseName for all files for this sil id
		String baseName = ctsdb.addCassetteFile(silId, filePrefix, userFileName);
		if(SilUtil.isError(baseName)) {
			String err = "Failed in addCassetteFile for sil id "
					+ silId + " because " + SilUtil.parseError(baseName);
			SilLogger.error(err);
			throw new Exception(err);
		}

		String owner = ctsdb.getCassetteOwner(silId);
		if (SilUtil.isError(owner))
			throw new Exception(SilUtil.parseError(owner));

		// Copy default spreadsheet from template dir
		SilConfig config = SilConfig.getInstance();

		String templateDir = config.getTemplateDir();
		String srcFile = templateDir + File.separator + whichTemplate;
		String destFile = "";

		// Create dir if it does not exist
		String cassetteDir = config.getCassetteDir() + File.separator + owner;
		File fso = new File(cassetteDir);
		if(!fso.exists())
			fso.mkdir();

		destFile = cassetteDir + File.separator + baseName;

		// xls file
		ctsio.copy(srcFile + ".xls", destFile + ".xls");

		// xml file
		ctsio.copy(srcFile + ".xml", destFile + ".xml");

		// tcl file
//		ctsio.copy(srcFile + ".txt", destFile + ".txt");

		// html file
//		ctsio.copy(srcFile + ".html", destFile + ".html");

		// src xls file. Need this file for download original excel
		ctsio.copy(srcFile + "_src.xls", destFile + "_src.xls");

		// src xml file
//		ctsio.copy(srcFile + "_src.xml", destFile + "_src.xml");

		// Create an editable xml file for this sil
		// Transforming from Guenter's xml to sil xml
		srcFile = cassetteDir + File.separator + baseName + ".xml";
		destFile = cassetteDir + File.separator + baseName + "_sil.xml";
		createSilFile(silId, cassettePin, srcFile, destFile);

	}

	/**
	 * Copy upload files from tmp dir
	 */
	public void createSilFiles(int silId,
				String cassettePin,
				String orgFileName,
				String srcExcelFile,
				String srcXmlFile,
				String xsltName)
		throws SilValidationWarning, Exception
	{

		// Copy default spreadsheet from template dir
		SilConfig config = SilConfig.getInstance();

		String templateDir = config.getTemplateDir();

		// Replace bad characters in some fields with _.
		// If it's really bad then throws an error.
		StringBuffer warnings = new StringBuffer();

		// Tranform src xml to Guenter's xml in tmp dir
		String owner = ctsdb.getCassetteOwner(silId);
		if (SilUtil.isError(owner))
			throw new Exception(SilUtil.parseError(owner));
		
		if ((xsltName == null) || (xsltName.length() == 0) || xsltName.equals("null"))
			xsltName = owner;
		String xsltFile = templateDir + File.separator + ctsdb.getXSLTemplate(xsltName);
		SilLogger.info("xslt for user " + owner + " is " + xsltFile);
		String destFile = srcXmlFile.substring(0, srcXmlFile.length()-4) + "_src.xml";
		SilLogger.info("in createSilFiles: srcXmlFile = " + srcXmlFile + " destFil = " + destFile);
		String result = ctsio.xslt(srcXmlFile, destFile, xsltFile, null);
		if(result.startsWith("OK")==false )
			throw new Exception("Failed to transform " + srcXmlFile
								+ " to " + destFile
								+ " using xslt " + xsltFile
								+ " because " + SilUtil.parseError(result));

		// Save this file name _src.xml in tmp dir (CrystalData format)
		String transformedXmlFile = destFile;

		// Validate _src.xml in tmp dir before
		// adding new entry to DB.
		validateSrcXml(transformedXmlFile, warnings);

		// baseName for all files for this sil id
		String baseName = ctsdb.addCassetteFile(silId, filePrefix, orgFileName);

		if(SilUtil.isError(baseName)) {
			String err = "Failed in addCassetteFile for sil id ";
			err += silId + " because " + SilUtil.parseError(baseName);
			SilLogger.error(err);
			throw new Exception(err);
		}

			
		String cassetteDir = config.getCassetteDir() + File.separator + owner;
		File fso = new File(cassetteDir);
		if(!fso.exists())
			fso.mkdir();

		// Base filename in cassette dir
		destFile = cassetteDir + File.separator + baseName;

		// xls file
		ctsio.copy(srcExcelFile, destFile + "_src.xls");

		// xml file (Data format)
		String rawXmlFile = destFile + "_src.xml";
		ctsio.copy(srcXmlFile, rawXmlFile);

		// Copy xml file (CrystalData format)
		String guenterXml = destFile + ".xml";
		ctsio.copy(transformedXmlFile, guenterXml);

//		String srcFile = templateDir + File.separator + templatePrefix;

		// Create an editable xml file for this sil
		// Transforming from Guenter's xml to sil xml
		destFile = cassetteDir + File.separator + baseName + "_sil.xml";

		createSilFile(silId, cassettePin, guenterXml, destFile);

		// This exception should be caught
		// so that the warning will be displayed
		// and the client knows that the sil has been
		// created.
		if (warnings.length() > 0)
			throw new SilValidationWarning(warnings.toString());

	}

	/**
	 * Tranform src xml (ADO format) to sil xml (sil.dtd).
	 */
	public void createSilFile(int silId, String cassettePin,
				String srcFile, String destFile)

		throws Exception
	{
		String xsltFile = SilConfig.getInstance().getTemplateDir()
						+ File.separator + fileCrystalData2Sil;
		String xsltTclFile = SilConfig.getInstance().getTemplateDir()
						+ File.separator + "xsltSil2Tcl.xsl";
		String destTclFile = destFile.substring(0, destFile.length()-3) + "tcl";

		TransformerFactory tFactory = TransformerFactory.newInstance();
		String systemId = SilConfig.getInstance().getSilDtdUrl();
		// Create sil xml file
		try {

			SilLogger.info("Creating sil xml file: " + destFile);

			Transformer transformer = tFactory.newTransformer( new StreamSource(xsltFile));
			transformer.setParameter("param1", String.valueOf(silId));
			transformer.setParameter("param2", cassettePin);

			StreamSource source = new StreamSource(new FileReader(srcFile), systemId);
			StreamResult out = new StreamResult(new FileWriter(destFile));
			transformer.transform(source, out);

		} catch( Exception ex) {
			String err = "Failed to transform " + srcFile + " to " + destFile
							+ " using " + xsltFile + " xslt tranformation because "
							+ ex.getMessage();
			throw new Exception(err);
		}

		// Creat sil tcl file
		try {

			SilLogger.info("Creating sil tcl file: " + destTclFile);

			Transformer transformer = tFactory.newTransformer( new StreamSource(xsltTclFile));
			StreamSource source = new StreamSource(new FileReader(destFile), systemId);
			StreamResult out = new StreamResult(new FileWriter(destTclFile));
			transformer.transform(source, out);

		} catch( Exception ex) {
			String err = "Failed to transform " + destFile + " to " + destTclFile
							+ " using " + xsltTclFile + " xslt tranformation because "
							+ ex.getMessage();
			throw new Exception(err);
		}
	}

	/**
	 * Make sure port contains a 2-3 letter code, [A-L][1-16].
	 */
	private String validatePort(Element rowNode, Hashtable lookup)
		throws Exception
	{
		int row = Integer.parseInt(rowNode.getAttribute("number").trim());

		// Validate Port. Can't fix this field.
		// If something is wrong we need to throw an exception.
		NodeList nodeList = rowNode.getElementsByTagName("Port");
		if ((nodeList == null) || (nodeList.getLength() != 1))
			throw new Exception("Missing Port in row " + row);
		Node port = nodeList.item(0);
		Text text = (Text)port.getFirstChild();
		if (text == null)
			throw new Exception("Invalid Port in row " + row);

		// Port must have 2 characters [A-L][1-8]
		String value = text.getNodeValue();
		if ((value == null) || (value.length() == 0))
			throw new Exception("Empty Port value in row " + row);

		if (value.length() > 3)
			throw new Exception("Invalid Port " + value + " in row " + row);

		if (portFirstChar.indexOf(value.charAt(0)) < 0)
			throw new Exception("Invalid Port " + value + " in row " + row);

		try {
			int num = Integer.parseInt(value.substring(1));
			if ((num < 0) || (num > maxPort))
				throw new Exception("Invalid Port " + value + " in row " + row);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid Port " + value + " in row " + row);
		}


		// Make sure it's unqiue
		Integer otherRow = null;
		if ((otherRow=(Integer)lookup.get(value)) != null)
			throw new Exception("Port " + value
								+ " in row " + row
								+ " duplicates value in row "
								+ otherRow);

		// Save the new Port in the loopup table.
		lookup.put(value, new Integer(row));

		return value;

	}

	/**
	 * Replace bad characters with _.
	 * Replace an empty CrystalID with Port
	 * throws an exception if CrystalID is not unique.
	 */
	private String validateCrystalID(Element rowNode,
					String defaultId,
					Hashtable lookup,
					StringBuffer warnings)
		throws Exception
	{
		int row = Integer.parseInt(rowNode.getAttribute("number").trim());

		// If CrystalID field is missing then
		// create one with the default value
		NodeList nodeList = rowNode.getElementsByTagName("CrystalID");
		if ((nodeList == null) || (nodeList.getLength() != 1)) {
			Document doc = rowNode.getOwnerDocument();
			Element node = doc.createElement("CrystalID");
			Text text = doc.createTextNode(defaultId);
			node.appendChild(text);
			rowNode.appendChild(node);
			warnings.append("Replaced empty CrystalID in row " + row
							+ " with " + defaultId + "\n");
			return defaultId;
		}

		// CrystalID missing value then set default value.
		Node node = nodeList.item(0);
		Text text = (Text)node.getFirstChild();
		if (text == null) {
			Document doc = rowNode.getOwnerDocument();
			text = doc.createTextNode(defaultId);
			node.appendChild(text);
			warnings.append("Replaced empty CrystalID in row " + row
							+ " with " + defaultId + "\n");
			return defaultId;
		}

		// Replace an empty value with Port
		String value = text.getNodeValue();
		if ((value == null) || (value.length() == 0) || value.equals("null")) {
			text.setNodeValue(defaultId);
			warnings.append("Replaced empty CrystalID in row " + row
							+ " with " + defaultId + "\n");
			return defaultId;
		}

		// Replace bad characters with underscores.
		StringBuffer buf = new StringBuffer();
		boolean modified = false;
		char ch;
		for (int i = 0; i < value.length(); ++i) {
			ch = value.charAt(i);
			if (Character.isLetterOrDigit(ch)
			   || (crystalIdChars.indexOf(ch) >= 0)) {
				buf.append(ch);
			} else {
				buf.append('_');
				modified = true;
			}
		}

		// Report the change
		if (modified) {
			warnings.append("Replaced CrystalID in row " + row
							+ " from " + value + " with " + buf.toString()
							+ ": removed bad characters\n");
			value = buf.toString();
			text.setNodeValue(value);
		}

		// Make sure it's unqiue
		// If not then append this row's port (which is unique) to
		// the CrystalID.
		Integer otherRow = null;
		if ((otherRow=(Integer)lookup.get(value)) != null) {
			String newValue = value + "_" + defaultId;
			warnings.append("Replaced CrystalID in row " + row
								+ " from " + value
								+ " with " + newValue
								+ ": duplicated value in row " + row
								+ "\n");
			value = newValue;
			text.setNodeValue(value);
		}

		// Save the new CrystalID in the lookup table.
		lookup.put(value, new Integer(row));

		return value;

	}

	/**
	 * Replace bad characters with _.
	 */
	private String validateDirectory(Element rowNode,
					StringBuffer warnings)
		throws Exception
	{
		int row = Integer.parseInt(rowNode.getAttribute("number").trim());

		// Validate Port. Can't fix this field.
		// If something is wrong we need to throw an exception.
		NodeList nodeList = rowNode.getElementsByTagName("Directory");
		if ((nodeList == null) || (nodeList.getLength() != 1))
			return "";
		Node node = nodeList.item(0);
		Text text = (Text)node.getFirstChild();
		if (text == null)
			return "";

		String value = text.getNodeValue();

		// Replace bad characters with underscores.
		StringBuffer buf = new StringBuffer();
		boolean modified = false;
		char ch;
		// Dir must be relative path
		// First pass:
		// 1. Remove non-alphanum leading chars
		// 2. Replace illigal chars with  _
		for (int i = 0; i < value.length(); ++i) {
			ch = value.charAt(i);
			if (Character.isLetterOrDigit(ch)) {
				buf.append(ch);
			} else {
				if (buf.length() == 0) {
					// Ignore all leading chars which are not alphanum
				} else {
					if (directoryChars.indexOf(ch) >= 0) {
						buf.append(ch); // only append allowed chars
					} else {
						buf.append('_'); // Replaced illigal chars with _
					}
				}
			}
		}
		// Second pass:
		// Remove non-alphanum chars that immediately follow slash
		String dir1 = buf.toString();
		buf.delete(0, buf.length());
		boolean marked = false;
		for (int i = 0; i < dir1.length(); ++i) {
			ch = dir1.charAt(i);
			if (ch == '/' && !marked) {
				// Mark first slash
				marked = true;
				buf.append(ch);
			} else {
				if (marked) {
					// This char follows a slash
					if (Character.isLetterOrDigit(ch)) {
						buf.append(ch);
						marked = false;
					}
				} else {
					if (Character.isLetterOrDigit(ch)
					|| (directoryChars.indexOf(ch) >= 0)) {
						buf.append(ch);
					}
				}
			}
			
		}
		String dir2 = buf.toString();
		
		if (dir2.length() == 0)
			throw new Exception("Directory in row " + row + " contains sequence of illegal characters: " + value);
		
		// Report the change
		if (!dir2.equals(value)) {
			warnings.append("Replaced Directory in row " + row
							+ " from " + value + " to " + dir2 + "\n");
			value = dir2;
			text.setNodeValue(value);
		}


		return value;

	}

	/**
	 * Replace bad characters with _ in CrystalID and directory fields.
	 * throws an error if data in Port field are bad.
	 */
	private void validateSrcXml(String file, StringBuffer warnings)
		throws Exception
	{
		// LOAD

		//Instantiate a DocumentBuilderFactory.
		javax.xml.parsers.DocumentBuilderFactory dFactory =
					javax.xml.parsers.DocumentBuilderFactory.newInstance();

		//Use the DocumentBuilderFactory to create a DocumentBuilder.
		javax.xml.parsers.DocumentBuilder dBuilder = dFactory.newDocumentBuilder();

		//Use the DocumentBuilder to parse the XML input.
		Document doc = dBuilder.parse(file);


		// VALIDATE & FIX
		Element dataNode = doc.getDocumentElement();
		Node child = dataNode.getFirstChild();
		if (child == null)
			throw new Exception("Empty spreadsheet");

		// Lookup table for Port
		// to ensure that it's unique.
		Hashtable portLookup = new Hashtable();

		// Lookup table for CrystalID
		// to ensure that it's unique.
		Hashtable idLookup = new Hashtable();

		// Loop over each row.
		while (child != null) {

			if ((child instanceof Element) && child.getNodeName().equals("Row")) {

				// Validate Port. Can't fix this field.
				// If something is wrong we need to throw an exception.
				String port = validatePort((Element)child, portLookup);

				// Validate CrystalID field. Replace invalid chars with _.
				// Also make sure that crystalID is unique.
				validateCrystalID((Element)child, port, idLookup, warnings);

				// Validate Directory
				validateDirectory((Element)child, warnings);

			}

			child = child.getNextSibling();

		}

		// SAVE
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer();
		transformer.setOutputProperty(OutputKeys.VERSION, "1.0");
		transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
		DOMSource source = new DOMSource(dataNode);
		StreamResult result = new StreamResult(new FileOutputStream(file));
		transformer.transform( source, result);

	}

	/**
	 * Create beamline info file describing which cassettes are
	 * assigned to the beamline.
	 */
	private void createBeamlineInfo(String beamlineName)
		throws Exception
	{

		String xmlString = ctsdb.getCassettesAtBeamline(beamlineName);
		String fileXSL1 = SilConfig.getInstance().getRootDir()
							+ File.separator + "cassettesAtBeamline.xsl";


		StringWriter tclStringWriter= new StringWriter();

		ctsio.xslt( xmlString, tclStringWriter, fileXSL1, null);

		String tcldata= tclStringWriter.toString();
		String x= tcldata;
		if(SilUtil.isError(x))
			throw new Exception(SilUtil.parseError(x));

		//save beamline info to disk
		String beamlineDir= SilConfig.getInstance().getBeamlineDir()
							+ beamlineName +File.separator;
		File fso = new File(beamlineDir);
		if(!fso.exists())
			fso.mkdir();

		Writer dest = null;
		String filepath = null;
		try {
		filepath= beamlineDir+ "cassettes.xml";
		dest= new FileWriter( filepath);
		dest.write( xmlString);
		dest.close();
		dest = null;
		filepath= beamlineDir+ "cassettes.txt";
		dest= new FileWriter( filepath);
		dest.write( tcldata);
		dest.close();
		dest = null;
		} catch (Exception e) {
			SilLogger.error("Failed to write file " + filepath + ": " + e.getMessage(), e);
			throw e;
		} finally {
			if (dest != null)
				dest.close();
			dest = null;
		}

	}

	/**
	 * class used to filter files when deleting cassette files.
	 */
	private class MyFilenameFilter implements FilenameFilter
	{
		String m_prefix = null;
		
		public void setFilePrefix( String prefix)
		{
			m_prefix= prefix;
		}

		public boolean accept(File fDir, String fName) 
		{
			return fName.startsWith(m_prefix);
		}
	}
}

