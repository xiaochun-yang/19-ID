package sil.controllers;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;

public class IsEventCompletedTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testIsEventCompleted() throws Exception {
		
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
        assertTrue(isEventCompleted(silId, 1));

        // eventId = 2
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "GOOD CRYSTAL");
        uniqueId = 2000015;
        silManager.setCrystalProperties(uniqueId, props);
        assertTrue(isEventCompleted(silId, 2));
  
        // eventId = 3
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "OK CRYSTAL");
        uniqueId = 2000021;
        silManager.setCrystalProperties(uniqueId, props);
        assertTrue(isEventCompleted(silId, 3));
        
        // eventId = 4
        props = new MutablePropertyValues();
        props.addPropertyValue("Comment", "SMALL CRYSTAL");
        uniqueId = 2000002;
        silManager.setCrystalProperties(uniqueId, props);
		assertTrue(isEventCompleted(silId, 4));
        
        Crystal crystal = new Crystal();
        crystal.setPort("M1");
        crystal.setCrystalId("M1");
        crystal.setContainerType("cassette");
        crystal.setContainerId("unknown");
        // sil event. eventId = 5
        silManager.addCrystal(crystal);
		assertTrue(isEventCompleted(silId, 5));
		assertFalse(isEventCompleted(silId, 6));
	}
	
	private boolean isEventCompleted(int silId, int eventId) throws Exception {
		
		CommandController controller = (CommandController)ctx.getBean("commandController");

		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("eventId", String.valueOf(eventId));
    	
    	controller.isEventCompleted(request, response);
        assertEquals(200, response.getStatus());
       
        String res = response.getContentAsString().trim();
        if (res.equals("completed"))
        	return true;
        else if (res.equals("not completed"))
        	return false;
        
        throw new Exception("isEventCompleted returns " + res);
	}

}
