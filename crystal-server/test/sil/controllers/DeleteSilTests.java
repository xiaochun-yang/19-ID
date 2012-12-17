package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.SilInfo;
import sil.managers.SilStorageManager;

public class DeleteSilTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	
	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}
	
	// User can delete unlocked and unassigned sil
	public void testDeleteSil() throws Exception {
		
	   	int silId = 15; // unlocked and unassigned
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	assertNotNull(info);
    	checkSilNotLocked(info);
    	checkSilNotAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(200, response.getStatus());
        assertEquals("OK", response.getContentAsString().trim());
        
        // Sil has been deleted
        info = storageManager.getSilInfo(silId);
        checkSilDoesNotExist(info);
        
	}

	// User cannot delete assigned sil
	public void testUserDeleteAssignedSil() throws Exception {
		
	   	int silId = 14; // assigned but not locked
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	assertNotNull(info);
    	checkSilNotLocked(info);
    	checkSilAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Cannot delete sil currently assigned to a beamline.", response.getErrorMessage());
        
        // Sil is unchanged.
    	info = storageManager.getSilInfo(silId);
    	assertNotNull(info);
    	checkSilNotLocked(info);
    	checkSilAssigned(info);
	}
	
	// User cannot delete locked sil
	public void testUserDeleteLockedSil() throws Exception {
		
	   	int silId = 12; // locked but not assigned
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilNotAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Cannot delete locked sil.", response.getErrorMessage());
        
        // Sil is unchanged.
        info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilNotAssigned(info);
	}
	
	// User cannot delete locked and assigned sil
	public void testUserDeleteLockedAndAssignedSil() throws Exception {
		
	   	int silId = 11; // locked and assigned
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Cannot delete locked sil.", response.getErrorMessage());
        
        // Sil is unchanged.
        info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilAssigned(info);
	}
	
	// Delete non existent sil
	public void testUserDeleteNonExistentSil() throws Exception {
		
	   	int silId = 2000000; // does not exist.
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	checkSilDoesNotExist(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Sil " + silId + " does not exist.", response.getErrorMessage());
        
	}
	
	// User cannot delete sil he does not own.
	public void testUserDeleteSomebodyElseSil() throws Exception {
		
	   	int silId = 1; // belongs to annikas
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("User " + sergiog.getLoginName() + " has no permission to access sil " + silId, response.getErrorMessage());
        
        // Sil is unchanged.
        info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilAssigned(info);
	}
	
	// Staff cannot delete assigned sil
	public void testStaffDeleteAssignedSil() throws Exception {
		
	   	int silId = 3; // assigned but not locked
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilNotLocked(info);
    	checkSilAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Cannot delete sil currently assigned to a beamline.", response.getErrorMessage());
        
        // Sil is unchanged.
    	info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilNotLocked(info);
    	checkSilAssigned(info);
	}
	
	// Staff cannot delete locked sil
	public void testStaffDeleteLockedSil() throws Exception {
		
	   	int silId = 17; // locked but not assigned
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	assertNotNull(info);
    	checkSilLocked(info);
    	checkSilNotAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Cannot delete locked sil.", response.getErrorMessage());
        
        // Sil is unchanged.
        info = storageManager.getSilInfo(silId);
        assertNotNull(info);
    	checkSilLocked(info);
    	checkSilNotAssigned(info);
	}
	
	// Staff cannot delete locked and assigned sil
	public void testStaffDeleteLockedAndAssignedSil() throws Exception {
		
	   	int silId = 1; // locked and assigned
	    
	   	CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	SilInfo info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilAssigned(info);
    	
    	request.addParameter("silId", String.valueOf(silId));
		
		// Add a new sil
        controller.deleteSil(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Cannot delete locked sil.", response.getErrorMessage());
        
        // Sil is unchanged.
        info = storageManager.getSilInfo(silId);
    	checkSilExists(info);
    	checkSilLocked(info);
    	checkSilAssigned(info);
	}
	
}
