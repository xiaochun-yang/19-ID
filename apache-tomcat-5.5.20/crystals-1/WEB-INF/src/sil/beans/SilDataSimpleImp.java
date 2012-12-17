package sil.beans;

import java.io.*;
import java.util.*;

import org.w3c.dom.*;
import org.xml.sax.*;
import javax.xml.transform.stream.*;
import javax.xml.parsers.*;

import jxl.Workbook;
import jxl.WorkbookSettings;
import jxl.write.*;
import jxl.format.Font;
import jxl.format.Alignment;

import java.net.URL;


/**************************************************
 *
 * SilData
 *
 **************************************************/
public class SilDataSimpleImp extends org.xml.sax.helpers.DefaultHandler implements SilData
{
	private String id = "";
	private int eventId = -1;
	private boolean locked = false;
	private String version = "1.0";
	private String key = "";

	private TreeMap crystals = new TreeMap();

	// Use by SAX parser
	private Crystal curCrystal = null;
	private ImageGroup curGroup = null;
	private String curCrystalField = null;
	
	private StringBuffer curFieldValue = new StringBuffer();

	/**
	 * Constructor
	 */
	public SilDataSimpleImp()
	{
	}

	/**
	 * LOADER
	 */
	public void load(String xmlFileName)
		throws Exception
	{
		File xmlFile = new File(xmlFileName);
		if (!xmlFile.exists())
			throw new FileNotFoundException();

		SAXParserFactory saxFactory = SAXParserFactory.newInstance();
		saxFactory.setValidating(false);
		SAXParser parser = saxFactory.newSAXParser();

		parser.parse(xmlFile, this);

		saxFactory = null;
		parser = null;

	}
	

	/**
	 */
	public String getKey()
	{
		return key;
	}
	
	/**
	 */
	public void setKey(String s)
	{
		if (s == null)
			return;
			
		key = s;
	}
	
	public String getId()
	{
		return id;
	}

	public int getEventId()
	{
		return eventId;
	}

	public boolean isLocked()
	{
		return locked;
	}

	public String getVersion()
	{
		return version;
	}

	public void setLocked(boolean l)
	{
		locked = l;
	}

	public void setEventId(int ev)
	{
		eventId = ev;
	}
	
	/**
	 * Search for a crystal by field.
 	 */
	synchronized private Crystal findCrystal(String fname, String fval)
	{
		Iterator keys = crystals.keySet().iterator();
		Crystal cc = null;
		String value = "";
		while (keys.hasNext()) {
			cc = (Crystal)crystals.get((Integer)keys.next());
			value = cc.getField(fname);
			if ((value != null) && value.equals(fval))
				return cc;
		}
		
		return null;
	}

	/**
	 */
	public int addCrystal(Crystal newCrystal)
		throws Exception
	{
		if (newCrystal == null)
			throw new Exception("Cannot add null crystal");
			
		// Expect some columns
		String newCrystalId = newCrystal.getField("CrystalID");
		String newPort = newCrystal.getField("Port");

		if (newCrystalId == null)
			throw new Exception("Cannot add crystal because CrystalID is null");
		if (newCrystalId.length() == 0)
			throw new Exception("Cannot add crystal because CrystalID string is empty");
		if (newPort == null)
			throw new Exception("Cannot add crystal because Port is null");
		if (newPort.length() == 0)
			throw new Exception("Cannot add crystal because Port string is empty");

		int row = 0;
		
		if (crystals.size() > 0) {
			// Set row number
			Integer lastRow = (Integer)crystals.lastKey();
			row = lastRow.intValue() + 1;
		}
		
		newCrystal.setRow(row);
		
		// Add it to the tree map
		crystals.put(new Integer(row), newCrystal);
		
		return row;
	}			

