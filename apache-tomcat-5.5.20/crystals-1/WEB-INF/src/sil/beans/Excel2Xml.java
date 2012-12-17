package sil.beans;

import jxl.*;
import java.util.*;
import java.io.*;

/**
 * Reads excel spreadsheet and writes it out as xml.
 */
public class Excel2Xml
{	
	// Name of the sheet that contains crystal data
	private String sheetName = "Sheet1";
	private String validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_";
		
	/**
	 */
	public Excel2Xml()
	{
	}
	
	/**
	 * Convert excel file into xml file.
	 */
	public void convert(String input, String output)
		throws Exception
	{
		Workbook workbook = readExcel(input);
		
		writeXml(workbook, output);
	}
	
	/**
	 * Create a workbook from an excel file.
	 */
	private Workbook readExcel(String filename)
		throws Exception
	{
		if (filename == null)
			throw new Exception("Null excel filename");
 		if (filename.length() == 0)
			throw new Exception("Zero length excel filename");
			
  		Workbook workbook = Workbook.getWorkbook(new File(filename));
		
		return workbook;
	}
	
	/**
	 * Parse a workbook and write out contents into an xml file.
	 */
	private void writeXml(Workbook workbook, String output)
		throws Exception
	{
		if (workbook == null)
			throw new Exception("Null workbook");
			
		if (output == null)
			throw new Exception("Null xml filename");
		
		if (output.length() == 0)
			throw new Exception("Zero length xml filename");
			
		FileOutputStream out = new FileOutputStream(output);	
		BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(out, "UTF8"));
		
		try {
      		
		Sheet s = workbook.getSheet(sheetName);
		
		if (s == null)
			throw new Exception("Cannot get sheet " + sheetName + " from this workbook");
			
		bw.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
		bw.write("<Data>\n");
      
		Cell[] cells = null;
		int count = 0;
		
		// First row contains column names
		cells = s.getRow(0);
		
		if (cells == null)
			throw new Exception("Cannot get row 0 from sheet " + sheetName);
					
		int numColumns = cells.length;
		String colNames[] = new String[numColumns];
		
		boolean foundPort = false;
		boolean foundCrystalID = false;
		
		// Get column names from first row
		for (int i = 0; i < cells.length; ++i) {
			if (cells[i] == null)
				throw new Exception("Cell[0," + i + "] is null");
			String cname = cells[i].getContents();
			if (cells[i].getType() != CellType.EMPTY) {
				String colName = cname.trim();
				// Make sure column name contains only allowed characters.
				validateColumnName(colName);				
				colNames[i] = colName;
				if (colName.equals("Port") || colName.equals("CurrentPosition"))
					foundPort = true;
				else if (colName.equals("CrystalID") || colName.equals("XtalID"))
					foundCrystalID = true;
			}
		}
		
		// Make sure we have at least the required columns
		// which are Port, CrystalID
		if (!foundPort)
			throw new Exception("The first row does not contain Port column");
		if (!foundCrystalID)
			throw new Exception("The first row does not contain CrystalID column");
			
    
      		// Loop over rows in this sheet
		String cellContent = "";
		for (int i = 1; i < s.getRows() ; i++) {
		
			cells = s.getRow(i);
			
			bw.write("	<Row number=\"" + (i+1) + "\">\n");
						
			// Loop over columns in this row
			for (int j = 0; j < cells.length; ++j) {
				// In case this row has more 
				// columns than the fist row.
				// Then ignore this extra column.
				if (j >= numColumns)
					continue;
				Cell cell = cells[j];
				String colName = colNames[j];
				if (cell.getType() != CellType.EMPTY) {
					cellContent = xmlEncode(cell.getContents());
					bw.write("		<" + colName + ">" + cellContent + "</" + colName + ">\n");
				}
//				System.out.println("cell[" + i + "," + j + "] name = " + colName + " val = " + cell.getContents());
			}
			
			bw.write("	</Row>\n");
			
		}
		
		bw.write("</Data>\n");
		bw.flush();

		} catch (Exception e) {
			throw new Exception("Cannot convert excel data to xml: " + e.getMessage());
		} finally {
			bw.close();
		}
				
		
	}
	
	/**
	 * XML encode cell content so that character like '&' is converted to &amp;
	 */
	static private String xmlEncode(String rawStr)
	{
		String ret = rawStr.replace("&", "&amp;");
		ret = ret.replace("\"", "&quot;");
		ret = ret.replace("'", "&apos;");
		ret = ret.replace("<", "&lt;");
		ret = ret.replace(">", "&gt;");
		
		return ret;
		
	}
	
	/**
	 * Replace xml escaped characters like '&amp;' with real char '&'.
	 */
	static public String xmlDecode(String xmlStr)
	{
		String ret = xmlStr.replace("&quot;", "\"");
		ret = ret.replace("&apos;", "'");
		ret = ret.replace("&lt;", "<");
		ret = ret.replace("&gt;", ">");
		ret = ret.replace("&amp;", "&");
		return ret;
	}
	
	/**
	 * Column name cannot contain space.
	 */
	private void validateColumnName(String n)
		throws Exception
	{
		if (n.length() == 0)
			throw new Exception("Column name is empty");
					
		for (int i = 0; i < n.length(); ++i) {
			if (validChars.indexOf(n.charAt(i)) < 0)
				throw new Exception("Column name ('" + n + "') must contain only the following characters: '" + validChars + "'");	
		}
		
	}
	
}

