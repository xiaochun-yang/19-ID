package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.Sil;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class SetCrystalImageTests extends ControllerTestBase {

	private int silId = 2;
	private String imageDir = "/data/penjitk/screening/SIM9-2/14256/A6";
	private int row = 5;
	private String port = "A6";
	private String crystalId = "A6";
	private long uniqueId = 2000102;
	private String group = "1";
	private String imageName = "A6_001.mccd";
	private String small = "A6_001_small.jpg";
	private String medium = "A6_001_medium.jpg";
	private String large = "A6_001_large.jpg";
	private String jpeg = "A6_001.jpg";
	private String spotfinderDir = "/data/penjitk/webice/screening/5/B3/spotfinder";
	private double integratedIntensity= 2.0 ;
	private int numOverloadSpots = 0;
	private double score = 5.0;
	private double resolution = 1.2;
	private int iceRings = 5;
	private int numBraggSpots = 408;
	private int numSpots = 600;
	private double spotShape = 0.9;
	private double diffractionStrength = 8.2;
	private double quality = 2.4;
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testSetCrystalImage() throws Exception {
		setCrystalImage(String.valueOf(uniqueId), String.valueOf(row));
	}
	
	public void testSetCrystalImageMissingUniqueId() throws Exception {
		setCrystalImage(null, String.valueOf(row));
	}
	
	public void testSetCrystalImageInvalidUniqueId() throws Exception {
		setCrystalImage("-1", String.valueOf(row));
	}
	
	public void testSetCrystalImageMissingUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        request.addParameter("silId", String.valueOf(silId));
        controller.setCrystalImage(request, response);	
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());

	}
	
	public void testSetCrystalImageInvalidUniqueIdAndRow() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("uniqueId", "-1");
        request.addParameter("row", "-1");
        controller.setCrystalImage(request, response);	
        assertEquals(500, response.getStatus());
        assertEquals("Missing uniqueId or row parameter", response.getErrorMessage());		
	}

	public void setCrystalImage(String uniqueIdStr, String rowStr) throws Exception {
				
        CommandController controller = (CommandController)ctx.getBean("commandController");
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
		assertNotNull(image);
		assertEquals(imageDir, image.getDir());
		assertEquals(imageName, image.getName());
		assertEquals(group, image.getGroup());
		assertEquals("", image.getData().getSmall());
		assertEquals("", image.getData().getMedium());
		assertEquals("", image.getData().getLarge());
		assertEquals("", image.getData().getJpeg());
		assertEquals("", image.getData().getSmall());
		assertEquals("", image.getData().getMedium());
		assertEquals("", image.getData().getLarge());
		assertEquals("", image.getData().getJpeg());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getIntegratedIntensity());
		assertEquals(0, image.getResult().getSpotfinderResult().getNumOverloadSpots());
		assertEquals(4.0, image.getResult().getSpotfinderResult().getScore());
		assertEquals(3.6, image.getResult().getSpotfinderResult().getResolution());
		assertEquals(1, image.getResult().getSpotfinderResult().getNumIceRings());
		assertEquals(0, image.getResult().getSpotfinderResult().getNumSpots());
		assertEquals(0.716, image.getResult().getSpotfinderResult().getSpotShape());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getQuality());
		assertEquals(4.0, image.getResult().getSpotfinderResult().getDiffractionStrength());
		assertEquals("", image.getResult().getSpotfinderResult().getDir());
		assertEquals(0, image.getResult().getSpotfinderResult().getNumBraggSpots());
		
		MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        request.addParameter("silId", String.valueOf(silId));
		if (uniqueIdStr != null)
			request.addParameter("uniqueId", uniqueIdStr);
		if (rowStr != null)
			request.addParameter("row", rowStr);
		request.addParameter("group", group);
		request.addParameter("dir", imageDir);
		request.addParameter("name", imageName);
		request.addParameter("small", small);
		request.addParameter("medium", medium);
		request.addParameter("large", large);
		request.addParameter("jpeg", jpeg);	
		request.addParameter("spotfinderDir", spotfinderDir);	
		request.addParameter("integratedIntensity", String.valueOf(integratedIntensity));	
		request.addParameter("numOverloadSpots", String.valueOf(numOverloadSpots));	
		request.addParameter("score", String.valueOf(score));	
		request.addParameter("resolution", String.valueOf(resolution));	
		request.addParameter("iceRings", String.valueOf(iceRings));	
		request.addParameter("numBraggSpots", String.valueOf(numBraggSpots));	
		request.addParameter("numSpots", String.valueOf(numSpots));	
		request.addParameter("spotShape", String.valueOf(spotShape));	
		request.addParameter("diffractionStrength", String.valueOf(diffractionStrength));	
		request.addParameter("quality", String.valueOf(quality));

        controller.setCrystalImage(request, response);	
        if (response.getStatus() != 200)
        	System.out.println("response error msg = " + response.getErrorMessage());
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
		image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNotNull(image);
		assertEquals(imageDir, image.getDir());
		assertEquals(imageName, image.getName());
		assertEquals(group, image.getGroup());
		assertEquals(small, image.getData().getSmall());
		assertEquals(medium, image.getData().getMedium());
		assertEquals(large, image.getData().getLarge());
		assertEquals(jpeg, image.getData().getJpeg());	
		assertEquals(integratedIntensity, image.getResult().getSpotfinderResult().getIntegratedIntensity());
		assertEquals(numOverloadSpots, image.getResult().getSpotfinderResult().getNumOverloadSpots());
		assertEquals(score, image.getResult().getSpotfinderResult().getScore());
		assertEquals(resolution, image.getResult().getSpotfinderResult().getResolution());
		assertEquals(iceRings, image.getResult().getSpotfinderResult().getNumIceRings());
		assertEquals(numSpots, image.getResult().getSpotfinderResult().getNumSpots());
		assertEquals(spotShape, image.getResult().getSpotfinderResult().getSpotShape());
		assertEquals(quality, image.getResult().getSpotfinderResult().getQuality());
		assertEquals(diffractionStrength, image.getResult().getSpotfinderResult().getDiffractionStrength());
		assertEquals(spotfinderDir, image.getResult().getSpotfinderResult().getDir());
		assertEquals(numBraggSpots, image.getResult().getSpotfinderResult().getNumBraggSpots());
		
	}
	
	
}
