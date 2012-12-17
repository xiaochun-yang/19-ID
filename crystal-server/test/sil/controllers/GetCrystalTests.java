package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;

public class GetCrystalTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetCrystalFromUniqueId() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", "2000001");
    	
    	controller.getCrystal(request, response);

    	assertEquals(200, response.getStatus());
        String content =  response.getContentAsString().trim();  	
        
        System.out.println(content);
        
        assertTrue(content.indexOf("<Crystal row=\"0\" excelRow=\"-1\" selected=\"0\">") > 0);
        assertTrue(content.indexOf("<UniqueID>2000001</UniqueID>") > 0);
        assertTrue(content.indexOf("<Port>A1</Port>") > 0);
        assertTrue(content.indexOf("<CrystalID>A1</CrystalID>") > 0);
        assertFalse(content.indexOf("<UniqueID>2000002</UniqueID>") > 0);

	}
	
	public void testGetCrystalFromCrystalId() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("crystalId", "A1");
    	
    	controller.getCrystal(request, response);

    	assertEquals(200, response.getStatus());
        String content =  response.getContentAsString().trim();  	
        
        assertTrue(content.indexOf("<Crystal row=\"0\" excelRow=\"-1\" selected=\"0\">") > 0);
        assertTrue(content.indexOf("<UniqueID>2000001</UniqueID>") > 0);
        assertTrue(content.indexOf("<Port>A1</Port>") > 0);
        assertTrue(content.indexOf("<CrystalID>A1</CrystalID>") > 0);
        assertFalse(content.indexOf("<UniqueID>2000002</UniqueID>") > 0);

	}
	
	public void testGetCrystalFromRow() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("row", "0");
    	
    	controller.getCrystal(request, response);

    	assertEquals(200, response.getStatus());
        String content =  response.getContentAsString().trim();  	
        
        assertTrue(content.indexOf("<Crystal row=\"0\" excelRow=\"-1\" selected=\"0\">") > 0);
        assertTrue(content.indexOf("<UniqueID>2000001</UniqueID>") > 0);
        assertTrue(content.indexOf("<Port>A1</Port>") > 0);
        assertTrue(content.indexOf("<CrystalID>A1</CrystalID>") > 0);
        assertFalse(content.indexOf("<UniqueID>2000002</UniqueID>") > 0);

	}
	
	public void testGetRowMissingSilId() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
     	request.addParameter("uniqueId", "2000001");
    	
    	controller.getCrystal(request, response);

    	assertEquals(500, response.getStatus());
        assertEquals("Missing silId parameter", response.getErrorMessage());

	}

	public void testGetRowMissingUniqueIdCrystalIdRow() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
     	request.addParameter("silId", String.valueOf(silId));
    	
    	controller.getCrystal(request, response);

    	assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or crystalId or row parameter", response.getErrorMessage());

	}
	
	public void testGetNonExistentUniqueId() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", "90000000000");
    	
    	controller.getCrystal(request, response);

    	if (response.getStatus() != 200)
    		System.out.println("ERROR: " + response.getErrorMessage());
    	assertEquals(200, response.getStatus());
        String content =  response.getContentAsString().trim();  
        
        System.out.println(content);

	}
	
	public void testGetNonExistentCrystalId() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("crystalId", "XXXXXXXXX");
    	
    	controller.getCrystal(request, response);

    	assertEquals(500, response.getStatus());
        assertEquals("CrystalId XXXXXXXXX does not exist.", response.getErrorMessage().trim());


	}
	
	public void testGetNonExistentRow() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
                
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("row", "1000000");
    	
    	controller.getCrystal(request, response);

    	assertEquals(500, response.getStatus());
        assertEquals("Row 1000000 does not exist.", response.getErrorMessage().trim());


	}
	
}
