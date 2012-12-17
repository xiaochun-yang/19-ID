package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class SetCrystalAttributeTests extends ControllerTestBase {
	
	private int silId = 1;
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}
	
	// 1 or 0
	public void testSetCrystalAttributeSelected() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        StringBuffer buf = new StringBuffer();
        buf.append("1");
        for (int i = 1; i < 96; ++i) {
        	if ((i == 7) || (i == 92))
        		buf.append(" 1");
         	else
        		buf.append(" 0");
        }
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("attrName", "selected");
        request.addParameter("attrValues", buf.toString());

		controller.setCrystalAttribute(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", true, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", true, crystal.getSelected());
		// L6
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L6");
		assertEquals("row", 93, crystal.getRow());
		assertEquals("port", "L6", crystal.getPort());
		assertEquals("CrystalID", "L6", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
	}
	
	// true or false
	public void testSetCrystalAttributeSelectedTrueOrFalse() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        StringBuffer buf = new StringBuffer();
        buf.append("true");
        for (int i = 1; i < 96; ++i) {
        	if ((i == 7) || (i == 92))
        		buf.append(" true");
         	else
        		buf.append(" false");
        }
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("attrName", "selected");
        request.addParameter("attrValues", buf.toString());

        // Add crystal
		controller.setCrystalAttribute(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", true, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", true, crystal.getSelected());
		// L6
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L6");
		assertEquals("row", 93, crystal.getRow());
		assertEquals("port", "L6", crystal.getPort());
		assertEquals("CrystalID", "L6", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
	}
	
	// User '+' as separator instead of space ' '.
	public void testSetCrystalAttributeSelectedPlusSign() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        StringBuffer buf = new StringBuffer();
        buf.append("1");
        for (int i = 1; i < 96; ++i) {
        	if ((i == 7) || (i == 92))
        		buf.append("+1");
         	else
        		buf.append("+0");
        }
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("attrName", "selected");
        request.addParameter("attrValues", buf.toString());

        // Add crystal
		controller.setCrystalAttribute(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", true, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", true, crystal.getSelected());
		// L6
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L6");
		assertEquals("row", 93, crystal.getRow());
		assertEquals("port", "L6", crystal.getPort());
		assertEquals("CrystalID", "L6", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
	}
	
	public void testSetCrystalAttributeSelectedAllOn() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("attrName", "selected");
        request.addParameter("attrValues", "all");

		controller.setCrystalAttribute(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		for (int i = 0; i < 96; ++i) {
			crystal = SilUtil.getCrystalFromRow(sil, i);
			assertEquals("selected", true, crystal.getSelected());
		}
	}

	public void testSetCrystalAttributeSelectedAllOff() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selected", false, crystal.getSelected());
		
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("attrName", "selected");
        request.addParameter("attrValues", "none");

		controller.setCrystalAttribute(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		for (int i = 0; i < 96; ++i) {
			crystal = SilUtil.getCrystalFromRow(sil, i);
			assertEquals("selected", false, crystal.getSelected());
		}
	}
	
	public void testSetCrystalAttributeSelectedForQueue() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selectedForQueue", false, crystal.getSelected());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selectedForQueue", false, crystal.getSelected());
		
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        StringBuffer buf = new StringBuffer();
        buf.append("1");
        for (int i = 1; i < 96; ++i) {
        	if ((i == 7) || (i == 92))
        		buf.append(" 1");
         	else
        		buf.append(" 0");
        }
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("attrName", "selectedForQueue");
        request.addParameter("attrValues", buf.toString());

		controller.setCrystalAttribute(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("selectedForQueue", true, crystal.isSelectedForQueue());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("selectedForQueue", true, crystal.isSelectedForQueue());
		// L6
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L6");
		assertEquals("row", 93, crystal.getRow());
		assertEquals("port", "L6", crystal.getPort());
		assertEquals("CrystalID", "L6", crystal.getCrystalId());
		assertEquals("selectedForQueue", false, crystal.isSelectedForQueue());
	}

		
}
