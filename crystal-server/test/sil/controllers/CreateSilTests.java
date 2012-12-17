package sil.controllers;

import java.io.File;
import java.io.FileInputStream;
import java.util.Map;

import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockMultipartHttpServletRequest;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.multipart.commons.CommonsMultipartResolver;
import org.springframework.web.multipart.support.DefaultMultipartHttpServletRequest;

import sil.ControllerTestBase;
import sil.beans.BeamlineInfo;
import sil.beans.Sil;
import sil.dao.SilDao;
import sil.factory.SilFactory;
import sil.managers.SilStorageManager;

public class CreateSilTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}
	
	public void testCreateEmptySil() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	checkSilDoesNotExist(21);
    	
    	request.addParameter("templateName", "empty");
		
		// Add a new sil
        controller.createDefaultSil(request, response);       
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString();
        assertTrue(content.startsWith("OK 21"));
        assertTrue(content.indexOf("No crystal validator for container type null") < 0);
        
        // Check that sil 21 exists
        // and has no crystal.
        checkSilExists(21, 0);
	}

	public void testCreateDefaultSilSsrl() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	checkSilDoesNotExist(21);
    	
    	request.addParameter("templateName", "ssrl");
    	request.addParameter("containerType", "cassette");
		
		// Add a new sil
        controller.createDefaultSil(request, response);
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        assertEquals("OK " + String.valueOf(silId), response.getContentAsString().trim());
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(21, 96);
	}
	
	public void testCreateDefaultSilPuck() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	checkSilDoesNotExist(21);
    	
    	// Can use templateName or template parameter
    	request.addParameter("template", "puck");
    	request.addParameter("containerType", "puck");
		
		// Add a new sil
        controller.createDefaultSil(request, response);  
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        assertEquals("OK " + String.valueOf(silId), response.getContentAsString().trim());
        
        // Check that sil 21 exists and has 64 crystals.
        checkSilExists(21, 64);

	}

	// User creates default sil and then assign the sil to a beamline position.
	// There is no other sil already assigned to this position.
	public void testUserCreateAndAssignSil() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");
		SilDao silDao = (SilDao)ctx.getBean("silDao");

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	checkSilDoesNotExist(silId);
    	
    	String beamline = "BL1-5";
    	String position = "middle";
    	
    	// There is no sil assigned to this position.
		checkBeamlineHasNoSil(beamline, position);
   	
    	request.addParameter("templateName", "ssrl");
    	request.addParameter("beamline", beamline);
    	request.addParameter("cassettePosition", "2"); // BL1-5 middle
		
		// Add a new sil
        controller.createDefaultSil(request, response);     
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString();
        assertTrue(content.startsWith("OK 21"));
        assertTrue(content.indexOf("No crystal validator for container type null") > -1);
                
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 96);
		
		// Check BL1-5 middle now has sil 21.
		checkBeamlineHasSil(beamline, position, silId);
	}	

	// User creates default sil and then assign the sil to a beamline position.
	// There is no other sil already assigned to this position.
	public void testUserCreateAndAssignSilNoBeamlinePermission() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        // Check that sil 21 does not exist.
    	checkSilDoesNotExist(silId);
    	
    	String beamline = "BL1-5";
    	String position = "middle";
    	
    	// There is no sil assigned to this position.
		checkBeamlineHasNoSil(beamline, position);
   	
    	request.addParameter("templateName", "ssrl");
    	request.addParameter("beamline", beamline);
    	request.addParameter("cassettePosition", "2"); // BL1-5 middle
		
		// Add a new sil
        controller.createDefaultSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("User has no permission to access beamline BL1-5", response.getErrorMessage());
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 96);
		
    	// There is no sil assigned to this position.
		checkBeamlineHasNoSil(beamline, position);
	}	

	// User creates default sil and then assign the sil to a beamline position.
	// There is another sil already assigned to this position. This sil is locked.
	// User cannot unassign locked sil.
	public void testUserCreateAndAssignSilLocked() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        // Check that sil 21 does not exist
     	checkSilDoesNotExist(silId);
    	
    	String beamline = "BL12-2";
    	String position = "left";
    	
    	// Sil 11 is already assigned to this beamline position
		checkBeamlineHasSil(beamline, position, 11);
   	
    	request.addParameter("templateName", "ssrl");
    	request.addParameter("beamline", beamline);
    	request.addParameter("cassettePosition", "1"); // BL12-2 left
		
		// Add a new sil
        controller.createDefaultSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Sil 11 is locked.", response.getErrorMessage());
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 96);
		
    	// Sil 11 is still assigned to this position
		checkBeamlineHasSil(beamline, position, 11);
	}
	
	// User creates default sil and then assign the sil to a beamline position.
	// There is another sil already assigned to this position. This sil is locked.
	// Staff can unassign locked sil.
	public void testStaffCreateAndAssignSilLocked() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	// Check that sil 21 does not exist.
    	checkSilDoesNotExist(silId);
    	
    	String beamline = "BL12-2";
    	String position = "left";
    	
    	// Sil 11 is already assigned to this beamline position
		checkBeamlineHasSil(beamline, position, 11);
   	
    	request.addParameter("templateName", "ssrl");
    	request.addParameter("beamline", beamline);
    	request.addParameter("cassettePosition", "1"); // BL12-2 left
		
		// Add a new sil
        controller.createDefaultSil(request, response);       
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString();
        assertTrue(content.startsWith("OK 21"));
        assertTrue(content.indexOf("No crystal validator for container type null") > -1);
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 96);
		
    	// Sil 21 is now assigned to this position
		checkBeamlineHasSil(beamline, position, 21);
	}	

	// Cannot get this test to work. 
	// Test uploadSil command by using real http request from a browser through a form.
	public void testUploadSilCassette() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");
	   	SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
       
    	// Check that beamline 21 does not exist.
    	checkSilDoesNotExist(silId);
 
    	// Borrow xls file from template dir for testing.
     	File templateFile = silFactory.getTemplateFile("cassette_template.xls");
    	if (!templateFile.exists())
    		throw new Exception("File + " + templateFile.getPath() + " does not exist.");

        MockMultipartHttpServletRequest request = createMockMultipartHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
		request.setMethod("POST");
		request.addParameter("templateName", "ssrl");
    	request.addParameter("sheetName", "Sheet1");
    	request.addParameter("containerType", "cassette");
    	
    	FileInputStream in = new FileInputStream(templateFile);
    	MultipartFile file = new MockMultipartFile("file", templateFile.getName(), "application/vnd.ms-excel", in); 
    	request.addFile(file);
		in.close();
		
		assertNotNull(request.getFileMap());
		file = request.getFile("file");
		assertNotNull(file);
		assertEquals(templateFile.length(), file.getSize());
		
		// Add a new sil
        controller.uploadSil(request, response);    
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        assertEquals("OK " + String.valueOf(silId), response.getContentAsString().trim());
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 96);
	}
	
	// Cannot get this test to work. 
	// Test uploadSil command by using real http request from a browser through a form.
	public void testUploadSilPuck() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");
	   	SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
       
    	// Check that beamline 21 does not exist.
    	checkSilDoesNotExist(silId);
 
    	// Borrow xls file from template dir for testing.
     	File templateFile = silFactory.getTemplateFile("puck_template.xls");
    	if (!templateFile.exists())
    		throw new Exception("File + " + templateFile.getPath() + " does not exist.");

        MockMultipartHttpServletRequest request = createMockMultipartHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
		request.setMethod("POST");
		request.addParameter("templateName", "ssrl");
    	request.addParameter("sheetName", "Sheet1");
    	request.addParameter("containerType", "puck");
    	
    	FileInputStream in = new FileInputStream(templateFile);
    	MultipartFile file = new MockMultipartFile("file", templateFile.getName(), "application/vnd.ms-excel", in); 
    	request.addFile(file);
		in.close();
		
		assertNotNull(request.getFileMap());
		file = request.getFile("file");
		assertNotNull(file);
		assertEquals(templateFile.length(), file.getSize());
		
		// Add a new sil
        controller.uploadSil(request, response);  
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        assertEquals("OK " + String.valueOf(silId), response.getContentAsString().trim());
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 64);
	}
	 
	// Uploading puck spreadsheet but do not set containerType.
	public void testUploadSilPuckNoContainerType() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");
	   	SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
       
    	// Check that beamline 21 does not exist.
    	checkSilDoesNotExist(silId);
 
    	// Borrow xls file from template dir for testing.
     	File templateFile = silFactory.getTemplateFile("puck_template.xls");
    	if (!templateFile.exists())
    		throw new Exception("File + " + templateFile.getPath() + " does not exist.");

        MockMultipartHttpServletRequest request = createMockMultipartHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
		request.setMethod("POST");
		request.addParameter("templateName", "ssrl");
    	request.addParameter("sheetName", "Sheet1");
    	
    	FileInputStream in = new FileInputStream(templateFile);
    	MultipartFile file = new MockMultipartFile("file", templateFile.getName(), "application/vnd.ms-excel", in); 
    	request.addFile(file);
		in.close();
		
		assertNotNull(request.getFileMap());
		file = request.getFile("file");
		assertNotNull(file);
		assertEquals(templateFile.length(), file.getSize());
		
		// Add a new sil
        controller.uploadSil(request, response);  
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        
        String content = response.getContentAsString();
        assertTrue(content.startsWith("OK 21"));
        assertTrue(content.indexOf("No crystal validator for container type null") > -1);
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 64);
	}
	
	public void testUploadXlsx() throws Exception {
		
	   	int silId = 21;
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");
	   	SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
       
    	// Check that beamline 21 does not exist.
    	checkSilDoesNotExist(silId);
 
    	// Borrow xls file from template dir for testing.
     	File excelFile = new File("WEB-INF/classes/sil/upload/test.xlsx");
    	if (!excelFile.exists())
    		throw new Exception("File + " + excelFile.getPath() + " does not exist.");

        MockMultipartHttpServletRequest request = createMockMultipartHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
		request.setMethod("POST");
		request.addParameter("templateName", "ssrl");
    	request.addParameter("sheetName", "Sheet1");
    	request.addParameter("containerType", "cassette");
    	
    	FileInputStream in = new FileInputStream(excelFile);
    	MultipartFile file = new MockMultipartFile("file", excelFile.getName(), "application/vnd.ms-excel", in); 
    	request.addFile(file);
		in.close();
		
		assertNotNull(request.getFileMap());
		file = request.getFile("file");
		assertNotNull(file);
		assertEquals(excelFile.length(), file.getSize());
		
		// Add a new sil
        controller.uploadSil(request, response);    
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        assertEquals("OK " + String.valueOf(silId), response.getContentAsString().trim());
        
        // Check that sil 21 exists and has 96 crystals.
        checkSilExists(silId, 96);
	}

}
