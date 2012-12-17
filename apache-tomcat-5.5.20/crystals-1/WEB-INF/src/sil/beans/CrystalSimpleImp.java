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
 * CrystalSimpleImp
 *
 **************************************************/
public class CrystalSimpleImp implements Crystal
{
	int row = -1;
	int excelRow = -1;
	boolean selected = false;

	Hashtable fields = new Hashtable();

	ImageGroup group1 = new ImageGroup("1");
	ImageGroup group2 = new ImageGroup("2");
	ImageGroup group3 = new ImageGroup("3");

	private static Vector fieldNames = new Vector();

	static {

		String[] ff = SilConfig.getInstance().getCrystalFields();
		if ((ff != null) && (ff.length > 0)) {
			for (int i = 0; i < ff.length; ++i) {
				fieldNames.add(ff[i]);
			}
		} else {

			fieldNames.add("ContainerID");
			fieldNames.add("Port");
			fieldNames.add("CrystalID");
			fieldNames.add("Protein");
			fieldNames.add("Comment");
			fieldNames.add("FreezingCond");
			fieldNames.add("CrystalCond");
			fieldNames.add("Metal");
			fieldNames.add("Priority");
			fieldNames.add("Person");
			fieldNames.add("CrystalURL");
			fieldNames.add("ProteinURL");
			fieldNames.add("Directory");
			fieldNames.add("SystemWarning");
			fieldNames.add("AutoindexImages");
			fieldNames.add("Score");
			fieldNames.add("UnitCell");
			fieldNames.add("Mosaicity");
			fieldNames.add("Rmsr");
			fieldNames.add("BravaisLattice");
			fieldNames.add("Resolution");
			fieldNames.add("ISigma");
			fieldNames.add("Images");
			fieldNames.add("AutoindexDir");
			fieldNames.add("Move");
		
		}
	}

	/**
	 * Constructor. Set default fields.
	 */
	public CrystalSimpleImp()
	{
		init();
	}

	public CrystalSimpleImp(int row, int excelRow, boolean selected)
	{
		init();

		this.row = row;
		this.excelRow = excelRow;
		this.selected = selected;
	}

	/**
	 */
	private void init()
	{
		for (int i = 0; i < fieldNames.size(); ++i) {
			fields.put((String)fieldNames.elementAt(i), "");
		}
	}

	/**
	 */
	public Crystal clone()
	{
		try {
				
		CrystalSimpleImp newCrystal = new CrystalSimpleImp();
	
		newCrystal.row = row;
		newCrystal.selected = selected;
				
		// Copy fields
		Enumeration keys = fields.keys();
		String n = "";
		while (keys.hasMoreElements()) {
			n = (String)keys.nextElement();
			newCrystal.setField(n, (String)fields.get(n));
		}
		
		newCrystal.group1 = group1.clone();
		newCrystal.group2 = group2.clone();		
		newCrystal.group3 = group3.clone();
		
		return newCrystal;
		
		} catch (Exception e) {
			SilLogger.warn("CrystalSimpleImp failed to clone crystal: " + e.getMessage());
			return null;
		}	

	}


	public int getRow()
	{
		return row;
	}
	
	public void setRow(int r)
	{
		row = r;
	}

	public int getExcelRow()
	{
		return excelRow;
	}
	
	public void setExcelRow(int r)
	{
		excelRow = r;
	}

	public boolean isSelected()
	{
		return selected;
	}

	public void setSelected(boolean l)
	{
		selected = l;
	}

	public void setSelected(String n)
	{
		if (n == null)
			return;

		if (n.equals("1"))
			selected = true;
		else if (n.equals("0"))
			selected = false;
		else if (n.equals("true"))
			selected = true;
		else if (n.equals("false"))
			selected = false;


	}

	/**
	 * Returns crystal field
	 */
	public String getField(String name)
	{
		return (String)fields.get(name);
	}
	
	/**
	 * Returns an image field of last image in the group
	 */
	public String getImageField(String groupName, String f)
	{
		ImageGroup group = getImageGroup(groupName);

		if (group == null)
			return null;
			
		// Get last image in this group
		return group.getImageField(f);
	}
	

	/**
	 * Set field of all images in this group
	 */
	public void setImageField(String groupName, String fieldName, String fieldValue)
	{

		ImageGroup group = getImageGroup(groupName);

		if (group == null)
			return;


		group.setImageField(fieldName, fieldValue);
	}

	/**
	 * Set image
	 */
	public void setImage(String groupName, String imgName, Hashtable params)
	{

		ImageGroup group = getImageGroup(groupName);

		if (group == null)
			return;


		group.setImage(imgName, params);
	}

	/**
	 * Add image
	 */
	public void addImage(String groupName, String imgName, Hashtable params)
	{

		ImageGroup group = getImageGroup(groupName);

		if (group == null)
			return;

		group.addImage(imgName, params);
	}

	/**
	 * Has image or not in the given group?
	 */
	public boolean hasImage(String groupName, String imgName)
	{
		ImageGroup group = getImageGroup(groupName);

		if (group == null)
			return false;

		return group.hasImage(imgName);

	}

	/**
	 * Clear image in the given group
	 */
	public void clearImages(String groupName)
	{
		ImageGroup group = getImageGroup(groupName);

		if (group == null)
			return;

		group.clearImages();

	}

	/**
	 * Clear image in all groups
	 */
	public void clearImages()
	{
		group1.clearImages();
		group2.clearImages();
		group3.clearImages();

	}
	
