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
 * ImageGroup
 *
 **************************************************/
class ImageGroup
{
	String name = "";
	Vector images = new Vector();

	ImageGroup(String n)
	{
		if (n != null)
			name = n;
	}
	
	/**
	 */
	public ImageGroup clone()
	{
		ImageGroup newGroup = new ImageGroup(this.name);
		
		for (int i = 0; i < images.size(); ++i) {
			ImageData img = (ImageData)images.elementAt(i);
			newGroup.images.add(img.clone());
		}
		
		return newGroup;
	}

	/**
	 */
	String getName()
	{
		return name;
	}

	/**
	 * Set image in the group
	 */
	void setImage(String n, Hashtable params)
	{
		ImageData img = getImage(n);

		if (img == null)
			return;

		img.setFields(params);

	}

	/**
	 * Add image to the group
	 */
	void addImage(String n, Hashtable params)
	{
		ImageData img = getImage(n);

		// Image already exist. Do nothing
		if (img != null)
			return;

		img = new ImageData(n, params);

		// Append new image to the group
		images.add(img);

	}

	/**
	 * Add image to the group. Used by SAX parser.
	 */
	void addImage(String n, Attributes params)
	{
		ImageData img = getImage(n);

		// Image already exist. Do nothing
		if (img != null)
			return;

		img = new ImageData(n, params);

		// Append new image to the group
		images.add(img);

	}

	/**
	 * Hash image or not?
	 */
	boolean hasImage(String n)
	{
		return (getImage(n) != null);
	}

	/**
	 * Clear images of this group
	 */
	void clearImages()
	{
		images.clear();
	}
	
	void clearSpotfinderResults()
	{
		for (int i = 0; i < images.size(); ++i) {
			ImageData dd = (ImageData)images.elementAt(i);
			dd.clearSpotfinderResults();
		}
	}

	/**
	 */
	void toTclString(StringBuffer buf)
	{
		if (buf == null)
			return;

		buf.append("      {\n");
		ImageData mm = null;
		for (int i = 0; i < images.size(); ++i) {
			mm = (ImageData)images.elementAt(i);
			mm.toTclString(buf);
		}
		buf.append("      }\n");
	}

	/**
	 */
	void toXmlString(StringBuffer buf)
	{
		if (buf == null)
			return;

		buf.append("<Group name=\"" + name + "\">\n");
		ImageData mm = null;
		for (int i = 0; i < images.size(); ++i) {
			mm = (ImageData)images.elementAt(i);
			mm.toXmlString(buf);
		}
		buf.append("</Group>\n");
	}

	/**
	 */
	void toXmlString(Writer writer)
		throws Exception
	{
		if (writer == null)
			return;

		writer.write("<Group name=\"" + name + "\">\n");
		ImageData mm = null;
		for (int i = 0; i < images.size(); ++i) {
			mm = (ImageData)images.elementAt(i);
			mm.toXmlString(writer);
		}
		writer.write("</Group>\n");
	}

	/**
	 */
	ImageData getLastImage()
	{
		if (images.size() == 0)
			return null;

		return (ImageData)images.lastElement();
	}

	/**
	 */
	private ImageData getImage(String n)
	{
		ImageData dd = null;
		for (int i = 0; i < images.size(); ++i) {
			dd = (ImageData)images.elementAt(i);
			if (dd.getName().equals(n))
				return dd;
		}

		return null;
	}
	
	/**
	 * Get field of the given image in this group
	 */
	public String getImageField(String n, String f)
	{
		ImageData d = getImage(n);
		
		if (d == null)
			return null;
			
		return d.getField(f);
	}

	/**
	 * Get field of last image in this group
	 */
	public String getImageField(String f)
	{
		ImageData d = getLastImage();
		
		if (d == null)
			return null;
			
		return d.getField(f);
	}

	/**
	 * Set field of all images in this group
	 */
	public void setImageField(String fieldName, String fieldValue)
	{
		for (int i = 0; i < images.size(); ++i) {
			ImageData dd = (ImageData)images.elementAt(i);
			dd.setField(fieldName, fieldValue);
		}
	}

	/**
	 * Set field of the given image in this group
	 */
	public void setImageField(String imgName, String fieldName, String fieldValue)
	{
		ImageData d = getImage(imgName);
		
		if (d == null)
			return;
			
		d.setField(fieldName, fieldValue);
		
	}

}