	/**
	 * Add a new row. Make sure that CrystalID and Port are unique within this sil.
	 */
	public int addCrystal(Hashtable params)
		throws Exception
	{			
		int row = 0;
		int excelRow = 0;	

		String newCrystalId = (String)params.get("CrystalID");
		String newPort = (String)params.get("Port");
		if (newCrystalId == null)
			throw new Exception("Cannot add crystal because CrystalID is null");
		if (newCrystalId.length() == 0)
			throw new Exception("Cannot add crystal because CrystalID string is empty");
		if (newPort == null)
			throw new Exception("Cannot add crystal because Port is null");
		if (newPort.length() == 0)
			throw new Exception("Cannot add crystal because Port string is empty");

		if (crystals.size() > 0) {
		
			Crystal existing = findCrystal("CrystalID", newCrystalId);
			if (existing != null)
				throw new Exception("Cannot add crystal to sil " + id + " because CrystalID " + newCrystalId + " already exists");
			existing = findCrystal("Port", newPort);
			if (existing != null)
				throw new Exception("Cannot add crystal to sil " + id + " because Port " + newPort + " already exists");
		
		
			Integer lastRow = (Integer)crystals.lastKey();
			row = lastRow.intValue() + 1;
			CrystalSimpleImp lastCrystal = (CrystalSimpleImp)crystals.get(lastRow);
			excelRow = lastCrystal.excelRow + 1;
		}
		
		boolean selected = false;
		
		Crystal newCrystal = new CrystalSimpleImp(row, excelRow, selected);
		Enumeration keys = params.keys();
		String n, val;
		while (keys.hasMoreElements()) {
			n = (String)keys.nextElement();
			val = (String)params.get(n);
			if (n.equals("row"))
				continue;
			else if (n.equals("ContainerID") && (val == null))
				val = "unknown";
			
			newCrystal.setField(n, val);
			
		}
		crystals.put(new Integer(row), newCrystal);
		
		return row;

	}

	public void setCrystalImage(int row, String groupName, String imgName, Hashtable params)
		throws Exception
	{
		Crystal crystal = getCrystal(row);

		if (crystal == null)
			return;

		crystal.setImage(groupName, imgName, params);

		crystal = null;
	}

	public void addCrystalImage(int row, String groupName, String imgName, Hashtable params)
		throws Exception
	{
		Crystal crystal = getCrystal(row);

		if (crystal == null)
			return;

		crystal.addImage(groupName, imgName, params);

		crystal = null;
	}

	public boolean hasCrystalImage(int row, String groupName, String imgName)
		throws Exception
	{
		Crystal crystal = getCrystal(row);

		if (crystal == null)
			return false;

		return crystal.hasImage(groupName, imgName);

	}
	
	public void clearCrystalImages(int row, int group)
		throws Exception
	{
		Crystal crystal = getCrystal(row);

		if (crystal == null)
			return;

		crystal.clearImages(String.valueOf(group));

	}

	public void clearCrystalImages(int row)
		throws Exception
	{
		if (row > -1) {
			Crystal crystal = getCrystal(row);
			if (crystal != null)
				crystal.clearImages();
		} else {
			Iterator keys = crystals.keySet().iterator();
			Crystal cc = null;
			while (keys.hasNext()) {
				cc = (Crystal)crystals.get((Integer)keys.next());
				cc.clearImages();
			}
		}		
	}

	public void clearSpotfinderResults(int row)
		throws Exception
	{
		if (row > -1) {
			Crystal crystal = getCrystal(row);
			if (crystal != null)
				crystal.clearSpotfinderResults();
		} else {
			Iterator keys = crystals.keySet().iterator();
			Crystal cc = null;
			while (keys.hasNext()) {
				cc = (Crystal)crystals.get((Integer)keys.next());
				cc.clearSpotfinderResults();
			}
		}		
	}

	public void clearAutoindexResults(int row)
		throws Exception
	{
		if (row > -1) {
			Crystal crystal = getCrystal(row);
			if (crystal != null)
				crystal.clearAutoindexResults();
		} else {
			Iterator keys = crystals.keySet().iterator();
			Crystal cc = null;
			while (keys.hasNext()) {
				cc = (Crystal)crystals.get((Integer)keys.next());
				cc.clearAutoindexResults();
			}
		}
		
	}

