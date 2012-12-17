package sil.controllers;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;

import jxl.Cell;
import jxl.Sheet;
import jxl.Workbook;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockMultipartHttpServletRequest;
import org.springframework.web.multipart.MultipartFile;

import sil.ControllerTestBase;

public class DownloadSilTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}
	
	// User can download only his own sil.
	public void testUserDownloadSil() throws Exception {
		
	   	int silId = 12; // belongs to sergiog
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
            	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.downloadSil(request, response);       
        assertEquals(200, response.getStatus());
        byte buf[] = response.getContentAsByteArray();
        ByteArrayInputStream in = new ByteArrayInputStream(buf);
		Workbook workbook = Workbook.getWorkbook(in);
		in.close();

		checkSil12Workbook(workbook);
	}
	
	// Make sure that we can reupload the result spreadsheet.
	public void testDownloadSilAndReuploadSil() throws Exception {
		
	   	int silId = 12; // belongs to sergiog
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
            	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.downloadSil(request, response);       
        assertEquals(200, response.getStatus());
        byte buf[] = response.getContentAsByteArray();
        ByteArrayInputStream in = new ByteArrayInputStream(buf);
		Workbook workbook = Workbook.getWorkbook(in);
		in.close();

		checkSil12Workbook(workbook);
		
        MockMultipartHttpServletRequest request2 = createMockMultipartHttpServletRequest(sergiog);
        MockHttpServletResponse response2 = new MockHttpServletResponse();
		request2.setMethod("POST");
		request2.addParameter("templateName", "ssrl");
    	request2.addParameter("sheetName", "Sheet1");
    	request2.addParameter("containerType", "cassette");
    	
    	in = new ByteArrayInputStream(buf);
    	MultipartFile file = new MockMultipartFile("file", "sil12.xls", "application/vnd.ms-excel", in); 
    	request2.addFile(file);
		in.close();
		
		assertNotNull(request2.getFileMap());
		file = request2.getFile("file");
		assertNotNull(file);
		
		// Add a new sil
        controller.uploadSil(request2, response2);    
        if (response2.getStatus() != 200)
        	fail(response2.getErrorMessage());
        assertEquals(200, response2.getStatus());
        assertEquals("OK 21", response2.getContentAsString().trim());
	}

	// User tries to download sil which does not exist.
	public void testDownloadNonExistentSil() throws Exception {
		
	   	int silId = 200000000; // belongs to annikas
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
            	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.downloadSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Sil " + String.valueOf(silId) + " does not exist.", response.getErrorMessage().trim());
	}
	
	// User tries to download sil that belongs to somebody else.
	public void testDownloadSilPermissionDenied() throws Exception {
		
	   	int silId = 1; // belongs to annikas
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
            	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.downloadSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("User " + sergiog.getLoginName() + " has no permission to access sil " + String.valueOf(silId), response.getErrorMessage().trim());
	}

	// Staff can download sil that belongs to anyone.
	public void testStaffDownloadSil() throws Exception {
		
	   	int silId = 12; // belongs to sergiog
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
            	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.downloadSil(request, response);       
        assertEquals(200, response.getStatus());
        byte buf[] = response.getContentAsByteArray();
        ByteArrayInputStream in = new ByteArrayInputStream(buf);
		Workbook workbook = Workbook.getWorkbook(in);
		in.close();
		
		checkSil12Workbook(workbook);
		
	}
	
	private void checkSil12Workbook(Workbook workbook) {

		assertNotNull(workbook);
		Sheet s = workbook.getSheet("Sheet1");
		assertNotNull(s);
		
		assertEquals(97, s.getRows());
		// First row contains column names
		Cell[] cells = s.getRow(0);
		assertEquals(80, cells.length);
		assertEquals("Row", cells[0].getContents().trim());
		assertEquals("Port", cells[1].getContents().trim());
		assertEquals("ContainerID", cells[2].getContents().trim());
		assertEquals("CrystalID", cells[3].getContents().trim());
		assertEquals("Dir3", cells[64].getContents().trim());
		assertEquals("Warning3", cells[79].getContents().trim());
		
		// First crystal
		cells = s.getRow(1);
		assertEquals("0", cells[0].getContents().trim());
		assertEquals("A1", cells[1].getContents().trim());
		assertEquals("unknown", cells[2].getContents().trim());
		assertEquals("A1", cells[3].getContents().trim());
		assertEquals("A1", cells[12].getContents().trim()); // Directory
		assertEquals("0.7407162825710274", cells[14].getContents().trim()); // Score
		assertEquals("81.56 81.56 129.48 90.0 90.0 120.0", cells[15].getContents().trim()); // Unitcell 
		assertEquals("0.2", cells[16].getContents().trim()); // Mosaicity 
		assertEquals("0.021", cells[17].getContents().trim()); // Rmsr 
		assertEquals("P3,P312,P321,P6,P622", cells[18].getContents().trim()); // BravaisLattice 
		assertEquals("3.04", cells[19].getContents().trim()); // Resolution 
		assertEquals("0.0", cells[20].getContents().trim()); // ISigma
		assertEquals("/data/penjitk/webice/screening/14256/A1/autoindex", cells[21].getContents().trim()); // AutoindexDir 
		assertEquals("/data/penjitk/screening/SIM9-2/14256/A1/A1_003.mccd /data/penjitk/screening/SIM9-2/14256/A1/A1_004.mccd", cells[22].getContents().trim()); // AutoindexImages 
		assertEquals("/data/penjitk/screening/SIM9-2/14256/A1/A1_003.mccd", cells[26].getContents().trim()); // Image1 
		assertEquals("A1_003.mccd", cells[27].getContents().trim()); // Image1.name 
		assertEquals("1", cells[29].getContents().trim()); // Group1
		assertEquals("4.0", cells[36].getContents().trim()); // Score1
		assertEquals("3.6", cells[37].getContents().trim()); // Resolution1

	}
}
