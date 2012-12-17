package sil.upload;


import java.io.*;
import java.util.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
//import org.apache.xerces.dom.DocumentImpl;
//import org.apache.xml.serialize.OutputFormat;
//import org.apache.xml.serialize.XMLSerializer;
//import org.w3c.dom.Document;
//import org.w3c.dom.Element;

/**
 * 
 * @author penjitk
 * Parse csv data from input stream.
 * Convert it to xml and send it back to output stream.
 * Return false if it fails to parse the csv data.
 *
 */
public class CsvParser implements UploadParser
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public RawData parse(UploadData data) 
		throws Exception
	{
		byte[] buf = data.getFile().getBytes();
		if (buf == null)
			throw new Exception("No input data.");
		
		
		// Test if this is a csv file
		// Expect to find a common within the first 500 characters.
		// If not, then assume that this is not a csv file.
		boolean found = false;
		char c;
		for (int i = 0; i < 500; ++i) {
			c = (char)buf[i];
			if (c != ',')
				continue;
			found = true;
			break;
		}
		if (!found)
			return null;
		
		RawData rawData = new RawData();
	
		try {
		
		ByteArrayInputStream in = new ByteArrayInputStream(buf);
		BufferedReader reader = new BufferedReader(new InputStreamReader(in));
		String line ;
		String[] columnNames = parseLine(reader.readLine());
		for (int i = 0; i < columnNames.length; ++i) {
			rawData.addColumn(columnNames[i], null);
		}
		int row = 1;
		while ((line=reader.readLine()) != null) {
			++row;
			if (line.length() == 0)
				continue;
			String[] contents = parseLine(line);
			RowData rowData = rawData.newRow();
			for (int col = 0; (col < columnNames.length) && (col < contents.length); ++col) {
				rowData.setCell(col, contents[col]);
			}
		}
		
		return rawData;
		
		} catch (Exception e) {
			logger.info("Not a csv document.");
			logger.debug(e.getMessage());
		}
		  		
			return null;
	}

	private String[] parseLine(String line)
	{
		StringTokenizer tok = new StringTokenizer(line, ",");
		String[] columns = new String[tok.countTokens()];
		int i = 0;
		while (tok.hasMoreTokens()) {
			columns[i] = tok.nextToken();
			++i;
		}
		return columns;
	}

}