	public void clearCrystal(int row, String fieldName)
		throws Exception
	{
		Crystal crystal = getCrystal(row);

		if (crystal == null)
			return;

		if (fieldName.equals("selected") || fieldName.equals("Selected"))
			crystal.setSelected(false);

		crystal.clearField(fieldName);

	}

	public void setCrystal(int row, String fieldName, String fieldValue)
		throws Exception
	{
		Crystal crystal = getCrystal(row);

		if (crystal == null)
			return;

		if (fieldName.equals("selected") || fieldName.equals("Selected")) {
			if (fieldValue.equalsIgnoreCase("true") || fieldValue.equalsIgnoreCase("yes") || fieldValue.equals("1"))
				crystal.setSelected(true);
		}

		crystal.setField(fieldName, fieldValue);

	}

	public void setCrystal(int row, Hashtable params)
		throws Exception
	{
		Crystal crystal = getCrystal(row);

		if (crystal == null)
			return;

		crystal.setFields(params);

	}
	
	/**
	 */
	public void setCrystal(Crystal c)
		throws Exception
	{
		int row = c.getRow();
		if (row < 0)
			throw new Exception("Invalid crystal row");
						
		String cId = c.getField("CrystalID");
		String pId = c.getField("Port");
					
		if ((pId == null) || (pId.length() == 0))
			throw new Exception("Invalid crystal Port");
		// Make sure port is unique
		int existingRow = getCrystalRow("Port", pId);
		if ((existingRow > -1) && (existingRow != row))
			throw new Exception("Sil already has Port " + pId);
		
		// Make sure crystal id is unique
		existingRow = getCrystalRow("CrystalID", cId);
		if ((cId != null) && (cId.length() > 0) && (existingRow > -1) && (existingRow != row))
			throw new Exception("Sil already has CrystalID " + cId);
										
		crystals.put(new Integer(row), c);
	}


	/**
	 * Set the "selected" attribute for all crystals
	 */
	public void selectCrystals(String values)
		throws Exception
	{
		StringTokenizer tok = null;
		boolean allOn = false;
		boolean allOff = false;
		String val = "";
		if (values.equals("all"))
			allOn = true;
		else if (values.equals("none"))
			allOff = true;
		else
        	tok = new StringTokenizer(values, " +&\t\n\r");

		Integer row = null;
		Crystal cc = null;
		Iterator keys = crystals.keySet().iterator();
		while (keys.hasNext()) {
			row = (Integer)keys.next();
			cc = (Crystal)crystals.get(row);
			if (allOn) {
				cc.setSelected(true);
			} else if (allOff) {
				cc.setSelected(false);
			} else {
				if ((tok == null) || !tok.hasMoreTokens())
					break;
				val = tok.nextToken();
				if (val.equalsIgnoreCase("true") || val.equalsIgnoreCase("yes") || val.equals("1"))
					cc.setSelected(true);
				else
					cc.setSelected(false);
			}
		}
	}
	
	/**
	 */
	public boolean hasCrystal(String fieldName, String fieldValue)
	{
		if ((fieldName == null) || (fieldValue == null))
			return false;
			
		Iterator keys = crystals.keySet().iterator();
		Crystal cc = null;
		String val = "";
		while (keys.hasNext()) {
			cc = (Crystal)crystals.get((Integer)keys.next());
			val = cc.getField(fieldName);
			if ((val != null) && val.equals(fieldValue))
				return true;
		}
		return false;
	}

	public int getCrystalRow(String fieldName, String fieldValue)
	{
		if ((fieldName == null) || (fieldValue == null))
			return -1;
			
		Iterator keys = crystals.keySet().iterator();
		Crystal cc = null;
		String val = "";
		while (keys.hasNext()) {
			cc = (Crystal)crystals.get((Integer)keys.next());
			val = cc.getField(fieldName);
			if ((val != null) && val.equals(fieldValue))
				return cc.getRow();
		}
		return -1;
	}

