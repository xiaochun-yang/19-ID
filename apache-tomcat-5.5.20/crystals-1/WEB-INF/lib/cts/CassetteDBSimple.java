/* CassetteDB.java
 */

package cts;

import java.sql.*;
import java.text.*;
import java.io.*;
import java.util.*;
import java.util.regex.*;

import org.apache.xerces.dom.DocumentImpl;
import org.apache.xerces.dom.DOMImplementationImpl;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import org.w3c.dom.*;
import org.xml.sax.InputSource;
import org.xml.sax.EntityResolver;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import org.apache.xml.serializer.*;

/**************************************************
 *
 * CassetteDB
 *
 **************************************************/
public class CassetteDBSimple implements CassetteDB
{
	private String cassetteDir = "";
	private String beamlineDir = "";
	
	private Document users = null;
	private Document beamlines = null;
	private Document params = null;
	private Properties cassetteLookup = new Properties();
	
	private static CassetteDB singleton = null;
	
	private static int lastUserId = 0;
	private static int lastBeamlineId = 0;
	private static int lastCassetteId = 0;
	
	private String[] beamlineAttr = new String[10];
	private String[] beamlinePositions = new String[4];
	
	private String paramFile = null;
	private String beamlineFile = null;
	private String userFile = null;
	private String cassetteLookupFile = null;

	//Instantiate a DocumentBuilderFactory.
	private javax.xml.parsers.DocumentBuilderFactory dFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();

	//Use the DocumentBuilderFactory to create a DocumentBuilder.
	private javax.xml.parsers.DocumentBuilder dBuilder = dFactory.newDocumentBuilder();
	
	private TransformerFactory tFactory = TransformerFactory.newInstance();

	/**
	 * Creates/returns singleton
	 */
	public static CassetteDB getCassetteDB(Properties prop)
		throws Exception
	{
		if (singleton == null)
			singleton = new CassetteDBSimple(prop);
			
		return singleton;
	}
	
	/**
	 * Constructor: can only be called by this class static methdo
 	 */
	private CassetteDBSimple(Properties prop)
		throws Exception
	{	
		cassetteDir = (String)prop.get("cassetteDir");
		beamlineDir = (String)prop.get("beamlineDir");
		
		paramFile = cassetteDir + "/../params.xml";
		beamlineFile = beamlineDir + "/beamlines.xml";
		userFile = cassetteDir + "/users.xml";
		cassetteLookupFile = cassetteDir + "/../cassette_lookup.prop";
		
		// Load users list
		loadUsers();
		
		// Load beamline list
		loadBeamlines();
		
		// Load params.xml
		loadParams();
		
		// Load cassette_lookup.prop
		loadCassetteLookup();

		int i = 0;
		beamlineAttr[i] = "BeamLineID"; ++i;
		beamlineAttr[i] = "BeamLineName";++i;
		beamlineAttr[i] = "BeamLinePosition";++i;
		beamlineAttr[i] = "UserName";++i;
		beamlineAttr[i] = "Pin";++i;
		beamlineAttr[i] = "CassetteID";++i;
		beamlineAttr[i] = "FileID";++i;
		beamlineAttr[i] = "FileName";++i;
		beamlineAttr[i] = "UploadFileName";++i;
		beamlineAttr[i] = "UploadTime";++i;
		
		i = 0;
		beamlinePositions[i] = "No cassette"; ++i;
		beamlinePositions[i] = "left"; ++i;
		beamlinePositions[i] = "middle"; ++i;
		beamlinePositions[i] = "right"; ++i;
		
	}

	/**
	 * Load users list from users.xml file
	 */
	private void loadUsers()
		throws Exception
	{
		//Use the DocumentBuilder to parse the XML input.
		users  = dBuilder.parse(userFile);
		
		// Synchronized call
		findLastUserId();

		System.out.println("last user id = " + lastUserId);
	}
		
	/**
	 * Load beamline list from beamlines.xml file
	 */
	private void loadBeamlines()
		throws Exception
	{
		//Use the DocumentBuilder to parse the XML input.
		beamlines  = dBuilder.parse(beamlineFile);
		
		findLastBeamlineId();
		
		System.out.println("last beamline id = " + lastBeamlineId);
	}
		
	/**
	 * Load cassette/user file
	 */
	private void loadCassetteLookup()
		throws Exception
	{		
		cassetteLookup.clear();
		FileInputStream istream = new FileInputStream(cassetteLookupFile);
		cassetteLookup.load(istream);
		istream.close();
				
	}

	/**
	 * Load beamline list from beamlines.xml file
	 */
	private void loadParams()
		throws Exception
	{
		
		//Use the DocumentBuilder to parse the XML input.
		params  = dBuilder.parse(paramFile);
		
		NodeList nodes = params.getElementsByTagName("LastCassetteID");
		if ((nodes == null) || (nodes.getLength() == 0))
			throw new Exception("Cannot find LastCassetteID node in " + paramFile);
		String lastCidStr = getText(nodes.item(0));
		lastCassetteId = Integer.parseInt(lastCidStr);

		System.out.println("last cassette id = " + lastCassetteId);
				
	}
		
	/**
	 * Find the highest user id number
	 */
	private void findLastBeamlineId()
	{	
		int biggest = 0;
		NodeList nodes = beamlines.getElementsByTagName("BeamLineID");
		for (int i = 0; i  < nodes.getLength(); ++i) {
			Element el = (Element)nodes.item(i);
			String str = getText(el);
			if ((str == null) || (str.length() == 0))
				continue;
			int id = Integer.parseInt(str);
			if (id > biggest)
				biggest = id;
		}
		
		lastBeamlineId = biggest;
			
	}

	/**
	 * Find the highest user id number
	 */
	private void findLastUserId()
	{	
		int biggest = 0;
		NodeList nodes = users.getElementsByTagName("UserID");
		for (int i = 0; i  < nodes.getLength(); ++i) {
			Element el = (Element)nodes.item(i);
			String str = getText(el);
			if ((str == null) || (str.length() == 0))
				continue;
			int id = Integer.parseInt(str);
			if (id > biggest)
				biggest = id;
		}
		
		lastUserId = biggest;
			
	}
	
