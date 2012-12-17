package sil.beans.util;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import sil.TestData;
import sil.beans.*;
import sil.beans.util.CrystalUtil;

import java.io.File;
import java.util.*;

import junit.framework.TestCase;

public class CrystalUtilTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	private Crystal createSimpleCrystal() throws Exception
	{
		Crystal crystal = new Crystal();
		crystal.setCrystalId("A1");
		crystal.setPort("A1");
		crystal.setContainerId("SSRL001");
		crystal.getData().setProtein("Myoglobin 1");
		crystal.getData().setDirectory("/data/penjitk/myo");
		
		Image image = new Image();
		image.setName("A1_001.img");
		image.setDir("/data/penjitk/myo1");
		image.setGroup("1");
		image.getResult().getSpotfinderResult().setNumIceRings(2);
		image.getData().setJpeg("A1_001.jpg");
		image.getResult().getSpotfinderResult().setScore(0.7882);
		CrystalUtil.addImage(crystal, image);
		
		image = new Image();
		image.setName("A1_002.img");
		image.setDir("/data/penjitk/myo1");
		image.setGroup("2");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A1_002.jpg");
		image.getResult().getSpotfinderResult().setScore(0.975);			
		CrystalUtil.addImage(crystal, image);
		
		image = new Image();
		image.setName("A1_004.img");
		image.setDir("/data/penjitk/myo1");
		image.setGroup("3");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A1_004.jpg");
		image.getResult().getSpotfinderResult().setScore(0.99);			
		CrystalUtil.addImage(crystal, image);

		image = new Image();
		image.setName("A1_005.img");
		image.setDir("/data/penjitk/myo1");
		image.setGroup("3");
		image.getResult().getSpotfinderResult().setNumIceRings(6);
		image.getData().setJpeg("A1_005.jpg");
		image.getResult().getSpotfinderResult().setScore(0.333);			
		CrystalUtil.addImage(crystal, image);

		image = new Image();
		image.setName("A1_006.img");
		image.setDir("/data/penjitk/myo1");
		image.setGroup("3");
		image.getResult().getSpotfinderResult().setNumIceRings(8);
		image.getData().setJpeg("A1_006.jpg");
		image.getResult().getSpotfinderResult().setScore(0.01);			
		CrystalUtil.addImage(crystal, image);
		
		// Collect image1 and image2 again in a new dir
		image = new Image();
		image.setName("A1_001.img");
		image.setDir("/data/penjitk/myo1/try2");
		image.setGroup("1");
		image.getResult().getSpotfinderResult().setNumIceRings(5);
		image.getData().setJpeg("A1_001.jpg");
		image.getResult().getSpotfinderResult().setScore(0.222);			
		CrystalUtil.addImage(crystal, image);

		image = new Image();
		image.setName("A1_002.img");
		image.setDir("/data/penjitk/myo1/try2");
		image.setGroup("2");
		image.getResult().getSpotfinderResult().setNumIceRings(10);
		image.getData().setJpeg("A1_002.jpg");
		image.getResult().getSpotfinderResult().setScore(0.0003);			
		CrystalUtil.addImage(crystal, image);

		return crystal;
		
	}	
	
	private int countImageInGroup(Crystal crystal, String groupName)
	{
		Map<String, Image> images = crystal.getImages();
		Iterator<Image> it = images.values().iterator();
		int num = 0;
		while (it.hasNext()) {
			Image image = it.next();
			if (image.getGroup().equals(groupName))
				++num;
		}
		return num;
	}
	
	public void testAddImage()
	{
		logger.info("testAddImage: START");
		try {
			
			Crystal crystal = createSimpleCrystal();
						
			Map<String, Image> images = crystal.getImages();

			assertEquals(7, images.size());	
			
			assertNotNull(CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1" + File.separator + "A1_001.img"));
			assertNotNull(CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1" + File.separator + "A1_002.img"));
			assertNotNull(CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1/try2" + File.separator + "A1_001.img"));
			assertNotNull(CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1" + File.separator + "A1_004.img"));
			assertNotNull(CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1" + File.separator + "A1_005.img"));
			assertNotNull(CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1" + File.separator + "A1_006.img"));
			assertNotNull(CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1/try2" + File.separator + "A1_002.img"));
			
			assertEquals(2, countImageInGroup(crystal, "1"));
			assertEquals(2, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}		
		logger.info("testAddImage: DONE");
	}
	
	public void testClearImagesInGroup()
	{
		logger.info("testClearImagesInGroup: START");
		try {
			Crystal crystal = createSimpleCrystal();
			
			assertEquals(2, countImageInGroup(crystal, "1"));
			assertEquals(2, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));
			
			CrystalUtil.clearImagesInGroup(crystal, "2");
			
			assertEquals(2, countImageInGroup(crystal, "1"));
			assertEquals(0, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));	
			
			CrystalUtil.clearImagesInGroup(crystal, "1");
			
			assertEquals(0, countImageInGroup(crystal, "1"));
			assertEquals(0, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));	
			
			CrystalUtil.clearImagesInGroup(crystal, "3");
			
			assertEquals(0, countImageInGroup(crystal, "1"));
			assertEquals(0, countImageInGroup(crystal, "2"));
			assertEquals(0, countImageInGroup(crystal, "3"));	
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}		
		logger.info("testClearImagesInGroup: DONE");
	}	

	public void testClearImageFromPath()
	{
		logger.info("testClearImageFromPath: START");
		try {
			
			String path = "/data/penjitk/myo1/try2" + File.separator + "A1_001.img";
			Crystal crystal = createSimpleCrystal();
			
			Collection images = crystal.getImages().values();
			assertEquals(7, images.size());			
			assertEquals(2, countImageInGroup(crystal, "1"));
			assertEquals(2, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));
			
			CrystalUtil.clearImageFromPath(crystal, path);
			
			assertEquals(6, images.size());
			assertEquals(1, countImageInGroup(crystal, "1"));
			assertEquals(2, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));
			Iterator<Image> it = images.iterator();
			while (it.hasNext()) {
				Image image = it.next();
				if (image.getPath().equals(path))
					fail("failed to remove image " + path);
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}		
		logger.info("testClearImageFromPath: DONE");
	}	

	public void testClearImageFromPathNonExistentImage()
	{
		logger.info("testClearImageFromPathNonExistentImage: START");
		try {
			
			String path = "/data/" + File.separator + "A1_001.img";
			Crystal crystal = createSimpleCrystal();
			
			Collection images = crystal.getImages().values();
			assertEquals(7, images.size());			
			assertEquals(2, countImageInGroup(crystal, "1"));
			assertEquals(2, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));
			
			CrystalUtil.clearImageFromPath(crystal, path);
			
			assertEquals(7, images.size());
			assertEquals(2, countImageInGroup(crystal, "1"));
			assertEquals(2, countImageInGroup(crystal, "2"));
			assertEquals(3, countImageInGroup(crystal, "3"));
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}		
		logger.info("testClearImageFromPathNonExistentImage: DONE");
	}	

	
	public void testGetLastImageInGroup()
	{
		logger.info("testGetLastImageInGroup: START");
		try {
			Crystal crystal = createSimpleCrystal();
						
			Image image = CrystalUtil.getLastImageInGroup(crystal, "1");
			assertNotNull(image);
			assertEquals("/data/penjitk/myo1/try2" + File.separator + "A1_001.img", image.getPath());

			image = CrystalUtil.getLastImageInGroup(crystal, "2");
			assertNotNull(image);
			assertEquals("/data/penjitk/myo1/try2" + File.separator + "A1_002.img", image.getPath());
			
			image = CrystalUtil.getLastImageInGroup(crystal, "3");
			assertNotNull(image);
			assertEquals("/data/penjitk/myo1" + File.separator + "A1_006.img", image.getPath());			
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testGetLastImageInGroup: DONE");
	}
	
	public void testGetLastImageInEachGroup()
	{
		logger.info("testGetLastImageInEachGroup: START");
		try {
			Crystal crystal = createSimpleCrystal();
						
			Map<String, Image> images = CrystalUtil.testGetLastImageInEachGroup(crystal);
			
			assertEquals(3, images.size());
			Image image = images.get("1");
			assertNotNull(image);
			assertEquals("/data/penjitk/myo1/try2" + File.separator + "A1_001.img", image.getPath());
			image = images.get("2");
			assertNotNull(image);
			assertEquals("/data/penjitk/myo1/try2" + File.separator + "A1_002.img", image.getPath());
			image = images.get("3");
			assertNotNull(image);
			assertEquals("/data/penjitk/myo1" + File.separator + "A1_006.img", image.getPath());			
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testGetLastImageInEachGroup: DONE");
	}	
	
	public void testClearAllCrystalImages() throws Exception
	{
		logger.info("testClearAllCrystalImages: START");

		Crystal crystal = createSimpleCrystal();	
		assertEquals(7, crystal.getImages().size());	
		CrystalUtil.clearAllImages(crystal);		
		assertEquals(0, crystal.getImages().size());
					
		logger.info("testClearAllCrystalImages: DONE");
	}	
	
	public void testClearAutoindexResult() throws Exception
	{
		logger.info("testClearAutoindexResult: START");

		Crystal crystal = TestData.createCrystal();	
		assertNotNull(crystal.getResult().getAutoindexResult());
		AutoindexResult autoindex = crystal.getResult().getAutoindexResult();
		assertNotNull(autoindex);
		assertEquals("/data/annikas/webice/autoindex/1/A1/autoindex", autoindex.getDir());
		assertEquals(0.89, autoindex.getRmsd());
		assertEquals(60.0, autoindex.getResolution());
		assertEquals("/data/annikas/A1/myo1/A1_001.img /data/annikas/A1/myo1/A1_002.img", autoindex.getImages());
		
		CrystalUtil.clearAutoindexResult(crystal);	
		
		autoindex = crystal.getResult().getAutoindexResult();
		assertNotNull(autoindex);
		assertEquals(null, autoindex.getDir());
		assertEquals(0.0, autoindex.getRmsd());
		assertEquals(0.0, autoindex.getResolution());
		assertEquals(null, autoindex.getImages());
					
		logger.info("testClearAutoindexResult: DONE");
	}	
	
	public void testClearAutoindexWarning() throws Exception 
	{
		logger.info("testClearAutoindexWarning: START");

		Crystal crystal = TestData.createCrystal();	
		assertNotNull(crystal.getResult().getAutoindexResult());
		AutoindexResult autoindex = crystal.getResult().getAutoindexResult();
		assertNotNull(autoindex);
		assertEquals("/data/annikas/webice/autoindex/1/A1/autoindex", autoindex.getDir());
		assertEquals(0.89, autoindex.getRmsd());
		assertEquals(60.0, autoindex.getResolution());
		assertEquals("/data/annikas/A1/myo1/A1_001.img /data/annikas/A1/myo1/A1_002.img", autoindex.getImages());
		assertEquals("Not perfect", autoindex.getWarning());
		
		CrystalUtil.clearAutoindexWarning(crystal);	
		
		autoindex = crystal.getResult().getAutoindexResult();
		assertNotNull(autoindex);
		assertEquals("/data/annikas/webice/autoindex/1/A1/autoindex", autoindex.getDir());
		assertEquals(0.89, autoindex.getRmsd());
		assertEquals(60.0, autoindex.getResolution());
		assertEquals("/data/annikas/A1/myo1/A1_001.img /data/annikas/A1/myo1/A1_002.img", autoindex.getImages());
		assertEquals(null, autoindex.getWarning());
					
		logger.info("testClearAutoindexWarning: DONE");		
	}
	
	public void testClearAllSpotfinderResult() throws Exception 
	{
		logger.info("testClearAllSpotfinderResult: START");

		Crystal crystal = TestData.createCrystal();	
		assertEquals(2, crystal.getImages().size());
		Image image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertEquals("A1_001.img", image.getName());
		assertEquals("/data/annikas/myo1", image.getDir());
		assertEquals("1", image.getGroup());
		assertEquals("A1_001.jpg", image.getData().getJpeg());
		assertEquals("/data/annikas/A1/A1_001_small.jpg", image.getData().getSmall());
		assertEquals("/data/annikas/A1/A1_001_medium.jpg", image.getData().getMedium());
		assertEquals("/data/annikas/A1/A1_001_large.jpg", image.getData().getLarge());
		assertEquals(0.7882, image.getResult().getSpotfinderResult().getScore());
		assertEquals(99.0, image.getResult().getSpotfinderResult().getIntegratedIntensity());
		assertEquals(20, image.getResult().getSpotfinderResult().getNumOverloadSpots());
		assertEquals(62.0,image.getResult().getSpotfinderResult().getResolution());
		assertEquals(3,image.getResult().getSpotfinderResult().getNumIceRings());
		assertEquals(678, image.getResult().getSpotfinderResult().getNumSpots());
		assertEquals(0.88, image.getResult().getSpotfinderResult().getSpotShape());
		assertEquals(0.99, image.getResult().getSpotfinderResult().getQuality());
		assertEquals(77.3, image.getResult().getSpotfinderResult().getDiffractionStrength());
		assertEquals("/data/annikas/webice/screening/1/A1/spotfinder", image.getResult().getSpotfinderResult().getDir());
		
		image = CrystalUtil.getLastImageInGroup(crystal, "2");
		assertEquals("A1_002.img", image.getName());
		assertEquals("/data/annikas/myo1", image.getDir());
		assertEquals("2", image.getGroup());
		assertEquals("A1_002.jpg", image.getData().getJpeg());
		assertEquals("/data/annikas/A1/A1_002_small.jpg", image.getData().getSmall());
		assertEquals("/data/annikas/A1/A1_002_medium.jpg", image.getData().getMedium());
		assertEquals("/data/annikas/A1/A1_002_large.jpg", image.getData().getLarge());
		assertEquals(0.4444, image.getResult().getSpotfinderResult().getScore());
		assertEquals(55.0, image.getResult().getSpotfinderResult().getIntegratedIntensity());
		assertEquals(30, image.getResult().getSpotfinderResult().getNumOverloadSpots());
		assertEquals(66.0,image.getResult().getSpotfinderResult().getResolution());
		assertEquals(3,image.getResult().getSpotfinderResult().getNumIceRings());
		assertEquals(566, image.getResult().getSpotfinderResult().getNumSpots());
		assertEquals(0.80, image.getResult().getSpotfinderResult().getSpotShape());
		assertEquals(0.97, image.getResult().getSpotfinderResult().getQuality());
		assertEquals(88.3, image.getResult().getSpotfinderResult().getDiffractionStrength());
		assertEquals("/data/annikas/webice/screening/1/A1/spotfinder", image.getResult().getSpotfinderResult().getDir());

		
		CrystalUtil.clearAllSpotfinderResult(crystal);	
		
		// Make sure spotfinder results are gone but other
		// data is unchanged.
		assertEquals(2, crystal.getImages().size());
		image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertEquals("A1_001.img", image.getName());
		assertEquals("/data/annikas/myo1", image.getDir());
		assertEquals("1", image.getGroup());
		assertEquals("A1_001.jpg", image.getData().getJpeg());
		assertEquals("/data/annikas/A1/A1_001_small.jpg", image.getData().getSmall());
		assertEquals("/data/annikas/A1/A1_001_medium.jpg", image.getData().getMedium());
		assertEquals("/data/annikas/A1/A1_001_large.jpg", image.getData().getLarge());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getScore());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getIntegratedIntensity());
		assertEquals(0, image.getResult().getSpotfinderResult().getNumOverloadSpots());
		assertEquals(0.0,image.getResult().getSpotfinderResult().getResolution());
		assertEquals(0,image.getResult().getSpotfinderResult().getNumIceRings());
		assertEquals(0, image.getResult().getSpotfinderResult().getNumSpots());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getSpotShape());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getQuality());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getDiffractionStrength());
		assertEquals(null, image.getResult().getSpotfinderResult().getDir());
					
		image = CrystalUtil.getLastImageInGroup(crystal, "2");
		assertEquals("A1_002.img", image.getName());
		assertEquals("/data/annikas/myo1", image.getDir());
		assertEquals("2", image.getGroup());
		assertEquals("A1_002.jpg", image.getData().getJpeg());
		assertEquals("/data/annikas/A1/A1_002_small.jpg", image.getData().getSmall());
		assertEquals("/data/annikas/A1/A1_002_medium.jpg", image.getData().getMedium());
		assertEquals("/data/annikas/A1/A1_002_large.jpg", image.getData().getLarge());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getScore());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getIntegratedIntensity());
		assertEquals(0, image.getResult().getSpotfinderResult().getNumOverloadSpots());
		assertEquals(0.0,image.getResult().getSpotfinderResult().getResolution());
		assertEquals(0,image.getResult().getSpotfinderResult().getNumIceRings());
		assertEquals(0, image.getResult().getSpotfinderResult().getNumSpots());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getSpotShape());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getQuality());
		assertEquals(0.0, image.getResult().getSpotfinderResult().getDiffractionStrength());
		assertEquals(null, image.getResult().getSpotfinderResult().getDir());
		
		logger.info("testClearAllSpotfinderResult: DONE");		
	}
	
	public void clearAutoindexWarning() throws Exception {
		logger.info("clearAutoindexWarning: START");

		Crystal crystal = TestData.createCrystal();	
		assertEquals("Not perfect", crystal.getResult().getAutoindexResult().getWarning());
		CrystalUtil.clearAutoindexWarning(crystal);
		assertEquals(null, crystal.getResult().getAutoindexResult().getWarning());	
		
		logger.info("clearAutoindexWarning: DONE");		
		
	}
	
	public void testAddDefaultRepositionData() throws Exception {
		
		Crystal crystal = TestData.createCrystal();	

		RepositionData data = new RepositionData();
		data.setLabel("repos0");
		data.setBeamSizeX(0.1);
		data.setBeamSizeY(0.1);
		int repositionId = CrystalUtil.addDefaultRepositionData(crystal, data);		
		assertEquals(0, repositionId);
		assertEquals(1, crystal.getResult().getRepositions().size());
	}
	
	public void testAddRunDefinition() throws Exception {
		
		Crystal crystal = TestData.createCrystal();	
		
		assertEquals(0, crystal.getResult().getRuns().size());
		
		RepositionData data = new RepositionData();
		data.setLabel("repos0");
		data.setBeamSizeX(0.1);
		data.setBeamSizeY(0.1);
		int repositionId = CrystalUtil.addDefaultRepositionData(crystal, data);
		
		RunDefinition run = new RunDefinition();
		run.setRepositionId(repositionId);
		CrystalUtil.addRunDefinition(crystal, run);	
		assertEquals(1, crystal.getResult().getRuns().size());
		assertEquals(1, ((RunDefinition)crystal.getResult().getRuns().get(0)).getRunLabel());
		
		run = new RunDefinition();
		run.setRepositionId(repositionId);
		CrystalUtil.addRunDefinition(crystal, run);
		assertEquals(2, crystal.getResult().getRuns().size());
		assertEquals(2, ((RunDefinition)crystal.getResult().getRuns().get(1)).getRunLabel());
	}
	
	public void testDeleteRunDefinition() throws Exception {
		
		Crystal crystal = TestData.createCrystal();	
		addRunDefinitions(crystal);	
		
		// Delete run at index 1
		// The rest of the runs will move up by one.
		CrystalUtil.deleteRunDefinition(crystal, 1);
		assertEquals(3, crystal.getResult().getRuns().size());
		assertEquals(1, ((RunDefinition)crystal.getResult().getRuns().get(0)).getRunLabel());
		assertEquals(3, ((RunDefinition)crystal.getResult().getRuns().get(1)).getRunLabel());
		assertEquals(4, ((RunDefinition)crystal.getResult().getRuns().get(2)).getRunLabel());
	}
	
	public void testGetRunDefinitionLabels() throws Exception {
		Crystal crystal = TestData.createCrystal();
		addRunDefinitions(crystal);	
		
		int[] labels = CrystalUtil.getRunDefinitionLabels(crystal);
		assertEquals(4, labels.length);
		assertEquals(1, labels[0]);
		assertEquals(2, labels[1]);
		assertEquals(3, labels[2]);
		assertEquals(4, labels[3]);
		
		// No run definition
		crystal = new Crystal();
		labels = CrystalUtil.getRunDefinitionLabels(crystal);
		assertNull(labels);
	}
	
	public void testGetRunDefinition() throws Exception {
		Crystal crystal = TestData.createCrystal();
		addRunDefinitions(crystal);	
		
		assertEquals(1, CrystalUtil.getRunDefinition(crystal, 0).getRunLabel());
		assertEquals(2, CrystalUtil.getRunDefinition(crystal, 1).getRunLabel());
		assertEquals(3, CrystalUtil.getRunDefinition(crystal, 2).getRunLabel());
		assertEquals(4, CrystalUtil.getRunDefinition(crystal, 3).getRunLabel());
		
		RunDefinition run = CrystalUtil.getRunDefinition(crystal, -1);
		assertNull(run);
		
		run = CrystalUtil.getRunDefinition(crystal, 4);
		assertNull(run);
	}
	
	public void testGetRunDefinitions() throws Exception {
		Crystal crystal = TestData.createCrystal();
		addRunDefinitions(crystal);	
		
		List<RunDefinition> runs = CrystalUtil.getRunDefinitions(crystal);
		assertEquals(4, runs.size());
	}
	
	public void testMoveRunDefinitionToTop() throws Exception {
		Crystal crystal = TestData.createCrystal();
		addRunDefinitions(crystal);
		
		try {
			CrystalUtil.moveRunDefinitionToTop(crystal, -1);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
		
		try {
			CrystalUtil.moveRunDefinitionToTop(crystal, 4);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
		
		// Move run at index 2 to the top of the list.
		CrystalUtil.moveRunDefinitionToTop(crystal, 2);
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
		
		// Nothing happens since run 0 is already at the top of the list.
		CrystalUtil.moveRunDefinitionToTop(crystal, 0);
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());

	}
	
	public void testMoveRunDefinitionToBottom() throws Exception {
		Crystal crystal = TestData.createCrystal();
		addRunDefinitions(crystal);
		
		try {
			CrystalUtil.moveRunDefinitionToBottom(crystal, -1);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
		
		try {
			CrystalUtil.moveRunDefinitionToBottom(crystal, 4);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
				
		// Move run at index 1 to the bottom of the list.
		CrystalUtil.moveRunDefinitionToBottom(crystal, 1);
		assertEquals(1, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(3).getRunLabel());
				
		// Nothing happens since run at index 3 is already at the bottom of the list.
		CrystalUtil.moveRunDefinitionToBottom(crystal, 3);
		assertEquals(1, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(3).getRunLabel());

	}
	
	public void testMoveRunDefinitionUp() throws Exception {
		
		Crystal crystal = TestData.createCrystal();
		addRunDefinitions(crystal);
		
		try {
			CrystalUtil.moveRunDefinitionDown(crystal, -1);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
		
		try {
			CrystalUtil.moveRunDefinitionDown(crystal, 4);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
		
		// Move run at index 2 up by one position.
		CrystalUtil.moveRunDefinitionUp(crystal, 2);
		assertEquals(1, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
		
		// Nothing happens. Can not move run position 0 up since it is already at the top.
		CrystalUtil.moveRunDefinitionUp(crystal, 0);
		assertEquals(1, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
		
	}
	
	public void testMoveRunDefinitionDown() throws Exception {
		
		Crystal crystal = TestData.createCrystal();
		addRunDefinitions(crystal);
		
		try {
			CrystalUtil.moveRunDefinitionDown(crystal, -1);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
		
		try {
			CrystalUtil.moveRunDefinitionDown(crystal, 4);
		} catch (Exception e) {
			assertEquals("Run definition index out of range.", e.getMessage());
		}
						
		// Move run at index 0 down by one position.
		CrystalUtil.moveRunDefinitionDown(crystal, 0);
		assertEquals(2, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
		
		// Nothing happens. Can not move run position 3 down since it is already at the bottom.
		CrystalUtil.moveRunDefinitionDown(crystal, 3);
		assertEquals(2, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
	}
	
	private void addRunDefinitions(Crystal crystal) throws Exception {
		
		RepositionData data = new RepositionData();
		data.setLabel("repos0");
		data.setBeamSizeX(0.1);
		data.setBeamSizeY(0.1);
		int repositionId = CrystalUtil.addDefaultRepositionData(crystal, data);
		
		RunDefinition run = new RunDefinition();
		data.setLabel("repos1");
		run.setBeamStop(10.0);
		run.setRepositionId(repositionId);
		CrystalUtil.addRunDefinition(crystal, run);	

		run = new RunDefinition();
		data.setLabel("repos2");
		run.setBeamStop(20.0);
		run.setRepositionId(repositionId);
		CrystalUtil.addRunDefinition(crystal, run);
		
		run = new RunDefinition();
		data.setLabel("repos3");
		run.setBeamStop(30.0);
		run.setRepositionId(repositionId);
		CrystalUtil.addRunDefinition(crystal, run);
		
		run = new RunDefinition();
		data.setLabel("repos4");
		run.setBeamStop(40.0);
		run.setRepositionId(repositionId);
		CrystalUtil.addRunDefinition(crystal, run);
		
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(10.0, crystal.getResult().getRuns().get(0).getBeamStop());
		assertEquals(20.0, crystal.getResult().getRuns().get(1).getBeamStop());
		assertEquals(30.0, crystal.getResult().getRuns().get(2).getBeamStop());
		assertEquals(40.0, crystal.getResult().getRuns().get(3).getBeamStop());
	}
	
}