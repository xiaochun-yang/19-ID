package sil.upload;

import java.io.File;
import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import sil.app.FakeUser;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;
import sil.upload.SilUploadManager;
import sil.upload.UploadData;
import sil.AllTests;
import sil.SilTestCase;
import sil.TestData;

import junit.framework.TestCase;

public class SilUploadManagerTests  extends SilTestCase {

	private String baseDir = "WEB-INF/classes/sil/upload";
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
	}

	@Override
	protected void tearDown() throws Exception {
    	super.tearDown();
    }

	public void testUploadDefaultTemplate() throws Exception
	{

		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "default_template.xls";
		UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
		List<String> warnings = new ArrayList<String>();
		manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
	}
	
	// By default all crystals have property selected=true
	public void testUploadDefaultTemplateSelectAll() throws Exception
	{

		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "default_template.xls";
		UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
		
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);		
		assertEquals("A1", crystal.getPort());
		assertTrue(crystal.getSelected());

		crystal = SilUtil.getCrystalFromRow(sil, 45);
		assertEquals("F6", crystal.getPort());
		assertTrue(crystal.getSelected());

		crystal = SilUtil.getCrystalFromRow(sil, 95);
		assertEquals("L8", crystal.getPort());
		assertTrue(crystal.getSelected());

	}
	
	public void testUploadSpreadsheetWithEmptyCrystalId() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "Q315.xls";
		UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);

		assertEquals("A1", crystal.getPort());
		assertEquals("TM1389", crystal.getCrystalId());
			
	}
	
	public void testUploadSpreadsheetWithBadFileName() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "cassette_template_result.xls";
		
		UploadData data = new UploadData();	
		FileInputStream in = new FileInputStream(excelFile);
		MultipartFile file = new MockMultipartFile("file", "bad filename.xls", "application/vnd.ms-excel", in);
		// Do we need to close it?
		in.close();
		
		data.setBeamline("BL1-5");
		data.setCassettePosition("left");
		data.setSheetName("Sheet1");
		data.setSilOwner("annikas");
		data.setTemplateName("ssrl");
		data.setContainerType("cassette");
		data.setFile(file);
				
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		assertEquals("Removed bad characters from original filename. New name is bad_filename.xls.", warnings.get(0));
		
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		SilInfo info = sil.getInfo();
		assertEquals("bad_filename.xls", info.getUploadFileName());
	}
	
	public void testUploadSpreadsheetOtherSheetName() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "other_sheetname_result.xls";
		UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "MyFavouriteCrystals");
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals("A1", crystal.getPort());
		assertEquals("A1", crystal.getCrystalId());
		assertEquals(0.7407162825710274, crystal.getResult().getAutoindexResult().getScore());

		crystal = SilUtil.getCrystalFromPort(sil, "A6");
		assertEquals(5, crystal.getRow());
		assertEquals("A6", crystal.getCrystalId());
		assertEquals("P3,P312,P321,P6,P622", crystal.getResult().getAutoindexResult().getBravaisLattice());	
	}

	public void testUploadSpreadsheetWithAutoindexResult() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "cassette_template_result.xls";
		UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals("A1", crystal.getPort());
		assertEquals("A1", crystal.getCrystalId());
		assertEquals(0.7407162825710274, crystal.getResult().getAutoindexResult().getScore());

		crystal = SilUtil.getCrystalFromPort(sil, "A6");
		assertEquals(5, crystal.getRow());
		assertEquals("A6", crystal.getCrystalId());
		assertEquals("P3,P312,P321,P6,P622", crystal.getResult().getAutoindexResult().getBravaisLattice());	
	}
	
	public void testUploadPuckSpreadsheet() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "puck_template.xls";
		UploadData data = TestData.createUploadData(excelFile, "ssrl", "puck", "Sheet1");
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals("A1", crystal.getPort());
		assertEquals("A1", crystal.getCrystalId());
//		assertEquals("", crystal.getData().getComment()); // null
		assertEquals("A1", crystal.getData().getDirectory());

		crystal = SilUtil.getCrystalFromPort(sil, "D16");
		assertEquals(63, crystal.getRow());
		assertEquals("D16", crystal.getCrystalId());
