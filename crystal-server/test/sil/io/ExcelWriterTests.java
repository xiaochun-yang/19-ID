package sil.io;

import sil.beans.Sil;
import sil.io.SilWriter;
import sil.AllTests;
import sil.TestData;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Hashtable;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;
import jxl.Cell;
import jxl.Sheet;
import jxl.Workbook;

public class ExcelWriterTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private String baseDir = "WEB-INF/classes/sil/io";
	
	public void testExcelWriter() throws Exception
	{	
			
			Sil sil = TestData.createSimpleSil();
					
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilWriter writer = (SilWriter)ctx.getBean("silExcelWriter");
		
			String outFile = baseDir + "/out.xls";
			FileOutputStream out = new FileOutputStream(outFile);
			writer.write(out, sil);
			
			FileInputStream in = new FileInputStream(outFile);
			
			Workbook workbook = Workbook.getWorkbook(in);
			Sheet s = workbook.getSheet("Sheet1");				
			if (s == null)
				throw new Exception("Cannot get sheet Sheet1 from this workbook");

			// First row contains column names
			Cell firstRowCells[] = s.getRow(0);
			
			// Create a lookup table where a key is a crystal property
			// and a value is the column index.
			Map<String, Integer> lookup = new Hashtable<String, Integer>();
			for (int i = 0; i < firstRowCells.length; ++i) {
				Cell cell = firstRowCells[i];
				String colName = cell.getContents();
			}			
		
	}
}