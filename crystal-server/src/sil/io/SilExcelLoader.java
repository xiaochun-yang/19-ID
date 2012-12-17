package sil.io;
 
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Hashtable;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import jxl.Cell;
import jxl.CellType;
import jxl.Sheet;
import jxl.Workbook;

import sil.beans.ColumnData;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.CrystalWrapper;
import sil.factory.SilFactory;
import sil.beans.util.SilUtil;

public class SilExcelLoader implements SilLoader, InitializingBean {

	protected final Log logger = LogFactoryImpl.getLog(getClass());
	protected String sheetName = "Sheet1";
	private SilFactory silFactory = null;
	private String columnFile = null;
	private List<ColumnData> columns = null;

	public SilFactory getSilFactory() {
		return silFactory;
	}
	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}
	public String getColumnFile() {
		return columnFile;
	}
	public void setColumnFile(String columnFile) {
		this.columnFile = columnFile;
	}

	public void afterPropertiesSet() throws Exception {
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for SilExcelLoader bean.");
		if (columnFile == null)
			throw new BeanCreationException("Must set 'columnNameFile' property for SilExcelLoader bean.");
		File file = silFactory.getTemplateFile(columnFile);
		if (!file.exists())
			throw new BeanCreationException("'columnFile' " + file.getAbsolutePath() + " not found.");
		columns = ColumnLoader.load(file);
	}
	
	public Sil load(String path) throws Exception {
		
/*		File excelFile = new File(path);
		if (excelFile == null)
			throw new Exception("Empty excel file " + path);
		
		FileInputStream in = new FileInputStream(excelFile);
				
		Workbook workbook = null;
		try {		
			workbook = Workbook.getWorkbook(in);
		} catch (Exception e) {
			logger.info("Not an excel2003 document.");
			logger.debug(e.getMessage());
			return null;
		}
		
		return createSil(workbook);*/
		
		File excelFile = new File(path);
		if (excelFile == null)
			throw new Exception("Empty excel file " + path);
		return load(new FileInputStream(excelFile));

	}
	
	public Sil load(InputStream in) throws Exception {
		Workbook workbook = null;
		try {		
			workbook = Workbook.getWorkbook(in);
		} catch (Exception e) {
			logger.info("Not an excel2003 document.");
			logger.debug(e.getMessage());
			return null;
		}
		
		return createSil(workbook);
	}

	
	private Sil createSil(Workbook workbook) throws Exception {	
					
		String[] sheetNames = workbook.getSheetNames();
		if ((sheetNames == null) || (sheetNames.length == 0))
			throw new Exception("Spreadsheet is empty.");
		
		Sil sil = new Sil();
		
		// Use first sheet if sheetName is not specified.
		if ((sheetName == null) || (sheetName.length() == 0))
			sheetName = sheetNames[0];
	
		Sheet s = workbook.getSheet(sheetName);
		
		if (s == null)
			throw new Exception("Cannot get sheet " + sheetName + " from this workbook");
			      
		// First row contains column names
		Cell firstRowCells[] = s.getRow(0);
		
		// Create a lookup table where a key is a crystal property
		// and a value is the column index.
		Map<String, Integer> lookup = new Hashtable<String, Integer>();
		Iterator<ColumnData> it = columns.iterator();
		while (it.hasNext()) {
			String name = it.next().getName();
			for (int col = 0; col < firstRowCells.length ; col++) {
				Cell cell = firstRowCells[col];
				if (cell == null)
					continue;
				String colName = cell.getContents();
				if ((colName == null) || (colName.length() < 1))
					continue;
				if (name.equals(colName)) {
					lookup.put(name, new Integer(col));
					break;
				}
			}
		}
	  	// Loop over rows in this sheet
		for (int i = 1; i < s.getRows() ; i++) {
			
			Cell cells[] = s.getRow(i);	
			Crystal crystal = new Crystal();
			crystal.setRow(i-1);
			crystal.setExcelRow(i);
			CrystalWrapper wrapper = getSilFactory().createCrystalWrapper(crystal);
			
			// Loop over crystal properties
			Iterator<String> it1 = lookup.keySet().iterator();
			while (it1.hasNext()) {
				String colName = it1.next();
				int col = lookup.get(colName).intValue();
				if ((col < 0) || (col >= cells.length)) {
					logger.warn("Row " + i + " does not contain column " + colName + " in column " + col);
					continue;
				}
				Cell cell = cells[col];
							
				if (cell == null) {
					logger.warn("Data in column " + col + " is null in workbook.");
					continue;
				}

				if (cell.getType() != CellType.EMPTY) {
					String contents = cell.getContents();
					if ((contents != null) && (contents.length() > 0))
						wrapper.setPropertyValue(colName, contents);
				}
			}
			SilUtil.addCrystal(sil, crystal);
				
		}	
		
		return sil;
	}
}
