package sil.io;

import java.io.File;
import java.io.OutputStream;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

import jxl.write.WritableCellFormat;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Hyperlink;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.NotReadablePropertyException;
import org.springframework.beans.NullValueInNestedPathException;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import sil.beans.ColumnData;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.CrystalCollection;
import sil.beans.util.CrystalSortTool;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.SilUtil;
import sil.factory.SilFactory;

public class SilXlsxWriter implements SilWriter, InitializingBean {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass()); 
	private SilFactory silFactory = null;
	private String columnFile = null;
	private List<ColumnData> columns = null;
	private CrystalSortTool crystalSortTool = null;

	public void write(OutputStream out, Sil sil) throws Exception {
    	List<Crystal> crystals = SilUtil.getCrystals(sil);
    	Collection sortedCrystal = crystalSortTool.sort(crystals, "row");
    	write(out, sil, crystals);	
	}

	public void write(OutputStream out, Sil sil, int[] rows) throws Exception {
		List<Crystal> crystals = SilUtil.getCrystals(sil, rows);
		write(out, sil, crystals);
	}

	public void write(OutputStream out, Sil sil, CrystalCollection crystalCol)
			throws Exception {
		Collection crystals = SilUtil.getCrystalsFromCrystalCollection(sil, crystalCol);
		write(out, sil, crystals);
	}
	
	private void write(OutputStream out, Sil sil, Collection crystals) throws Exception {
		
        Workbook wb = new XSSFWorkbook(); //or new HSSFWorkbook();
        CreationHelper creationHelper = wb.getCreationHelper();
        Sheet sheet = wb.createSheet("Sheet1");

	    // Get the column headers
	    // and put them in the first row of the spreadsheet.
	    int rowNum = 0;
	    int colNum = 0;
	    
        CellStyle cellStyle = wb.createCellStyle();
        cellStyle.setAlignment(XSSFCellStyle.ALIGN_CENTER);
        cellStyle.setVerticalAlignment(XSSFCellStyle.VERTICAL_CENTER);
       
        Row row = sheet.createRow((short)rowNum);
		Iterator it = columns.iterator();
 	    while (it.hasNext()) {
	    	ColumnData colData = (ColumnData)it.next();
	        Cell cell = row.createCell((short)colNum);
	        cell.setCellValue(colData.getName());
	        cell.setCellStyle(cellStyle);
	        ++colNum;
		}
	    ++rowNum;
		
	    WritableCellFormat cellFormat = new WritableCellFormat();
	    cellFormat.setWrap(true);
	
	    it = crystals.iterator();
    	while (it.hasNext()) {
    		Crystal crystal = (Crystal)it.next();
			writeCrystal(crystal, row, cellStyle);
			++rowNum;
    	}
    	
    	wb.write(out);
    	out.close();
	}
	
	private void writeCrystal(Crystal crystal, Row row, CellStyle style)
		throws Exception
	{
		if (crystal == null)
			return;
		
		Workbook wb = row.getSheet().getWorkbook();
		CreationHelper creationHelper = wb.getCreationHelper();
		
        CellStyle cellStyle = wb.createCellStyle();
        cellStyle.setAlignment(XSSFCellStyle.ALIGN_CENTER);
        cellStyle.setVerticalAlignment(XSSFCellStyle.VERTICAL_CENTER);
        
        CellStyle hlink_style = wb.createCellStyle();
        Font hlink_font = wb.createFont();
        hlink_font.setUnderline(Font.U_SINGLE);
        hlink_font.setColor(IndexedColors.BLUE.getIndex());
        hlink_style.setFont(hlink_font);

        
		CrystalWrapper wrapper = getSilFactory().createCrystalWrapper(crystal);
		Iterator<ColumnData> it = columns.iterator();
		int col = 0;
	    while (it.hasNext()) {
	    	ColumnData colData = it.next();
	    	String colName = colData.getName();
	    	String propVal = "";
	    	try {
	    		Object prop = wrapper.getPropertyValue(colName);
	    		if (prop != null)
	    			propVal = prop.toString();
	    	} catch (NullValueInNestedPathException e) {
	    		logger.debug(e.getMessage());
	    	} catch (NotReadablePropertyException e) {
	    		logger.debug(e.getMessage());
	    	}
	    	Cell cell = row.createCell((short)col);
	    	String format = colData.getFormat();
	    	System.out.println("colName = " + colName + " format = " + format + " value = " + propVal);
	    	if (propVal != null) {
	    		if (format.equals("int")) {
	    			try {
	    				cell.setCellValue(Integer.parseInt(propVal));
	    			} catch (NumberFormatException e) {
	    				// Ignore
	    			}
	    		} else if (format.equals("double")) {
	    			try {
	    				cell.setCellValue(Double.parseDouble(propVal));
	    			} catch (NumberFormatException e) {
	    				// Ignore
	    			}
	    		} else if (format.equals("url")) {
	    			Hyperlink link = creationHelper.createHyperlink(Hyperlink.LINK_URL);
	    			link.setAddress(propVal);
	    			cell.setHyperlink(link);
	            	cell.setCellStyle(hlink_style);
	    		} else {
	    			cell.setCellValue(propVal);
	    			cell.setCellStyle(cellStyle);
	    		}
	    	}
	    	++col;
		}
	}
	
	public void afterPropertiesSet() throws Exception {
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for SilXlsxWriter bean.");
		if (columnFile == null)
			throw new BeanCreationException("Must set 'columnNameFile' property for SilXlsxWriter bean.");
		if (crystalSortTool == null)
			throw new BeanCreationException("Must set 'crystalSortTool' property for SilXlsxWriter bean.");
		File file = silFactory.getTemplateFile(columnFile);
		if (!file.exists())
			throw new BeanCreationException("'columnFile' " + file.getAbsolutePath() + " not found.");
		columns = ColumnLoader.load(file);
	}

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

	public List<ColumnData> getColumns() {
		return columns;
	}

	public void setColumns(List<ColumnData> columns) {
		this.columns = columns;
	}

	public CrystalSortTool getCrystalSortTool() {
		return crystalSortTool;
	}

	public void setCrystalSortTool(CrystalSortTool crystalSortTool) {
		this.crystalSortTool = crystalSortTool;
	}

}