	public void toTclString(StringBuffer buf)
		throws Exception
	{
		buf.append("{\n");
		buf.append("  {" + id + "} {" + eventId + "} {load}\n");

		SilHeader.toTclString(buf);

		Iterator keys = crystals.keySet().iterator();
		Crystal cc = null;
		while (keys.hasNext()) {
			cc = (Crystal)crystals.get((Integer)keys.next());
			cc.toTclString(buf);
		}

		buf.append("}");

	}

	public void toTclString(StringBuffer buf, Object[] rows)
		throws Exception
	{
		buf.append("{\n");
		buf.append("  {" + id + "} {" + eventId + "} {update}\n");

		if (rows != null) {

			Integer iRow = null;
			Crystal cc = null;
			for (int i = 0; i < rows.length; ++i) {
				iRow = (Integer)rows[i];
				if (iRow == null)
					continue;
				cc = (Crystal)crystals.get(iRow);
				if (cc == null)
					continue;
				cc.toTclString(buf, true);
			}

		}
		buf.append("}");

	}

	public void toXmlString(StringBuffer buf)
		throws Exception
	{
		if (buf == null)
			return;

		buf.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
		buf.append("<!DOCTYPE Sil>\n");
		buf.append("<Sil eventId=\"" + eventId + "\" lock=\""
					+ locked + "\" name=\""
					+ id + "\" version=\"" + version + "\""
					+ " key=\"" + key + "\">\n");

		Iterator keys = crystals.keySet().iterator();
		Crystal cc = null;
		while (keys.hasNext()) {
			cc = (Crystal)crystals.get((Integer)keys.next());
			cc.toXmlString(buf);
		}
		buf.append("</Sil>");

	}

	public void toXmlString(StringBuffer buf, Object[] rows)
		throws Exception
	{
		buf.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
		buf.append("<!DOCTYPE Sil>\n");
		buf.append("<Sil eventId=\"" + eventId + "\" lock=\""
					+ locked + "\" name=\""
					+ id + "\" version=\"" + version + "\""
					+ " key=\"" + key + "\">\n");
		if (rows != null) {

			Integer iRow = null;
			Crystal cc = null;
			for (int i = 0; i < rows.length; ++i) {
				iRow = (Integer)rows[i];
				if (iRow == null)
					continue;
				cc = (Crystal)crystals.get(iRow);
				if (cc == null)
					continue;
				cc.toXmlString(buf);
			}

		}
		buf.append("</Sil>");
	}


