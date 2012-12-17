package sil.io;

import java.io.File;
import java.io.OutputStream;
import java.net.URL;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
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
import jxl.Workbook;
import jxl.format.Alignment;
import jxl.write.Label;
import jxl.write.WritableCellFormat;
import jxl.write.WritableFont;
import jxl.write.WritableHyperlink;
import jxl.write.WritableSheet;
import jxl.write.WritableWorkbook;

public class SilExcelWriter implements SilWriter, InitializingBean
{
	protected final Log logger = LogFactoryImpl.getLog(getClass()); 
	private SilFactory silFactory = null;
	private String columnFile = null;
	private List<ColumnData> columns = null;
	private CrystalSortTool crystalSortTool = null;

	public void afterPropertiesSet() throws Exception {
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for SilExcelWriter bean.");
		if (columnFile == null)
			throw new BeanCreationException("Must set 'columnNameFile' property for SilExcelWriter bean.");
		if (crystalSortTool == null)
			throw new BeanCreationException("Must set 'crystalSortTool' property for SilExcelWriter bean.");
		File file = silFactory.getTemplateFile(columnFile);
		if (!file.exists())
			throw new BeanCreationException("'columnFile' " + file.getAbsolutePath() + " not found.");
		columns = ColumnLoader.load(file);
	}

	public void write(OutputStream out, Sil sil)
		throws Exception 
	{
    	// Write all rows
    	List<Crystal> crystals = SilUtil.getCrystals(sil);
    	Collection sortedCrystal = crystalSortTool.sort(crystals, "row");
    	write(out, sil, crystals);
	}
	
	public void write(OutputStream out, Sil sil, int[] rows)
		throws Exception 
	{
		List<Crystal> crystals = SilUtil.getCrystals(sil, rows);
		write(out, sil, crystals);
	}
	
	public void write(OutputStream out, Sil sil, CrystalCollection crystalCol)
		throws Exception 
	{
		Collection crystals = SilUtil.getCrystalsFromCrystalCollection(sil, crystalCol);
		write(out, sil, crystals);
	}
	
	public void write(OutputStream out, Sil sil, Collection crystals)
		throws Exception 
	{
		WritableWorkbook workbook = Workbook.createWorkbook(out);
		WritableSheet sheet = workbook.createSheet("Sheet1", 0);		
	
		WritableFont font = new WritableFont(WritableFont.ARIAL);
	    font.setBoldStyle(WritableFont.BOLD);
	    WritableCellFormat headerFormat = new WritableCellFormat(font);
	    headerFormat.setWrap(true);
	    headerFormat.setAlignment(Alignment.CENTRE);
	    	
	    // Get the column headers
	    // and put them in the first row of the spreadsheet.
	    int row = 0;
	    int col = 0;
		Iterator it = columns.iterator();
 	    while (it.hasNext()) {
	    	ColumnData colData = (ColumnData)it.next();
			sheet.addCell(new Label(col, row, colData.getName(), headerFormat)); ++col;
		}
	    ++row;
		
	    WritableCellFormat cellFormat = new WritableCellFormat();
	    cellFormat.setWrap(true);
	
	    it = crystals.iterator();
    	while (it.hasNext()) {
    		Crystal crystal = (Crystal)it.next();
			writeCell(crystal, sheet, cellFormat, row);
			++row;
    	}
    	workbook.write();
		workbook.close();
	}
	
	private void writeCell(Crystal crystal, WritableSheet sheet, WritableCellFormat format, int row)
		throws Exception
	{
		if (crystal == null)
			return;
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
	    	if ((colName.indexOf("URL") < 0) || (propVal.length() == 0)) {
	    		sheet.addCell(new Label(col, row, propVal, format));
	    	} else {
	    		WritableHyperlink link = new WritableHyperlink(col, row, new URL(propVal));
				sheet.addHyperlink(link);
	    	}
	    	++col;
		}
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

	public CrystalSortTool getCrystalSortTool() {
		return crystalSortTool;
	}

	public void setCrystalSortTool(CrystalSortTool crystalSortTool) {
		this.crystalSortTool = crystalSortTool;
	}


}