	/**
	 * Generates a new user id
	 */
	private int newUserId()
	{
		++lastUserId;
		return lastUserId;
	}

	/**
	 * Save Users list to user.xml file
	 */
	private void saveUsers(Writer writer)
		throws Exception
	{
		if (writer == null)
			return;

		saveXmlDocument(writer, users);

	}
	
	private void saveUsers()
		throws Exception
	{
		// Save beamlines.xml file
		PrintWriter writer = new PrintWriter(new File(userFile));
		saveUsers(writer);
		writer.close();
	}

	/**
	 * Save beamline list to user.xml file
	 */
	private void saveBeamlines(Writer writer)
		throws Exception
	{
		if (writer == null)
			return;

		saveXmlDocument(writer, beamlines);

	}
	
	private void saveBeamlines()
		throws Exception
	{
		// Save beamlines.xml file
		PrintWriter writer = new PrintWriter(new File(beamlineFile));
		saveBeamlines(writer);
		writer.close();
	}
	
	private void saveCassetteLookup()
		throws Exception
	{
		// Save caseette_lookup.xml file
		FileOutputStream ostream = new FileOutputStream(cassetteLookupFile);
		cassetteLookup.store(ostream, "Cassette/Owner Lookup Table");
		ostream.close();
	}

	private void saveParams()
		throws Exception
	{
		// Save beamlines.xml file
		PrintWriter writer = new PrintWriter(new File(paramFile));
		saveXmlDocument(writer, params);
		writer.close();
	}

	private void saveXmlDocument(String fileName, Document doc)
		throws Exception
	{
		// Save cassettes.xml file
		PrintWriter writer = new PrintWriter(new File(fileName));
		saveXmlDocument(writer, doc);
		writer.close();
	}

	/**
	 * Save xml document to file
	 */
	private void saveXmlDocument(Writer writer, Document doc)
		throws Exception
	{
		if (writer == null)
			return;

		Transformer transformer = tFactory.newTransformer();
		transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
		DOMSource source = new DOMSource(doc.getDocumentElement());
		StreamResult result = new StreamResult(writer);
		transformer.transform(source, result);

	}
	
	private String getNodeParam(Node node, String paramName)
	{
		if (node == null)
			return null;
		NodeList children = node.getChildNodes();
		for (int i = 0; i < children.getLength(); ++i) {
			Node child = children.item(i);
			if ((child instanceof Element) && child.getNodeName().equals(paramName)) { 
				String val = getText(child);
				return val;
			}
		}
		return null;
	}

	/**
	 * Example:
	 * setNodeParam(row, "CassetteID", 1111);
	 * Results to:
	 * <Row>
	 *   <CasetteID>1111</CassetteID>
	 * </Row>
 	 */
	private void setNodeParam(Node row, String paramName, String value)
	{
		NodeList children = row.getChildNodes();
		for (int i = 0; i < children.getLength(); ++i) {
			Node child = children.item(i);
			if ((child instanceof Element) && child.getNodeName().equals(paramName)) { 
				setText(child, value);
			}
		}
	}
	
	private String getText(Node node)
	{
		NodeList nodes = node.getChildNodes();
		for (int k = 0; k < nodes.getLength(); ++k) {
			if (nodes.item(k) instanceof Text) {
				return nodes.item(k).getNodeValue();
			}
		}
		
		return null;
	}
	
