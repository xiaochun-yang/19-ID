package sil.beans;

import java.io.*;
import java.util.*;

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
import org.apache.xml.serializer.*;

import jxl.Workbook;
import jxl.WorkbookSettings;
import jxl.write.*;
import jxl.format.Font;
import jxl.format.Alignment;

import java.net.URL;


public class SilDataDomImp implements EntityResolver, SilData
{
	public static String commentField = "Comment";
	public static String systemWarningField = "SystemWarning";

	public static int FORMAT_TCL = 1;
	public static int FORMAT_XML = 2;

	/**
	 * DOM document holding sil data
	 */
	private Document doc = null;

	private int excelIndex = 0;

	/**
	 */
	private String xsltSil2TclLoad = "xsltSil2Tcl.xsl";
	private String xsltSil2TclUpdate = "xsltSil2TclUpdate.xsl";

	private Transformer loadSilTransformer = null;
	private Transformer updateSilTransformer = null;

	private String id = null;
	private String fileName = null;

	Properties silProp = new Properties();
	/**
	 */
	public SilDataDomImp()
		throws Exception
	{

		TransformerFactory tFactory = TransformerFactory.newInstance();

		// Read xslt file from template dir
		String xsltFileName = SilConfig.getInstance().get("templateDir") + xsltSil2TclLoad;
		StreamSource xslSource = new StreamSource(new FileReader(xsltFileName));
		loadSilTransformer = tFactory.newTransformer(xslSource);

		SilConfig silConfig = SilConfig.getInstance();
		xsltFileName = silConfig.get("templateDir") + xsltSil2TclUpdate;
		xslSource = new StreamSource(new FileReader(xsltFileName));
		updateSilTransformer = tFactory.newTransformer(xslSource);

		silProp.setProperty(OutputKeys.DOCTYPE_SYSTEM, silConfig.getSilDtd());
	}

	/**
	 * LOADER
	 */
	public void load(String xmlFileName)
		throws Exception
	{
		this.fileName = xmlFileName;

		//Instantiate a DocumentBuilderFactory.
		javax.xml.parsers.DocumentBuilderFactory dFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();

		//Use the DocumentBuilderFactory to create a DocumentBuilder.
		javax.xml.parsers.DocumentBuilder dBuilder = dFactory.newDocumentBuilder();
		dBuilder.setEntityResolver(this);

		//Use the DocumentBuilder to parse the XML input.
		doc = dBuilder.parse(xmlFileName);

		this.id = doc.getDocumentElement().getAttribute("name");
	}

	/**
	 */
	public String getId()
	{
		return this.id;
	}

	/**
	 */
	public int getEventId()
	{
		try {

			String str =  doc.getDocumentElement().getAttribute("eventId");
			if (str != null)
				return Integer.parseInt(str);

		} catch (NumberFormatException e) {
		}

		return 0;
	}

	/**
	 */
	public String getKey()
	{
		return "";
	}
	
	/**
	 */
	public void setKey(String s)
	{
	}

	/**
	 */
	public boolean isLocked()
	{
		Element silElement = doc.getDocumentElement();
		if (silElement.getAttribute("lock").equals("true"))
			return true;

		return false;
	}

	public String getVersion()
	{
		Element silElement = doc.getDocumentElement();
		return silElement.getAttribute("version");
	}

	/**
	 * SETTER
	 */
	public void setLocked(boolean l)
	{
		Element silElement = doc.getDocumentElement();
		if (l)
			silElement.setAttribute("lock", "true");
		else
			silElement.setAttribute("lock", "false");

	}


	/**
	 */
	public void setEventId(int eId)
	{
		doc.getDocumentElement().setAttribute("eventId", String.valueOf(eId));
	}

	/**
	 */
	public int addCrystal(Crystal newCrystal)
		throws Exception
	{
		// Not implemented
		throw new Exception("Method not implemented");
//		return 0;
	}

	/**
	 */
	public int addCrystal(Hashtable fields)
		throws Exception
	{
		// Not implemented
		throw new Exception("Method not implemented");
//		return 0;
	}
	
