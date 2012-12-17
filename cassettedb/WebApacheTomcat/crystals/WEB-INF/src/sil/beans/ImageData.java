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
 * ImageData
 *
 **************************************************/
class ImageData
{

	String name = "";
	Hashtable fields = new Hashtable();

	static private Vector fieldNames = new Vector();

	static {

		fieldNames.add("dir");
		fieldNames.add("name");
		fieldNames.add("jpeg");
		fieldNames.add("small");
		fieldNames.add("medium");
		fieldNames.add("large");
		fieldNames.add("quality");
		fieldNames.add("spotShape");
		fieldNames.add("resolution");
		fieldNames.add("iceRings");
		fieldNames.add("diffractionStrength");
		fieldNames.add("score");
		fieldNames.add("numSpots");
		fieldNames.add("numOverloadSpots");
		fieldNames.add("integratedIntensity");
		fieldNames.add("spotfinderDir");
	}

	/**
	 * Default constructor
	 */
	ImageData()
	{
		init();
	}

	/**
	 * Constructs ImageData with real data
	 */
	ImageData(String n, Hashtable params)
	{
		init();

		if (n != null)
			name = n;
		setFields(params);
	}

	/**
	 * Constructs ImageData with real data.
	 * Used by SAX parser.
	 */
	ImageData(String n, Attributes params)
	{
		init();

		if (n != null)
			name = n;

		setFields(params);
	}
	
	/**
	 * Initialize all fields
	 */
	private void init()
	{
		name = "";
		String nn = "";
		for (int i = 0; i < fieldNames.size(); ++i) {
			nn = (String)fieldNames.elementAt(i);
			if (!nn.equals("name"))
				fields.put(nn, "");
		}
	}

	/**
	 * Copy data
	 */
	public ImageData clone()
	{
		ImageData newData = new ImageData();
		newData.name = name;
		
		String nn = "";
		String val = "";
		for (int i = 0; i < fieldNames.size(); ++i) {
			nn = (String)fieldNames.elementAt(i);
			val = (String)fields.get(nn);
			if (val != null)
				newData.fields.put(nn, val);
		}
		
		return newData;
	}

	/**
	 * Returns name
	 */
	String getName()
	{
		return name;
	}

	/**
	 * Set all valid fields
	 */
	void setFields(Hashtable params)
	{
		String n = "";
		Enumeration keys = params.keys();
		while (keys.hasMoreElements()) {
			n = (String)keys.nextElement();
			setField(n, (String)params.get(n));
		}

	}

	/**
	 */
	String getField(String n)
	{
		return (String)fields.get(n);
	}

	/**
	 * Set all valid fields. Used by SAX parser.
	 */
	void setFields(Attributes params)
	{
		String n = "";
		for (int i = 0; i < params.getLength(); ++i) {
			setField(params.getQName(i), params.getValue(i));
		}

	}

	/**
	 * Set valid field
	 */
	void setField(String n, String val)
	{
		if ((n == null) || (n.length() <= 0) || (val == null))
			return;

		if (fields.containsKey(n)) {
			fields.put(n, val);
		}
	}

	/**
	 */
	void toTclString(StringBuffer buf)
	{
		if (buf == null)
			return;


		buf.append("        {");
		Enumeration keys = fields.keys();
		String nn = "";
		for (int i = 0; i < fieldNames.size(); ++i) {
			nn = (String)fieldNames.elementAt(i);
			if (nn.equals("name"))
				buf.append(" {" + name + "}");
			else
				buf.append(" {" + (String)fields.get(nn) + "}");
		}
		buf.append(" }\n");
	}

	/**
	 */
	void toXmlString(StringBuffer buf)
	{
		if (buf == null)
			return;

		buf.append("<Image name=\"" + name + "\"");
		Enumeration keys = fields.keys();
		String nn = "";
		while (keys.hasMoreElements()) {
			nn = (String)keys.nextElement();
			buf.append(" " + nn + "=\"" + (String)fields.get(nn) + "\"");
		}
		buf.append(" />\n");
	}

	/**
	 */
	void toXmlString(Writer writer)
		throws Exception
	{
		if (writer == null)
			return;

		writer.write("<Image name=\"" + name + "\"");
		Enumeration keys = fields.keys();
		String nn = "";
		while (keys.hasMoreElements()) {
			nn = (String)keys.nextElement();
			writer.write(" " + nn + "=\"" + (String)fields.get(nn) + "\"");
		}
		writer.write(" />\n");
	}
	
	void clearSpotfinderResults()
	{
		setField("spotShape", "");
		setField("resolution", "");
		setField("iceRings", "");
		setField("diffractionStrength", "");
		setField("score", "");
		setField("numSpots", "");
		setField("numOverloadSpots", "");
		setField("integratedIntensity", "");
		setField("spotfinderDir", "");
	}

}

