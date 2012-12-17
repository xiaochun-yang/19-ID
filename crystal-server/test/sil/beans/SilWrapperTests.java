package sil.beans;

import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.ImageWrapper;
import sil.beans.util.MappableBeanWrapper;
import sil.beans.util.SilUtil;
import sil.TestData;

import java.beans.*;
import java.io.*;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import junit.framework.TestCase;

public class SilWrapperTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	// Show how to use XmlEncoder class to write Sil as xml.
	// Create sil by adding crystals and images manually.
	// Reconstructing Sil object from the xml file.
	public void ttestXmlEncoder()
	{
		try {

			logger.debug("START testXmlEncoder");
			Sil sil = TestData.createSimpleSil();
			
			// Save it as xml using javabean schema.
			ByteArrayOutputStream out = new ByteArrayOutputStream();
			XMLEncoder encoder = new XMLEncoder(out);
			encoder.writeObject(sil);
			encoder.close();
	
			// Create a new Sil object from the xml file.
			ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());
			XMLDecoder decoder = new XMLDecoder(in);
			Sil newSil = (Sil)decoder.readObject();
			decoder.close();
			
			assertTrue(sil.equals(newSil));

			logger.debug("FINISH testXmlEncoder");
		
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void testCrystalWrapper()
	{
		try {
			
			Sil sil = createSilFromCrystalWrapper();
			
			Crystal crystal = sil.getCrystals().get(new Long(100));
			assertNotNull(crystal);
			assertEquals("A1", crystal.getPort());
			assertEquals("/data/penjitk/myo1", crystal.getData().getDirectory());
			
			Image image = crystal.getImages().get("1");
			assertNotNull(image);
			assertEquals("A1_001.img", image.getName());
			assertEquals("/data/penjitk/myo1", image.getDir());
			assertEquals("/data/penjitk/myo1" + File.separator + "A1_001.img", image.getPath());
			assertEquals("1", image.getGroup());
			assertEquals(2, image.getResult().getSpotfinderResult().getNumIceRings());
			assertEquals("A1_001.jpg", image.getData().getJpeg());
			assertEquals(0.7882, image.getResult().getSpotfinderResult().getScore());
			
			Sil sil1 = createSil();
			
//			assertEquals(sil1, sil);
			if (!sil1.equalsDebug(sil))
				fail("sil not the same");
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
		
	// Show how to use XmlEncoder class to write Sil as xml.
	// Create sil by using SilWrapper, CrystalWrapper and ImageWrapper.
	public void testCrystalWrapperAndImageWrapper()
	{
		try {
			
			UnitCell cell = new UnitCell();
			cell.setA(81.56);
			cell.setB(81.56);
			cell.setC(129.48);
			cell.setAlpha(90.00);
			cell.setBeta(90.00);
			cell.setGamma(120.00);
			
			logger.debug("START testCrystalWrapperAndImageWrapper");
			Sil sil = createSilFromWrapper();
			
			assertEquals(2, SilUtil.getCrystalCount(sil));
	
			Crystal crystal = sil.getCrystals().get(100L);
			assertEquals("A1", crystal.getCrystalId());
			assertEquals("A1", crystal.getPort());
			assertEquals("SSRL001", crystal.getContainerId());
			assertEquals("/data/penjitk/myo1", crystal.getData().getDirectory());
			assertEquals("Myoglobin 1", crystal.getData().getProtein());
			assertEquals(cell, crystal.getResult().getAutoindexResult().getUnitCell());
			
			Image img1 = CrystalUtil.getImageFromPath(crystal, "/data/penjitk/myo1" + File.separator + "A1_001.img");
			assertEquals("A1_001.img", img1.getName());
			assertEquals("/data/penjitk/myo1", img1.getDir());
			assertEquals("1", img1.getGroup());
			assertEquals(2, img1.getResult().getSpotfinderResult().getNumIceRings());
			assertEquals("A1_001.jpg", img1.getData().getJpeg());
			assertEquals(0.7882, img1.getResult().getSpotfinderResult().getScore());

			logger.debug("FINISH testCrystalWrapperAndImageWrapper");
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	// Test that we can set unitCell property by using 
	// UnitCellPropertyEditor registered with CrystalWrapper.
	public void testUnitCell()
	{
		logger.debug("START testUnitCell");
		try {
		
		Crystal crystal = new Crystal();
		crystal.setCrystalId("A1");
		crystal.setPort("A1");
		crystal.setContainerId("SSRL001");
		
		MappableBeanWrapper wrapper = new CrystalWrapper(crystal);
		wrapper.setPropertyValue("result.autoindexResult.unitCell", "81.56 81.56 129.48 90.00 90.00 120.00");
		
		UnitCell cell = new UnitCell();
		cell.setA(81.56);
		cell.setB(81.56);
		cell.setC(129.48);
		cell.setAlpha(90.00);
		cell.setBeta(90.00);
		cell.setGamma(120.00);
		
		assertEquals(cell, crystal.getResult().getAutoindexResult().getUnitCell());

		logger.debug("FINISH testUnitCell");
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
		
	// 
	private Sil createSilFromWrapper()
		throws Exception
	{
		Sil sil = new Sil();
		sil.setId(1);
		sil.getInfo().setEventId(0);
		sil.getInfo().setKey("");
		
		// First crystal
		CrystalWrapper crystalWrapper = new CrystalWrapper(new Crystal());

		crystalWrapper.setPropertyValue("uniqueId", "100");
		crystalWrapper.setPropertyValue("crystalId", "A1");
		crystalWrapper.setPropertyValue("port", "A1");
		crystalWrapper.setPropertyValue("containerId", "SSRL001");
		crystalWrapper.setPropertyValue("data.directory", "/data/penjitk/myo1");
		crystalWrapper.setPropertyValue("data.protein", "Myoglobin 1");
		crystalWrapper.setPropertyValue("result.autoindexResult.unitCell", "81.56 81.56 129.48 90.00 90.00 120.00");
		
		ImageWrapper imageWrapper = new ImageWrapper(new Image());
		imageWrapper.setPropertyValue("name", "A1_001.img");
		imageWrapper.setPropertyValue("dir", "/data/penjitk/myo1");
		imageWrapper.setPropertyValue("group", "1");
		imageWrapper.setPropertyValue("result.spotfinderResult.numIceRings", "2");
		imageWrapper.setPropertyValue("data.jpeg", "A1_001.jpg");
		imageWrapper.setPropertyValue("result.spotfinderResult.score", 0.7882);
		CrystalUtil.addImage(crystalWrapper.getCrystal(), (Image)imageWrapper.getWrappedInstance());		

		imageWrapper = new ImageWrapper(new Image());
		imageWrapper.setPropertyValue("name", "A1_002.img");
		imageWrapper.setPropertyValue("dir", "/data/penjitk/myo1");
		imageWrapper.setPropertyValue("group", "2");
		imageWrapper.setPropertyValue("result.spotfinderResult.numIceRings", "0");
		imageWrapper.setPropertyValue("data.jpeg", "A1_002.jpg");
		imageWrapper.setPropertyValue("result.spotfinderResult.score", "0.975");
		CrystalUtil.addImage(crystalWrapper.getCrystal(), (Image)imageWrapper.getWrappedInstance());		

		SilUtil.addCrystal(sil, crystalWrapper.getCrystal());

		// Second crystal
		crystalWrapper = new CrystalWrapper(new Crystal());
		crystalWrapper.setPropertyValue("uniqueId", "101");
		crystalWrapper.setPropertyValue("crystalId", "A2");
		crystalWrapper.setPropertyValue("port", "A2");
		crystalWrapper.setPropertyValue("containerId", "SSRL001");
		crystalWrapper.setPropertyValue("data.directory", "/data/penjitk/myo2");
		crystalWrapper.setPropertyValue("data.protein", "Myoglobin 2");
		
		imageWrapper = new ImageWrapper(new Image());
		imageWrapper.setPropertyValue("name", "A2_001.img");
		imageWrapper.setPropertyValue("dir", "/data/penjitk/myo2");
		imageWrapper.setPropertyValue("group", "1");
		imageWrapper.setPropertyValue("result.spotfinderResult.numIceRings", "0");
		imageWrapper.setPropertyValue("data.jpeg", "A2_001.jpg");
		imageWrapper.setPropertyValue("result.spotfinderResult.score", 0.978);
		CrystalUtil.addImage(crystalWrapper.getCrystal(), (Image)imageWrapper.getWrappedInstance());		
		
		imageWrapper = new ImageWrapper(new Image());
		imageWrapper.setPropertyValue("name", "A2_002.img");
		imageWrapper.setPropertyValue("dir", "/data/penjitk/myo2");
		imageWrapper.setPropertyValue("group", "2");
		imageWrapper.setPropertyValue("result.spotfinderResult.numIceRings", "0");
		imageWrapper.setPropertyValue("data.jpeg", "A2_002.jpg");
		imageWrapper.setPropertyValue("result.spotfinderResult.score", "0.916");
		CrystalUtil.addImage(crystalWrapper.getCrystal(), (Image)imageWrapper.getWrappedInstance());		
		
		SilUtil.addCrystal(sil, crystalWrapper.getCrystal());

		
		return sil;
	}
	// 
	private Sil createSilFromCrystalWrapper() throws Exception
	{
			
		Sil sil = new Sil();
		sil.setId(1);
		sil.getInfo().setEventId(0);
		sil.getInfo().setKey("");
		
		// First crystal
		CrystalWrapper crystalWrapper = new CrystalWrapper(new Crystal());

		crystalWrapper.setPropertyValue("uniqueId", "100");
		crystalWrapper.setPropertyValue("crystalId", "A1");
		crystalWrapper.setPropertyValue("row", "0");
		crystalWrapper.setPropertyValue("port", "A1");
		crystalWrapper.setPropertyValue("containerId", "SSRL001");
		crystalWrapper.setPropertyValue("data.directory", "/data/penjitk/myo1");
		crystalWrapper.setPropertyValue("data.protein", "Myoglobin 1");
		crystalWrapper.setPropertyValue("result.autoindexResult.unitCell", "81.56 81.56 129.48 90.00 90.00 120.00");		

		crystalWrapper.setPropertyValue("images[1].path", "/data/penjitk/myo1" + File.separator + "A1_001.img");
		crystalWrapper.setPropertyValue("images[1].group", "1");
		crystalWrapper.setPropertyValue("images[1].result.spotfinderResult.numIceRings", "2");
		crystalWrapper.setPropertyValue("images[1].data.jpeg", "A1_001.jpg");
		crystalWrapper.setPropertyValue("images[1].result.spotfinderResult.score", "0.7882");

		crystalWrapper.setPropertyValue("images[2].path", "/data/penjitk/myo1" + File.separator + "A1_002.img");
		crystalWrapper.setPropertyValue("images[2].group", "2");
		crystalWrapper.setPropertyValue("images[2].result.spotfinderResult.numIceRings", "0");
		crystalWrapper.setPropertyValue("images[2].data.jpeg", "A1_002.jpg");
		crystalWrapper.setPropertyValue("images[2].result.spotfinderResult.score", "0.975");

		SilUtil.addCrystal(sil, crystalWrapper.getCrystal());

		// Second crystal
		crystalWrapper = new CrystalWrapper(new Crystal());
		crystalWrapper.setPropertyValue("uniqueId", "101");
		crystalWrapper.setPropertyValue("crystalId", "A2");
		crystalWrapper.setPropertyValue("row", "1");
		crystalWrapper.setPropertyValue("port", "A2");
		crystalWrapper.setPropertyValue("containerId", "SSRL001");
		crystalWrapper.setPropertyValue("data.directory", "/data/penjitk/myo2");
		crystalWrapper.setPropertyValue("data.protein", "Myoglobin 2");
		
		crystalWrapper.setPropertyValue("images[1].name", "A2_001.img");
		crystalWrapper.setPropertyValue("images[1].dir", "/data/penjitk/myo2");
		crystalWrapper.setPropertyValue("images[1].group", "1");
		crystalWrapper.setPropertyValue("images[1].result.spotfinderResult.numIceRings", "0");
		crystalWrapper.setPropertyValue("images[1].data.jpeg", "A2_001.jpg");
		crystalWrapper.setPropertyValue("images[1].result.spotfinderResult.score", "0.978");
		
		crystalWrapper.setPropertyValue("images[2].name", "A2_002.img");
		crystalWrapper.setPropertyValue("images[2].dir", "/data/penjitk/myo2");
		crystalWrapper.setPropertyValue("images[2].group", "2");
		crystalWrapper.setPropertyValue("images[2].result.spotfinderResult.numIceRings", "0");
		crystalWrapper.setPropertyValue("images[2].data.jpeg", "A2_002.jpg");
		crystalWrapper.setPropertyValue("images[2].result.spotfinderResult.score", "0.916");
		
		SilUtil.addCrystal(sil, crystalWrapper.getCrystal());

		
		return sil;
	}
	private Sil createSil() throws Exception
	{
			
		Sil sil = new Sil();
		sil.setId(1);
		sil.getInfo().setEventId(0);
		sil.getInfo().setKey("");
		
		Crystal crystal = new Crystal();
		crystal.setUniqueId(100);
		crystal.setCrystalId("A1");
		crystal.setRow(0);
		crystal.setPort("A1");
		crystal.setContainerId("SSRL001");
		crystal.getData().setDirectory("/data/penjitk/myo1");
		crystal.getData().setProtein("Myoglobin 1");
		crystal.getResult().getAutoindexResult().getUnitCell().setA(81.56);
		crystal.getResult().getAutoindexResult().getUnitCell().setB(81.56);
		crystal.getResult().getAutoindexResult().getUnitCell().setC(129.48);
		crystal.getResult().getAutoindexResult().getUnitCell().setAlpha(90.00);
		crystal.getResult().getAutoindexResult().getUnitCell().setBeta(90.00);
		crystal.getResult().getAutoindexResult().getUnitCell().setGamma(120.00);		

		Map<String, Image> images = crystal.getImages();
		Image image = new Image();
		image.setPath("/data/penjitk/myo1" + File.separator + "A1_001.img");
		image.setGroup("1");
		image.getResult().getSpotfinderResult().setNumIceRings(2);
		image.getData().setJpeg("A1_001.jpg");
		image.getResult().getSpotfinderResult().setScore(0.7882);
		images.put("1", image);

		image = new Image();
		image.setPath("/data/penjitk/myo1" + File.separator + "A1_002.img");
		image.setGroup("2");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A1_002.jpg");
		image.getResult().getSpotfinderResult().setScore(0.975);
		images.put("2", image);

		Map<Long, Crystal> crystals = sil.getCrystals();
		crystals.put(crystal.getUniqueId(), crystal);

		// Second crystal
		crystal = new Crystal();
		crystal.setRow(1);
		crystal.setUniqueId(101);
		crystal.setCrystalId("A2");
		crystal.setPort("A2");
		crystal.setContainerId("SSRL001");
		crystal.getData().setDirectory("/data/penjitk/myo2");
		crystal.getData().setProtein("Myoglobin 2");
		
		images = crystal.getImages();
		image = new Image();
		image.setName("A2_001.img");
		image.setDir("/data/penjitk/myo2");
		image.setGroup("1");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A2_001.jpg");
		image.getResult().getSpotfinderResult().setScore(0.978);
		images.put("1", image);
		
		image = new Image();
		image.setName("A2_002.img");
		image.setDir("/data/penjitk/myo2");
		image.setGroup("2");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A2_002.jpg");
		image.getResult().getSpotfinderResult().setScore(0.916);
		images.put("2", image);
		
		crystals.put(crystal.getUniqueId(), crystal);
		
		return sil;
	}
	
}