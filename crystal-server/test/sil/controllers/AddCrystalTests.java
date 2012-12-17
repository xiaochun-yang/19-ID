package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.TestData;
import sil.app.FakeUser;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class AddCrystalTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void ttestAddCrystal() throws Exception {
		
		int silId = 21;
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
     	
    	// Check that sil 21 does not exist.
    	try {
    		Sil sil = storageManager.loadSil(silId);
    		fail("loadSil should have failed.");
    	} catch (Exception e) {
    		assertEquals("silId " + silId + " does not exist.", e.getMessage().trim());
    	}
    	
    	request.addParameter("templateName", "empty");
    	controller.createDefaultSil(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK " + String.valueOf(silId), response.getContentAsString().trim());
        
        // Check that sil 21 exists
        // and has no crystal.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertEquals(0, sil.getCrystals().size());
		
		Crystal crystal = TestData.createCrystal();
		
		// Add crystal
		request = createRequest(annikas, silId, crystal);
        response = new MockHttpServletResponse();
		
        // Add crystal
		controller.addCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal newCrystal = SilUtil.getCrystalFromCrystalId(sil, crystal.getCrystalId());
		assertNotNull(newCrystal);
		assertEquals(3000001, newCrystal.getUniqueId());
		assertEquals(crystal.getPort(), newCrystal.getPort());
		assertEquals(crystal.getCrystalId(), newCrystal.getCrystalId());
		assertEquals(crystal.getContainerId(), newCrystal.getContainerId());
		assertEquals(crystal.getData(), newCrystal.getData());
		assertEquals(crystal.getResult().getAutoindexResult(), newCrystal.getResult().getAutoindexResult());	
			
	}
	
	// Current crystal on row2 will be pushed to row3 and subsequent crystals will be pushed down by 1.
	// New crystal will go to row 2. Port can duplicate.
	public void testAddCrystalToRow2() throws Exception {
		
		int silId = 3;
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		
		// Port A2 is on row 1
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "A2");
		assertNotNull(crystal);
		assertEquals(2000194, crystal.getUniqueId());
		assertEquals(1, crystal.getRow());
		assertEquals("A2", crystal.getPort());
		assertEquals("A2", crystal.getCrystalId());
		assertEquals("A2", crystal.getData().getDirectory());
		
		// Port A3 is on row 2
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A3");
		assertNotNull(crystal);
		assertEquals(2000195, crystal.getUniqueId());
		assertEquals(2, crystal.getRow());
		assertEquals("A3", crystal.getPort());
		assertEquals("A3", crystal.getCrystalId());
		assertEquals("A3", crystal.getData().getDirectory());
		
		

		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int row = 2;
        String port = "A2";
        String crystalId = "A2_2";
        String dir = "A2_2_dir";
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("row", String.valueOf(row));
        request.addParameter("Port", port);
        request.addParameter("CrystalID", crystalId);
        request.addParameter("Directory", dir);
		
        response = new MockHttpServletResponse();
	
		controller.addCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		
		// Port A2 is still on row 1.
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A2");
		assertNotNull(crystal);
		assertEquals(2000194, crystal.getUniqueId());
		assertEquals(1, crystal.getRow());
		assertEquals("A2", crystal.getPort());
		assertEquals("A2", crystal.getCrystalId());
		assertEquals("A2", crystal.getData().getDirectory());
		
		// Row 2 now has the new crystal which is also on port A2.
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A2_2");
		assertNotNull(crystal);
		assertTrue(2000194 != crystal.getUniqueId());
		assertTrue(2000195 != crystal.getUniqueId());
		assertEquals(2, crystal.getRow());
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		assertEquals(dir, crystal.getData().getDirectory());
		
		// Port A3 now is on row 3.
		crystal = SilUtil.getCrystalFromCrystalId(sil, "A3");
		assertNotNull(crystal);
		assertEquals(2000195, crystal.getUniqueId());
		assertEquals(3, crystal.getRow());
		assertEquals("A3", crystal.getPort());
		assertEquals("A3", crystal.getCrystalId());
		assertEquals("A3", crystal.getData().getDirectory());
		
	}
	
	// Add new crystal to the row after last.
	public void testAddCrystalToNextToLastRow() throws Exception {
		
		int silId = 3;
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		
		// Port D16 is on row 63
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "D16");
		assertNotNull(crystal);
		assertEquals(2000256, crystal.getUniqueId());
		assertEquals(63, crystal.getRow());
		assertEquals("D16", crystal.getPort());
		assertEquals("D16", crystal.getCrystalId());
		assertEquals("D16", crystal.getData().getDirectory());
	
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int row = -1;
        String port = "E1";
        String crystalId = "E1";
        String dir = "E1_dir";
		
        request.addParameter("silId", String.valueOf(silId));
 //       request.addParameter("row", String.valueOf(row));
        request.addParameter("Port", port);
        request.addParameter("CrystalID", crystalId);
        request.addParameter("Directory", dir);
		
        response = new MockHttpServletResponse();
	
		controller.addCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		
		// Port D16 is still on row 63
		crystal = SilUtil.getCrystalFromCrystalId(sil, "D16");
		assertNotNull(crystal);
		assertEquals(2000256, crystal.getUniqueId());
		assertEquals(63, crystal.getRow());
		assertEquals("D16", crystal.getPort());
		assertEquals("D16", crystal.getCrystalId());
		assertEquals("D16", crystal.getData().getDirectory());
		
		// The new crystal goes to row 64.
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertTrue(2000256 != crystal.getUniqueId());
		assertEquals(64, crystal.getRow());
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		assertEquals(dir, crystal.getData().getDirectory());
			
	}
	
	private MockHttpServletRequest createRequest(FakeUser user, int silId, Crystal crystal) throws Exception {
		
		MockHttpServletRequest request = createMockHttpServletRequest(user);
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("Port", crystal.getPort());
        request.addParameter("CrystalID", crystal.getCrystalId());
        request.addParameter("ContainerID", crystal.getContainerId());
        request.addParameter("Directory", crystal.getData().getDirectory());
        request.addParameter("Protein", crystal.getData().getProtein());
        request.addParameter("Comment", crystal.getData().getComment());
        request.addParameter("FreezingCond", crystal.getData().getFreezingCond());
        request.addParameter("CrystalCond", crystal.getData().getCrystalCond());
        request.addParameter("Metal", crystal.getData().getMetal());
        request.addParameter("Priority", crystal.getData().getPriority());
        request.addParameter("Person", crystal.getData().getPerson());
        request.addParameter("CrystalURL", crystal.getData().getCrystalUrl());
        request.addParameter("ProteinURL", crystal.getData().getProteinUrl());
        request.addParameter("Move", crystal.getData().getMove());
        
        request.addParameter("SystemWarning", crystal.getResult().getAutoindexResult().getWarning());
        request.addParameter("Mosaicity", String.valueOf(crystal.getResult().getAutoindexResult().getMosaicity()));
        request.addParameter("ISigma", String.valueOf(crystal.getResult().getAutoindexResult().getIsigma()));
        request.addParameter("Score", String.valueOf(crystal.getResult().getAutoindexResult().getScore()));
        request.addParameter("AutoindexImages", crystal.getResult().getAutoindexResult().getImages());
        request.addParameter("UnitCell", crystal.getResult().getAutoindexResult().getUnitCell().toString());
        request.addParameter("Rmsr", String.valueOf(crystal.getResult().getAutoindexResult().getRmsd()));
        request.addParameter("BravaisLattice", crystal.getResult().getAutoindexResult().getBravaisLattice());
        request.addParameter("Resolution", String.valueOf(crystal.getResult().getAutoindexResult().getResolution()));
        request.addParameter("AutoindexDir", crystal.getResult().getAutoindexResult().getDir());
        request.addParameter("Solution", String.valueOf(crystal.getResult().getAutoindexResult().getBestSolution()));
	 
		return request;
	}
}
