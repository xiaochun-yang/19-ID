package sil.controllers;

import java.io.ByteArrayOutputStream;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Sil;
import sil.io.SilWriter;
import sil.managers.SilStorageManager;

public class GetSilTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	
	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetSil() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 1;
    	
        request.setParameter("silId", String.valueOf(silId));
    	controller.getSil(request, response);
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        
        SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
        Sil sil = storageManager.loadSil(silId);
        
        SilWriter writer = (SilWriter)ctx.getBean("silXmlWriter");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        writer.write(out, sil);
        String expectedContent = out.toString().trim();
        assertEquals(expectedContent, content);
        System.out.println(content);
	}

}
