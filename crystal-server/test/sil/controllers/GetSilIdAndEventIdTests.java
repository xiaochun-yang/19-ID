package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.managers.SilStorageManager;

public class GetSilIdAndEventIdTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetSilIdAndEventId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
        storageManager.setLatestEventId(1, 600);
        storageManager.setLatestEventId(3, 278);
    	
        String beamline = "BL1-5";
    	request.addParameter("beamline", beamline);
    	controller.getSilIdAndEventId(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("-1 -1 1 600 -1 -1 3 278", response.getContentAsString().trim());
       
	}
	
	public void testGetSilIdAndEventIdDetail() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
        storageManager.setLatestEventId(1, 600);
        storageManager.setLatestEventId(3, 278);
    	
        String beamline = "BL1-5";
    	request.addParameter("beamline", beamline);
    	request.addParameter("detail", "true");
    	controller.getSilIdAndEventId(request, response);
        assertEquals(200, response.getStatus());
        StringBuffer buf1 = new StringBuffer();
        buf1.append("0");
        for (int i = 1; i < 96; ++i) {
        	buf1.append(" 0");
        }
        StringBuffer buf2 = new StringBuffer();
        buf2.append("0");
        for (int i = 1; i < 64; ++i) {
        	buf2.append(" 0");
        }
        String expected = "-1 -1 {}\n1 600 {" + buf1.toString() + "}\n-1 -1 {}\n3 278 {" + buf2.toString() + "}";
        assertEquals(expected, response.getContentAsString().trim());
       
	}
		
	public void testGetLatestEventIdMissingBeamline() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	controller.getSilIdAndEventId(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing beamline parameter", response.getErrorMessage());
        
	}
	
	public void testGetLatestEventIdNonExistentBeamline() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        String beamline = "BLXXX-XXXX";
    	request.addParameter("beamline", beamline);
    	controller.getSilIdAndEventId(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Beamline " + beamline + " does not exist.", response.getErrorMessage());
        
	}
}
