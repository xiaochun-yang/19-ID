package sil.upload;

import java.io.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
//import org.apache.xerces.dom.DocumentImpl;
//import org.w3c.dom.Document;
//import org.w3c.dom.Element;

import jxl.Cell;
import jxl.CellType;
import jxl.Sheet;
import jxl.Workbook;

/**
 * 
 * @author penjitk
 * Parse Excel 2003 spreadsheet data from input stream.
 * Convert it to xml and send it back to output stream.
 * Return false if it fails to parse the spreadhsheet.
 *
 */
public class Excel2003Parser implements UploadParser
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public RawData parse(UploadData data)
		throws Exception
	{
		if (data.getFile().getBytes() == null)
			throw new Exception("No input data.");
		
		ByteArrayInputStream in = new ByteArrayInputStream(data.getFile().getBytes());
				
		Workbook workbook = null;
		try {		
			workbook = Workbook.getWorkbook(in);
		} catch (Exception e) {
			logger.info("Not an excel2003 document.");
			logger.debug(e.getMessage());
			e.printStackTrace();
			return null;
		}

		String sheetName = data.getSheetName();

		// Create xml document
  		return createRawData(workbook, sheetName);
	}
	
	private RawData createRawData(Workbook workbook, String sheetName)
		throws Exception
	{					
		RawData rawData = new RawData();
			
		String[] sheetNames = workbook.getSheetNames();
		if ((sheetNames == null) || (sheetNames.length == 0))
			throw new Exception("Spreadsheet is empty.");
		
		// Use first sheet if sheetName is not specified.
		if ((sheetName == null) || (sheetName.length() == 0))
			sheetName = sheetNames[0];
	
		Sheet s = workbook.getSheet(sheetName);
		
		if (s == null) {
			String nn = "";
			for (int i = 0; i < sheetNames.length; ++i) {
				if (i == 0)
					nn += sheetNames[i];
				else
					nn += ", " + sheetNames[i];
			}
			throw new Exception("Cannot get sheet " + sheetName + " from this workbook. Available sheet names are " + nn);
		}
			      
		Cell[] cells = null;
		
		// First row contains column names
		cells = s.getRow(0);
		
		if (cells == null)
			throw new Exception("Cannot get row 0 from sheet " + sheetName);
							
		// Get column names from first row
		for (int i = 0; i < cells.length; ++i) {
			if (cells[i] == null)
				throw new Exception("Cell[0," + i + "] is null");
			String cname = cells[i].getContents().trim();
			if (cname.length() == 0) {
				logger.debug("Excel003Parser.createRawData: zero length column name in cell(0" + "," + i + "). Skipping the rest of the columns. ");
				break;
			}
			int col = rawData.addColumn(cname, null);
			logger.debug("Excel003Parser.createRawData: adding column name[" + col + "]=" + cname);
		}
	
//		System.out.println("num rows in sheet = " + s.getRows());
	  	// Loop over rows in this sheet
		for (int i = 1; i < s.getRows() ; i++) {
		
			cells = s.getRow(i);
//			System.out.println("row = " + i + " num columns = " + cells.length + " cell[0] = '" + cells[0].getContents() + "'");
			boolean isEmptyRow = true;
			String content = null;
			for (int col = 0; col < cells.length; ++col) {
				Cell cell = cells[col];
				if (cell == null)
					continue;
				content = cell.getContents();
				if ((content != null) && (content.trim().length() > 0)) {
					isEmptyRow = false;
					break;
				}
			}
			
			if (isEmptyRow) {
				logger.debug("Skipping row " + i + ". All cells are empty.");
				continue;
			}
			
			// Loop over columns in this row
			RowData rowData = rawData.newRow();
			for (int col = 0; (col < rawData.getColumnCount()) && (col < cells.length); ++col) {
				Cell cell = cells[col];
				String colName = rawData.getColumnName(col);
				if (cell == null) {
					logger.warn("Data in column " + col + " is null in workbook.");
					continue;
				}
				if (colName == null) {
					logger.warn("Column name " + col + " is null in workbook.");
					continue;
				}
				if ((colName.length() > 0) && (cell.getType() != CellType.EMPTY)) {
					rowData.setCell(col, cells[col].getContents());
//					System.out.println("Adding row = " + i + " col = " + col + " name = " + colName + " value = '" + cells[col].getContents() + "'");
				} else {
					rowData.setCell(col, null);
//					System.out.println("Adding row = " + i + " col = " + col + " name = " + colName + " value = NULL");
				}
			}
			logger.debug("Adding row to rawData numRows = " + rawData.getRowCount());
				
		}	
				
		return rawData;
	}
	
}