	/**
	 */
	private void setText(Node parent, String value)
	{
		NodeList nodes = parent.getChildNodes();
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node tnode = nodes.item(i);
			if (tnode instanceof Text) {
				tnode.setNodeValue(value);
				break;
			}
		}
	}

	/**
	 * Find user node in users.xml for the given user name
 	 */
	private Element findUserElementByName(String name)
		throws Exception
	{
		// Get list of <Row> elements
		NodeList nodes = users.getElementsByTagName("Row");
		for (int i = 0; i  < nodes.getLength(); ++i) {
			Element el = (Element)nodes.item(i);
			String uname = getNodeParam(el, "LoginName");
			if ((uname != null) && uname.equals(name)) {
				return el;
			}
		}
			
		return null;
	}

	/**
	 * Find user node in users.xml for the given userId
 	 */
	private Element findUserElementById(int id)
		throws Exception
	{
		String idStr = String.valueOf(id);
		// Get list of <Row> elements
		NodeList nodes = users.getElementsByTagName("Row");
		for (int i = 0; i  < nodes.getLength(); ++i) {
			Element el = (Element)nodes.item(i);
			String uid = getNodeParam(el, "UserID");
			if ((uid != null) && uid.equals(idStr))
				return el;
		}
			
		return null;
	}
	
	/**
 	 * <UserList>
	 *   <User name="joeuser" id="22" realName="Joe User"/>
	 *   <User name="tigerw" id="87" realName="Tiger Woods"/>
	 * </UserList>
	 */
	synchronized public String removeUser(int userID)
	{
		String userName = getUserName(userID);
		
		if (userName.indexOf("Error") > -1)
			return userName;
		
		// Remove users entry in users.xml file
		try {
			Node tobeRemoved = findUserElementById(userID);
			if (tobeRemoved != null) {
				Node tt = tobeRemoved.getNextSibling();
				if (tt instanceof Text) {
					users.getDocumentElement().removeChild(tt);
				}
				users.getDocumentElement().removeChild(tobeRemoved);
			}
		} catch (Exception e) {
			return createErrorString("removeUser", "cannot remove user" + userID + " " + e.getMessage());
		} 

		// Save users.xml file
		try {
			saveUsers();
		} catch (Exception e) {
			return createErrorString("removeUser", "cannot save users.xml " + e.getMessage());
		}

		// Remove all files in <cassetteDir>/<user> dir
		String dirName = cassetteDir + "/" + userName;		
		try {
			File dir = new File(dirName);
			File[] files = dir.listFiles();
			for (int i = 0; i < files.length; ++i) {
				files[i].delete();
			}	
		} catch (Exception e) {
			return createErrorString("removeUser", "cannot rm files in dir " + dirName + " " + e.getMessage());
		}
		
		// Remove <cassetteDir>/<user> dir
		try { 
			// Add <cassetteDir>/<user> dir
			File newDir = new File(dirName);
			newDir.delete();
		} catch (Exception e) {
			return createErrorString("removeUser", "cannot delete dir " + dirName + " " + e.getMessage());
		}
		
		return "OK";
		
		
	}
	
	private void addUserElement(String loginName, int uid,
					String realName, String template)
		throws Exception
	{
		Element node = users.createElement("Row");

		// UserID
		addChild(users, node, "UserID", String.valueOf(uid));
		// LoginName
		addChild(users, node, "LoginName", loginName);
		// MySQLUserID
		addChild(users, node, "MySQLUserID", "null");		
		// RealName
		addChild(users, node, "RealName", realName);
		// DataImportTemplate
		addChild(users, node, "DataImportTemplate", template);
				
		users.getDocumentElement().appendChild(node);
		users.getDocumentElement().appendChild(users.createTextNode("\n"));
	}
		
	/**
	 */
	private String getUserTemplate(String user)
	{
		if (user.equals("jcsg"))
			return "import_jcsg.xsl";
		
		return "import_default.xsl";
	}
	
	/**
	 * Add new dir for this user
 	 */
	synchronized public String addUser(String loginName, String mySQLUSerID, String realName)
	{
		if ((loginName == null) || (loginName.length() == 0))
			return createErrorString("addUser", "invalid login name, user id or real name");
			
		// Add users entry in users.xml file
		try {
			Element node = findUserElementByName(loginName);
			if (node == null) {
				int uid = newUserId();
				String template = getUserTemplate(loginName);
				addUserElement(loginName, uid, 
						realName, template);
			} else {
				throw new Exception("user " + loginName + " already exists");
			}
		} catch (Exception e) {
			return createErrorString("addUser", "cannot add user " + loginName + " " + e.getMessage());
		} 

		// Save users.xml file
		try {
			saveUsers();
		} catch (Exception e) {
			return createErrorString("addUser", "cannot save users.xml " + e.getMessage());
		}

		// Add new dir
		String dirName = cassetteDir + "/" + loginName;
		try { 
			// Add <cassetteDir>/<user> dir
			File newDir = new File(dirName);
			if (newDir.exists())
				return createErrorString("addUser", "dir " + dirName + " already exists");
			newDir.mkdir();
		} catch (Exception e) {
			System.out.println(e.getMessage());
			e.printStackTrace();
			return createErrorString("addUser", "cannot create dir " + dirName + " " + e.getMessage());
		}
		
		
		String fileName = dirName + "/cassettes.xml";
		try {
		
		// Add <user>/cassettes.xml
		File newFile = new File(fileName);
		PrintWriter writer = new PrintWriter(newFile);
		writer.println("<CassetteFileList>");
		writer.println("</CassetteFileList>");
		writer.close();
		
		} catch (Exception e) {
			return createErrorString("addUser", "cannot create file " + fileName + " " + e.getMessage());
		}
		
		return "OK";
	}

	
	private void addChild(Document doc, Node parent, String cname, String str)
	{
		Node child = doc.createElement(cname);
		Text text = doc.createTextNode(str);
		
		child.appendChild(text);
		parent.appendChild(child);
		
	}
	
	private int newCassetteId()
		throws Exception
	{
		++lastCassetteId;

		NodeList nodes = params.getElementsByTagName("LastCassetteID");
		if ((nodes == null) || (nodes.getLength() != 1))
			throw new Exception("Cannot find LastCassetteID in params.xml");
		setText(nodes.item(0), String.valueOf(lastCassetteId));
		
		saveParams();
		
		return lastCassetteId;
	}
	

	/**
 	 */
	public String addCassette(int userID, String PIN)
	{
		// Add cassette in <user>/cassettes.xml
		//Use the DocumentBuilder to parse the XML input.
		String uname = getUserName(userID);
		
		if (uname.indexOf("<Error>") > -1)
			return uname;
		
		return addCassette(uname, PIN);
		
	}
	
	/**
	 */
	synchronized public String addCassette(String owner, String PIN)
	{
		try {
		
		if ((owner == null) || (owner.length() == 0))
			return createErrorString("addCassette", "Invalid cassette owner");
			
		String fileName = cassetteDir + "/" + owner + "/cassettes.xml";
		Document cassettes  = dBuilder.parse(fileName);
		
		int newId = newCassetteId();
		String cassetteId = String.valueOf(newId);
		Node node = cassettes.createElement("Row");
		addChild(cassettes, node, "CassetteID", cassetteId);
		addChild(cassettes, node, "Pin", PIN);
		addChild(cassettes, node, "FileID", "0");
		addChild(cassettes, node, "FileName", "null");
		addChild(cassettes, node, "UploadFileName", "null");
		addChild(cassettes, node, "UploadTime", "null");
		addChild(cassettes, node, "BeamLineID", "0");
		addChild(cassettes, node, "BeamLineName", "null");
		addChild(cassettes, node, "BeamLinePosition", "null");
		
		cassettes.getDocumentElement().appendChild(node);
		cassettes.getDocumentElement().appendChild(cassettes.createTextNode("\n"));
		
		// Save <users>/cassettes.xml file
		saveXmlDocument(fileName, cassettes);
		
		// add the new cassette and owner to casette lookup table.
		cassetteLookup.put(cassetteId, owner);
		// save cassette lookup table.
		saveCassetteLookup();
		
		return cassetteId;
		
		} catch (Exception e) {
			return createErrorString("addCassette", e.getMessage());
		}
		
	}
	
	synchronized public String getCassetteOwner(int cid)
	{
		String owner = (String)cassetteLookup.get(String.valueOf(cid));
		if ((owner == null) || (owner.length() == 0))
			return createErrorString("getCassetteOwner", "Cannot find cassette id " + cid + " in lookup table");
		
		return owner;
	
	}

	/**
 	 */
	synchronized public String removeCassette(int cid)
	{
		try {
		
		// get cassette owner
		String owner = (String)cassetteLookup.get(String.valueOf(cid));
		
		if ((owner == null) || (owner.length() == 0))
			return createErrorString("removeCassette", "Cannot find cassstte id " + cid + " in lookup table");
			
		// Unassign cassette from beamline
		mountCassette(cid, 0);

		String cassetteId = String.valueOf(cid);
		
		//Use the DocumentBuilder to parse the XML input.
		// Find cassette id in <user>/cassettes.xml file
		String fileName = cassetteDir + owner + "/cassettes.xml";
		Document cassettes  = dBuilder.parse(fileName);
		
		Node found = null;
		NodeList nodes = cassettes.getElementsByTagName("Row");
		for (int i = 0; (found == null) &&  (i < nodes.getLength()); ++i) {
			Node row = nodes.item(i);
			found = null;
			NodeList children = row.getChildNodes();
			// Find the entry
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if ((child instanceof Element) &&
				    child.getNodeName().equals("CassetteID") && 
				    cassetteId.equals(getText(child))) {
						found = row;
						break;
				}
			}
			
		}

		if (found == null)
			return createErrorString("removeCassette", 
						"cassette id " + cassetteId + " does not exist");
		
		Node tt = found.getNextSibling();
		if ((tt != null) && (tt instanceof Text))
			cassettes.getDocumentElement().removeChild(tt);
		cassettes.getDocumentElement().removeChild(found);
		
		// Save <users>/cassettes.xml file
		saveXmlDocument(fileName, cassettes);
				
		
		// Remove the cassette and owner from casette lookup table.
		cassetteLookup.remove(cassetteId);
		// save cassette lookup table.
		saveCassetteLookup();

		return "OK";
		
		} catch (Exception e) {
			return createErrorString("addCassette", e.getMessage());
		}
		
	}

	/**
 	 */
	public String getXSLTemplate(String userName)
	{
		try {
			Element el = findUserElementByName(userName);
			if (el == null)
				return createErrorString("getXSLTemplate", "user " + userName + " does not exist");
			return getNodeParam(el, "DataImportTemplate");
		} catch (Exception e) {
			return createErrorString("getXSLTemplate", e.getMessage());
		}
	}

	/**
 	 */;
	public String getUserList()
	{
		try {
			StringWriter writer = new StringWriter();
			saveUsers(writer);
			return writer.toString();
		} catch (Exception e) {
			return createErrorString("getUserList",  e.getMessage());
		}
	}

	/**
 	 */
	public int getUserID( String userName)
	{
		try {
			Element el = findUserElementByName(userName);
			if (el == null)
				throw new Exception("user " + userName + " does not exist");
			String att = getNodeParam(el, "UserID");
			return Integer.parseInt(att);
		} catch (Exception e) {
			System.out.println("Cannot get user id for user name " 
					+ userName + ": " + e.getMessage());
			return -1;
		}
	}

	/**
 	 */
	public String getUserName( int userID)
	{
		try {
			Element el = findUserElementById(userID);
			if (el == null)
				throw new Exception("user id " + userID + " does not exist");
			return getNodeParam(el, "LoginName");
		} catch (Exception e) {
			return createErrorString("getUserName", "Cannot get user name for user id " 
					+ userID + ": " + e.getMessage());
		}
	}
	
	private Node findNodeByAttr(Document doc, String attrName, String attrValue)
		throws Exception
	{
		if (doc == null)
			return null;
			
		NodeList nodes = doc.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node row = nodes.item(i);
			NodeList children = row.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				String cname = child.getNodeName();
				if (cname.equals(attrName)) {
					String val = getText(child);
					if ((val != null) && val.equals(attrValue))
						return row;
				}
			}
		}
		
		return null;
	}

	/**
 	 */
	synchronized public String mountCassette(int cassetteID, int beamlineID)
	{
		try {
				
		String cidStr = String.valueOf(cassetteID);
		String bidStr = String.valueOf(beamlineID);
		
		String owner = (String)cassetteLookup.get(String.valueOf(cassetteID));
		if ((owner == null) || (owner.length() == 0))
			return createErrorString("mountCassette", "Could not find cassette id " + cassetteID + " in lookup table");
							
		int userId = getUserID(owner);
		
		if (userId < 0)
			return createErrorString("mountCassette", "Invalid owner for cassette id " + cassetteID);
		
		// Load <user>/cassettes.xml
		String cassettesFile = cassetteDir + "/" + owner + "/cassettes.xml";
		Document cassettes  = dBuilder.parse(cassettesFile);
		
		// Find cassette node
		Node cassetteNode = findNodeByAttr(cassettes, "CassetteID", cidStr);
		
		if (cassetteNode == null)
			return createErrorString("mountCassette", "Cassette id " + cassetteID
						+ " for user " + owner
						+ " does not exist");
						
		Node oldBeamlineNode = findNodeByAttr(beamlines, "CassetteID", cidStr);
		int oldBid = 0;
		if (oldBeamlineNode != null) {
			oldBid = Integer.parseInt(getNodeParam(oldBeamlineNode, "BeamLineID"));
		}
					
		// Already mounted on this beamline/position
		if (oldBid == beamlineID)
			return "OK";
								
		
		// If already mounted then unmount first
		if (oldBeamlineNode != null) {
			setNodeParam(oldBeamlineNode, "CassetteID", "null");
			setNodeParam(oldBeamlineNode, "Pin", "null");
			setNodeParam(oldBeamlineNode, "FileID", "null");
			setNodeParam(oldBeamlineNode, "FileName", "null");
			setNodeParam(oldBeamlineNode, "UploadFileName", "null");
			setNodeParam(oldBeamlineNode, "UploadTime", "null");
			setNodeParam(oldBeamlineNode, "UserName", "null");
			setNodeParam(oldBeamlineNode, "UserID", "null");
			
			saveBeamlines();
			
			setNodeParam(cassetteNode, "BeamLineID", "0");
			setNodeParam(cassetteNode, "BeamLineName", "null");
			setNodeParam(cassetteNode, "BeamLinePosition", "null");
			
			saveXmlDocument(cassettesFile, cassettes);
		}
			
		// Unmount only	
		if (beamlineID == 0)
			return "OK";

		// Mount it: need to update beamlines.xml and <user>/cassettes.xml
		Node newBeamlineNode = findNodeByAttr(beamlines, "BeamLineID", bidStr);
		
		// Set beamline attributes
		if (newBeamlineNode != null) {
		
			// Get cassette attributes
			String cassetteId = getNodeParam(cassetteNode, "CassetteID");
			String pin =  getNodeParam(cassetteNode, "Pin");
			String fileId = getNodeParam(cassetteNode, "FileID");
			String fileName = getNodeParam(cassetteNode, "FileName");
			String uploadFileName = getNodeParam(cassetteNode, "UploadFileName");
			String uploadTime = getNodeParam(cassetteNode, "UploadTime");

			setNodeParam(newBeamlineNode, "CassetteID", cassetteId);
			setNodeParam(newBeamlineNode, "Pin", pin);
			setNodeParam(newBeamlineNode, "FileID", fileId);
			setNodeParam(newBeamlineNode, "FileName", fileName);
			setNodeParam(newBeamlineNode, "UploadFileName", uploadFileName);
			setNodeParam(newBeamlineNode, "UploadTime", uploadTime);
			setNodeParam(newBeamlineNode, "UserName", owner);
			setNodeParam(newBeamlineNode, "UserID", String.valueOf(userId));
			
			saveBeamlines();
			
			String bid = getNodeParam(newBeamlineNode, "BeamLineID");
			String bname = getNodeParam(newBeamlineNode, "BeamLineName");
			String bposition = getNodeParam(newBeamlineNode, "BeamLinePosition");

			setNodeParam(cassetteNode, "BeamLineID", bid);
			setNodeParam(cassetteNode, "BeamLineName", bname);
			setNodeParam(cassetteNode, "BeamLinePosition", bposition);
			
			saveXmlDocument(cassettesFile, cassettes);
		}		

		return "OK";
		
		} catch (Exception e) {
			return createErrorString("", e.getMessage());
		}
	}
	
	/**
 	 */
	synchronized public String addCassetteFile(int cid, String filePrefix, String usrFileName)
	{	
		try {
			
		String cassetteId = String.valueOf(cid);
		
		String owner = (String)cassetteLookup.get(cassetteId);
		
		if ((owner == null) || (owner.length() == 0)) 
			return createErrorString("addCassette", "Invalid owner for cassette id " + cassetteId);
		
		
		//Use the DocumentBuilder to parse the XML input.
		String fileName = cassetteDir + owner + "/cassettes.xml";
		Document cassettes  = dBuilder.parse(fileName);
		
		Node found = null;
		NodeList nodes = cassettes.getElementsByTagName("Row");
		for (int i = 0; (found == null) &&  (i < nodes.getLength()); ++i) {
			Node row = nodes.item(i);
			found = null;
			NodeList children = row.getChildNodes();
			// Find the entry
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if ((child instanceof Element) &&
				    child.getNodeName().equals("CassetteID") && 
				    cassetteId.equals(getText(child))) {
						found = row;
						break;
				}
			}
			
		}

		// Cassette must have been added by addCassette method before
		// addCassetteFIle can be called.
		if (found == null)
			return createErrorString("addCassetteFile", 
						"cassette id " + cassetteId + " does not exist");
				
		// Set the other parameters for this cassette
		NodeList children = found.getChildNodes();
		String fileId = "001";
		String baseName = filePrefix + cassetteId + "_" + fileId;

		SimpleDateFormat ff = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		StringBuffer buf = new StringBuffer();

		setNodeParam(found, "FileName", baseName);
		setNodeParam(found, "FileID", fileId);
		setNodeParam(found, "UploadFileName", usrFileName);
		setNodeParam(found, "UploadTime", ff.format(new java.util.Date()));
		setNodeParam(found, "BeamLineID", "0");
		setNodeParam(found, "BeamLineName", "null");
		setNodeParam(found, "BeamLinePosition", "null");
		
		// Save <users>/cassettes.xml file
		saveXmlDocument(fileName, cassettes);
		
		return baseName;
		
		} catch (Exception e) {
			return createErrorString("addCassette", e.getMessage());
		}
		
	}
	
	/**
 	 */
