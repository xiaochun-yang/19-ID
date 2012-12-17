package sil.upload;

import java.io.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.RichTextString;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * 
 * @author penjitk
 * Use common interface to parse
 * excel file using hssf or xssf.
 *
 */
public class PoiParser implements UploadParser
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
			logger.debug("PoiParser parsing file: " + data.getOriginalFileName());
			workbook = WorkbookFactory.create(in);
			if (workbook instanceof HSSFWorkbook) {
				logger.debug("File " + data.getOriginalFileName() + " is in office 2007 format");
			} else if (workbook instanceof XSSFWorkbook) {
				logger.debug("File " + data.getOriginalFileName() + " is in xlsx format");
			} else {
				logger.debug("File " + data.getOriginalFileName() + " is in NOT office 2007 or xlsx format");
			}
		} catch (Exception e) {
			logger.debug("PoiParser failed to parse " + data.getOriginalFileName() + ". Root cause: " + e.getMessage());
//			e.printStackTrace();
//			logger.info("Not an excel document.");
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
			
		if (workbook.getNumberOfSheets() == 0)
			throw new Exception("Workbook is empty.");
	
		Sheet s = workbook.getSheet(sheetName);
		
		if (s == null) {
			String nn = "";
			for (int i = 0; i < workbook.getNumberOfSheets(); ++i) {
				if (i == 0)
					nn += workbook.getSheetName(i);
				else
					nn += ", " + workbook.getSheetName(i);
			}
			throw new Exception("Cannot get sheet " + sheetName + " from this workbook. Available sheet names are " + nn);
		}
		
		// First row contains column names
		Row row = s.getRow(0);
		
		if (row == null)
			throw new Exception("Cannot get row 0 from sheet " + sheetName);
							
		// Get column names from first row
		int firstCol = row.getFirstCellNum();
		int lastCol = row.getLastCellNum();
		for (int i = firstCol; i < lastCol; ++i) {
			Cell cell = row.getCell(i, Row.RETURN_BLANK_AS_NULL);
			if (cell == null) {
				// Do not allow an empty column.
				break;
			}
			String cname = cell.toString();
			if (cname.length() == 0) {
				logger.debug("zero length column name in cell(0" + "," + i + "). Skipping the rest of the columns. ");
				break;
			}
			int col = rawData.addColumn(cname, null);
			logger.debug("adding column name[" + col + "]=" + cname);
//			System.out.println("adding column name[" + col + "]=" + cname);
		}
	
	  	// Loop over rows in this sheet
		int firstRow = s.getFirstRowNum();
		int lastRow = s.getLastRowNum();
		for (int i = firstRow+1; i <= lastRow; i++) {
		
			row = s.getRow(i);
			if (row == null)
				continue;
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
				logger.debug("Skipping row " + i + ". All cells are empty.");
				continue;
			}
			
			// Loop over columns in this row
			RowData rowData = rawData.newRow();
			for (int col = firstCol; col <= lastCol; ++col) {
				Cell cell = row.getCell(col, Row.RETURN_BLANK_AS_NULL);
				String colName = rawData.getColumnName(col);
				if (colName == null) {
					logger.warn("Column name " + col + " is null.");
//					if (i == 1)
//						System.out.println("Row = " + i + " column = " + col + " colName is null.");
					continue;
				}
				String value = "";
				if ((colName.length() > 0) && (cell != null) && (cell.getCellType() != Cell.CELL_TYPE_BLANK)) {
					switch (cell.getCellType()) {
					case Cell.CELL_TYPE_BOOLEAN:
						value = String.valueOf(cell.getBooleanCellValue());
						break;
					case Cell.CELL_TYPE_ERROR:
						value = String.valueOf(cell.getErrorCellValue());
						break;
					case Cell.CELL_TYPE_FORMULA:
						value = String.valueOf(cell.getCellFormula());
						break;
					case Cell.CELL_TYPE_NUMERIC:
						CellStyle style = cell.getCellStyle();
						// If cell type is Numeric, excel will save cell data as double.
						// If format type is General, number that has no decimal digit
						// will be displayed without decimal, for example, if entered value is 672983
						// it will be saved as 672983.0 and displayed as 672983.
						// This causes a problem for us if the column is mapped to a crystal property 
						// type text. For example, we should be able to get value 672983
						// from the cell but instead we will get 672983.0 from cell.getNumericCellValue().
						// So here remove the decimal points if they are all 0.
						if (style.getDataFormatString().equalsIgnoreCase("General")) {
							double doubleVal = cell.getNumericCellValue();
							double intVal = (int)cell.getNumericCellValue(); // Round it up.
							if (intVal == doubleVal) {
								// No decimal place
								value = String.valueOf((int)doubleVal);
							}
						} else {
							value = String.valueOf(cell.getNumericCellValue());
						}
						break;
					case Cell.CELL_TYPE_STRING:
					default:
						value = cell.toString().trim();
					}
					rowData.setCell(col, value);
//					if (i == 1)
//						System.out.println("Adding row = " + i + " col = " + col + " name = " + colName + " value = '" + value + "'");
				} else {
					rowData.setCell(col, null);
//					if (i == 1)
//						System.out.println("Adding row = " + i + " col = " + col + " name = " + colName + " value = NULL");
				}
			}
			logger.debug("Adding row to rawData numRows = " + rawData.getRowCount());
				
		}	
				
		return rawData;
	}
	
}
