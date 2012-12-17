package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.app.FakeUser;
import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.Sil;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class AddCrystalImageTests extends ControllerTestBase {

	private int silId = 1;
	private String imageDir = "/data/annikas/screening/1";
	private int row = 5;
	private String port = "A6";
	private String crystalId = "A6";
	private long uniqueId = 2000006;
	private String group = "1";
	private String imageName = "A6_001.img";
	private String small = "A6_001_small.jpg";
	private String medium = "A6_001_medium.jpg";
	private String large = "A6_001_large.jpg";
	private String jpeg = "A6_001.jpg";
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testAddCrystalImage() throws Exception {
				
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas, silId, uniqueId);
        MockHttpServletResponse response = new MockHttpServletResponse();
		
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        // Check that image does not exist in group 1 in A6.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertEquals(-1, sil.getInfo().getEventId());
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNotNull(crystal);
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		Image image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNull(image);
		
		// Add image to group 1 in A6.
        controller.addCrystalImage(request, response);	
        assertEquals(200, response.getStatus());
//        assertEquals("OK 1", response.getContentAsString());
		
		// Check that image exists in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNotNull(crystal);
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNotNull(image);
		assertEquals(imageDir, image.getDir());
		assertEquals(imageName, image.getName());
		assertEquals(group, image.getGroup());
		assertEquals(small, image.getData().getSmall());
		assertEquals(medium, image.getData().getMedium());
		assertEquals(large, image.getData().getLarge());
		assertEquals(jpeg, image.getData().getJpeg());		
	}
	
	// Invalid uniqueId but valid row.
	public void testAddCrystalImageMissingUniqueId() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas, silId, uniqueId);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        request.addParameter("row", String.valueOf(row));
		
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        // Check that image does not exist in group 1 in A6.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertEquals(-1, sil.getInfo().getEventId());
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNotNull(crystal);
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		Image image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNull(image);
		
		// Add image to group 1 in A6.
        controller.addCrystalImage(request, response);	
        assertEquals(200, response.getStatus());
		
		// Check that image exists in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNotNull(crystal);
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNotNull(image);
		assertEquals(imageDir, image.getDir());
		assertEquals(imageName, image.getName());
		assertEquals(group, image.getGroup());
		assertEquals(small, image.getData().getSmall());
		assertEquals(medium, image.getData().getMedium());
		assertEquals(large, image.getData().getLarge());
		assertEquals(jpeg, image.getData().getJpeg());		
	}
	
	public void testAddCrystalImageInvalidUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas, silId, 1000);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        request.addParameter("row", String.valueOf(100000));
        
		// Add image to group 1 in A6.
        controller.addCrystalImage(request, response);	
        assertEquals(500, response.getStatus());
        assertEquals("Crystal uniqueId 1000 does not exist in sil 1", response.getErrorMessage());        
		
	}
	
	public void testAddCrystalImageMissingUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequestNoUniqueId(annikas, silId);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
		// Add image to group 1 in A6.
        controller.addCrystalImage(request, response);	
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());        
		
	}
	
	public void testAddCrystalImageIgnoreUnknownProperties() throws Exception {
				
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas, silId, uniqueId);
        MockHttpServletResponse response = new MockHttpServletResponse();
   
		request.addParameter("XXXX", "Bad property name");
		
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
        
        // Check that image does not exist in group 1 in A6.
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNotNull(crystal);
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		Image image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNull(image);
		
		// Add image to group 1 in A6.
        controller.addCrystalImage(request, response);	
        assertEquals(200, response.getStatus());
        assertEquals("OK 1", response.getContentAsString());        
		
		// Check that image exists in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNotNull(crystal);
		assertEquals(port, crystal.getPort());
		assertEquals(crystalId, crystal.getCrystalId());
		assertEquals(1, crystal.getImages().size());
		image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNotNull(image);	
		assertEquals(imageDir, image.getDir());
		assertEquals(imageName, image.getName());
		assertEquals(group, image.getGroup());
		assertEquals(small, image.getData().getSmall());
		assertEquals(medium, image.getData().getMedium());
		assertEquals(large, image.getData().getLarge());
		assertEquals(jpeg, image.getData().getJpeg());	
	}
	
	public void testAddCrystalImageNonExistentSilId() throws Exception {
				
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas, 2000, uniqueId);
        MockHttpServletResponse response = new MockHttpServletResponse();
        		
		// Add image to group 1 in A6.
        controller.addCrystalImage(request, response);	
        assertEquals(500, response.getStatus());
        assertEquals("silId 2000 does not exist.", response.getErrorMessage());        
		
	}
	
	public void testAddCrystalImageNonExistentUniqueId() throws Exception {
				
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas, silId, 1000);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
		// Add image to group 1 in A6.
        controller.addCrystalImage(request, response);	
        assertEquals(500, response.getStatus());
        assertEquals("Crystal uniqueId 1000 does not exist in sil 1", response.getErrorMessage());        
		
	}
	
	private MockHttpServletRequest createMockHttpServletRequest(FakeUser user, int silId, long uniqueId) throws Exception {
		String imageDir = "/data/annikas/screening/1";
		String group = "1";
		String imageName = crystalId + "_001.img";
		String small = crystalId + "_001_small.jpg";
		String medium = crystalId + "_001_medium.jpg";
		String large = crystalId + "_001_large.jpg";
		String jpeg = crystalId + "_001.jpg";
				
		MockHttpServletRequest request = createMockHttpServletRequest(user);
        
        request.addParameter("silId", String.valueOf(silId));
		request.addParameter("uniqueId", String.valueOf(uniqueId));
		request.addParameter("group", group);
		request.addParameter("dir", imageDir);
		request.addParameter("name", imageName);
		request.addParameter("small", small);
		request.addParameter("medium", medium);
		request.addParameter("large", large);
		request.addParameter("jpeg", jpeg);	
	
		return request;
	}
	
	private MockHttpServletRequest createMockHttpServletRequestNoUniqueId(FakeUser user, int silId) throws Exception {
		String imageDir = "/data/annikas/screening/1";
		String group = "1";
		String imageName = crystalId + "_001.img";
		String small = crystalId + "_001_small.jpg";
		String medium = crystalId + "_001_medium.jpg";
		String large = crystalId + "_001_large.jpg";
		String jpeg = crystalId + "_001.jpg";
				
		MockHttpServletRequest request = createMockHttpServletRequest(user);
        
        request.addParameter("silId", String.valueOf(silId));
		request.addParameter("group", group);
		request.addParameter("dir", imageDir);
		request.addParameter("name", imageName);
		request.addParameter("small", small);
		request.addParameter("medium", medium);
		request.addParameter("large", large);
		request.addParameter("jpeg", jpeg);	
	
		return request;
	}
	
}
