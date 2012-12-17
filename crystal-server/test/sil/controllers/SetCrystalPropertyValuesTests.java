package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class SetCrystalPropertyValuesTests extends ControllerTestBase {
	
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
	public void testSetCrystalPropertyValues() throws Exception {
		
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
		assertEquals("Reorientable", 0, crystal.getResult().getReorientable());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("Reorientable", 0, crystal.getResult().getReorientable());
		
		
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
        request.addParameter("propertyName", "ReOrientable");
        request.addParameter("propertyValues", buf.toString());

		controller.setCrystalPropertyValues(request, response);
		if (response.getStatus() != 200)
			fail(response.getErrorMessage());
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		// A8
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A8");
		assertEquals("row", 7, crystal.getRow());
		assertEquals("port", "A8", crystal.getPort());
		assertEquals("CrystalID", "A8", crystal.getCrystalId());
		assertEquals("Reorientable", 1, crystal.getResult().getReorientable());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("Reorientable", 1, crystal.getResult().getReorientable());
		// L6
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L6");
		assertEquals("row", 93, crystal.getRow());
		assertEquals("port", "L6", crystal.getPort());
		assertEquals("CrystalID", "L6", crystal.getCrystalId());
		assertEquals("Reorientable", 0, crystal.getResult().getReorientable());
	}
	
	public void testSetCrystalPropertyValuesDouble() throws Exception {
		
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
		assertEquals("Score", 0.0, crystal.getResult().getAutoindexResult().getScore());
		
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        StringBuffer buf = new StringBuffer();
        buf.append(String.valueOf("1.01"));
        for (int i = 2; i <= 96; ++i) {
        	buf.append(" " + String.valueOf(i) + ".01");
        }
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("propertyName", "Score");
        request.addParameter("propertyValues", buf.toString());

        // Add crystal
		controller.setCrystalPropertyValues(request, response);
		if (response.getStatus() != 200)
			fail(response.getErrorMessage());
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
		assertEquals("Score", 8.01, crystal.getResult().getAutoindexResult().getScore());
		// L5
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L5");
		assertEquals("row", 92, crystal.getRow());
		assertEquals("port", "L5", crystal.getPort());
		assertEquals("CrystalID", "L5", crystal.getCrystalId());
		assertEquals("Score", 93.01, crystal.getResult().getAutoindexResult().getScore());
		// L6
		crystal = SilUtil.getCrystalFromCrystalId(sil, "L6");
		assertEquals("row", 93, crystal.getRow());
		assertEquals("port", "L6", crystal.getPort());
		assertEquals("CrystalID", "L6", crystal.getCrystalId());
		assertEquals("Score", 94.01, crystal.getResult().getAutoindexResult().getScore());
	}
	
}
