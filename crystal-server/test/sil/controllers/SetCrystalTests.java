package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class SetCrystalTests extends ControllerTestBase {
	
	private int silId = 1;
	private String crystalId = "A2";		
	private String port = "A2";
	private int row = 1;
	private String directory = "A2";
	private long uniqueId = 2000002;
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testSetCrystal() throws Exception {
		setCrystal(String.valueOf(uniqueId), String.valueOf(row));
	}
	
	public void testSetCrystalMissingUniqueId() throws Exception {
		setCrystal(null, String.valueOf(row));
	}
	
	public void testSetCrystalInvalidUniqueId() throws Exception {
		setCrystal("", String.valueOf(row));
	}

	
	public void setCrystal(String uniqueIdStr, String rowStr) throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertEquals("row", row, crystal.getRow());
		assertEquals("port", port, crystal.getPort());
		assertEquals("uniqueId", uniqueId, crystal.getUniqueId());
		assertEquals("CrystalID", crystalId, crystal.getCrystalId());
		// general data
		assertEquals("Directory", directory, crystal.getData().getDirectory());
		assertNull("Protein", crystal.getData().getProtein());
		assertNull("Comment", crystal.getData().getComment());
		assertNull("FreezingCond", crystal.getData().getFreezingCond());
		assertNull("CrystalCond", crystal.getData().getCrystalCond());
		assertNull("Metal", crystal.getData().getMetal());
		assertNull("Priority", crystal.getData().getPriority());
		assertNull("Person", crystal.getData().getPerson());
		assertNull("CrystalURL", crystal.getData().getCrystalUrl());
		assertNull("ProteinURL", crystal.getData().getProteinUrl());
		assertNull("Move", crystal.getData().getMove());
		// autoindex result
		assertNull("SystemWarning", crystal.getResult().getAutoindexResult().getWarning());
		assertEquals("Mosaicity", 0.0, crystal.getResult().getAutoindexResult().getMosaicity());
		assertEquals("ISigma", 0.0, crystal.getResult().getAutoindexResult().getIsigma());
		assertEquals("Score", 0.0, crystal.getResult().getAutoindexResult().getScore());
		assertNull("AutoindexImages", crystal.getResult().getAutoindexResult().getImages());
		assertEquals("UnitCell", "0.0 0.0 0.0 0.0 0.0 0.0", crystal.getResult().getAutoindexResult().getUnitCell().toString());
		assertEquals("Rmsr", 0.0, crystal.getResult().getAutoindexResult().getRmsd());
		assertNull("BravaisLattice", crystal.getResult().getAutoindexResult().getBravaisLattice());
		assertEquals("Resolution", 0.0, crystal.getResult().getAutoindexResult().getResolution());
		assertNull("AutoindexDir", crystal.getResult().getAutoindexResult().getDir());
		assertEquals("Solution", -1, crystal.getResult().getAutoindexResult().getBestSolution());
		
		// Add crystal
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("Port", port);
        if (uniqueIdStr != null)
        	request.addParameter("uniqueId", uniqueIdStr);
        if (rowStr != null)
        	request.addParameter("row", rowStr);
        request.addParameter("Directory", "/data/annikas/newdir");
        request.addParameter("Protein", "new protein");
        request.addParameter("Comment", "new comment");
        request.addParameter("FreezingCond", "new freezing cond");
        request.addParameter("CrystalCond", "new crystal cond");
        request.addParameter("Metal", "new metal");
        request.addParameter("Priority", "highest priority");
        request.addParameter("Person", "sergiog");
        request.addParameter("CrystalURL", "http://www.annikas.com/crystal/A2");
        request.addParameter("ProteinURL", "http://www.annikas.com/protein/A2");
        request.addParameter("Move", "from silId=22,port=L1");
        // autoindex result
        request.addParameter("SystemWarning", "very very good");
        request.addParameter("Mosaicity", "0.5");
        request.addParameter("ISigma", "0.99");
        request.addParameter("Score", "0.2");
        request.addParameter("AutoindexImages", "/data/annikas/images/A2_001.img /data/annikas/images/A2_002.img");
        request.addParameter("UnitCell", "100.0 100.0 100.0 80.0 89.0 90.0");
        request.addParameter("Rmsr", "0.11");
        request.addParameter("BravaisLattice", "P422");
        request.addParameter("Resolution", "3.0");
        request.addParameter("AutoindexDir", "/data/annikas/autoindex/A2");
        request.addParameter("Solution", "5");

        // Add crystal
		controller.setCrystal(request, response);
		if (response.getStatus() != 200)
			System.out.println("response error message = " + response.getErrorMessage());
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertEquals("row", 1, crystal.getRow());
		assertEquals("uniqueId", uniqueId, crystal.getUniqueId());
		assertEquals("port", port, crystal.getPort());
		assertEquals("CrystalID", crystalId, crystal.getCrystalId());
		// general data
		assertEquals("Directory", "/data/annikas/newdir", crystal.getData().getDirectory());
		assertEquals("Protein", "new protein", crystal.getData().getProtein());
		assertEquals("Comment", "new comment", crystal.getData().getComment());
		assertEquals("FreezingCond", "new freezing cond", crystal.getData().getFreezingCond());
		assertEquals("CrystalCond", "new crystal cond", crystal.getData().getCrystalCond());
		assertEquals("Metal", "new metal", crystal.getData().getMetal());
		assertEquals("Priority", "highest priority", crystal.getData().getPriority());
		assertEquals("Person", "sergiog", crystal.getData().getPerson());
		assertEquals("CrystalURL", "http://www.annikas.com/crystal/A2", crystal.getData().getCrystalUrl());
		assertEquals("ProteinURL", "http://www.annikas.com/protein/A2", crystal.getData().getProteinUrl());
		assertEquals("Move", "from silId=22,port=L1", crystal.getData().getMove());
		// autoindex result
		assertEquals("SystemWarning", "very very good", crystal.getResult().getAutoindexResult().getWarning());
		assertEquals("Mosaicity", 0.5, crystal.getResult().getAutoindexResult().getMosaicity());
		assertEquals("ISigma", 0.99, crystal.getResult().getAutoindexResult().getIsigma());
		assertEquals("Score", 0.2, crystal.getResult().getAutoindexResult().getScore());
		assertEquals("AutoindexImages", "/data/annikas/images/A2_001.img /data/annikas/images/A2_002.img", crystal.getResult().getAutoindexResult().getImages());
		assertEquals("UnitCell", "100.0 100.0 100.0 80.0 89.0 90.0", crystal.getResult().getAutoindexResult().getUnitCell().toString());
		assertEquals("Rmsr", 0.11, crystal.getResult().getAutoindexResult().getRmsd());
		assertEquals("BravaisLattice", "P422", crystal.getResult().getAutoindexResult().getBravaisLattice());
		assertEquals("Resolution", 3.0, crystal.getResult().getAutoindexResult().getResolution());
		assertEquals("AutoindexDir", "/data/annikas/autoindex/A2", crystal.getResult().getAutoindexResult().getDir());
		assertEquals("Solution", 5, crystal.getResult().getAutoindexResult().getBestSolution());
	}
	
	public void testSetCrystalReorientable() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertEquals("row", row, crystal.getRow());
		assertEquals("port", port, crystal.getPort());
		assertEquals("uniqueId", uniqueId, crystal.getUniqueId());
		assertEquals("CrystalID", crystalId, crystal.getCrystalId());
		// reorientable
		assertEquals(0, crystal.getResult().getReorientable());
		assertEquals(null, crystal.getResult().getReorientInfo());
		assertEquals(null, crystal.getResult().getReorientPhi());
		
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("Port", port);
        request.addParameter("uniqueId", String.valueOf(uniqueId));
