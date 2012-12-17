package sil.controllers;

import java.util.Iterator;
import java.util.Map;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class ClearCrystalImagesTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	// Clear images in group 1
	public void testClearCrystalImages1() throws Exception {
		
		int silId = 2;
		String crystalId = "A2";
		int row = 1;
		String group = "1";
		int uniqueId = 2000098;
		
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
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("group", group);
		
        // Add crystal
		controller.clearCrystalImages(request, response);
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
		checkCrystalHasOneImageInGroup(crystal, "2");		
			
	}

		
	// Clear images in group 2
	public void testClearCrystalImages2() throws Exception {
		
		int silId = 2;
		String crystalId = "A2";
		int row = 1;
		String group = "2";
		int uniqueId = 2000098;
		
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
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("group", group);
		
        // Add crystal
		controller.clearCrystalImages(request, response);
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
		checkCrystalHasOneImageInGroup(crystal, "1");
		
	}
	
	// Missing uniqueId but has row in parameter
	public void testClearCrystalImagesMissingUniqueId() throws Exception {
		
		int silId = 2;
		String crystalId = "A2";
		int row = 1;
		String group = "1";
		int uniqueId = 2000098;
		
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
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("row", String.valueOf(row));
    	request.addParameter("group", group);
		
        // Add crystal
		controller.clearCrystalImages(request, response);
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
		checkCrystalHasOneImageInGroup(crystal, "2");				
	}
	
	// Missing uniqueId and row in parameter
	public void testClearCrystalImagesMissingUniqueIdAndRow() throws Exception {
		
		int silId = 2;
		String crystalId = "A2";
		int row = 1;
		String group = "1";
		int uniqueId = 2000098;
		
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
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("group", group);
		
        // Add crystal
		controller.clearCrystalImages(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());        			
	}
	
	// Invalid uniqueId but has row parameter
	public void testClearCrystalImagesInvalidUniqueId() throws Exception {
		
		int silId = 2;
		String crystalId = "A2";
		int row = 1;
		String group = "1";
		int uniqueId = 2000098;
		
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
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", "");
    	request.addParameter("row", String.valueOf(row));
    	request.addParameter("group", group);
		
        // Add crystal
		controller.clearCrystalImages(request, response);       
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
		checkCrystalHasOneImageInGroup(crystal, "2");	
        			
	}
	
	// Invalid uniqueId and row parameter
	public void testClearCrystalImagesInvalidUniqueIdAndRow() throws Exception {
		
		int silId = 2;
		String crystalId = "A2";
		int row = 1;
		String group = "1";
		int uniqueId = 2000098;
		
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
		
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", "-1");
    	request.addParameter("row", "-1");
    	request.addParameter("group", group);
		
		controller.clearCrystalImages(request, response);       
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());   
        			
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
	
}
