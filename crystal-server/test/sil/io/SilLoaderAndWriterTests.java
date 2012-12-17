package sil.io;

import java.beans.XMLEncoder;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;
import sil.io.SilLoader;
import sil.managers.SilStorageManager;
import sil.AllTests;
import sil.SilTestCase;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import org.springframework.context.ApplicationContext;

public class SilLoaderAndWriterTests extends SilTestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public void testSilBeanLoader() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();

		int silId = 1;
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilInfo info = storageManager.getSilInfo(silId);
		String path = storageManager.getSilFilePath(info);
		
		SilLoader silLoader = (SilLoader)ctx.getBean("silBeanLoader");
		Sil sil = silLoader.load(path);		
		
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertNotNull(crystal);
		assertEquals("A1", crystal.getCrystalId());
		
		crystal = SilUtil.getCrystalFromRow(sil, 95);
		assertNotNull(crystal);
		assertEquals("L8", crystal.getCrystalId());
				
	}
		
	// This test shows that Collections.synchronizedList
	// does written out by XMLEncoder. Use ArrayList or
	// Vector (thread safe) instead.
	public void testXMLEncoder() throws Exception {
		XMLEncoderTestData data = new XMLEncoderTestData();
		data.addToList1("Hello");
		data.addToList2("Goodbye");
		data.addToList3("See you again soon");
		
		XMLEncoder encoder = new XMLEncoder(System.out);
		encoder.writeObject(data);
		encoder.close();
	}
	
	public void testSilBeanWriter() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();

		Sil sil = new Sil();
		sil.setId(1);
		Crystal crystal = new Crystal();
		crystal.setUniqueId(10000);
		crystal.setRow(0);
		crystal.setPort("A1");
		crystal.setCrystalId("A1");
		
		RepositionData data = new RepositionData();
		data.setLabel("repos0");
		data.setBeamSizeX(0.1);
		data.setBeamSizeY(0.2);
		CrystalUtil.addDefaultRepositionData(crystal, data);
		
		RunDefinition run = new RunDefinition();
		run.setRepositionId(0);
		run.setRunLabel(100);
		run.setStartAngle(15.0);
		run.setEndAngle(205.0);
		CrystalUtil.addRunDefinition(crystal, run);
		Image image1 = new Image();
		image1.setName("test_001.img");
		image1.setDir("/data/penjitk/img");
		image1.setGroup("1");
		CrystalUtil.addImage(crystal, image1);
		
		SilUtil.addCrystal(sil, crystal);
		
		crystal = sil.getCrystals().get((long)10000);
		assertEquals(1, crystal.getResult().getRuns().size());
		
		SilWriter writer = (SilWriter)ctx.getBean("silBeanWriter");
		writer.write(System.out, sil);
		System.out.flush();		
	}
	
	public void testSilXmlLoader() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilLoader silLoader = (SilLoader)ctx.getBean("silXmlLoader");
		Sil sil = silLoader.load("WEB-INF/classes/sil/io/sil.xml");	
		
		assertEquals(2, sil.getCrystals().size());
		
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertNotNull(crystal);
		assertEquals("A1", crystal.getPort());
		assertEquals("TM1389", crystal.getCrystalId());
		
		crystal = SilUtil.getCrystalFromRow(sil, 1);
		assertNotNull(crystal);
		assertEquals("A2", crystal.getPort());
		assertEquals("15699", crystal.getCrystalId());
				
	}

	//
	public void testSsrlXmlLoaderAndSsrlXmlWriter() throws Exception
	{

		ApplicationContext ctx = AllTests.getApplicationContext();
		SilLoader silLoader = (SilLoader)ctx.getBean("silXmlLoader");
		Sil sil1 = silLoader.load("WEB-INF/classes/sil/io/sil.xml");		
		
		Crystal crystal = SilUtil.getCrystalFromRow(sil1, 0);
		assertNotNull(crystal);
		assertEquals("A1", crystal.getPort());
		assertEquals("TM1389", crystal.getCrystalId());
		
		crystal = SilUtil.getCrystalFromRow(sil1, 1);
		assertNotNull(crystal);
		assertEquals("A2", crystal.getPort());
		assertEquals("15699", crystal.getCrystalId());
		
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		SilWriter writer = (SilWriter)ctx.getBean("silXmlWriter");
		writer.write(out, sil1);
		out.close();
		
		ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());
		Sil sil2 = silLoader.load(in);	
		
		crystal = SilUtil.getCrystalFromRow(sil2, 0);
		assertNotNull(crystal);
		assertEquals("A1", crystal.getPort());
		assertEquals("TM1389", crystal.getCrystalId());
		
		crystal = SilUtil.getCrystalFromRow(sil2, 1);
		assertNotNull(crystal);
		assertEquals("A2", crystal.getPort());
		assertEquals("15699", crystal.getCrystalId());

	}
		
	// Load sil from excel spreadsheet
	public void ttestExcelLoader1() throws Exception
	{

		ApplicationContext ctx = AllTests.getApplicationContext();

		int silId = 1;
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilInfo info = storageManager.getSilInfo(silId);
		String path = storageManager.getOriginalExcelFilePath(info);
		
		System.out.println("Loading sil from " + path);
		
		SilLoader silLoader = (SilLoader)ctx.getBean("silExcelLoader");
		Sil sil = silLoader.load(path);		
						
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertNotNull(crystal);
		assertEquals("A1", crystal.getCrystalId());
		
		crystal = SilUtil.getCrystalFromRow(sil, 95);
		assertNotNull(crystal);
		assertEquals("L8", crystal.getCrystalId());

		
	}