	public void toXmlString(Writer writer)
		throws Exception
	{
		if (writer == null)
			return;

		writer.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
		writer.write("<!DOCTYPE Sil>\n");
		writer.write("<Sil eventId=\"" + eventId + "\" lock=\""
					+ locked + "\" name=\""
					+ id + "\" version=\"" + version + "\""
					+ " key=\"" + key + "\">\n");

		Iterator keys = crystals.keySet().iterator();
		Crystal cc = null;
		while (keys.hasNext()) {
			cc = (Crystal)crystals.get((Integer)keys.next());
			cc.toXmlString(writer);
		}
		writer.write("</Sil>");

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

	    if ((crystals == null) || (crystals.size() == 0))
	    	throw new Exception("No crystal in sil " + getId());


	    // Get the column headers
	    // and put them in the first row of the spreadsheet.
	    Vector headers = SilHeader.getHeaders();
	    int col = 0;
	    int row = 0;
	    String hh = "";
		String suffix = "";
		HeaderData dd = null;
	    for (int i = 0; i < headers.size(); ++i) {
			dd = (HeaderData)headers.elementAt(i);
			hh = (String)dd.name;
			if (hh.equals("Images")) {
				suffix = "";
				for (int j = 1; j < 4; ++j) {
					suffix = String.valueOf(j);
					sheet.addCell(new Label(col, row, "Image" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "Quality" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "SpotShape" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "Resolution" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "IceRings" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "DiffractionStrength" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "Score" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "numSpots" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "numOverloadSpots" + suffix, headerFormat)); ++col;
					sheet.addCell(new Label(col, row, "integratedIntensity" + suffix, headerFormat)); ++col;
				}
				sheet.addCell(new Label(col, row, hh, headerFormat)); ++col;
			} else if (hh.equals("Selected")) {
			} else {
				sheet.addCell(new Label(col, row, hh, headerFormat)); ++col;
			}
		}

		col = 0;

	    WritableCellFormat cellFormat = new WritableCellFormat();
	    cellFormat.setWrap(true);

	    Iterator keys = crystals.keySet().iterator();
	    CrystalSimpleImp cc = null;
	    String tt = "";
	    ImageData img = null;
	    while (keys.hasNext()) {
			cc = (CrystalSimpleImp)crystals.get((Integer)keys.next());
			col = 0;
			row = cc.getRow();
			for (int i = 0; i < headers.size(); ++i) {
				dd = (HeaderData)headers.elementAt(i);
				hh = (String)dd.name;
				if (hh.equals("Images")) {

					for (int k = 1; k < 4; ++k) {

						// Get last image of each group
						img = cc.getLastImage(String.valueOf(k));

						if (img != null) {
							if (tt.length() > 0)
								tt += " ";
							// Save image path
							tt += img.getField("dir")
											+ File.separator
											+ img.getName();
							// Save image scores as separate columns
							addCell(sheet, col, row+1, img.getField("dir")
											+ File.separator
											+ img.getName(),
											cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("quality"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("spotShape"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("resolution"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("iceRings"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("diffractionStrength"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("score"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("numSpots"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("numOverloadSpots"), cellFormat); ++col;
							addCell(sheet, col, row+1, img.getField("integratedIntensity"), cellFormat); ++col;

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
					sheet.addCell(new Label(col, row+1,tt, cellFormat)); ++col;


				} else if (hh.equals("Selected")) {
				} else {	// Other fields

					tt = cc.getField(hh);
					if ((tt != null) && (tt.length() > 0) && (hh.indexOf("URL") > 0)) {
						try {
							WritableHyperlink link = new WritableHyperlink(col, row+1, new URL(tt)); ++col;
							sheet.addHyperlink(link);
							link = null;
						} catch (Exception e) {
							SilLogger.error("Cannot create hyperlink for cell ("
												+ row+1 + "," + col
												+ ") for data=" + tt
												+ ": " + e);
							sheet.addCell(new Label(col, row+1,tt, cellFormat)); ++col;
						}
					} else {
						sheet.addCell(new Label(col, row+1,tt, cellFormat)); ++col;
					}

				}
			}

		}

/*		} catch (Exception e) {
			SilLogger.error("Failed to fill workbook for sil " + getId() + ": " + e.getMessage(), e);
		}*/

	}

	/**
	 * HELPER
	 */
	private void addCell(WritableSheet sheet, int col, int row,
						String value, WritableCellFormat format)
		throws Exception
	{
		if (value == null)
			value = "";
		sheet.addCell(new Label(col, row, value, format));
	}

	private Crystal getCrystal(int row)
	{
		return (Crystal)crystals.get(new Integer(row));

	}
	
	public Crystal cloneCrystal(int row)
		throws Exception
	{
		Crystal c = getCrystal(row);
				
		if (c == null)
			return null;
			
		return c.clone();
	}

	/**
	 * SAX parser
	 */
	public void startElement(String uri, String localName,
				String qName, Attributes attributes)
		throws SAXException
	{
		// clear buffer
		curFieldValue.delete(0, curFieldValue.length());
		
		String tmp = "";
		if (qName.equals("Sil")) {
			tmp = attributes.getValue("name");
			if (tmp != null)
				id = tmp;
			tmp = attributes.getValue("eventId");
			if (tmp != null) {
				try {
					eventId = Integer.parseInt(tmp);
				} catch (NumberFormatException e) {
					SilLogger.error("Invalid eventId for sil " + id + ": " + tmp);
				}
			}
			tmp = attributes.getValue("version");
			if (tmp != null)
				version = tmp;
			tmp = attributes.getValue("key");
			if (tmp != null)
				key = tmp;
			tmp = attributes.getValue("lock");
			if (tmp != null) {
				if (tmp.equals("true") || tmp.equals("yes") || tmp.equals("1"))
					locked = true;
				else
					locked = false;
			}

		} else if (qName.equals("Crystal")) {

			int row = -1;
			int excelRow = -1;
			boolean selected = false;

			tmp = attributes.getValue("row");
			if (tmp != null) {
				try {
					row = Integer.parseInt(tmp);
				} catch (NumberFormatException e) {
					SilLogger.error("Invalid row for sil " + id + ": " + tmp);
				}
			}

			tmp = attributes.getValue("excelRow");
			if (tmp != null) {
				try {
					excelRow = Integer.parseInt(tmp);
				} catch (NumberFormatException e) {
					SilLogger.error("Invalid excelRow for sil " + id + ": " + tmp);
				}
			}


			tmp = attributes.getValue("selected");
			if (tmp != null) {
				if (tmp.equals("1"))
					selected = true;
				else
					selected = false;
			}

			Crystal newCrystal = new CrystalSimpleImp(row, excelRow, selected);

			curCrystal = newCrystal;

			crystals.put(new Integer(row), newCrystal);


		} else if (qName.equals("Group")) {

			if (curCrystal == null)
				return;

			tmp = attributes.getValue("name");

			if (tmp == null)
				return;

			ImageGroup group = curCrystal.getImageGroup(tmp);

			if (group == null)
				return;

			curGroup = group;

		} else if (qName.equals("Image")) {

			if (curGroup == null)
				return;

			tmp = attributes.getValue("name");

			curGroup.addImage(tmp, attributes);

		} else {

			if (curCrystal  != null) {
				curCrystalField = qName;
			}
		}
	}

	public void characters(char[] ch,
                       int start,
                       int length)
                throws SAXException
	{
		if (curGroup != null) {
			// We are inside a Group node
		} else if (curCrystal != null) {
			// We are inside Crystal node
			if (curCrystalField != null) {
				curFieldValue.append(new String(ch, start, length));
			}
		}
	}


	public void endElement(String uri, String localName, String qName)
		throws SAXException
	{

		if (qName.equals("Sil")) {
		} else if (qName.equals("Crystal")) {
			curCrystal = null;
		} else if (qName.equals("Group")) {
			curGroup = null;
		} else {
			if (curCrystal != null) {
				if (curCrystalField != null) {
					curCrystal.setField(curCrystalField, curFieldValue.toString());
				}
				curCrystalField = null;
			}
		}
	}

	public void startDocument()
		throws SAXException
	{
	}

	public void endDocument()
		throws SAXException
	{
	}

	public InputSource resolveEntity(String publicId,
                                 String systemId)
                          throws SAXException
	{
		String dtdFile = "";
		try {

			SilConfig silConfig = SilConfig.getInstance();
			if (systemId.endsWith("sil.dtd")) {
				dtdFile = silConfig.getTemplateDir() + "/sil.dtd";
			} else if (systemId.endsWith(silConfig.getSilDtd())) {
				dtdFile = silConfig.getTemplateDir() + "/" + silConfig.getSilDtd();
			} else {
				return null;
			}

			FileInputStream stream = new FileInputStream(dtdFile);
			return new InputSource(stream);

		} catch (FileNotFoundException e) {
			SilLogger.error("DTD file does not exist: " + dtdFile);
			throw new SAXException("DTD file does not exist: " + dtdFile);
		}
	}

}

