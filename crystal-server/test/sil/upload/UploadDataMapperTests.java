package sil.upload;

import sil.AllTests;
import sil.TestData;

import java.util.ArrayList;
import java.util.Properties;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;

public class UploadDataMapperTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
		
	// Test mapping logic but use simple static mapping from Properties
	// instead of loading from template files.
	public void testSimplePropertiesMapper()
	{
		try {
			logger.debug("START testSimplePropertiesMapper");
						
			RawData rawData = new RawData();
			rawData.addColumn("column1");  // port
			rawData.addColumn("uniqueId"); // crystalId
			rawData.addColumn("column2"); // crystalId
			rawData.addColumn("column3"); // directory
			rawData.addColumn("protein");
			rawData.addColumn("userData");
			rawData.addColumn("containerID");
			rawData.addColumn("mosaicity");
			rawData.addColumn("iSigma");
			rawData.addColumn("images[1].path");
			rawData.addColumn("images[1].group");
			rawData.addColumn("images[1].iceRing");
			rawData.addColumn("images[1].jpeg");
			rawData.addColumn("images[1].score");
			rawData.addColumn("images[2].path");
			rawData.addColumn("images[2].group");
			rawData.addColumn("images[2].iceRing");
			rawData.addColumn("images[2].jpeg");
			rawData.addColumn("column17"); // images[2].score
		
			// Crystal 1
			RowData rowData1 = rawData.newRow();
			UploadTestUtil.setRowData1(rowData1);
			
			// Crystal 2
			RowData rowData2 = rawData.newRow();
			UploadTestUtil.setRowData2(rowData2);
			
			Properties props = new Properties();
			props.setProperty("column1", "port");
			props.setProperty("column17", "images[2].score");
			
			String templateName = "simple";
			SimplePropertiesMapper mapper = new SimplePropertiesMapper();
			mapper.setTemplate(templateName, props);
			ArrayList<String> warnings = new ArrayList<String>();
			RawData newRawData = mapper.applyTemplate(rawData, templateName, warnings);
			if (newRawData == null)
				throw new Exception("Template test is not supported.");
			
			TestData.printWarnings(warnings);
			
//			UploadTestUtil.debugRawData(rmapper_test.propertiesawData);
			
			// Mapped columns
			assertTrue(rawData.hasColumnName("column1"));
			assertTrue(newRawData.hasColumnName("port"));
			assertEquals(rawData.getData(0, "column1"), "A1");
			assertEquals(newRawData.getData(0, "port"), "A1");
			assertEquals(rawData.getData(1, "column1"), "A2");
			assertEquals(newRawData.getData(1, "port"), "A2");
			
			assertEquals(rawData.getData(0, "column17"), "0.975");
			assertEquals(newRawData.getData(0, "images[2].score"), "0.975");
			assertEquals(rawData.getData(1, "column17"), "0.916");
			assertEquals(newRawData.getData(1, "images[2].score"), "0.916");
			
			// Unmapped columns
			assertTrue(rawData.hasColumnName("column2"));
			assertFalse(newRawData.hasColumnName("crystalId"));
			assertEquals(rawData.getData(0, "column2"), "myo1");
			assertNull(newRawData.getData(0, "crystalId"));
			
			logger.debug("FINISH testSimplePropertiesMapper");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}

	// Test properties mapping by getting mapping from a template file
	// from template dir.
	public void testSsrlPropertiesMapper1()
	{
		try {
			logger.debug("START testSsrlPropertiesMapper1");
			
			ApplicationContext ctx = AllTests.getApplicationContext();

			RawData rawData = new RawData();
			rawData.addColumn("Port");  // port
			rawData.addColumn("CrystalID"); // crystalId
			rawData.addColumn("Directory"); // directory
			rawData.addColumn("Images");
			rawData.addColumn("UserData");
		
			// Crystal 1
			RowData rowData1 = rawData.newRow();
			rowData1.setCell(0, "A1");
			rowData1.setCell(1, "myo1");
			rowData1.setCell(2, "/data/penjitk/myo1");
			rowData1.setCell(3, "/data/penjitk/myo1/myo1_001.img /data/penjitk/myo1/myo1_002.img");
			rowData1.setCell(4, "my data 1");
			
			// Crystal 2
			RowData rowData2 = rawData.newRow();
			rowData2.setCell(0, "A2");
			rowData2.setCell(1, "myo2");
			rowData2.setCell(2, "/data/penjitk/myo2");
			rowData2.setCell(3, "/data/penjitk/myo2/myo2_001.img /data/penjitk/myo2/myo2_002.img");
			rowData2.setCell(4, "my data 2");

			String templateName = "ssrl";
			BasePropertiesMapper mapper = (BasePropertiesMapper)ctx.getBean("propertiesMapper");
			ArrayList<String> warnings = new ArrayList<String>();
			RawData newRawData = mapper.applyTemplate(rawData, templateName, warnings);
			if (newRawData == null)
				throw new Exception("Template " + templateName + " is not supported.");
			
			TestData.printWarnings(warnings);
			
			// Mapped columns in ssrl.properties
			assertTrue(rawData.hasColumnName("Port"));
			assertTrue(newRawData.hasColumnName("port"));
			assertEquals(rawData.getData(0, "Port"), "A1");
			assertEquals(newRawData.getData(0, "port"), "A1");
			assertEquals(rawData.getData(1, "Port"), "A2");
			assertEquals(newRawData.getData(1, "port"), "A2");
			
			// Unmapped columns
			assertTrue(rawData.hasColumnName("UserData"));
			assertFalse(newRawData.hasColumnName("UserData"));
			assertEquals(rawData.getData(0, "UserData"), "my data 1");
			assertNull(newRawData.getData(0, "UserData"));
			
			assertTrue(rawData.hasColumnName("Images"));
			assertFalse(newRawData.hasColumnName("Images"));
			assertEquals(rawData.getData(0, "Images"), "/data/penjitk/myo1/myo1_001.img /data/penjitk/myo1/myo1_002.img");
			assertNull(newRawData.getData(0, "Images"));
			
			logger.debug("FINISH testSsrlPropertiesMapper1");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}

	// Test properties mapping by getting mapping from a template file
	// from template dir.
	public void testSsrlPropertiesMapper()
	{
		try {
			logger.debug("START testSsrlPropertiesMapper");
			
			ApplicationContext ctx = AllTests.getApplicationContext();

			RawData rawData = new RawData();
			rawData.addColumn("Port");  // port
			rawData.addColumn("uniqueId"); 
			rawData.addColumn("CRYSTALID"); // crystalId
			rawData.addColumn("Directory"); // directory
			rawData.addColumn("Protein");
			rawData.addColumn("UserData");
			rawData.addColumn("ContainerID");
			rawData.addColumn("Mosaicity");
			rawData.addColumn("ISigma");
			rawData.addColumn("Path1"); 
			rawData.addColumn("Group1");
			rawData.addColumn("IceRings1");
			rawData.addColumn("Jpeg1");
			rawData.addColumn("Score1");
			rawData.addColumn("Path2");
			rawData.addColumn("Group2");
			rawData.addColumn("IceRings2");
			rawData.addColumn("Jpeg2");
			rawData.addColumn("Score2"); // images[2].result.spotfinderResult.score
		
			// Crystal 1
			RowData rowData1 = rawData.newRow();
			UploadTestUtil.setRowData1(rowData1);
			
			// Crystal 2
			RowData rowData2 = rawData.newRow();
			UploadTestUtil.setRowData2(rowData2);

			String templateName = "ssrl";
			BasePropertiesMapper mapper = (BasePropertiesMapper)ctx.getBean("propertiesMapper");
			ArrayList<String> warnings = new ArrayList<String>();
			RawData newRawData = mapper.applyTemplate(rawData, templateName, warnings);
			if (newRawData == null)
				throw new Exception("Template " + templateName + " is not supported.");
			
			TestData.printWarnings(warnings);
			
			// Mapped columns in ssrl.properties
			assertTrue(rawData.hasColumnName("Port"));
			assertTrue(newRawData.hasColumnName("port"));
			assertEquals(rawData.getData(0, "Port"), "A1");
			assertEquals(newRawData.getData(0, "port"), "A1");
			assertEquals(rawData.getData(1, "Port"), "A2");
			assertEquals(newRawData.getData(1, "port"), "A2");
			
			assertEquals(rawData.getData(0, "Score2"), "0.975");
			assertEquals(newRawData.getData(0, "images[2].result.spotfinderResult.score"), "0.975");
			assertEquals(rawData.getData(1, "Score2"), "0.916");
			assertEquals(newRawData.getData(1, "images[2].result.spotfinderResult.score"), "0.916");
			
			// Unmapped columns
			assertTrue(rawData.hasColumnName("UserData"));
			assertFalse(newRawData.hasColumnName("UserData"));
			assertEquals(rawData.getData(0, "UserData"), "my data 1");
			assertNull(newRawData.getData(0, "UserData"));
			
			logger.debug("FINISH testSsrlPropertiesMapper");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}
	
	// Test properties mapping by getting mapping from a template file
	// from template dir.
	public void testJcsgMapper()
	{
		try {
			logger.debug("START testJcsgMapper");
			
			ApplicationContext ctx = AllTests.getApplicationContext();

			RawData rawData = new RawData();
			rawData.addColumn("CurrentPosition");  // port
			rawData.addColumn("XtalID"); // crystalId
			rawData.addColumn("Directory"); // directory
			rawData.addColumn("AccessionID"); // protein
			rawData.addColumn("CCRemarks"); //Comment
			rawData.addColumn("CurrentCasette"); // containerId
			rawData.addColumn("Cryo"); // freezingCond
			rawData.addColumn("CrystalConditions"); // crystalCond
			rawData.addColumn("SelMetOrNative"); // metal
			rawData.addColumn("PRIScore"); // priority
			rawData.addColumn("CrystalURL"); // crystalUrl
			rawData.addColumn("UserData"); 
					
			// Crystal 1
			RowData rowData1 = rawData.newRow();
			int i = 0;
			rowData1.setCell(i, "A1"); ++i;
			rowData1.setCell(i, "myo1"); ++i;
			rowData1.setCell(i, "/data/penjitk/myo1"); ++i;
			rowData1.setCell(i, "myoglobin"); ++i;
			rowData1.setCell(i, "good crystal"); ++i;
			rowData1.setCell(i, "SSRL1008"); ++i;
			rowData1.setCell(i, "-20.5"); ++i;
			rowData1.setCell(i, "small crystal"); ++i;
			rowData1.setCell(i, "Se"); ++i;
			rowData1.setCell(i, "10"); ++i;
			rowData1.setCell(i, "http://smb.slac.stanford.edu/myo/myo1.html"); ++i;
			rowData1.setCell(i, "my data 1"); ++i;
			
			// Crystal 2
			// Crystal 1
			RowData rowData2 = rawData.newRow();
			i = 0;
			rowData2.setCell(i, "A2"); ++i;
			rowData2.setCell(i, "myo2"); ++i;
			rowData2.setCell(i, "/data/penjitk/myo2"); ++i;
			rowData2.setCell(i, "myoglobin"); ++i;
			rowData2.setCell(i, "has ice"); ++i;
			rowData2.setCell(i, "SSRL1008"); ++i;
			rowData2.setCell(i, "-21.5"); ++i;
			rowData2.setCell(i, "medium crystal"); ++i;
			rowData2.setCell(i, "Fe"); ++i;
			rowData2.setCell(i, "5"); ++i;
			rowData2.setCell(i, "http://smb.slac.stanford.edu/myo/myo2.html"); ++i;
			rowData2.setCell(i, "my data 2");

			String templateName = "jcsg";
			JcsgMapper mapper = (JcsgMapper)ctx.getBean("jcsgMapper");
			ArrayList<String> warnings = new ArrayList<String>();
			RawData newRawData = mapper.applyTemplate(rawData, templateName, warnings);
			if (newRawData == null)
				throw new Exception("Template " + templateName + " is not supported.");
			
			TestData.printWarnings(warnings);
			
//			UploadTestUtil.debugRawData(rawData);
			assertTrue(rawData.hasColumnName("CurrentPosition"));
			assertTrue(newRawData.hasColumnName("port"));
			assertEquals(rawData.getData(0, "CurrentPosition"), "A1");
			assertEquals(newRawData.getData(0, "port"), "A1");
			assertEquals(rawData.getData(1, "CurrentPosition"), "A2");
			assertEquals(newRawData.getData(1, "port"), "A2");
			
			assertEquals(rawData.getData(0, "XtalID"), "myo1");
			assertEquals(newRawData.getData(0, "crystalId"), "myo1");
			assertEquals(rawData.getData(1, "XtalID"), "myo2");
			assertEquals(newRawData.getData(1, "crystalId"), "myo2");
			
			assertTrue(rawData.hasColumnName("UserData"));
			assertFalse(newRawData.hasColumnName("UserData"));
			assertEquals(rawData.getData(0, "UserData"), "my data 1");
			assertNull(newRawData.getData(0, "UserData"));
			
			logger.debug("FINISH testJcsgMapper");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}
}