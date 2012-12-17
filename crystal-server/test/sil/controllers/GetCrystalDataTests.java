package sil.controllers;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.FileReader;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.dao.SilDao;
import sil.io.SilWriter;
import sil.managers.SilStorageManager;

public class GetCrystalDataTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetCrystalDataBL15Left() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 1; // sil 1 is currently assigned to BL1-5 left
        String beamline = "BL1-5";
        String cassetteIndex = "1"; // left
    	request.addParameter("beamline", beamline);
    	request.addParameter("forCassetteIndex", cassetteIndex);
    	
    	controller.getCrystalData(request, response);
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        
        SilDao silDao = (SilDao)ctx.getBean("silDao");
        SilInfo info = silDao.getSilInfo(silId);
        assertNotNull(info);

        SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
        Sil sil = storageManager.loadSil(silId);
        SilWriter writer = storageManager.getTclWriter();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        writer.write(out, sil);
        String expectedContent = out.toString().trim();
        
        assertEquals(expectedContent.toString(), content);
        
	}

	// No sil assigned to the requested beamline position.
	public void testGetCrystalDataInvalidBeamline() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 1; // sil 1 is currently assigned to BL1-5 left
        String beamline = "BLXX-XX";
        String cassetteIndex = "2"; // middle
        String position = "middle";
    	request.addParameter("beamline", beamline);
    	request.addParameter("forCassetteIndex", cassetteIndex);
    	
    	controller.getCrystalData(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Beamline " + beamline + " " + position + " does not exist.", response.getErrorMessage());
 
	}
	
	// No sil assigned to the requested beamline position.
	public void testGetCrystalDataInvalidBeamlinePosition() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 1; // sil 1 is currently assigned to BL1-5 left
        String beamline = "BL1-5";
        String cassetteIndex = "5";
        String position = "center";
    	request.addParameter("beamline", beamline);
    	request.addParameter("forCassetteIndex", cassetteIndex);
    	
    	controller.getCrystalData(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Invalid cassettePosition or forCassetteIndex", response.getErrorMessage());
 
	}
	
	// No sil assigned to the requested beamline position.
	public void testGetCrystalDataNoSilAtBeamline() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        int silId = 1; // sil 1 is currently assigned to BL1-5 left
        String beamline = "BL1-5";
        String cassetteIndex = "2"; // middle
        String position = "middle";
    	request.addParameter("beamline", beamline);
    	request.addParameter("forCassetteIndex", cassetteIndex);
    	
    	controller.getCrystalData(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("No sil at beamline " + beamline + " " + position, response.getErrorMessage());
 
	}
}