/*
	// Load sil from excel spreadsheet
	public void testExcelLoader2()
	{
		logger.debug("testExcelLoader2: START");
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilLoader silXmlLoader = (SilLoader)ctx.getBean("silXmlLoader");
			Sil silFromXml1 = silXmlLoader.load(silXmlFile);
						
			// Sil writers
			SilWriter excelWriter = (SilWriter)ctx.getBean("silExcelWriter");
			SilWriter xmlWriter = (SilWriter)ctx.getBean("silXmlWriter");
		
			String outFile = outputDir + "/test1.xml";
			FileOutputStream out = new FileOutputStream(outFile);
			xmlWriter.write(out, silFromXml1);
			out.close();

			Sil silFromXml2 = silXmlLoader.load(outFile);

			outFile = outputDir + "/test1.xls";
			out = new FileOutputStream(outFile);
			excelWriter.write(out, silFromXml1);
			out.close();			

			SilLoader excelLoader = (SilLoader)ctx.getBean("silExcelLoader");
			Sil silFromExcel2 = excelLoader.load(outFile);
			silFromExcel2.setId(silFromXml1.getId());
			silFromExcel2.setEventId(silFromXml1.getEventId());
			silFromExcel2.setLocked(silFromXml1.getLocked());
			silFromExcel2.setKey(silFromXml1.getKey());
			silFromExcel2.setVersion(silFromXml1.getVersion());
			
			
			if (!silFromXml2.equals(silFromExcel2))
				throw new Exception("testExcelLoader2 failed: expected sil from test1.xml file and sil from test1.xls file to be the same");
			
			outFile = outputDir + "/test2.xml";
			out = new FileOutputStream(outFile);
			xmlWriter.write(out, silFromXml2);
			out.close();

			outFile = outputDir + "/test2.xls";
			out = new FileOutputStream(outFile);
			excelWriter.write(out, silFromExcel2);
			out.close();

			Sil silFromExcel3 = excelLoader.load(outFile);
			silFromExcel3.setId(silFromExcel2.getId());
			silFromExcel3.setEventId(silFromExcel2.getEventId());
			silFromExcel3.setLocked(silFromExcel2.getLocked());
			silFromExcel3.setKey(silFromExcel2.getKey());
			silFromExcel3.setVersion(silFromExcel2.getVersion());

			if (!silFromExcel2.equals(silFromExcel2))
				throw new Exception("testExcelLoader2 failed: expected sil from test2.xml and sil from test2.xls to be the same");
		
		} catch (Exception e) {
			e.printStackTrace();
			assertNull(e);
		}
		logger.debug("testExcelLoader2: DONE");
	}


	// Load sil from xml file
	// Save it as xml to another file
	// Load the new xml file and compare new sil with the original sil.
	// The two sils should be identicle if the loader and writer work correctly.
	public void testSilXmlWriter() 
	{
		logger.debug("testSilXmlWriter: START");
		try {
			
		// Sil loader
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilLoader silLoader = (SilLoader)ctx.getBean("silXmlLoader");
		Sil sil1 = silLoader.load(silXmlFile);
					
		// Sil writer
		SilWriter writer = (SilWriter)ctx.getBean("silXmlWriter");

		String outFile = outputDir + "/sil.xml";
		FileOutputStream out = new FileOutputStream(outFile);
		writer.write(out, sil1);
		out.close();
		
		// load the new xml file written by SilXmlWriter
		// to make sure we can still read it.
		// Xml validation is done by SiLLoader.
		Sil sil2 = silLoader.load(outFile);
		
		if (!sil1.equals(sil2))
			throw new Exception("testSilXmlWriter failed: expected sil1 and sil2 to be the same");
		
		} catch (Exception e) {
			e.printStackTrace();
			assertNull(e);
		}
		logger.debug("testSilXmlWriter: DONE");
	}

	// Load sil from xml file.
	// Save it as bean xml file.
	// Load bean xml file into a new sil.
	// Compare new sil with the original sil.
	// The two sils should be identicle.
	public void testSilBeanXmlWriter() 
	{
		logger.debug("testSilBeanXmlWriter: START");
		try {
			
		ApplicationContext ctx = AllTests.getApplicationContext();

		// Load sil from ssrl xml file
		SilLoader silLoader1 = (SilLoader)ctx.getBean("silXmlLoader");
		Sil sil1 = silLoader1.load(silXmlFile);
					
		// Write sil in bean xml format
		SilWriter writer = (SilWriter)ctx.getBean("silBeanWriter");
	
		String outFile = outputDir + "/sil_bean1.xml";
		FileOutputStream out = new FileOutputStream(outFile);
		writer.write(out, sil1);
		out.close();
		
		// Load sil from bean xml format
		SilLoader silLoader2 = (SilLoader)ctx.getBean("silBeanLoader");
		Sil sil2 = silLoader2.load(outFile);
		
		if (!sil1.equals(sil2))
			throw new Exception("testSilBeanXmlWriter failed: expected sil1 and sil2 to be the same");

		// Alter sil2 and save it to another bean file
		sil2.setEventId(30);
		
		outFile = outputDir + "/sil_bean2.xml";
		out = new FileOutputStream(outFile);
		writer.write(out, sil2);
		out.close();

		// Load the altered sil from bean xml format into another sil
		SilLoader silLoader3 = (SilLoader)ctx.getBean("silBeanLoader");
		Sil sil3 = silLoader3.load(outFile);
		
		// sil1 and sil3 are not the identicle. sil3 has different eventId.
		if (sil1.equals(sil3))
			throw new Exception("testSilBeanXmlWriter failed: expected sil1 and sil3 to be the different");

		// sil2 and sil3 are identicle.
		if (!sil2.equals(sil3))
			throw new Exception("testSilBeanXmlWriter failed: expected sil2 and sil3 to be the same");

		} catch (Exception e) {
			e.printStackTrace();
			assertNull(e);
		}
		logger.debug("testSilBeanXmlWriter: DONE");
	}
	
	// Load sil from xml file
	// Print it out to a tcl file.
	public void testSilTclWriter() 
	{
		logger.debug("testSilTclWriter: START");
		try {
			
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilLoader silLoader = (SilLoader)ctx.getBean("silXmlLoader");
		Sil data = silLoader.load(silXmlFile);
					
		// Sil writer
		SilWriter writer = (SilWriter)ctx.getBean("silTclWriter");

		String outFile = outputDir + "/sil.tcl";
		FileOutputStream out = new FileOutputStream(outFile);
		writer.write(System.out, data);
		writer.write(out, data);
		
		} catch (Exception e) {
			e.printStackTrace();
			assertNull(e);
		}
		logger.debug("testSilTclWriter: DONE");
	}

	// Load sil from xml file
	// Print it out to a tcl file.
	public void testSilExcelWriter() 
	{
		logger.debug("testSilExcelWriter: START");
		try {
			
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilLoader silLoader = (SilLoader)ctx.getBean("silXmlLoader");
		Sil data = silLoader.load(silXmlFile);
					
		// Sil writer
		SilWriter writer = (SilWriter)ctx.getBean("silExcelWriter");
	
		String outFile = outputDir + "/sil.xls";
		FileOutputStream out = new FileOutputStream(outFile);
		writer.write(out, data);
		out.close();
		
		} catch (Exception e) {
			e.printStackTrace();
			assertNull(e);
		}
		logger.debug("testSilExcelWriter: DONE");
	}
*/
}