/*	public String getParameterValue(String name)
	{
		return "<Error>Not implemented</Error>";
	}*/

	/**
	 * <Row>
	 	<BeamLineID>0</BeamLineID>
		<BeamLineName>None</BeamLineName>
		<BeamLinePosition>null</BeamLinePosition><UserID>null</UserID>
		<UserName>null</UserName>
		<CassetteID>null</CassetteID>
		<Pin>null</Pin>
		<FileID>null</FileID>
		<FileName>null</FileName>
		<UploadFileName>null</UploadFileName>
		<UploadTime>null</UploadTime>
	   </Row>

 	 */
	synchronized public void addBeamline(String name)
		throws Exception
	{
		// Add new beamline to xml
		NodeList nodes = beamlines.getElementsByTagName("BeamLineName");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			if (node instanceof Element) {
				String text = getText(node);
				if ((text != null) && text.equals(name))
					throw new Exception("Beamline " + name + " already exists");
			}
		}
		addBeamlineElement(name);
		
		// Save beamlines.xml file
		saveBeamlines();
	}
	
	synchronized public void removeBeamline(String name)
		throws Exception
	{
		// Add new beamline to xml
		boolean done = false;
		while (!done) {
			NodeList nodes = beamlines.getElementsByTagName("BeamLineName");
			done = true;
			for (int i = 0; i < nodes.getLength(); ++i) {
				Node node = nodes.item(i);
				if (node instanceof Element) {
					String text = getText(node);
					if ((text != null) && text.equals(name)) {
						Node parent = node.getParentNode();
						Node sibling= parent.getNextSibling();
						beamlines.getDocumentElement().removeChild(parent);
						// Remove empty line
						if (sibling instanceof Text)
							beamlines.getDocumentElement().removeChild(sibling);
						done = false;
						break;
					}
				}
			}
		}
		
		// Save beamlines.xml file
		saveBeamlines();
	}

	/**
	 */
	private int newBeamlineId()
	{
		++lastBeamlineId;
		return lastBeamlineId;
	}
	
	/**
	 */
	private void addBeamlineElement(String name)
		throws Exception
	{
		for (int p = 0; p < beamlinePositions.length; ++ p) {
		
		    Element node = beamlines.createElement("Row");
		    for (int i = 0; i < beamlineAttr.length; ++i) {
			Element child = beamlines.createElement(beamlineAttr[i]);
			String str = "null";
			if (beamlineAttr[i].equals("BeamLineID")) {
				str = String.valueOf(newBeamlineId());
			} else if (beamlineAttr[i].equals("BeamLinePosition")) {
				str = beamlinePositions[p];
			} else if (beamlineAttr[i].equals("BeamLineName")) {
				str = name;
			}
			Text text = beamlines.createTextNode(str);
			child.appendChild(text);
			node.appendChild(child);			
		   }
		    beamlines.getDocumentElement().appendChild(node);
		    beamlines.getDocumentElement().appendChild(beamlines.createTextNode("\n"));
		    
		}
		
	}	

	public String getBeamlineList()
	{
		Vector bb = getBeamlines();
		StringBuffer data = new StringBuffer();
		data.append("<Beamlines>");
	  	data.append("\r\n");
		BeamlineInfo bi = null;
		for (int i = 0; i < bb.size(); ++i) {
			bi = (BeamlineInfo)bb.elementAt(i);
			data.append("<BeamLine bid=\""+ bi.getId() +"\">");
			data.append(bi.getBeamlineName() +" "+ bi.getCassettePosition());
			data.append("</Beamline>");
		}
	  	data.append("</Beamlines>");
	 	data.append("\r\n");
		
		return data.toString();
	}
	/**
	 * Used by CassetteInfo.jsp to construct dropdown menu 
	 * for beamline/position selection when assigning a cassette
	 * to beamline.
 	 */
	public Vector getBeamlines()
	{
		
		Vector ret = new Vector();
		
		try {
		
		String bidStr = "";
		String bname = "";
		String bposition = "";
		NodeList nodes = beamlines.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			bidStr = "";
			bname = "";
			bposition = "";
			NodeList children = node.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				if (child.getNodeName().equals("BeamLineID"))
					bidStr = getText(child);
				else if (child.getNodeName().equals("BeamLineName"))
					bname = getText(child);
				else if (child.getNodeName().equals("BeamLinePosition"))
					bposition = getText(child);
			}
			int bid = Integer.parseInt(bidStr);
			if ((bposition == null) || bposition.equals("null") || (bposition.length() == 0))
				ret.add(new BeamlineInfo(bid, bname));
			else
				ret.add(new BeamlineInfo(bid, bname + " " + bposition));
		}
		
		} catch (Exception e) {
			System.out.println("getBeamlines failed");
			e.printStackTrace();
		}
		
		return ret;
	}

	/**
 	 */
	public String getCassetteIdAtBeamline(String beamlineName, String position)
		throws Exception
	{
		String cassetteId = "";
		String bname = "";
		String bposition = "";
		NodeList nodes = beamlines.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			cassetteId = "";
			bname = "";
			bposition = "";
			NodeList children = node.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				if (child.getNodeName().equals("CassetteID"))
					cassetteId = getText(child);
				else if (child.getNodeName().equals("BeamLineName"))
					bname = getText(child);
				else if (child.getNodeName().equals("BeamLinePosition"))
					bposition = getText(child);
			}
			if (bname.equals(beamlineName) && bposition.equals(position))
				return cassetteId;
		}
		
		return "";
	}

	/**
 	 */
	public Hashtable getAssignedBeamline(int cid)
		throws Exception
	{
		String cassetteId = String.valueOf(cid);
		String id = "";
		String bid = "";
		String bname = "";
		String bposition = "";
		Hashtable ret = new Hashtable();
		NodeList nodes = beamlines.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			id = "";
			bname = "";
			bposition = "";
			NodeList children = node.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				if (child.getNodeName().equals("CassetteID"))
					id = getText(child);
				else if (child.getNodeName().equals("BeamLineID"))
					bid = getText(child);
				else if (child.getNodeName().equals("BeamLineName"))
					bname = getText(child);
				else if (child.getNodeName().equals("BeamLinePosition"))
					bposition = getText(child);
			}
			if (id.equals(cassetteId)) {
				ret.put("BEAMLINE_ID", bid);
				ret.put("BEAMLINE_NAME", bname);
				ret.put("BEAMLINE_POSITION", bposition);
				return ret;
			}
		}
		
		return ret;
	}

	/**
 	 */
	public Hashtable getBeamlineInfo(int bid)
		throws Exception
	{
		String bidStr = String.valueOf(bid);
		String id = "";
		String bname = "";
		String bposition = "";
		Hashtable ret = new Hashtable();
		NodeList nodes = beamlines.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			id = "";
			bname = "";
			bposition = "";
			NodeList children = node.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				if (child.getNodeName().equals("BeamLineID"))
					id = getText(child);
				else if (child.getNodeName().equals("BeamLineName"))
					bname = getText(child);
				else if (child.getNodeName().equals("BeamLinePosition"))
					bposition = getText(child);
			}
			if (id.equals(bidStr)) {
				ret.put("BEAMLINE_NAME", bname);
				ret.put("BEAMLINE_POSITION", bposition);
				return ret;
			}
		}
		
		return ret;
		
	}

	/**
 	 */
	public Hashtable getCassetteInfoAtBeamline(String beamlineName, String position)
		throws Exception
	{
		String bname = "";
		String bposition = "";
		Hashtable ret = new Hashtable();
		NodeList nodes = beamlines.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			bname = "";
			bposition = "";
			ret.clear();
			NodeList children = node.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				String cname = child.getNodeName();
				String cvalue = getText(child);
				if (cvalue == null)
					cvalue = "";
				if (cname.equals("BeamLineName"))
					bname = cvalue;
				else if (cname.equals("BeamLinePosition"))
					bposition = cvalue;
				ret.put(cname, cvalue);
			}
			if (bname.equals(beamlineName) && bposition.equals(position))
				return ret;
		}
		
		ret.clear();
		return ret;
	}

	/**
 	 */
	public String getCassettesAtBeamline(String beamlineName)
	{
		try {
		
		Document doc = beamlines;
		if (beamlineName != null) {
			doc = dBuilder.newDocument();
			Node root = doc.createElement("CassettesAtBeamline");
			doc.appendChild(root);
			NodeList nodes = beamlines.getElementsByTagName("Row");
			for (int i = 0; i < nodes.getLength(); ++i) {
				Node node = nodes.item(i);
				String bname = getNodeParam(node, "BeamLineName");
				if (bname.equals(beamlineName)) {
					// Copy nodes from beamlines document
					Node copied = doc.importNode(node, true);
					// Copied node has no parent yet in this document.
					// Add it as a child of the document element.
					root.appendChild(copied);
					root.appendChild(doc.createTextNode("\n"));
				}
			}
		}
		
		StringWriter writer = new StringWriter();
		saveXmlDocument(writer, doc);
		return writer.toString();

		} catch (Exception e) {
			return createErrorString("getCassettesAtBeamline", e.getMessage());
		}
	}

	/**
 	 */
	public String getBeamlineID(String beamlineName, String position)
		throws Exception
	{
		String bidStr = "";
		String bname = "";
		String bposition = "";
		NodeList nodes = beamlines.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			bidStr = "";
			bname = "";
			bposition = "";
			NodeList children = node.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				if (child.getNodeName().equals("BeamLineID"))
					bidStr = getText(child);
				else if (child.getNodeName().equals("BeamLineName"))
					bname = getText(child);
				else if (child.getNodeName().equals("BeamLinePosition"))
					bposition = getText(child);
			}
			if (bname.equals(beamlineName) && bposition.equals(position))
				return bidStr;
		}
		
		return "";
	}
	

	/**
 	 */
	public String getBeamlineName(int beamlineID)
	{
		String bidStr = String.valueOf(beamlineID);
		String id = "";
		String bname = "";
		NodeList nodes = beamlines.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			Node node = nodes.item(i);
			bname = "";
			id = "";
			NodeList children = node.getChildNodes();
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (!(child instanceof Element))
					continue;
				if (child.getNodeName().equals("BeamLineID"))
					id = getText(child);
				else if (child.getNodeName().equals("BeamLineName"))
					bname = getText(child);
			}
			if (id.equals(bidStr))
				return bname;
		}
		
		return "";
	}

	/**
 	 */
	public String getCassetteFileName(int cassetteID)
	{
		try {
		
		String cidStr = String.valueOf(cassetteID);
		String owner = (String)cassetteLookup.get(cidStr);
		
		if ((owner == null) || (owner.length() == 0))
			return createErrorString("getCassetteFileName", "Cannot find cassette id " 
						+ cidStr + " in lookup table"); 
		
		// Load <user>/cassettes.xml
		String cassettesFile = cassetteDir + "/" + owner + "/cassettes.xml";
		Document cassettes  = dBuilder.parse(cassettesFile);
		
		NodeList nodes = cassettes.getElementsByTagName("CassetteID");
		if ((nodes == null) || (nodes.getLength() == 0))
			return createErrorString("getCassetteFileName", "cassette id " 
					+ cassetteID + " does not exist for owner "
					+ owner);
				
		String ret = null;
		for (int i = 0; i  < nodes.getLength(); ++i) {
			Element el = (Element)nodes.item(i);
			String str = getText(el);
			if ((str != null) && str.equals(cidStr)) {
				Node parent = el.getParentNode();
				ret = getNodeParam(parent, "FileName");
				break;
			}
		}
		
		if (ret == null)
			return createErrorString("getCassetteFileName", "Cannot find cassette id " 
						+ cassetteID + " for owner " + owner);
						
		return ret;
		
		} catch (Exception e) {
			return createErrorString("getCassetteFileName", e.getMessage());
		}
		
	}

	/**
 	 */
