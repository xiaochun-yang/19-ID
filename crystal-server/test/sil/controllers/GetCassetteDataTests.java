package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;

public class GetCassetteDataTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetCassetteDataBL15() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        String beamline = "BL1-5";
    	request.addParameter("beamline", beamline);
    	
    	controller.getCassetteData(request, response);
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        
        StringBuffer expectedContent = new StringBuffer("{\n");
        expectedContent.append("undefined\n");
        expectedContent.append("sil1.xls(annikas|UNKNOWN|1)\n");
        expectedContent.append("undefined\n");
        expectedContent.append("sil3.xls(annikas|UNKNOWN|3)\n");
        expectedContent.append("}");
       	
        assertEquals(expectedContent.toString(), content);
	}
		
	public void testGetCassetteDataInvalidBeamline() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        String beamline = "BLXX-XXX";
    	request.addParameter("beamline", beamline);
    	
    	controller.getCassetteData(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Beamline name or position does not exist.", response.getErrorMessage());
	}
}
