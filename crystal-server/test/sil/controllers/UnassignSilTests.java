package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.dao.SilDao;
import sil.managers.SilStorageManager;

public class UnassignSilTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	// Missing beamline parameter
	public void testMissingBeamlineParameter() throws Exception {

		CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
         request.addParameter("cassettePosition", "1"); // BL9-1 left
        		
        // Unassign sil at this beamline position
		controller.unassignSil(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing beamline parameter", response.getErrorMessage());
        			
	}	
	
	// Staff annikas unassigns sil that belongs to tigerw.
	// which is currently assigned to BL9-1 left.
	// Sil is unlocked.
	public void testStaffUnassignSil() throws Exception {

		CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		
		String beamline = "BL9-1";

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
        request.addParameter("forBeamLine", beamline);
        request.addParameter("cassettePosition", "1"); // BL9-1 left
        
        BeamlineInfo info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        SilInfo silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(5, silInfo.getId());
        assertEquals(tigerw.getLoginName(), silInfo.getOwner());
		
        // Unassign sil at this beamline position
		controller.unassignSil(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK", response.getContentAsString());
        			
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        silInfo = info.getSilInfo();
        assertEquals(0, silInfo.getId());	
	}
	
	// Staff annikas unassigns all sills at BL9-1
	public void testStaffUnassignAllSilsAtBeamline() throws Exception {

		CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		
		String beamline = "BL9-1";

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
        request.addParameter("forBeamLine", beamline);
        
        BeamlineInfo info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        SilInfo silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(5, silInfo.getId());
        assertEquals(tigerw.getLoginName(), silInfo.getOwner());

        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.MIDDLE);
        assertNotNull(info);
        assertEquals(11, info.getId());
        silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(2, silInfo.getId());
        assertEquals(annikas.getLoginName(), silInfo.getOwner());

        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.RIGHT);
        assertNotNull(info);
        assertEquals(12, info.getId());
        silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(7, silInfo.getId());
        assertEquals(lorenao.getLoginName(), silInfo.getOwner());
        
        // Unassign sil at this beamline position
		controller.unassignSil(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK", response.getContentAsString());
        			
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        silInfo = info.getSilInfo();
        assertEquals(0, silInfo.getId());	
        
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.MIDDLE);
        assertNotNull(info);
        assertEquals(11, info.getId());
        silInfo = info.getSilInfo();
        assertEquals(0, silInfo.getId());	
        
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.RIGHT);
        assertNotNull(info);
        assertEquals(12, info.getId());
        silInfo = info.getSilInfo();
        assertEquals(0, silInfo.getId());	
        
	}
	
	// User tigerw unassigns his own sil
	// which is currently assigned to BL9-1 left.
	// Sil is unlocked.
	public void testUserUnassignSil() throws Exception {

		CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		
		String beamline = "BL9-1";

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
        request.addParameter("forBeamLine", beamline);
        request.addParameter("cassettePosition", "1"); // BL9-1 left
        
        BeamlineInfo info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        SilInfo silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(5, silInfo.getId());
        assertEquals(tigerw.getLoginName(), silInfo.getOwner());
		
        // Unassign sil at this beamline position
		controller.unassignSil(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK", response.getContentAsString());
        			
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        silInfo = info.getSilInfo();
        assertEquals(0, silInfo.getId());	
	}

	// User sergiog unassigns sil that belongs to tigerw
	// which is currently assigned to BL9-1 left.
	// Sil is unlocked.
	// THIS SHOULD FAIL under interceptor
	// This user has no access to this beamline
	public void testUserUnassignSilBeamlinePermissionDenied() throws Exception {

		CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		
		String beamline = "BL9-1";

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
        request.addParameter("forBeamLine", beamline);
        request.addParameter("cassettePosition", "1"); // BL9-1 left
        
        BeamlineInfo info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        SilInfo silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(5, silInfo.getId());
        assertEquals(tigerw.getLoginName(), silInfo.getOwner());
		
        // Unassign sil at this beamline position
		controller.unassignSil(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("User has no permission to access beamline BL9-1", response.getErrorMessage());
        
        // Beamline is left unchanged.
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(10, info.getId());
        silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(5, silInfo.getId());
        assertEquals(tigerw.getLoginName(), silInfo.getOwner());
	}
	
	// Sil is locked
	// User cannot unassign locked sil.
	public void testUserUnassignLockedSil() throws Exception {

		CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		
		String beamline = "BL12-2";
		int silId = 11;
		int beamlineId = 26;

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
        request.addParameter("forBeamLine", beamline);
        request.addParameter("cassettePosition", "1"); // BL12-2 left
        
        BeamlineInfo info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(beamlineId, info.getId());
        SilInfo silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(silId, silInfo.getId());
        assertEquals(sergiog.getLoginName(), silInfo.getOwner());
		
        // Unassign sil at this beamline position
		controller.unassignSil(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Sil " + String.valueOf(silId) + " is locked.", response.getErrorMessage());
        
        // Beamline is left unchanged.
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(beamlineId, info.getId());
        silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(silId, silInfo.getId());
        assertEquals(sergiog.getLoginName(), silInfo.getOwner());
	}
		
	// Sil is locked
	// Staff can unassign locked sil.
	public void testStaffUnassignLockedSil() throws Exception {

		CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		
		String beamline = "BL12-2";
		int silId = 11;
		int beamlineId = 26;

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
        request.addParameter("forBeamLine", beamline);
        request.addParameter("cassettePosition", "1"); // BL12-2 left
        
        BeamlineInfo info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(beamlineId, info.getId());
        SilInfo silInfo = info.getSilInfo();
        assertNotNull(silInfo);
        assertEquals(silId, silInfo.getId());
        assertEquals(sergiog.getLoginName(), silInfo.getOwner());
		
        // Unassign sil at this beamline position
		controller.unassignSil(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK", response.getContentAsString());
        
        // Beamline is left unchanged.
        info = silDao.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
        assertNotNull(info);
        assertEquals(beamlineId, info.getId());
        silInfo = info.getSilInfo();
        assertEquals(0, silInfo.getId());
	}
}
