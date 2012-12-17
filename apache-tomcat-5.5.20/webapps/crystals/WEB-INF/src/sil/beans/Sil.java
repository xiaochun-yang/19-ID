package sil.beans;

import java.io.*;
import java.util.*;

import javax.xml.parsers.*;

import jxl.Workbook;
import jxl.WorkbookSettings;
import jxl.write.*;
import jxl.format.Font;
import jxl.format.Alignment;

import java.net.URL;


public class Sil
{
	public static String commentField = "Comment";
	public static String systemWarningField = "SystemWarning";

	public static int FORMAT_TCL = 1;
	public static int FORMAT_XML = 2;

	private String id = "";
	private String owner = "";
	private String fileName = "";
	private String tclFileName = "";

	private int excelIndex = 0;

	private SilData silData = null;


	/**
	 */
	public Sil(String silId, String owner, String xmlFileName)
		throws Exception
	{
		this.id = silId;
		this.owner = owner;
		this.fileName = xmlFileName;
		this.tclFileName = xmlFileName.substring(0, xmlFileName.length()-3) + "tcl";


		// Load the xml file
		load(this.fileName);

	}

	/**
	 */
	public String getId()
	{
		return id;
	}

	/**
	 */
	public String getOwner()
	{
		return owner;
	}

	/**
	 */
	public String getFileName()
	{
		return fileName;
	}

	/**
	 */
	public int getEventId()
	{
		return silData.getEventId();
	}

	/**
	 */
	public void setEventId(int eId)
	{
		silData.setEventId(eId);
	}

	/**
	 */
	synchronized public int addCrystal(Hashtable fields)
		throws Exception
	{
		if ((fields == null) || (fields.size() == 0))
			throw new Exception("Error in addCrystal: null field");
			
		int newRow = silData.addCrystal(fields);
		
		save();
		
		return newRow;
	}

