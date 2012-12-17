package sil.io;

import sil.beans.Sil;
import sil.io.SilWriter;
import sil.AllTests;
import sil.TestData;

import java.io.FileInputStream;
import java.io.FileOutputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;

public class SilXlsxWriterTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private String baseDir = "WEB-INF/classes/sil/io";
	
	public void testExcelWriter() throws Exception
	{	
			
			Sil sil = TestData.createSimpleSil();
					
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilWriter writer = (SilWriter)ctx.getBean("silXlsxWriter");
		
			String outFile = baseDir + "/out.xlsx";
			FileOutputStream out = new FileOutputStream(outFile);
			writer.write(out, sil);
			
			FileInputStream in = new FileInputStream(outFile);
			
			Workbook workbook = new XSSFWorkbook(in);
			Sheet s = workbook.getSheet("Sheet1");				
			if (s == null)
				throw new Exception("Cannot get sheet Sheet1 from this workbook");

			// First row contains column names
/*			Cell firstRowCells[] = s.getRow(0);
			
			// Create a lookup table where a key is a crystal property
			// and a value is the column index.
			Map<String, Integer> lookup = new Hashtable<String, Integer>();
			for (int i = 0; i < firstRowCells.length; ++i) {
				Cell cell = firstRowCells[i];
				String colName = cell.getContents();
			}			*/
		
	}
}