//		assertEquals("", crystal.getData().getComment()); // null
		assertEquals("D16", crystal.getData().getDirectory());
			
	}

	public void testUploadJcsgSpreadsheet() throws Exception
	{
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "jcsg_cassette.xls";
		UploadData data = TestData.createUploadData(excelFile, "jcsg", "cassette", "Sheet1");
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertEquals(96, SilUtil.getCrystalCount(sil));
			
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals("A1", crystal.getPort());
		assertEquals("131644", crystal.getCrystalId());
		assertEquals("SSRL00321", crystal.getContainerId());

		crystal = SilUtil.getCrystalFromPort(sil, "L8");
		assertEquals(95, crystal.getRow());
		assertEquals("131739", crystal.getCrystalId());
		assertEquals("SSRL00321", crystal.getContainerId());
		assertEquals("MI15887S", crystal.getData().getProtein());
		assertEquals("Rectangle", crystal.getData().getComment());
		assertNull(crystal.getData().getFreezingCond());
		assertEquals("GNF4 E07: 0.2000M NaCl, 30.0000% PEG-3000, 0.1M TRIS pH 7.0", crystal.getData().getCrystalCond());
		assertEquals("Met-Inhibition", crystal.getData().getMetal());
		assertNull(crystal.getData().getPriority());
		assertNull(crystal.getData().getCrystalUrl());
		assertEquals("http://www1.jcsg.org/cgi-bin/psat/analyzer.cgi?acc=MI15887S", crystal.getData().getProteinUrl());
		assertEquals("MI15887S/131739", crystal.getData().getDirectory());	
	}
	
	public void testUploadJcsgSpreadsheetOtherSheetName() throws Exception
	{
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		String excelFile = baseDir + File.separator + "jcsg_other_sheetname.xls";
		UploadData data = TestData.createUploadData(excelFile, "jcsg", "cassette", "MyFavouriteCrystals");
		List<String> warnings = new ArrayList<String>();
		int silId = manager.uploadFile(data, warnings);
		TestData.printWarnings(warnings);
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertEquals(96, SilUtil.getCrystalCount(sil));
			
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals("A1", crystal.getPort());
		assertEquals("131644", crystal.getCrystalId());
		assertEquals("SSRL00321", crystal.getContainerId());

		crystal = SilUtil.getCrystalFromPort(sil, "L8");
		assertEquals(95, crystal.getRow());
		assertEquals("131739", crystal.getCrystalId());
		assertEquals("SSRL00321", crystal.getContainerId());
		assertEquals("MI15887S", crystal.getData().getProtein());
		assertEquals("Rectangle", crystal.getData().getComment());
		assertNull(crystal.getData().getFreezingCond());
		assertEquals("GNF4 E07: 0.2000M NaCl, 30.0000% PEG-3000, 0.1M TRIS pH 7.0", crystal.getData().getCrystalCond());
		assertEquals("Met-Inhibition", crystal.getData().getMetal());
		assertNull(crystal.getData().getPriority());
		assertNull(crystal.getData().getCrystalUrl());
		assertEquals("http://www1.jcsg.org/cgi-bin/psat/analyzer.cgi?acc=MI15887S", crystal.getData().getProteinUrl());
		assertEquals("MI15887S/131739", crystal.getData().getDirectory());	
	}

	public void testUploadDefaultTemplateSsrl() throws Exception
	{
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		ArrayList<String> warnings = new ArrayList<String>();
		int silId = manager.uploadDefaultTemplate(annikas.getLoginName(), "ssrl", "cassette", warnings);
		assertEquals(0, warnings.size());
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertEquals(21, sil.getId());
		assertEquals(96, sil.getCrystals().size());
			
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals(3000001, crystal.getUniqueId());
		assertEquals("A1", crystal.getPort());
		assertEquals("A1", crystal.getCrystalId());
		assertEquals("cassette", crystal.getContainerType());
		
		crystal = SilUtil.getCrystalFromRow(sil, 95);
		assertEquals(3000096, crystal.getUniqueId());
		assertEquals("L8", crystal.getPort());
		assertEquals("L8", crystal.getCrystalId());
		assertEquals("cassette", crystal.getContainerType());

	}
	
	public void testUploadDefaultTemplatePuck() throws Exception
	{
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		ArrayList<String> warnings = new ArrayList<String>();
		int silId = manager.uploadDefaultTemplate(annikas.getLoginName(), "puck", "puck", warnings);
		assertEquals(0, warnings.size());
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertEquals(21, sil.getId());
		assertEquals(64, sil.getCrystals().size());
			
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals(3000001, crystal.getUniqueId());
		assertEquals("A1", crystal.getPort());
		assertEquals("A1", crystal.getCrystalId());
		assertEquals("puck", crystal.getContainerType());
		
		crystal = SilUtil.getCrystalFromRow(sil, 15);
		assertEquals(3000016, crystal.getUniqueId());
		assertEquals("A16", crystal.getPort());
		assertEquals("A16", crystal.getCrystalId());
		assertEquals("puck", crystal.getContainerType());

		crystal = SilUtil.getCrystalFromRow(sil, 16);
		assertEquals(3000017, crystal.getUniqueId());
		assertEquals("B1", crystal.getPort());
		assertEquals("B1", crystal.getCrystalId());
		assertEquals("puck", crystal.getContainerType());

		crystal = SilUtil.getCrystalFromRow(sil, 63);
		assertEquals(3000064, crystal.getUniqueId());
		assertEquals("D16", crystal.getPort());
		assertEquals("D16", crystal.getCrystalId());
		assertEquals("puck", crystal.getContainerType());
	}
	
	public void testUploadDefaultTemplatePuckNoContainerType() throws Exception
	{
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		ArrayList<String> warnings = new ArrayList<String>();
		int silId = manager.uploadDefaultTemplate(annikas.getLoginName(), "puck", null, warnings);
		assertEquals(64, warnings.size());
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertEquals(21, sil.getId());
		assertEquals(64, sil.getCrystals().size());
			
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals(3000001, crystal.getUniqueId());
		assertEquals("A1", crystal.getPort());
		assertEquals("A1", crystal.getCrystalId());
		assertEquals(null, crystal.getContainerType());
		
		crystal = SilUtil.getCrystalFromRow(sil, 15);
		assertEquals(3000016, crystal.getUniqueId());
		assertEquals("A16", crystal.getPort());
		assertEquals("A16", crystal.getCrystalId());
		assertEquals(null, crystal.getContainerType());

		crystal = SilUtil.getCrystalFromRow(sil, 16);
		assertEquals(3000017, crystal.getUniqueId());
		assertEquals("B1", crystal.getPort());
		assertEquals("B1", crystal.getCrystalId());
		assertEquals(null, crystal.getContainerType());

		crystal = SilUtil.getCrystalFromRow(sil, 63);
		assertEquals(3000064, crystal.getUniqueId());
		assertEquals("D16", crystal.getPort());
		assertEquals("D16", crystal.getCrystalId());
		assertEquals(null, crystal.getContainerType());
	}
	
	public void testUploadDefaultTemplateEmpty() throws Exception
	{
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
			
		ArrayList<String> warnings = new ArrayList<String>();
		int silId = manager.uploadDefaultTemplate(annikas.getLoginName(), "empty", null, warnings);
		assertEquals(0, warnings.size());
			
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertEquals(21, sil.getId());
		assertEquals(0, sil.getCrystals().size());

	}
	
	public void testUploadXlsx() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
		
		File dir = new File("/home/penjitk/workspace/crystal-server/data/examples/xlsx");
		String excelFile = dir + "/mboulang465565370205294878.xlsx";
		UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
		List<String> warnings = new ArrayList<String>();
		try {
			manager.uploadFile(data, warnings);
//			fail("Expected an exception.");
//			System.out.println("file = " + excelFile + " OK.");
		} catch (Exception e) {
				fail("file = " + excelFile + " error = " + e.getMessage());
		}
	}
	
	public void testUploadBadFile() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilUploadManager manager = (SilUploadManager)ctx.getBean("uploadManager");
		
		File dir = new File("/home/penjitk/workspace/crystal-server/data/examples/xls");
		String[] files = dir.list();
		for (int i = 0; i < files.length; ++i) {
			
			String excelFile = dir.getPath() + "/" + files[i];
			if (excelFile.indexOf(".xls") < 0) {
				System.out.println("Skipping file " + excelFile);
				continue;
			}
			UploadData data = TestData.createUploadData(excelFile, "ssrl", "cassette", "Sheet1");
			List<String> warnings = new ArrayList<String>();
			try {
				System.out.println("Uploading file " + excelFile);
				manager.uploadFile(data, warnings);
//				fail("Expected an exception.");
				System.out.println("file = " + excelFile + " OK.");
			} catch (Exception e) {
				System.out.println("file = " + excelFile + " error = " + e.getMessage());
				e.printStackTrace();
			}
		}
	}
}