	/**
	 */
	public void setCrystalImage(int row, String imageGroup, String imageName, Hashtable fields)
		throws Exception
	{

		if ((imageGroup == null) || (imageGroup.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid group");
		if ((imageName == null) || (imageName.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid name");

		if ((fields == null) || (fields.size() == 0))
			throw new Exception("Error in setCrystalImage: null field");

		// Find or create image node
		Element imageNode = getCrystalImageElement(row, imageGroup, imageName);

		if (imageNode == null)
			throw new Exception("Error in setCrystalImage: image " + imageName
									+ " in group " + imageGroup
									+ " does not exist");

		// Set the field that matches the attribute of image node
		Enumeration keys = fields.keys();
		while (keys.hasMoreElements()) {
			String key = (String)keys.nextElement();
			String value = (String)fields.get(key);
			// cannot change fieldName or group attributes
			if (!key.equals("name") && imageNode.hasAttribute(key)) {
				imageNode.setAttribute(key, value);
			}
		}

	}

	/**
	 */
	public void addCrystalImage(int row, String imageGroup, String imageName, Hashtable fields)
		throws Exception
	{
		if ((imageGroup == null) || (imageGroup.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid group");

		if ((imageName == null) || (imageName.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid name");

		if ((fields == null) || (fields.size() == 0))
			throw new Exception("Error in setCrystalImage: null field");

		String imageDir = (String)fields.get("dir");

		if ((imageDir == null) || (imageDir.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid dir");

		// Find image node
		Element imageNode = getCrystalImageElement(row, imageGroup, imageName);

		if (imageNode != null)
			throw new Exception("Error in addCrystalImage: image " + imageName
									+ " in group " + imageGroup
									+ " already exists");


		// Create a new Image element
		// Get Images element
		imageNode = createImageElement(row, imageGroup, imageDir, imageName);

		// Set the field that matches the attribute of image node
		Enumeration keys = fields.keys();
		while (keys.hasMoreElements()) {
			String key = (String)keys.nextElement();
			String value = (String)fields.get(key);
			if (imageNode.hasAttribute(key)) {
				imageNode.setAttribute(key, value);
			}
		}

	}

	/**
	 */
	public boolean hasCrystalImage(int row, String groupName, String imgName)
		throws Exception
	{
		// Find image node
		Element imageNode = getCrystalImageElement(row, groupName, imgName);

		return (imageNode != null);
	}

	/**
	 */
	public void clearCrystalImages(int row, int group)
		throws Exception
	{

		// Get Images element
		Element images = getImagesElement(row);

		Node child = images.getFirstChild();
		int count = 0;
		while (child != null) {
			try {
				if (child instanceof Element) {
					String groupStr = ((Element)child).getAttribute("name");
					if (groupStr != null) {
						int imgGroup = Integer.parseInt(groupStr);
						Node toDelete = child;
						child = child.getNextSibling();
						if (imgGroup == group) {
							images.removeChild(toDelete);
						}
					}
				}

			} catch (NumberFormatException e) {
				// Ignore
			}

			++count;
			if (count > 50) {
				SilLogger.error("Error in clearCrystalImages1: stuck in infinite loop");
				throw new Exception("Error in clearCrystalImages1: stuck in infinite loop");
			}

		}

	}

	/**
	 */
	public void clearCrystalImages(int row)
		throws Exception
	{

		// Get Images element
		Element images = getImagesElement(row);

		// Removing all groups
		Node child = images.getFirstChild();
		int count = 0;
		while (child != null) {
			if (child instanceof Element) {
				String groupStr = ((Element)child).getAttribute("name");
				if (groupStr != null) {
					int imgGroup = Integer.parseInt(groupStr);
					Node toDelete = child;
					child = child.getNextSibling();
					images.removeChild(toDelete);
				}
			}

			++count;
			if (count > 50) {
				SilLogger.error("Error in clearCrystalImages2: stuck in infinite loop");
				throw new Exception("Error in clearCrystalImages2: stuck in infinite loop");
			}

		}

	}


	/**
	 * Set crystal field. Identify the crystal by using row number.
	 */
	public void setCrystal(int row, String name, String value)
		throws Exception
	{

        	Element crystal = getCrystalElement(row);
		setCrystal(crystal, name, value);

	}

	public void setCrystal(Crystal c)
		throws Exception
	{
	}

	public void clearCrystal(int row, String name)
		throws Exception
	{

        	Element crystal = getCrystalElement(row);
		setCrystal(crystal, name, "");

	}


	/**
	 * Sets fields of an existing crystal.
	 * Throws an exception if the crystal does not exist.
	 */
	public void setCrystal(int row, Hashtable fields)
		throws Exception
	{

        Element crystal = getCrystalElement(row);

		Enumeration keys = fields.keys();
		for (; keys.hasMoreElements() ;) {
			String name = (String)keys.nextElement();
			setCrystal(crystal, name, (String)fields.get(name));
		}

	}

	/**
	 * Set attribute of all crystals
	 */
	public void selectCrystals(String values)
		throws Exception
	{
		String attrName = "selected";

		NodeList crystals = getCrystalNodes();
       // is there anything to do?
        if ((crystals == null) || (crystals.getLength() == 0))
        	return;

		int crystalCount = crystals.getLength();
		StringTokenizer tok = null;
		boolean allOn = false;
		boolean allOff = false;
		if (values.equals("all"))
			allOn = true;
		else if (values.equals("none"))
			allOff = true;
		else
        	tok = new StringTokenizer(values, " +&\t\n\r");


		String val = "";
		for (int i = 0; i < crystalCount; i++) {
			Element crystal = (Element)crystals.item(i);
			if (allOn) {
				crystal.setAttribute(attrName, "1");
			} else if (allOff) {
				crystal.setAttribute(attrName, "0");
			} else {
				if ((tok == null) || !tok.hasMoreTokens())
					break;
				val = tok.nextToken();
				if (val.equals("1"))
					crystal.setAttribute(attrName, "1");
				else
					crystal.setAttribute(attrName, "0");;
			}
		}
	}
	
	/**
	 */
	public int getCrystalRow(String fieldName, String fieldValue)
	{
		return -1;
	}


	/**
	 * OUTPUT
	 */
	/**
	 * Return the whole sil
	 */
	public void toTclString(StringBuffer strBuf)
		throws Exception
	{
		if (strBuf == null)
			return;

		strBuf.append(crystalNodeToTclString(doc.getDocumentElement(), loadSilTransformer));

	}

	/**
	 * Return some crystals in the sil
	 */
	public void toTclString(StringBuffer strBuf, Object[] rows)
		throws Exception
	{
		if (strBuf == null)
			return;

		strBuf.append("{ ");
		strBuf.append("{" + String.valueOf(getId()) + "}");
		strBuf.append(" {" + String.valueOf(getEventId()) + "}");
		strBuf.append(" {update} ");

		if (rows != null) {

			// Add crystal elements in the new document
			for (int i = 0; i < rows.length; ++i) {
				Element element = getCrystalElement(((Integer)rows[i]).intValue());
				if (element != null) {
					strBuf.append(crystalNodeToTclString(element, updateSilTransformer));
				}

			}
		}

		strBuf.append("}");

	}

	/**
	 * Return some crystals in the sil
	 */
	public void toXmlString(StringBuffer strBuf, Object[] rows)
		throws Exception
	{
		throw new Exception("Method not implemented in SilDataDomImp");

	}

	public void toXmlString(StringBuffer strBuf)
		throws Exception
	{
		if (strBuf == null)
			return;

		try
		{
			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer();
			transformer.setOutputProperties(silProp);
			String systemId = SilConfig.getInstance().getSilDtdUrl();
			DOMSource source = new DOMSource(doc.getDocumentElement(), systemId);
			StringWriter writer = new StringWriter();
			StreamResult result = new StreamResult(writer);
			transformer.transform( source, result);

			strBuf.append(writer.getBuffer());

		} catch (Exception e) {
			throw new Exception("Failed to save sil because " + e.getMessage());
		}
	}

	public void toXmlString(Writer writer)
		throws Exception
	{
		if (writer == null)
			return;

		try
		{
			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer();
			transformer.setOutputProperties(silProp);
			String systemId = SilConfig.getInstance().getSilDtdUrl();
			DOMSource source = new DOMSource(doc.getDocumentElement(), systemId);
			StreamResult result = new StreamResult(writer);
			transformer.transform( source, result);

		} catch (Exception e) {
			throw new Exception("Failed to save sil because " + e.getMessage());
		}
	}


	/**
	 * Fill Excel spread sheet with sil data
	 * collapse level to one flat level per crystal.
	 * Data from all images are compressed into one cell.
	 */
	public void toExcel(WritableSheet sheet)
		throws Exception
	{
//		try {

		WritableFont font = new WritableFont(WritableFont.ARIAL);
	    font.setBoldStyle(WritableFont.BOLD);
	    WritableCellFormat headerFormat = new WritableCellFormat(font);
	    headerFormat.setWrap(true);
	    headerFormat.setAlignment(Alignment.CENTRE);

	    NodeList crystals = getCrystalNodes();

	    if ((crystals == null) || (crystals.getLength() == 0))
	    	throw new Exception("No crystal in sil " + getId());

	    // Get the column headers
	    // and put them in the first row of the spreadsheet.
	    Node crystal = crystals.item(0);
	    NodeList children = crystal.getChildNodes();
	    Node child = null;
	    int col = 0;
	    for (int i = 0; i < children.getLength(); ++i) {
			child = children.item(i);
			if (child instanceof Element) {
				if (child.getNodeName().equals("Images")) {
					String suffix = "";
					for (int j = 1; j < 4; ++j) {
						suffix = String.valueOf(j);
						sheet.addCell(new Label(col, 0, "Image" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "Quality" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "SpotShape" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "Resolution" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "IceRings" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "DiffractionStrength" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "Score" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "numSpots" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "numOverloadSpots" + suffix, headerFormat)); ++col;
						sheet.addCell(new Label(col, 0, "integratedIntensity" + suffix, headerFormat)); ++col;
					}
				}
	    		sheet.addCell(new Label(col, 0, child.getNodeName(), headerFormat));
	    		++col;
			}
		}


	    WritableCellFormat cellFormat = new WritableCellFormat();
	    cellFormat.setWrap(true);

		// Now loop over crystals and fill the subsequent rows
		// in the spreadsheet
		Node grandChild = null;
		String childName = "";
		String textValue = "";
		for (int row = 0; row < crystals.getLength(); ++row) {
			col = 0;
			crystal = crystals.item(row);
			children = crystal.getChildNodes();
			for (int i = 0; i < children.getLength(); ++i) {
				child = children.item(i);
				if (!(child instanceof Element))
					continue;

				// Special treament for Images node
				childName = child.getNodeName();
				if (childName.equals("Images") && child.hasChildNodes()) {

					textValue = "";
					NodeList groupNodes = child.getChildNodes();
					if (groupNodes != null) {
						for (int k = 1; k < 4; ++k) {
							NodeList imgNodes = null;
							// find each group
							for (int kk = 0; kk < groupNodes.getLength(); ++kk) {
								grandChild = groupNodes.item(kk);
								if (!grandChild.getNodeName().equals("Group"))
									continue;
								if (((Element)grandChild).getAttribute("name").equals(String.valueOf(k))) {
									imgNodes = ((Element)grandChild).getElementsByTagName("Image");
									break;
								}
							}
							if (imgNodes != null) {
								for (int j = 0; j < imgNodes.getLength(); ++j) {
									grandChild = imgNodes.item(j);
									if (textValue.length() > 0)
										textValue += " ";
									// Save image path
									textValue += ((Element)grandChild).getAttribute("dir")
													+ File.separator
													+ ((Element)grandChild).getAttribute("name");
									// Save image scores as separate columns
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("dir")
													+ File.separator
													+ ((Element)grandChild).getAttribute("name"),
													cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("quality"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("spotShape"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("resolution"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("iceRings"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("diffractionStrength"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("score"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("numSpots"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("numOverloadSpots"), cellFormat); ++col;
									addCell(sheet, col, row+1, ((Element)grandChild).getAttribute("integratedIntensity"), cellFormat); ++col;

								}
							} else {
								// Save image scores as separate columns
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;
								addCell(sheet, col, row+1, "", cellFormat); ++col;

							}
						}
						// all image paths for this crystals
						sheet.addCell(new Label(col, row+1,textValue, cellFormat));

					}

				} else {	// Other nodes

					grandChild = child.getFirstChild();
					if ((grandChild != null) && (grandChild instanceof Text)) {
						textValue = (String)grandChild.getNodeValue();
						if (childName.indexOf("URL") > 0) {
							try {
								WritableHyperlink link = new WritableHyperlink(col, row+1,
										new URL(textValue));
								sheet.addHyperlink(link);
								link = null;
							} catch (Exception e) {
								SilLogger.error("Cannot create hyperlink for cell ("
													+ row+1 + "," + col
													+ ") for data=" + textValue
													+ ": " + e);
								sheet.addCell(new Label(col, row+1,textValue, cellFormat));
							}
						} else {
							sheet.addCell(new Label(col, row+1,textValue, cellFormat));
						}
					}

				}
				++col;
			}

		}

//		} catch (Exception e) {
//			SilLogger.error("Failed to fill workbook for sil " + getId() + ": " + e.getMessage(), e);
//		}

	}


	/**
	 * HELPER
	 */


	/**
	 * Set crystal field. Identify the crystal.
	 */
	private void setCrystal(Element crystal, String name, String value)
		throws Exception
	{
		// special tag
		if (name.equals("Selected")) {
			crystal.setAttribute("selected", value);
			return;
		}

		NodeList children = crystal.getElementsByTagName(name);
		// this child does not exist.
		// Create a new one
		if (children != null) {
			Element child = (Element)children.item(0);
			if (child == null) {
				return;
			}
			Text text = (Text)child.getFirstChild();
			// Create text node if it does not exist
			if (text == null) {
				text = doc.createTextNode(value);
				child.appendChild(text);
			} else {
				text.setNodeValue(value);
			}
		} else {
			SilLogger.info("in setCrystal: could not find field name = " + name);
		}

	}


	/**
	 * Returns all Crystal nodes of this sil
	 */
	private NodeList getCrystalNodes()
	{
		if (doc == null)
			return null;

		Element silElement = doc.getDocumentElement();

		return silElement.getElementsByTagName("Crystal");
	}

	/**
	 */
	private Element getCrystalImagesGroupElement(int row, String imageGroup, boolean create)
		throws Exception
	{
		Element images = getImagesElement(row);

		// Get all groups
		Element group = null;
		NodeList nodeList = images.getElementsByTagName("Group");
		if ((nodeList == null) && !create)
			return null;

		if (nodeList != null) {
			// Find the requested group
			String groupStr = String.valueOf(imageGroup);
			for (int i = 0; i < nodeList.getLength(); ++i) {
				group = (Element)nodeList.item(i);
				if (group.getAttribute("name").equals(groupStr))
					return group;
			}
		}

		if (!create)
			return null;

		// create it
		Element groupNode = doc.createElement("Group");
		groupNode.setAttribute("name", imageGroup);

		images.appendChild(groupNode);

		return groupNode;

	}

	/**
	 */
	private Element getCrystalImageElement(int row,
										String imageGroup,
										String imageName)
		throws Exception
	{

		Element group = getCrystalImagesGroupElement(row, imageGroup, false);

		if (group == null)
			return null;

		// Get all Image elements under the requested group
		NodeList nodeList = group.getElementsByTagName("Image");
		Element imageNode = null;
		if (nodeList != null) {
			for (int i = 0; i < nodeList.getLength(); ++i) {
				imageNode = (Element)nodeList.item(i);
				if (imageNode.getAttribute("name").equals(imageName)) {
					return imageNode;
				}
			}
		}

		return null;

	}

	/**
	 */
	private Element createImageElement(int row, String groupName, String dir, String imageName)
		throws Exception
	{

		Element group = getCrystalImagesGroupElement(row, groupName, true);

		if (group == null)
			throw new Exception("Error in createImageElement: failed to get or create Group node for row = "
								+ row + " group = " + groupName + " image  = " + imageName);

		if (imageName == null)
			throw new Exception("Error in createImageElement: null image name");
		Element imageNode = doc.createElement("Image");
		imageNode.setAttribute("dir", dir);
		imageNode.setAttribute("name", imageName);
		imageNode.setAttribute("jpeg", "");
		imageNode.setAttribute("small", "");
		imageNode.setAttribute("medium", "");
		imageNode.setAttribute("large", "");
		imageNode.setAttribute("quality", "");
		imageNode.setAttribute("spotShape", "");
		imageNode.setAttribute("resolution", "");
		imageNode.setAttribute("iceRings", "");
		imageNode.setAttribute("diffractionStrength", "");
		imageNode.setAttribute("score", "");
		imageNode.setAttribute("numSpots", "");
		imageNode.setAttribute("numOverloadSpots", "");
		imageNode.setAttribute("integratedIntensity", "");

		group.appendChild(imageNode);

		return imageNode;

	}

	/**
	 */
	private Element getImagesElement(int row)
		throws Exception
	{
		// Get Images element
        Element crystal = getCrystalElement(row);
		NodeList nodeList = crystal.getElementsByTagName("Images");
		Element images = (Element)nodeList.item(0);

		return images;
	}

	/**
	 * Returns crystal element whose attribute row equals the given row
	 * number. Throws an error if row is not found.
	 */
	private Element getCrystalElement(int row)
		throws Exception
	{
        // get elements that match
        NodeList crystals = getCrystalNodes();

        // is there anything to do?
        if ((crystals == null) || (crystals.getLength() == 0))
        	throw new Exception("Sil " + this.id + " contains no crystal");

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
	 */
	private void dump()
	{
		NodeList crystals = getCrystalNodes();

		String str = "";
		for (int i = 0; i < crystals.getLength(); i++) {
			Element crystal = (Element)crystals.item(i);
			str += "DUMP Crystal id=" + crystal.getAttribute("row");
			NodeList children = crystal.getElementsByTagName("Protein");
			str += " Protein=" + ((Text)((Element)children.item(0)).getFirstChild()).getNodeValue();
			SilLogger.info(str);
		}
	}


	/**
	 * EntityResolver method
	 */
	public InputSource resolveEntity(String publicId, String systemId)
	{
		SilConfig silConfig = SilConfig.getInstance();
		if (systemId.endsWith("sil.dtd")) {
			return new InputSource(silConfig.getSilDtdUrl());
		} else if (systemId.endsWith(silConfig.getSilDtd())) {
			return new InputSource(silConfig.getSilDtdUrl());
		}

		// use the default behaviour
		return null;
	}

	/**
	 */
	private int getNextExcelIndex()
	{
		++excelIndex;
		return excelIndex;
	}

	/**
	 */
	private String getNextExcelFileName()
	{
		String orgFileName = this.fileName;
		int index = getNextExcelIndex();
		String ext = "";
		if (index < 10)
			ext = "00";
		else if (index < 100)
			ext = "0";
		ext += String.valueOf(index);


		return orgFileName.substring(0, orgFileName.length()-4)
								+ "_" + ext + ".xls";
	}


	/**
	 */
	private void addCell(WritableSheet sheet, int col, int row,
						String value, WritableCellFormat format)
		throws Exception
	{
		if (value == null)
			value = "";
		sheet.addCell(new Label(col, row, value, format));
	}


	/**
	 * Transform xml Document to tcl string using xslt transformation
	 */
	private StringBuffer crystalNodeToTclString(Node node, Transformer transformer)
		throws Exception
	{

		DOMSource source = new DOMSource(node);
		StringWriter writer = new StringWriter();
		StreamResult result = new StreamResult(writer);
		transformer.transform( source, result);

		return writer.getBuffer();

	}
	public void clearAutoindexResults(int row)
		throws Exception
	{
		throw new Exception("clearAutoindexResults method not implemented");
	}

	public void clearSpotfinderResults(int row)
		throws Exception
	{
		throw new Exception("clearSpotfinderResults method not implemented");
	}
	
	public Crystal cloneCrystal(int row)
		throws Exception
	{
		return null;
	}

}

