package sil.controllers;

import java.util.Iterator;
import java.util.Map;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.AutoindexResult;
import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.Sil;
import sil.beans.SpotfinderResult;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class ClearCrystalTests extends ControllerTestBase {
		
	private int silId = 2;
	private String crystalId = "A6";
	private int row = 5;
	private int uniqueId = 2000102;
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	// clear all results and images
	public void testClearCrystalImagesAndResults() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("clearImages", "true");
    	request.addParameter("clearSpot", "true");
    	request.addParameter("clearAutoindex", "true");
    	request.addParameter("clearSystemWarning", "true");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 4", response.getContentAsString());
        		
        // Check that sil has this crystal and one image. 
        // Check that it does not have image in group1.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		assertEquals(0, crystal.getImages().size());
		checkCrystalDoesNotHaveAutoindexResult(crystal);
		checkCrystalDoesNotHaveSystemWarning(crystal);
	}

		
	// Only clear crystal images (including their spotfinder results)
	public void testClearCrystalImages() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("clearImages", "true");
    	request.addParameter("clearSpot", "false");
    	request.addParameter("clearAutoindex", "false");
    	request.addParameter("clearSystemWarning", "false");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that sil has this crystal and one image. 
        // Check that it does not have image in group1.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		// No longer has any image
		assertEquals(0, crystal.getImages().size());
		// Still has autoindex result
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
	}
	
	// Missing uniqueId but has row parameter
	public void testClearCrystalImagesMissingUniqueId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("row", String.valueOf(row));
    	request.addParameter("clearImages", "true");
    	request.addParameter("clearSpot", "false");
    	request.addParameter("clearAutoindex", "false");
    	request.addParameter("clearSystemWarning", "false");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that sil has this crystal and one image. 
        // Check that it does not have image in group1.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		// No longer has any image
		assertEquals(0, crystal.getImages().size());
		// Still has autoindex result
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
	}
	
	// Invalid uniqueId but has row parameter
	public void testClearCrystalImagesInvalidUniqueId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", "");
    	request.addParameter("row", String.valueOf(row));
    	request.addParameter("clearImages", "true");
    	request.addParameter("clearSpot", "false");
    	request.addParameter("clearAutoindex", "false");
    	request.addParameter("clearSystemWarning", "false");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that sil has this crystal and one image. 
        // Check that it does not have image in group1.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		// No longer has any image
		assertEquals(0, crystal.getImages().size());
		// Still has autoindex result
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
	}
	
	// Missing uniqueId and row parameter
	public void testClearCrystalImagesMissingUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("clearImages", "true");
    	request.addParameter("clearSpot", "false");
    	request.addParameter("clearAutoindex", "false");
    	request.addParameter("clearSystemWarning", "false");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());
        	
	}
	
	// Invalid uniqueId and row parameter
	public void testClearCrystalImagesInvalidUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", "-1");
    	request.addParameter("row", "-1");
    	request.addParameter("clearSpot", "false");
    	request.addParameter("clearAutoindex", "false");
    	request.addParameter("clearSystemWarning", "false");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());
        	
	}
	
	// Only clear spotfinder result
	public void testClearSpotfinderResult() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("clearImages", "false");
    	request.addParameter("clearSpot", "true");
    	request.addParameter("clearAutoindex", "false");
    	request.addParameter("clearSystemWarning", "false");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that sil has this crystal and one image. 
        // Check that it does not have image in group1.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		// Still has 2 images
		checkCrystalHasTwoImages(crystal);
		// No longer has spotfinder result
		checkCrystalDoesNotHaveSpotfinderResult(crystal);
		// Still has autoindex result
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
	}

	
	// Only clear autoindex result
	public void testClearAutoindexResult() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("clearImages", "false");
    	request.addParameter("clearSpot", "false");
    	request.addParameter("clearAutoindex", "true");
    	request.addParameter("clearSystemWarning", "false");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that sil has this crystal and one image. 
        // Check that it does not have image in group1.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		// Still has 2 images
		checkCrystalHasTwoImages(crystal);
		// Still has spotfinder result
		checkCrystalHasSpotfinderResult(crystal);
		// No longer has autoindex result
		checkCrystalDoesNotHaveAutoindexResult(crystal);
		checkCrystalDoesNotHaveSystemWarning(crystal);
	}
	
	// Only clear autoindex result
	public void testClearSystemWarning() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        // Check that sil has this crystal and has 2 images.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		checkCrystalHasTwoImages(crystal);
		checkCrystalHasSpotfinderResult(crystal);
		checkCrystalHasAutoindexResult(crystal);
		checkCrystalHasSystemWarning(crystal);
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("clearImages", "false");
    	request.addParameter("clearSpot", "false");
    	request.addParameter("clearAutoindex", "false");
    	request.addParameter("clearSystemWarning", "true");
		
        // Add crystal
		controller.clearCrystal(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());
        		
        // Check that sil has this crystal and one image. 
        // Check that it does not have image in group1.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(uniqueId, crystal.getUniqueId());
		assertEquals(crystalId, crystal.getCrystalId());
		// Still has 2 images
		checkCrystalHasTwoImages(crystal);
		// Still has spotfinder result
		checkCrystalHasSpotfinderResult(crystal);
		// Still has autoindex result
		checkCrystalHasAutoindexResult(crystal);
		// No longer has autoindex warning
		checkCrystalDoesNotHaveSystemWarning(crystal);
	}
	
	private void checkCrystalHasTwoImages(Crystal crystal) {
		Map images = crystal.getImages();
		assertEquals(2, images.size()); // this crystal has 2 images.
		Iterator it = images.values().iterator();
		boolean foundImage1 = false;
		boolean foundImage2 = false;
		while (it.hasNext()) {
			Image image = (Image)it.next();
			assertNotNull(image);
			if (image.getGroup().equals("1")) {
				foundImage1 = true;
			} else if (image.getGroup().equals("2")) {
				foundImage2 = true;
			} else {
				fail("wrong image group");
			}
		}
		assertTrue(foundImage1);
		assertTrue(foundImage2);		
	}
	
	private void checkCrystalHasOneImageInGroup(Crystal crystal, String group) {
		Map images = crystal.getImages();
		assertEquals(1, images.size()); // this crystal has 1 image.
		Iterator it = images.values().iterator();
		Image image = (Image)it.next();
		assertNotNull(image);
		assertEquals(group, image.getGroup());		
	}
	
	private void checkCrystalHasSpotfinderResult(Crystal crystal) {
		Map images = crystal.getImages();
		assertTrue(images.size() > 0);
		Iterator it = images.values().iterator();
		while (it.hasNext()) {
			Image image = (Image)it.next();
			assertNotNull(image);
			SpotfinderResult res = image.getResult().getSpotfinderResult();
			assertFalse(res.getScore() == 0.0);
			assertFalse(res.getSpotShape() == 0.0);
			assertFalse(res.getDiffractionStrength() == 0.0);
			assertFalse(res.getResolution() == 0.0);
			
		}		
	}
	
	private void checkCrystalDoesNotHaveSpotfinderResult(Crystal crystal) {
		Map images = crystal.getImages();
		assertTrue(images.size() > 0);
		Iterator it = images.values().iterator();
		while (it.hasNext()) {
			Image image = (Image)it.next();
			assertNotNull(image);
			SpotfinderResult res = image.getResult().getSpotfinderResult();
			assertEquals(0.0, res.getScore());
			assertEquals(0.0, res.getSpotShape());
			assertEquals(0.0, res.getDiffractionStrength());
			assertEquals(0.0, res.getResolution());
			
		}		
	}	
	
	private void checkCrystalHasAutoindexResult(Crystal crystal) {
		AutoindexResult res = crystal.getResult().getAutoindexResult();
		assertNotNull(res);
		assertFalse(res.getScore() == 0.0);
		assertNotNull(res.getImages());
		assertNotNull(res.getDir());
		assertFalse(res.getResolution() == 0.0);
	}
	
	private void checkCrystalDoesNotHaveAutoindexResult(Crystal crystal) {
		AutoindexResult res = crystal.getResult().getAutoindexResult();
		assertNotNull(res);
		assertEquals(0.0, res.getScore());
		assertNull(res.getImages());
		assertNull(res.getDir());
		assertEquals(0.0, res.getResolution());
	}
	
	private void checkCrystalHasSystemWarning(Crystal crystal) {
		AutoindexResult res = crystal.getResult().getAutoindexResult();
		assertNotNull(res);
		assertNotNull(res.getWarning());
	}
	private void checkCrystalDoesNotHaveSystemWarning(Crystal crystal) {
		AutoindexResult res = crystal.getResult().getAutoindexResult();
		assertNotNull(res);
		assertNull(res.getWarning());
	}
	
}
