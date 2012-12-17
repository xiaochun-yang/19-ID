package sil.upload;

import java.io.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import org.odftoolkit.odfdom.doc.OdfSpreadsheetDocument;
import org.odftoolkit.odfdom.doc.office.OdfOfficeSpreadsheet;
import org.odftoolkit.odfdom.doc.table.OdfTable;
import org.odftoolkit.odfdom.pkg.OdfPackage;
import org.w3c.dom.Node;

/**
 * 
 * @author penjitk
 * OpenOffice document parser.
 *
 */
public class OdfParser implements UploadParser
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public RawData parse(UploadData data)
		throws Exception
	{
		if (data.getFile().getBytes() == null)
			throw new Exception("No input data.");
		
		ByteArrayInputStream in = new ByteArrayInputStream(data.getFile().getBytes());
				
		OdfSpreadsheetDocument doc = null;		
		OdfOfficeSpreadsheet workbook = null;
		try {
			doc.loadDocument(in);
			workbook = doc.getContentRoot();
		} catch (Exception e) {
			logger.debug("OdfParser failed to parse " + data.getOriginalFileName() + ". Root cause: " + e.getMessage());
			return null;
		}

		String sheetName = data.getSheetName();

		// Create xml document
  		return createRawData(workbook, sheetName);
	}
	
	private RawData createRawData(OdfOfficeSpreadsheet workbook, String sheetName)
		throws Exception
	{					
		RawData rawData = new RawData();
			
		Node node = workbook.getFirstChild();
		OdfTable sheet = null;
		if (node instanceof OdfTable) {
			sheet = (OdfTable)node;
		} else {
			throw new Exception("Got wrong node: " + node.getNodeName());
		}
		if (sheet == null)
			throw new Exception("Workbook is empty.");
	
		if (!sheet.getTableNameAttribute().equals("Sheet1"))
			throw new Exception("Cannot get sheet " + sheetName + " from this workbook");
		
		// First row contains column names
/*		sheet.getOdfName
		Row row = s.getRow(0);
		
		if (row == null)
			throw new Exception("Cannot get row 0 from sheet " + sheetName);
							
		// Get column names from first row
		int firstCol = row.getFirstCellNum();
		int lastCol = row.getLastCellNum();
		for (int i = firstCol; i < lastCol; ++i) {
			Cell cell = row.getCell(i, Row.RETURN_BLANK_AS_NULL);
			if (cell == null)
				throw new Exception("Cell[0," + i + "] is null");
			String cname = cell.toString();
			if (cname.length() == 0) {
				logger.debug("zero length column name in cell(0" + "," + i + "). Skipping the rest of the columns. ");
				break;
			}
			int col = rawData.addColumn(cname, null);
			logger.debug("adding column name[" + col + "]=" + cname);
		}
	
	  	// Loop over rows in this sheet
		int firstRow = s.getFirstRowNum();
		int lastRow = s.getLastRowNum();
		for (int i = firstRow+1; i <= lastRow; i++) {
		
			row = s.getRow(i);
			boolean isEmptyRow = true;
			String content = "";
			for (int col = firstCol; col <= lastCol; ++col) {
				Cell cell = row.getCell(col, Row.RETURN_BLANK_AS_NULL);
				if (cell == null)
					continue;
				content = cell.toString();
				if ((content != null) && (content.trim().length() > 0)) {
					isEmptyRow = false;
					break;
				}
			}
			
			if (isEmptyRow) {
				System.out.println("Skipping row " + i + ". All cells are empty.");
				continue;
			}
			
			// Loop over columns in this row
			RowData rowData = rawData.newRow();
			for (int col = firstCol; col <= lastCol; ++col) {
				Cell cell = row.getCell(col, Row.RETURN_BLANK_AS_NULL);
				String colName = rawData.getColumnName(col);
				if (cell == null) {
					logger.warn("Data in row " + i + " column " + col + " is null.");
					continue;
				}
				if (colName == null) {
					logger.warn("Column name " + col + " is null.");
					continue;
				}
				String value = "";
				if ((colName.length() > 0) && (cell.getCellType() != Cell.CELL_TYPE_BLANK)) {
					switch (cell.getCellType()) {
					case Cell.CELL_TYPE_BOOLEAN:
						value = String.valueOf(cell.getBooleanCellValue());
					case Cell.CELL_TYPE_ERROR:
						value = String.valueOf(cell.getErrorCellValue());
					case Cell.CELL_TYPE_FORMULA:
						value = String.valueOf(cell.getCellFormula());
					case Cell.CELL_TYPE_NUMERIC:
						value = String.valueOf(cell.getNumericCellValue());
					case Cell.CELL_TYPE_STRING:
					default:
						value = String.valueOf(cell.toString().trim());
					}
					rowData.setCell(col, value);
//					System.out.println("Adding row = " + i + " col = " + col + " name = " + colName + " value = '" + cell.getStringCellValue() + "'");
				} else {
					rowData.setCell(col, null);
//					System.out.println("Adding row = " + i + " col = " + col + " name = " + colName + " value = NULL");
				}
			}
			logger.debug("Adding row to rawData numRows = " + rawData.getRowCount());
				
		}	*/
				
		return rawData;
	}
	
}