	/**
	 ( clear spotfinder result fields for all images
 	 */
	public void clearSpotfinderResults()
	{
		group1.clearSpotfinderResults();
		group2.clearSpotfinderResults();
		group3.clearSpotfinderResults();
		clearField("SystemWarning");
	}

	/**
	 * Clear autoindex result fields
 	 */
	public void clearAutoindexResults()
	{
		clearField("AutoindexImages");
		clearField("Score");
		clearField("UnitCell");
		clearField("Mosaicity");
		clearField("Rmsr");
		clearField("BravaisLattice");
		clearField("Resolution");
		clearField("ISigma");
		clearField("AutoindexDir");
		clearField("SystemWarning");
	}
	
	/**
	 * Clear all fields
 	 */
	public void clearFields()
	{
		Enumeration keys = fields.keys();
		String n = "";
		while (keys.hasMoreElements()) {
			n = (String)keys.nextElement();
			setField(n, "");
		}
		clearImages();
	}
	

	public void clearField(String n)
	{
		if ((n == null) || (n.length() <= 0))
			return;
			
		if (!fields.containsKey(n))
			return;
			
		fields.put(n, "");
	}
	/**
	 * Set a field
	 */
	public void setField(String n, String val)
	{
		if ((n == null) || (n.length() <= 0) || (val == null))
			return;
			
		if (!fields.containsKey(n))
			return;

		if (n.equals("SystemWarning")) {
			String old = (String)fields.get(n);
			if ((old != null) && (old.length() > 0))
				fields.put(n, old + " " + val);
			else
				fields.put(n, val);
		} else {
			fields.put(n, val);
		}
	}

	/**
	 * Set fields
	 */
	public void setFields(Hashtable params)
	{
		String n = "";
		Enumeration keys = params.keys();
		while (keys.hasMoreElements()) {
			n = (String)keys.nextElement();
			if (fields.containsKey(n)) {
			   setField(n, (String)params.get(n));
			}
		}
	}

	/**
	 * Dump data to tcl string
	 */
	public void toTclString(StringBuffer buf)
		throws Exception
	{
		toTclString(buf, false);
	}
	/**
	 * Dump data to tcl string
	 */
	public void toTclString(StringBuffer buf, boolean update)
		throws Exception
	{
		if (buf == null)
			return;

		buf.append("  {\n");
		if (update) {
			buf.append("   {" + row + "}\n");
			buf.append("   {\n");
		}
		String n = "";
		HeaderData hh = null;
		Vector headers = SilHeader.getHeaders();
		for (int i = 0; i < headers.size(); ++i) {
			hh = (HeaderData)headers.elementAt(i);
			n = (String)hh.name;
			if (n.equals("Images")) {
				buf.append("    {\n");
				group1.toTclString(buf);
				group2.toTclString(buf);
				group3.toTclString(buf);
				buf.append("    }\n");
			} else if (n.equals("Selected")) {
				if (selected)
					buf.append("    {1}\n");
				else
					buf.append("    {0}\n");
			} else {
				buf.append("    {" + (String)fields.get(n) + "}\n");
			}
		}
		if (update) {
			buf.append("   }\n");
		}
		buf.append("  }\n");

	}

	/**
	 * Dump data to xml string
	 */
	public void toXmlString(StringBuffer buf)
		throws Exception
	{
		if (buf == null)
			return;

		int ss = selected ? 1 : 0;

		buf.append("<Crystal row=\"" + row + "\" excelRow=\"" + excelRow
					+ "\" selected=\"" + ss + "\">\n");
		String n = "";
		for (int i = 0; i < fieldNames.size(); ++i) {
			n = (String)fieldNames.elementAt(i);
			if (n.equals("Images")) {
					buf.append("<Images>\n");
					group1.toXmlString(buf);
					group2.toXmlString(buf);
					group3.toXmlString(buf);
					buf.append("</Images>\n");
				} else {
					// Apply xml encoding to the string
					buf.append("<" + n + ">" + XMLEncoder.encode((String)fields.get(n)) + "</" + n + ">\n");
				}
		}
		buf.append("</Crystal>\n");

	}

	/**
	 * Dump data to xml string
	 */
	public void toXmlString(Writer writer)
		throws Exception
	{
		if (writer == null)
			return;

		int ss = selected ? 1 : 0;

		writer.write("<Crystal row=\"" + row + "\" excelRow=\"" + excelRow
					+ "\" selected=\"" + ss + "\">\n");
		String n = "";
		for (int i = 0; i < fieldNames.size(); ++i) {
			n = (String)fieldNames.elementAt(i);
			if (n.equals("Images")) {
					writer.write("<Images>\n");
					group1.toXmlString(writer);
					group2.toXmlString(writer);
					group3.toXmlString(writer);
					writer.write("</Images>\n");
				} else {
					writer.write("<" + n + ">" + (String)fields.get(n) + "</" + n + ">\n");
				}
		}
		writer.write("</Crystal>\n");

	}

	ImageData getLastImage(String gName)
	{
		ImageGroup gg = getImageGroup(gName);

		if (gg == null)
			return null;

		return gg.getLastImage();
	}

	/**
	 * HELPER
	 */
	public ImageGroup getImageGroup(String groupName)
	{
		if (groupName == null)
			return null;

		if (groupName.equals("1"))
			return group1;
		else if (groupName.equals("2"))
			return group2;
		else if (groupName.equals("3"))
			return group3;

		return null;
	}


}


