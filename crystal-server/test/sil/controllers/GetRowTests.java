package sil.controllers;

import java.io.BufferedReader;
import java.io.FileReader;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.beans.SilInfo;
import sil.dao.SilDao;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import sil.managers.SilStorageManager;

public class GetRowTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetRowA1() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
        int row = 0;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("row", String.valueOf(row));
    	
    	controller.getRow(request, response);

    	assertEquals(200, response.getStatus());
        String content =  response.getContentAsString().trim();  	
        
        assertTrue(content.indexOf("{update}") > 0);
        assertTrue(content.indexOf("A1") > 0);
        assertTrue(content.indexOf("A8") < 0);
        assertTrue(content.indexOf("L1") < 0);
        assertTrue(content.indexOf("L8") < 0);

	}

	public void testGetRowB2() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
        int row = 9;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("row", String.valueOf(row));
    	
    	controller.getRow(request, response);

    	assertEquals(200, response.getStatus());
        String content =  response.getContentAsString().trim();  	
        
        assertTrue(content.indexOf("{update}") > 0);
        assertTrue(content.indexOf("A1") < 0);
        assertTrue(content.indexOf("A8") < 0);
        assertTrue(content.indexOf("B2") > 0);
        assertTrue(content.indexOf("L8") < 0);

	}

	public void testGetNonExistentRow() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
        int row = 2000;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("row", String.valueOf(row));
    	
    	controller.getRow(request, response);

    	assertEquals(200, response.getStatus());
        String content =  response.getContentAsString().trim();  	
        
        String expectedContent = "{\n  {1} {-1} {update}\n}";
        
        assertEquals(expectedContent, content);

	}
	public void testGetRowMissingSilId() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
        int row = 0;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
     	request.addParameter("row", String.valueOf(row));
    	
    	controller.getRow(request, response);

    	assertEquals(500, response.getStatus());
        assertEquals("Missing silId parameter", response.getErrorMessage());

	}

	public void testGetRowMissingRow() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
        int row = 0;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
     	request.addParameter("silId", String.valueOf(silId));
    	
    	controller.getRow(request, response);

    	assertEquals(500, response.getStatus());
        assertEquals("Missing row parameter", response.getErrorMessage());

	}

	
}
