package sil.controllers;

import java.util.StringTokenizer;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import sil.managers.SilStorageManager;

public class GetLatestEventIdTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetLatestEventId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 1;
        int eventId = -1;
    	request.addParameter("silId", String.valueOf(silId));
    	controller.getLatestEventId(request, response);
        assertEquals(200, response.getStatus());
        assertEquals(String.valueOf(eventId), response.getContentAsString().trim());
        
        eventId = 235;
        SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
        storageManager.setLatestEventId(silId, eventId);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
        
    	request.addParameter("silId", String.valueOf(silId));
    	controller.getLatestEventId(request, response);
        assertEquals(200, response.getStatus());
        assertEquals(String.valueOf(eventId), response.getContentAsString().trim());

	}
	
	public void testGetLatestEventIdWithDetail() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 3;
        long uniqueId = 2000194;
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("detail", "true");
    	
    	controller.getLatestEventId(request, response);
        assertEquals(200, response.getStatus());
        String body = response.getContentAsString();
        System.out.println("body1 = " + body);
        StringTokenizer tok = new StringTokenizer(body, " {}");
        assertEquals(65, tok.countTokens());
        assertEquals("-1", tok.nextToken()); // first token = event id for the sil
        assertEquals("0", tok.nextToken()); // event id for A1
        assertEquals("0", tok.nextToken()); // event id for A2
        
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertNotNull(silManager);
        MutablePropertyValues props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "Good");
        silManager.setCrystalProperties(uniqueId, props);
        cacheManager.removeSil(silId, false); // force the next call to getOrCreateSilManager() to reload sil.
        
        props = new MutablePropertyValues();
        props.addPropertyValue("label", "repos0");
        props.addPropertyValue("beam_width", 0.1);
        props.addPropertyValue("beam_height", 0.1);
        silManager.addDefaultRepositionData(uniqueId, props);
        cacheManager.removeSil(silId, false); 
        
        silManager = cacheManager.getOrCreateSilManager(silId);
        assertNotNull(silManager);
        props = new MutablePropertyValues();
        props.addPropertyValue("distance", 300.0);
        silManager.addRunDefinition(uniqueId, 0, props);
        props = new MutablePropertyValues();
        props.addPropertyValue("distance", 500.0);
        silManager.addRunDefinition(uniqueId, 0, props);
        cacheManager.removeSil(silId, false);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
        
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("detail", "true");

    	controller.getLatestEventId(request, response);
        assertEquals(200, response.getStatus());
        body = response.getContentAsString();
        System.out.println("body2 = " + body);
        tok = new StringTokenizer(body, " {}");
        assertEquals(65, tok.countTokens());
        assertEquals("1", tok.nextToken()); // first token = event id for the sil
        assertEquals("0", tok.nextToken()); // event id for A1
        assertEquals("3", tok.nextToken()); // event id for A2

	}
		
	public void testGetLatestEventIdMissingSilId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 1;
        int eventId = -1;
    	controller.getLatestEventId(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing silId parameter", response.getErrorMessage());
        
	}
	
	public void testGetLatestEventIdNonExistentSilId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 200000000;
        int eventId = -1;
    	request.addParameter("silId", String.valueOf(silId));
    	controller.getLatestEventId(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Sil " + silId + " does not exist.", response.getErrorMessage());
        
	}
}