/*	public String getCassetteOwner( int cassetteID)
	{
		return null;
	}*/

	/**
 	 */
	public String getCassetteFileList(int userID)
	{
		return getCassetteFileList(userID, null, null);
	}
	
	public String getCassetteFileList(int userID, String filterBy, String wildcard)
	{
		String uname = getUserName(userID);
		
		if (uname.indexOf("<Error>") > -1)
			return uname;
			
		return getCassetteFileList(uname, filterBy, wildcard);
	}

	/**
 	 */
	public String getCassetteFileList(String owner)
	{
		return getCassetteFileList(owner, null, null);
	}
	
	public String getCassetteFileList(String owner, String filterBy, String wildcard)
	{	
		if ((filterBy == null) || (filterBy.length() == 0)
			|| (wildcard == null) || (wildcard.length() == 0)
			|| (wildcard.equals("*")))
			return getCassetteFileListAll(owner);
			
		String udir = cassetteDir + "/" + owner;
		File dir = new File(udir);
		if (!dir.exists())
			return createErrorString("getCassetteFileList", "no cassette directory for owner " + owner);
	 	Pattern pattern = Pattern.compile(wildcard);
		// New document only contains the nodes that match the wildcard.
		Document newDoc = dBuilder.newDocument();
		Element newRoot = newDoc.createElement("CassetteFileList");
		try {
			FileInputStream stream = new FileInputStream(dir + "/cassettes.xml");
			Document doc = dBuilder.parse(stream);
			Element root = doc.getDocumentElement();
			stream.close();
			
			NodeList ll = root.getChildNodes();
			String key = "";
			for (int i = 0; i < ll.getLength(); ++i) {
				Node rowNode_ = ll.item(i);
				if (!(rowNode_ instanceof org.w3c.dom.Element))
					continue;
					
				Element rowNode = (Element)rowNode_;
				if (!rowNode.getTagName().equals("Row"))
					continue;
							
				NodeList nn = rowNode.getElementsByTagName(key);
				if ((nn == null) || (nn.getLength() == 0)) {
					return "<CassetteFileList></CassetteFileList>";
				}
				Node val = nn.item(0).getFirstChild();
				if ((val == null) || (!(val instanceof org.w3c.dom.Text)))
					continue;
				if (!pattern.matcher(val.getNodeValue()).matches())
					continue;
					
				// import Row node and its children
				Node copied = doc.importNode(rowNode, true);
				newRoot.appendChild(copied);
				newRoot.appendChild(doc.createTextNode("\n"));
			}
			
			
			StringWriter writer = new StringWriter();
			saveXmlDocument(writer, doc);
			String ret = writer.toString();
			writer.close();
			return ret;

		} catch (Exception e) {
			return createErrorString("getCassetteFileList",  e.getMessage());
		}
		
		
	}

        private String getCassetteFileListAll(String owner)
        {
                String udir = cassetteDir + "/" + owner;
                File dir = new File(udir);
                if (!dir.exists())
                        return createErrorString("getCassetteFileList", "no cassette directory for owner " + owner);
                StringBuffer ret = new StringBuffer();
                try {
                        FileReader reader = new FileReader(dir + "/cassettes.xml");
                        char buff[] = new char[1000];
                        int numRead = -1;
                        while ((numRead=reader.read(buff, 0, 1000)) > -1) {
                                ret.append(buff, 0, numRead);
                        }

                        return ret.toString();

                } catch (Exception e) {
                        return createErrorString("getCassetteFileList",  e.getMessage());
                }


        }
	
	private String parseErrorString(String xml)
	{
		int pos1 = xml.indexOf("<Error>");
		if (pos1 < 0)
			return xml;
			
		int pos2 = xml.indexOf("</Error>");
		if (pos2 < 0)
			return xml.substring(7);
			
		return xml.substring(7, pos2);
	}

	/**
 	 */
	public Vector getUserCassettes(int userID)
		throws Exception
	{		
		String uname = getUserName(userID);
		
		if (uname.indexOf("<Error>") > -1)
			throw new Exception(parseErrorString(uname));
		
		return getUserCassettes(uname);
	}
		
	public Vector getUserCassettes(String userID)
		throws Exception
	{
		return getUserCassettes(userID, null, null);
	}
	
	/**
	 */
	public Vector getUserCassettes(String uname, String filterBy, String wildcard)
		throws Exception
	{	
		Vector ret = new Vector();
					
		String udir = cassetteDir + "/" + uname;
		File dir = new File(udir);
		if (!dir.exists())
			throw new Exception("No cassette directory for user " + uname);
		//Use the DocumentBuilder to parse the XML input.
		Document cassettes  = dBuilder.parse(udir + "/cassettes.xml");
	 	Pattern pattern = null;
		if ((filterBy != null) && (filterBy.length() > 0)
			&& (wildcard != null) && (wildcard.length() > 0)
			&& !wildcard.equals("*")) {
			
			wildcard = wildcard.replace("*", ".*");
			pattern = Pattern.compile(wildcard);
		}
		
		NodeList nodes = cassettes.getElementsByTagName("Row");
		for (int i = 0; i < nodes.getLength(); ++i) {
			
			Node row = nodes.item(i);
			NodeList children = row.getChildNodes();
			String cassetteId = "";
			String pin = "";
			String fileId = "";
			String fileName = "";
			String uploadTime = "";
			String uploadFileName = "";
			String cname = "";
			String foundStr = "";
			for (int c = 0; c < children.getLength(); ++c) {
				Node child = children.item(c);
				if (child instanceof Element) {
					cname = child.getNodeName();
					if (cname.equals("CassetteID"))
						cassetteId = getText(child);
					else if (cname.equals("Pin"))
						pin = getText(child);
					else if (cname.equals("FileID"))
						fileId = getText(child);
					else if (cname.equals("FileName"))
						fileName = getText(child);
					else if (cname.equals("UploadFileName"))
						uploadFileName = getText(child);
					else if (cname.equals("UploadTime"))
						uploadTime = getText(child);
						
					if ((foundStr.length() == 0) && (filterBy != null) && cname.equals(filterBy)) {
						foundStr = getText(child);
					}
				}
			}
			
			if ((filterBy != null) && (wildcard != null) && (pattern != null) && !pattern.matcher(foundStr).matches())
					continue;
								
			// check if sil is assigned to a beamline
			int cid = Integer.parseInt(cassetteId);
			int fid = Integer.parseInt(fileId);
			Hashtable binfo = getAssignedBeamline(cid);
			int bid = 0;
			String beamlineId = "";
			String beamlineName = "";
			String beamlinePosition = "";
			if (binfo.size() > 0) {
				beamlineId = (String)binfo.get("BEAMLINE_ID");
				if ((beamlineId != null) && (beamlineId.length() != 0))
					bid = Integer.parseInt(beamlineId);
				beamlineName = (String)binfo.get("BEAMLINE_NAME");
				if (beamlineName == null)
					beamlineName = "";
				beamlinePosition = (String)binfo.get("BEAMLINE_POSITION");
				if (beamlinePosition == null)
					beamlinePosition = "";
				
			}

			ret.add(new CassetteInfo(cid,
					pin,
					fid,
					fileName,
					uploadFileName,
					uploadTime,
					bid,
					beamlineName,
					beamlinePosition));
		}
		
		return ret;
		

	}


	/**
 	 */
	private String formatDateTime(Timestamp t1) 
	{
		String dt2;
		if (t1 != null) {
			dt2= t1.toString();
		int i= dt2.lastIndexOf('.');
			if (i > 5) {
				dt2= dt2.substring(0,i);
			}
		} else {
			dt2= "null";
		}
		return dt2;
	}
	
	/**
 	 */
	public String deleteUnusedCassetteFiles( String userName)
	{
		return null;
	}

	/**
 	 * Convenient method to create an xml error string
 	 */
	private String createErrorString(String method, String message)
	{
		return "<Error>" + method + ": " + message + "</Error>";
	}
}

