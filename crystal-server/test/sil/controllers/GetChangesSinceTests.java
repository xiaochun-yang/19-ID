package sil.controllers;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;

public class GetChangesSinceTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetChangesSince() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 1; 
        int eventId = -1;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        
        // eventId = 1
        MutablePropertyValues props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "BAD CRYSTAL");
        long uniqueId = 2000002;
        silManager.setCrystalProperties(uniqueId, props);

        String content = getChangesSince(silId, -1);
        assertTrue(content.indexOf("load") < 0);
        assertTrue(content.indexOf("update") > 0);
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("BAD CRYSTAL") > 0);
        content = getChangesSince(silId, 0);
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("BAD CRYSTAL") > 0);
        
        content = getChangesSince(silId, 1);
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("BAD CRYSTAL") > 0);
        
        content = getChangesSince(silId, 2);
        assertTrue(content.indexOf("A2") < 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);

        // eventId = 2
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "GOOD CRYSTAL");
        uniqueId = 2000015;
        silManager.setCrystalProperties(uniqueId, props);
        
        content = getChangesSince(silId, 1);
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("BAD CRYSTAL") > 0);
        assertTrue(content.indexOf("B7") > 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") > 0);        
        content = getChangesSince(silId, 2);
        assertTrue(content.indexOf("A2") < 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);
        assertTrue(content.indexOf("B7") > 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") > 0);  
        content = getChangesSince(silId, 3);
        assertTrue(content.indexOf("A2") < 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);
        assertTrue(content.indexOf("B7") < 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") < 0);   
  
        // eventId = 3
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "OK CRYSTAL");
        uniqueId = 2000021;
        silManager.setCrystalProperties(uniqueId, props);
        
        content = getChangesSince(silId, 2);
        assertTrue(content.indexOf("A2") < 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);
        assertTrue(content.indexOf("B7") > 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") > 0);   
        assertTrue(content.indexOf("C5") > 0);
        assertTrue(content.indexOf("OK CRYSTAL") > 0);   
        content = getChangesSince(silId, 3);
        assertTrue(content.indexOf("A2") < 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);
        assertTrue(content.indexOf("B7") < 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") < 0);   
        assertTrue(content.indexOf("C5") > 0);
        assertTrue(content.indexOf("OK CRYSTAL") > 0); 
        content = getChangesSince(silId, 4);
        assertTrue(content.indexOf("A2") < 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);
        assertTrue(content.indexOf("B7") < 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") < 0);   
        assertTrue(content.indexOf("C5") < 0);
        assertTrue(content.indexOf("OK CRYSTAL") < 0); 
        
        // eventId = 4
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "SMALL CRYSTAL");
        uniqueId = 2000002;
        silManager.setCrystalProperties(uniqueId, props);
        
        content = getChangesSince(silId, 3);
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);
        assertTrue(content.indexOf("B7") < 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") < 0);   
        assertTrue(content.indexOf("C5") > 0);
        assertTrue(content.indexOf("OK CRYSTAL") > 0);    
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("SMALL CRYSTAL") > 0);      
        content = getChangesSince(silId, 4);
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("BAD CRYSTAL") < 0);
        assertTrue(content.indexOf("B7") < 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") < 0);   
        assertTrue(content.indexOf("C5") < 0);
        assertTrue(content.indexOf("OK CRYSTAL") < 0);    
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("SMALL CRYSTAL") > 0);  
       
        // Get the whole sil
        content = getChangesSince(silId, -2);
        assertTrue(content.indexOf("load") > 0);
        assertTrue(content.indexOf("update") < 0);
        assertTrue(content.indexOf("B7") > 0);
        assertTrue(content.indexOf("GOOD CRYSTAL") > 0);   
        assertTrue(content.indexOf("C5") > 0);
        assertTrue(content.indexOf("OK CRYSTAL") > 0);    
        assertTrue(content.indexOf("A2") > 0);
        assertTrue(content.indexOf("SMALL CRYSTAL") > 0);  
        assertTrue(content.indexOf("A1") > 0);
        assertTrue(content.indexOf("A3") > 0);  
        assertTrue(content.indexOf("L1") > 0);
        assertTrue(content.indexOf("L8") > 0);  
        
        Crystal crystal = new Crystal();
        crystal.setPort("M1");
        crystal.setCrystalId("M1");
        crystal.setContainerType("cassette");
        crystal.setContainerId("unknown");
        // sil event. eventId = 5
        silManager.addCrystal(crystal);
        
        // The whole sil is returned.
        content = getChangesSince(silId, 4);
        assertTrue(content.indexOf("A1") > 0);
        assertTrue(content.indexOf("A8") > 0);
        assertTrue(content.indexOf("L1") > 0);
        assertTrue(content.indexOf("L8") > 0);
        assertTrue(content.indexOf("M1") > 0);
       

	}
	
	public void testGetChangesSinceRunDefinitionChanges() throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        
        MutablePropertyValues props = new MutablePropertyValues();
        props.addPropertyValue("label", "repos0");
        props.addPropertyValue("beam_width", 0.1);
        props.addPropertyValue("beam_height", 0.1);
        silManager.addDefaultRepositionData(uniqueId, props);
        
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "BAD CRYSTAL");       
        silManager.setCrystalProperties(uniqueId, props);
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "GOOD CRYSTAL");       
        silManager.setCrystalProperties(uniqueId, props);
        
        props = new MutablePropertyValues();
        props.addPropertyValue("beamStop", 100.0);
        silManager.addRunDefinition(uniqueId, 0, props);
        props = new MutablePropertyValues();
        props.addPropertyValue("beamStop", 200.0);
        silManager.addRunDefinition(uniqueId, 0, props);  
        props = new MutablePropertyValues();
        props.addPropertyValue("beamStop", 300.0);
        silManager.addRunDefinition(uniqueId, 0, props);   
//        cacheManager.removeSil(silId, false);
        
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("eventId", "1");
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "1");
    	
    	controller.getChangesSince(request, response);
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        System.out.println("getChangesSince content = " + content);
        assertFalse(content.indexOf("A1") > 0);
        assertTrue(content.indexOf("A2") > 0);
        assertFalse(content.indexOf("A3") > 0);    
        assertTrue(content.indexOf("GOOD CRYSTAL") > 0);
        assertTrue(content.indexOf("{1 2 3 }") > 0);
        assertTrue(content.indexOf("{inactive inactive inactive }") > 0);
        
	}
	
	private String getChangesSince(int silId, int eventId) throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");

		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("eventId", String.valueOf(eventId));
    	
    	controller.getChangesSince(request, response);
        assertEquals(200, response.getStatus());
        return response.getContentAsString().trim();
 
	}

}