//        request.addParameter("CrystalID", crystalId);
        request.addParameter("ReOrientable", "1");
        request.addParameter("ReOrientInfo", "/data/annikas/screening/reorient_info.txt");
        request.addParameter("ReOrientPhi", "30.65");

        // Set crystal
		controller.setCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertEquals("row", 1, crystal.getRow());
		assertEquals("uniqueId", uniqueId, crystal.getUniqueId());
		assertEquals("port", port, crystal.getPort());
		assertEquals("CrystalID", crystalId, crystal.getCrystalId());
		// reorientable
		assertEquals(1, crystal.getResult().getReorientable());
		assertEquals("/data/annikas/screening/reorient_info.txt", crystal.getResult().getReorientInfo());
		assertEquals("30.65", crystal.getResult().getReorientPhi());
		
	}
		
	public void testSetCrystalMissingSilId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
		
		// Add crystal
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("uniqueId", String.valueOf(uniqueId));
//        request.addParameter("CrystalID", crystalId);
        
        // Add crystal
		controller.setCrystal(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing silId parameter", response.getErrorMessage());

	}
	
	public void testSetCrystalMissingUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
		
		// Set crystal
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("silId", String.valueOf(silId));
        
		controller.setCrystal(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());

	}
	
	public void testSetCrystalInvalidUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
		
		// Set crystal
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("uniqueId", "");
        request.addParameter("row", "");
        
		controller.setCrystal(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());

	}

	public void testSetCrystalUnknownProperties() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertEquals("row", row, crystal.getRow());
		assertEquals("uniqueId", uniqueId, crystal.getUniqueId());
		assertEquals("port", port, crystal.getPort());
		assertEquals("CrystalID", crystalId, crystal.getCrystalId());
		// general data
		assertEquals("Directory", directory, crystal.getData().getDirectory());
		assertNull("Protein", crystal.getData().getProtein());

		
		// Add crystal
		request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("Port", port);
        request.addParameter("uniqueId", String.valueOf(uniqueId));
//        request.addParameter("CrystalID", crystalId);
        request.addParameter("AAAA", "Nonexistent");
        request.addParameter("Protein", "new protein");
        request.addParameter("Directory", "/data/annikas/newdir");

        // Add crystal
		controller.setCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertEquals("row", 1, crystal.getRow());
		assertEquals("uniqueId", uniqueId, crystal.getUniqueId());
		assertEquals("port", port, crystal.getPort());
		assertEquals("CrystalID", crystalId, crystal.getCrystalId());
		// general data
		assertEquals("Directory", "/data/annikas/newdir", crystal.getData().getDirectory());
		assertEquals("Protein", "new protein", crystal.getData().getProtein());

	}
}