	/**
	 */
	synchronized public void setCrystalImage(int row, Hashtable fields)
		throws Exception
	{

		if ((fields == null) || (fields.size() == 0))
			throw new Exception("Error in setCrystalImage: null field");

		String imageGroup = (String)fields.get("group");
		String imageName = (String)fields.get("name");

		if ((imageGroup == null) || (imageGroup.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid group");
		if ((imageName == null) || (imageName.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid name");

		silData.setCrystalImage(row, imageGroup, imageName, fields);

		// Set system warning
		if (fields.containsKey(systemWarningField)) {
			silData.setCrystal(row, systemWarningField, (String)fields.get(systemWarningField));
		}

		save();

	}

	/**
	 */
	synchronized public void addCrystalImage(int row, Hashtable fields)
		throws Exception
	{
		if ((fields == null) || (fields.size() == 0))
			throw new Exception("Error in setCrystalImage: null field");

		String imageGroup = (String)fields.get("group");
		String imageDir = (String)fields.get("dir");
		String imageName = (String)fields.get("name");

		if ((imageGroup == null) || (imageGroup.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid group");
		if ((imageDir == null) || (imageDir.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid dir");
		if ((imageName == null) || (imageName.length() == 0))
			throw new Exception("Error in setCrystalImage: invalid name");

		if (silData.hasCrystalImage(row, imageGroup, imageName))
			throw new Exception("Error in addCrystalImage: sil " + id
									+ " image " + imageName
									+ " in group " + imageGroup
									+ " already exists");


		silData.addCrystalImage(row, imageGroup, imageName, fields);

		save();

	}

	/**
	 */
	synchronized public void clearCrystalImages(int row, int group)
		throws Exception
	{

		silData.clearCrystalImages(row, group);

		save();

	}

	/**
	 */
	synchronized public void clearCrystalImages(int row)
		throws Exception
	{

		silData.clearCrystalImages(row);

		save();

	}

	/**
	 */
	synchronized public void clearSpotfinderResults(int row)
		throws Exception
	{

		silData.clearSpotfinderResults(row);

		save();

	}

	/**
	 */
	synchronized public void clearAutoindexResults(int row)
		throws Exception
	{

		silData.clearAutoindexResults(row);

		save();

	}

	synchronized public int getCrystalRow(String fieldName, String fieldValue)
	{
		return silData.getCrystalRow(fieldName, fieldValue);
	}

	/**
	 * Sets fields of an existing crystal.
	 * Throws an exception if the crystal does not exist.
	 */
	synchronized public void setCrystal(int row, Hashtable fields)
		throws Exception
	{

        	silData.setCrystal(row, fields);
		save();

	}

	/**
	 * Set crystal field. Identify the crystal by using row number.
	 */
	synchronized public void setCrystal(int row, String name, String value)
		throws Exception
	{

        	silData.setCrystal(row, name, value);
		save();

	}
	
	/**
 	 */
	synchronized public void setCrystal(Crystal c)
		throws Exception
	{
		silData.setCrystal(c);
		save();
	}

	/**
	 * Set crystal field. Identify the crystal by using row number.
	 */
	synchronized public void clearCrystal(int row, String name)
		throws Exception
	{

        	silData.clearCrystal(row, name);
		save();

	}
	
	/**
	 */
	synchronized public boolean isLocked()
	{
		return silData.isLocked();
	}

	synchronized public void setLock(boolean l)
		throws Exception
	{
		silData.setLocked(l);
		save();
	}
	
	synchronized public String getKey()
	{
		return silData.getKey();
	}
	
	synchronized public void setKey(String s)
		throws Exception
	{
		silData.setKey(s);
		save();
	}

	
	/**
	 * Set attribute of all crystals
	 */
	synchronized public void setCrystalAttribute(String attrName, String values)
		throws Exception
	{
		if (attrName.equals("selected") || attrName.equals("Selected")) {
			silData.selectCrystals(values);
			save();
		}
	}

	/**
	 */
	private void load(String xmlFileName)
		throws Exception
	{
		try {

		silData = SilDataFactory.getFactory(SilDataFactory.SIMPLE_SILDATA).getSilData();

		silData.load(xmlFileName);

		} catch (Exception e) {
			SilLogger.error(e.getMessage(), e);
			throw new Exception ("Failed to load sil from file " + xmlFileName
									+ " because " + e.getMessage());
		}
	}

	/**
	 * Save sil in cache to file
	 */
	private void save()
		throws Exception
	{
		FileWriter writer = null;
		try
		{
			// Save as sil file
			writer = new FileWriter(fileName);
			StringBuffer buf = new StringBuffer();
			silData.toXmlString(buf);
			writer.write(buf.toString(), 0, buf.length());
			writer.close();

			// Save as tcl file
			writer = new FileWriter(tclFileName);
			buf = new StringBuffer();
			silData.toTclString(buf);
			writer.write(buf.toString(), 0, buf.length());
			writer.close();
			writer = null;

		} catch (Exception e) {
			SilLogger.error(e.getMessage(), e);
			throw new Exception("Failed to save sil because " + e.getMessage());
		} finally {
			if (writer != null)
				writer.close();
			writer = null;
		}

	}

	synchronized public void save(OutputStream stream)
		throws Exception
	{
		if (stream == null)
			throw new Exception("Null output stream");

		StringBuffer buf = new StringBuffer();

		silData.toXmlString(buf);

		OutputStreamWriter writer = new OutputStreamWriter(stream);
		writer.write(buf.toString(), 0, buf.length());
		writer.close();
	}

	/**
	 */
	synchronized private int getNextExcelIndex()
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
	 * Save sil as excel Workbook and pipe it through the stream
	 */
	synchronized public void saveAsWorkbook(String sheetName, OutputStream stream)
		throws Exception
	{

		// Unique tmp filename
		String path = getNextExcelFileName();
		File excelFile = new File(path);

	    WorkbookSettings ws = new WorkbookSettings();
	    ws.setLocale(new Locale("en", "EN"));
	    WritableWorkbook workbook = Workbook.createWorkbook(excelFile, ws);

	    if ((sheetName == null) || (sheetName.length() == 0))
	    	sheetName = "Sheet1";

	    WritableSheet sheet = workbook.createSheet(sheetName, 0);

	    silData.toExcel(sheet);

	    workbook.write();
	    workbook.close();
	    
	    FileInputStream input = null;
	    try {

		// read tmp excel file
		input = new FileInputStream(path);

		byte[] buff = new byte[1000];
		int numBytes = 0;
		while ((numBytes = input.read(buff)) != -1) {
			stream.write(buff, 0, numBytes);
		}

		// Flush the stream
		// Do not close it here.
		stream.flush();
		
		input.close();
		input = null;
		
	    } catch (Exception e) {
	    	SilLogger.error(e.getMessage(), e);
	    } finally {
	    	if (input != null)
			input.close();
		input = null;
	    }

		// Remove tmp excel file
		excelFile.delete();

	}


	/**
	 * Return the whole sil
	 */
	synchronized public String toTclString()
		throws Exception
	{
		StringBuffer strBuf = new StringBuffer();

		silData.toTclString(strBuf);

		return strBuf.toString();
	}

	/**
	 * Return some crystals in the sil
	 */
	synchronized public String toTclString(Object[] rows)
		throws Exception
	{
		StringBuffer strBuf = new StringBuffer();

		silData.toTclString(strBuf, rows);

		return strBuf.toString();
	}

	/**
	 * Return all crystals in the sil
	 */
	synchronized public String toXmlString()
		throws Exception
	{
		StringBuffer strBuf = new StringBuffer();

		silData.toXmlString(strBuf);

		return strBuf.toString();
	}

	/**
	 * Return some crystals in the sil
	 */
	synchronized public String toXmlString(Object[] rows)
		throws Exception
	{
		StringBuffer strBuf = new StringBuffer();

		silData.toXmlString(strBuf, rows);

		return strBuf.toString();
	}

	/**
 	 */
	synchronized public boolean hasCrystal(String fieldName, String fieldValue)
	{
		return (silData.getCrystalRow(fieldName, fieldValue) < 0);
	}
	
	/**
	 * Returns a copy of a crystal
	 */
	synchronized public Crystal cloneCrystal(int row)
		throws Exception
	{
		return silData.cloneCrystal(row);

	}
	
	static public Crystal newCrystal()
	{
		return SilDataFactory.getFactory(SilDataFactory.SIMPLE_SILDATA).newCrystal();
	}
}

