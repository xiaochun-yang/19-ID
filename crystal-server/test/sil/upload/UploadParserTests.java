package sil.upload;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.odftoolkit.odfdom.doc.OdfSpreadsheetDocument;
import org.odftoolkit.odfdom.doc.office.OdfOfficeSpreadsheet;
import org.springframework.context.ApplicationContext;

import sil.upload.Excel2003Parser;
import sil.upload.RawData;
import sil.upload.UploadData;
import sil.upload.UploadParser;
import sil.AllTests;
import sil.TestData;

import junit.framework.TestCase;

public class UploadParserTests  extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private String baseDir = "WEB-INF/classes/sil/upload";
	
	public void testXssf() throws Exception {
		Workbook workbook = new XSSFWorkbook();
		Sheet sheet = workbook.createSheet("Sheet1");
		Row row = sheet.createRow(0);
		Cell cell = row.createCell(0); cell.setCellValue("ContainerID");
		cell = row.createCell(1); cell.setCellValue("Port");
		cell = row.createCell(2); cell.setCellValue("CrystalID");
		cell = row.createCell(3); cell.setCellValue("Directory");
		
		String firstChar = "ABCDEFGHIJKL";
		
		int a = 0;
		int b = 1;
		for (int i = 1; i < 97; ++i) {
			row = sheet.createRow(i);
			String text = firstChar.charAt(a) + String.valueOf(b);
			if (b >= 8) {
				b = 1;
				++a;
			} else {
				++b;
			}
			cell = row.createCell(0); cell.setCellValue("UNKNOWN");
			cell = row.createCell(1); cell.setCellValue(text);
			cell = row.createCell(2); cell.setCellValue(text);
			cell = row.createCell(3); cell.setCellValue(text);
		}
		
		String testFile = "/data/penjitk/tmp/out.xlsx";
		FileOutputStream out = new FileOutputStream(testFile);
		workbook.write(out);
		out.close();
		
		FileInputStream in = new FileInputStream(testFile);
		workbook = new XSSFWorkbook(in);
		
	}

	public void testExcel2003Parser()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (Excel2003Parser)ctx.getBean("excel2003Parser");
			
			String excelFile = baseDir + File.separator + "default_template.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
			RawData rawData = parser.parse(data);
			
			assertEquals(11, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("ContainerID", rawData.getColumnName(0));
			assertEquals("Port", rawData.getColumnName(1));
			assertEquals("CrystalID", rawData.getColumnName(2));
			assertEquals("Protein", rawData.getColumnName(3));
			assertEquals("Directory", rawData.getColumnName(4));
			assertEquals("Comment", rawData.getColumnName(5));
			assertEquals("FreezingCond", rawData.getColumnName(6));
			assertEquals("CrystalCond", rawData.getColumnName(7));
			assertEquals("Metal", rawData.getColumnName(8));
			assertEquals("Priority", rawData.getColumnName(9));
			assertEquals("Person", rawData.getColumnName(10));
			
			// Notice the misspelled UNK(N)OWN
			assertEquals("UNKOWN", rawData.getData(0, 0));
			assertEquals("A1", rawData.getData(0, 1));
			assertEquals("A1", rawData.getData(0, 2));
			assertNull(rawData.getData(0, 3));
			assertEquals("A1", rawData.getData(0, 4));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void testExcel2003ParserOtherSheetName()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (Excel2003Parser)ctx.getBean("excel2003Parser");
			
			String excelFile = baseDir + File.separator + "other_sheetname.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "My_Favourite_Crystals");
			RawData rawData = parser.parse(data);
			
			assertEquals(11, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("ContainerID", rawData.getColumnName(0));
			assertEquals("Port", rawData.getColumnName(1));
			assertEquals("CrystalID", rawData.getColumnName(2));
			assertEquals("Protein", rawData.getColumnName(3));
			assertEquals("Directory", rawData.getColumnName(4));
			assertEquals("Comment", rawData.getColumnName(5));
			assertEquals("FreezingCond", rawData.getColumnName(6));
			assertEquals("CrystalCond", rawData.getColumnName(7));
			assertEquals("Metal", rawData.getColumnName(8));
			assertEquals("Priority", rawData.getColumnName(9));
			assertEquals("Person", rawData.getColumnName(10));
			
			// Notice the misspelled UNK(N)OWN
			assertEquals("UNKOWN", rawData.getData(0, 0));
			assertEquals("A1", rawData.getData(0, 1));
			assertEquals("A1", rawData.getData(0, 2));
			assertNull(rawData.getData(0, 3));
			assertEquals("A1", rawData.getData(0, 4));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void testExcel2003ParserOtherSheetNameJcsg()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (Excel2003Parser)ctx.getBean("excel2003Parser");
			
			String excelFile = baseDir + File.separator + "jcsg_other_sheetname.xls";
			UploadData data = TestData.createUploadData(excelFile, "jcsg", "cassette", "MyFavouriteCrystals");
			RawData rawData = parser.parse(data);
			
			assertEquals(63, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("UniqueID", rawData.getColumnName(0));
			assertEquals("ShipDate", rawData.getColumnName(1));
			assertEquals("ShipmentID", rawData.getColumnName(2));
			assertEquals("ShipDewar", rawData.getColumnName(3));
			assertEquals("ShipDewarPosition", rawData.getColumnName(4));
			assertEquals("ShipCasette", rawData.getColumnName(5));
			assertEquals("ShipPosition", rawData.getColumnName(6));
			assertEquals("CurrentDewar", rawData.getColumnName(7));
			assertEquals("CurrentDewarPosition", rawData.getColumnName(8));
			assertEquals("CurrentCasette", rawData.getColumnName(9));
			assertEquals("CurrentPosition", rawData.getColumnName(10));
			assertEquals("NewDewar", rawData.getColumnName(11));
			
			// Notice the misspelled UNK(N)OWN
			assertEquals("131644", rawData.getData(0, 0));
			assertEquals("263294", rawData.getData(0, 23));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	// Row 97 (after L8) is empty but not null.
	public void testExcel2003ParserEmptyRow()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (Excel2003Parser)ctx.getBean("excel2003Parser");
			
			String excelFile = baseDir + File.separator + "has_empty_row.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
			RawData rawData = parser.parse(data);
			
			assertEquals(8, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("Port", rawData.getColumnName(0));
			assertEquals("CrystalID", rawData.getColumnName(1));
			assertEquals("Protein", rawData.getColumnName(2));
			assertEquals("Directory", rawData.getColumnName(3));
			assertEquals("comment", rawData.getColumnName(4));
			assertEquals("FreezingCond", rawData.getColumnName(5));
			assertEquals("CrystalCond", rawData.getColumnName(6));
			assertEquals("Person", rawData.getColumnName(7));
			
			assertEquals("A1", rawData.getData(0, 0));
			assertEquals("keith_A1", rawData.getData(0, 1));
			assertNull(rawData.getData(0, 2));
			assertEquals("ssrl_Nov09/keith/a1", rawData.getData(0, 3));
			assertNull(rawData.getData(0, 4));
			assertNull(rawData.getData(0, 5));
			assertNull(rawData.getData(0, 6));
			assertEquals("Keith", rawData.getData(0, 7));
			
			assertEquals("C5", rawData.getData(20, 0));
			assertEquals("anx2_ip2_C5", rawData.getData(20, 1));
			assertEquals("anxA2", rawData.getData(20, 2));
			assertEquals("ssrl_Nov09/anxA2/ip2/c5", rawData.getData(20, 3));
			assertEquals("cocrystallization, 12x molar excess", rawData.getData(20, 4));
			assertEquals("25% glycerol", rawData.getData(20, 5));
			assertEquals("20% PEG8000, 0.1M CaAcetate, 0.1M HEPES 6.5", rawData.getData(20, 6));
			assertEquals("Gabe", rawData.getData(20, 7));
			
			assertEquals("L8", rawData.getData(95, 0));
			assertEquals("", rawData.getData(95, 1));
			assertEquals("", rawData.getData(95, 2));
			assertEquals("", rawData.getData(95, 3));
			assertEquals("", rawData.getData(95, 4));
			assertEquals("", rawData.getData(95, 5));
			assertEquals("", rawData.getData(95, 6));
			assertEquals("", rawData.getData(95, 7));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void testPoiParser()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (PoiParser)ctx.getBean("poiParser");
			
			String excelFile = baseDir + File.separator + "default_template.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
			RawData rawData = parser.parse(data);
			
			assertEquals(11, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("ContainerID", rawData.getColumnName(0));
			assertEquals("Port", rawData.getColumnName(1));
			assertEquals("CrystalID", rawData.getColumnName(2));
			assertEquals("Protein", rawData.getColumnName(3));
			assertEquals("Directory", rawData.getColumnName(4));
			assertEquals("Comment", rawData.getColumnName(5));
			assertEquals("FreezingCond", rawData.getColumnName(6));
			assertEquals("CrystalCond", rawData.getColumnName(7));
			assertEquals("Metal", rawData.getColumnName(8));
			assertEquals("Priority", rawData.getColumnName(9));
			assertEquals("Person", rawData.getColumnName(10));
			
			// Notice the misspelled UNK(N)OWN
			assertEquals("UNKOWN", rawData.getData(0, 0));
			assertEquals("A1", rawData.getData(0, 1));
			assertEquals("A1", rawData.getData(0, 2));
			assertNull(rawData.getData(0, 3));
			assertEquals("A1", rawData.getData(0, 4));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void testPoiParserOtherSheetName()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (PoiParser)ctx.getBean("poiParser");
			
			String excelFile = baseDir + File.separator + "other_sheetname.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "My_Favourite_Crystals");
			RawData rawData = parser.parse(data);
			
			assertEquals(11, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("ContainerID", rawData.getColumnName(0));
			assertEquals("Port", rawData.getColumnName(1));
			assertEquals("CrystalID", rawData.getColumnName(2));
			assertEquals("Protein", rawData.getColumnName(3));
			assertEquals("Directory", rawData.getColumnName(4));
			assertEquals("Comment", rawData.getColumnName(5));
			assertEquals("FreezingCond", rawData.getColumnName(6));
			assertEquals("CrystalCond", rawData.getColumnName(7));
			assertEquals("Metal", rawData.getColumnName(8));
			assertEquals("Priority", rawData.getColumnName(9));
			assertEquals("Person", rawData.getColumnName(10));
			
			// Notice the misspelled UNK(N)OWN
			assertEquals("UNKOWN", rawData.getData(0, 0));
			assertEquals("A1", rawData.getData(0, 1));
			assertEquals("A1", rawData.getData(0, 2));
			assertNull(rawData.getData(0, 3));
			assertEquals("A1", rawData.getData(0, 4));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void testPoiParserLongSheetName()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (PoiParser)ctx.getBean("poiParser");
			
			String excelFile = baseDir + File.separator + "long_sheetname.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "My_big_bad_spreadsheet_for_SSRL");
			RawData rawData = parser.parse(data);
			
			assertEquals(11, rawData.getColumnCount());
			assertEquals(64, rawData.getRowCount());
			assertEquals("ContainerID", rawData.getColumnName(0));
			assertEquals("Port", rawData.getColumnName(1));
			assertEquals("CrystalID", rawData.getColumnName(2));
			assertEquals("Protein", rawData.getColumnName(3));
			assertEquals("Directory", rawData.getColumnName(4));
			assertEquals("Comment", rawData.getColumnName(5));
			assertEquals("FreezingCond", rawData.getColumnName(6));
			assertEquals("CrystalCond", rawData.getColumnName(7));
			assertEquals("Metal", rawData.getColumnName(8));
			assertEquals("Priority", rawData.getColumnName(9));
			assertEquals("Person", rawData.getColumnName(10));
			
			// Notice the misspelled UNK(N)OWN
			assertEquals("UNKOWN", rawData.getData(0, 0));
			assertEquals("A1", rawData.getData(0, 1));
			assertEquals("A1", rawData.getData(0, 2));
			assertNull(rawData.getData(0, 3));
			assertEquals("A1", rawData.getData(0, 4));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void testPoiParserSheetNameWithSpace()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (PoiParser)ctx.getBean("poiParser");
			
			String excelFile = baseDir + File.separator + "sheetname_with_space.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "My Favourite Crystals");
			RawData rawData = parser.parse(data);
			
			assertEquals(11, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("ContainerID", rawData.getColumnName(0));
			assertEquals("Port", rawData.getColumnName(1));
			assertEquals("CrystalID", rawData.getColumnName(2));
			assertEquals("Protein", rawData.getColumnName(3));
			assertEquals("Directory", rawData.getColumnName(4));
			assertEquals("Comment", rawData.getColumnName(5));
			assertEquals("FreezingCond", rawData.getColumnName(6));
			assertEquals("CrystalCond", rawData.getColumnName(7));
			assertEquals("Metal", rawData.getColumnName(8));
			assertEquals("Priority", rawData.getColumnName(9));
			assertEquals("Person", rawData.getColumnName(10));
			
			// Notice the misspelled UNK(N)OWN
			assertEquals("UNKOWN", rawData.getData(0, 0));
			assertEquals("A1", rawData.getData(0, 1));
			assertEquals("A1", rawData.getData(0, 2));
			assertNull(rawData.getData(0, 3));
			assertEquals("A1", rawData.getData(0, 4));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	// Row 97 (after L8) is empty but not null.
	public void testPoiParserEmptyRow()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (PoiParser)ctx.getBean("poiParser");
			
			String excelFile = baseDir + File.separator + "has_empty_row.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
			RawData rawData = parser.parse(data);
			
			assertEquals(8, rawData.getColumnCount());
			assertEquals(96, rawData.getRowCount());
			assertEquals("Port", rawData.getColumnName(0));
			assertEquals("CrystalID", rawData.getColumnName(1));
			assertEquals("Protein", rawData.getColumnName(2));
			assertEquals("Directory", rawData.getColumnName(3));
			assertEquals("comment", rawData.getColumnName(4));
			assertEquals("FreezingCond", rawData.getColumnName(5));
			assertEquals("CrystalCond", rawData.getColumnName(6));
			assertEquals("Person", rawData.getColumnName(7));
			
			assertEquals("A1", rawData.getData(0, 0));
			assertEquals("keith_A1", rawData.getData(0, 1));
			assertNull(rawData.getData(0, 2));
			assertEquals("ssrl_Nov09/keith/a1", rawData.getData(0, 3));
			assertNull(rawData.getData(0, 4));
			assertNull(rawData.getData(0, 5));
			assertNull(rawData.getData(0, 6));
			assertEquals("Keith", rawData.getData(0, 7));
			
			assertEquals("C5", rawData.getData(20, 0));
			assertEquals("anx2_ip2_C5", rawData.getData(20, 1));
			assertEquals("anxA2", rawData.getData(20, 2));
			assertEquals("ssrl_Nov09/anxA2/ip2/c5", rawData.getData(20, 3));
			assertEquals("cocrystallization, 12x molar excess", rawData.getData(20, 4));
			assertEquals("25% glycerol", rawData.getData(20, 5));
			assertEquals("20% PEG8000, 0.1M CaAcetate, 0.1M HEPES 6.5", rawData.getData(20, 6));
			assertEquals("Gabe", rawData.getData(20, 7));
			
			assertEquals("L8", rawData.getData(95, 0));
			assertNull(rawData.getData(95, 1));
			assertNull(rawData.getData(95, 2));
			assertNull(rawData.getData(95, 3));
			assertNull(rawData.getData(95, 4));
			assertNull(rawData.getData(95, 5));
			assertNull(rawData.getData(95, 6));
			assertNull(rawData.getData(95, 7));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	// Row 86 is null.
	public void testPoiParserHasNullRow()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (PoiParser)ctx.getBean("poiParser");
			
			String excelFile = baseDir + File.separator + "has_null_row.xls";
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "puck", "Sheet1");
			// should not throw an exception.
			RawData rawData = parser.parse(data);
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}

	
	public void testPoiParserXlsx() throws Exception {
		
		File dir = new File("/home/penjitk/workspace/crystal-server/data/examples/xlsx");
		String[] files = dir.list();
		for (int i = 0; i < files.length; ++i) {
			
			String excelFile = dir.getPath() + "/" + files[i];
			if (excelFile.indexOf(".xlsx") < 0) {
				System.out.println("Skipping file " + excelFile);
				continue;
			}
			ApplicationContext ctx = AllTests.getApplicationContext();
			UploadParser parser = (UploadParser)ctx.getBean("poiParser");
				
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
			RawData rawData = parser.parse(data);
			if (rawData == null)
				fail(excelFile + " not an xlsx file");
		}		
	}
	
	public void ttestOdfParseSxc() {
		
		File dir = new File("/home/penjitk/workspace/crystal-server/data/examples/sxc");
		String[] files = dir.list();
		for (int i = 0; i < files.length; ++i) {
			
			String excelFile = dir.getPath() + "/" + files[i];
			if (excelFile.indexOf(".sxc") < 0) {
				System.out.println("Skipping file " + excelFile);
				continue;
			}
			try {
				OdfSpreadsheetDocument doc = null;		
				OdfOfficeSpreadsheet workbook = null;
				System.out.println("Parsing file: " + excelFile);
				doc = (OdfSpreadsheetDocument)OdfSpreadsheetDocument.loadDocument(excelFile);
				workbook = doc.getContentRoot();
			} catch (Exception e) {
				e.printStackTrace();
				fail("file = " + excelFile + " error = " + e.getMessage());
			}
		}		
	}
	
}
