package sil.managers;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.NotWritablePropertyException;
import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.util.CrystalCollection;
import sil.beans.util.SilUtil;
import sil.beans.util.CrystalUtil;
import sil.factory.SilFactory;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import sil.managers.SilStorageManager;
import sil.SilTestCase;

public class SilManagerTests extends SilTestCase {
	
	private SilCacheManager cache;
	
	@Override
	protected void setUp() throws Exception {
		// TODO Auto-generated method stub
		super.setUp();
		
		cache = (SilCacheManager)ctx.getBean("silCacheManager");
	}

	@Override
	protected void tearDown() throws Exception {
		cache.clearCache();
		super.tearDown();

	}
	public void testLoadSil()
	{
		try {
			
			int silId = 1;
			int row = 0;
						
			// Load sil from repository
			SilManager manager = cache.getOrCreateSilManager(silId);
			
			Sil sil = manager.getSil();
			System.out.println("testLoadSil: sil = " + sil);
			this.assertNotNull(sil);
			Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
			System.out.println("testLoadSil: crystal = " + crystal);
			this.assertNotNull(crystal);
			this.assertEquals(crystal.getPort(), "A1");
			this.assertEquals(crystal.getCrystalId(), "A1");
						
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	public void ttestLoadAndWriteSil()
	{
		try {
			
			int silId = 13431;
			String crystalId = "A8";
						
			// Load sil from repository
			SilManager manager = cache.getOrCreateSilManager(silId);
			
			Sil sil = manager.getSil();
			Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
			
			SilStorageManager storageManager = manager.getStorageManager();
			
			String newFilePath = ctx.getResource("WEB-INF/classes/test/sil/managers/testLoadAndWriteSil.xml").getFile().getPath();
			storageManager.storeSilXmlFile(newFilePath, sil);
			
			// Reloading sil from repository
//			Sil newSil = storageManager.loadSil(silId);	
			Sil newSil = storageManager.getSilLoader().load(newFilePath);
			Crystal newCrystal = SilUtil.getCrystalFromCrystalId(newSil, crystalId);
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	
	public void testSetCrystalPropertiesUsingAliasNames() throws Exception
	{
			
		int silId = 1;
		String crystalId = "A1";
			
		SilManager manager = cache.getOrCreateSilManager(silId);			
		Sil sil = manager.getSil();
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
			
		// Bean properties
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("containerId", "SSRL102");
		props.addPropertyValue("data.protein", "Myoglobin");
		props.addPropertyValue("data.comment", "Bad crystal");
		props.addPropertyValue("result.autoindexResult.score", "0.00001");
		long uniqueId = 2000001;
		manager.setCrystalProperties(uniqueId, props);
			
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertEquals("SSRL102", crystal.getContainerId());
		assertEquals("Myoglobin", crystal.getData().getProtein());
		assertEquals("Bad crystal", crystal.getData().getComment());
		assertEquals(0.00001, crystal.getResult().getAutoindexResult().getScore());
			
	}

	public void testAddCrystalImage() throws Exception
	{
		int silId = 1;
		String crystalId = "A3";			
			
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
									
		// Bean properties
		MutablePropertyValues props = new MutablePropertyValues();

		props.addPropertyValue("group", "1");
		props.addPropertyValue("name", crystalId + "_001.img");
		props.addPropertyValue("dir", "/data/penjitk/sil/" + crystalId);
		props.addPropertyValue("jpeg", crystalId + "_0deg_001.jpg");
		props.addPropertyValue("small", crystalId + "_001_small.jpg");
		props.addPropertyValue("medium", crystalId + "_001_medium.jpg");
		props.addPropertyValue("large", crystalId + "_001_large.jpg");
		props.addPropertyValue("integratedIntensity", "0.99");
		props.addPropertyValue("numOverloadSpots", "223");
		props.addPropertyValue("score", "0.34");
		props.addPropertyValue("resolution", "2.5");
		props.addPropertyValue("iceRings", "1");
		props.addPropertyValue("numSpots", "800");
		props.addPropertyValue("spotShape", "1.2");
		props.addPropertyValue("quality", "44.0");
		props.addPropertyValue("diffractionStrength", "55.32");
		props.addPropertyValue("spotfinderDir", "/data/penjitk/webice/screening/" + silId + "/" + crystalId + "/spotfinder");			
		long uniqueId = 2000003;
		silManager.addCrystalImage(uniqueId, props);
			
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		Image image = CrystalUtil.getLastImageInGroup(crystal, "1");
		assertNotNull(image);
		assertEquals(crystalId + "_001.img", image.getName());
		assertEquals("/data/penjitk/sil/" + crystalId, image.getDir());
		assertEquals("1", image.getGroup());
		assertEquals(crystalId + "_0deg_001.jpg", image.getData().getJpeg());
		assertEquals(crystalId + "_001_small.jpg", image.getData().getSmall());
		assertEquals(crystalId + "_001_medium.jpg", image.getData().getMedium());
		assertEquals(crystalId + "_001_large.jpg", image.getData().getLarge());
		assertEquals(0.99, image.getResult().getSpotfinderResult().getIntegratedIntensity());
		assertEquals(223, image.getResult().getSpotfinderResult().getNumOverloadSpots());
		assertEquals(0.34, image.getResult().getSpotfinderResult().getScore());
		assertEquals(2.5, image.getResult().getSpotfinderResult().getResolution());
		assertEquals(1, image.getResult().getSpotfinderResult().getNumIceRings());
		assertEquals(800, image.getResult().getSpotfinderResult().getNumSpots());
		assertEquals(1.2, image.getResult().getSpotfinderResult().getSpotShape());
		assertEquals(44.0, image.getResult().getSpotfinderResult().getQuality());
		assertEquals(55.32, image.getResult().getSpotfinderResult().getDiffractionStrength());
		assertEquals("/data/penjitk/webice/screening/" + silId + "/" + crystalId + "/spotfinder", image.getResult().getSpotfinderResult().getDir());			
			
	}
	
	public void testAddCrystalImageWithInvalidProperties() throws Exception
	{
		try {
			int silId = 1;
			String crystalId = "A3";			

			SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
									
			SilManager silManager = cache.getOrCreateSilManager(silId);
			Sil sil = silManager.getSil();
									
			// Bean properties
			MutablePropertyValues props = new MutablePropertyValues();

			props.addPropertyValue("group", "1");
			props.addPropertyValue("name", crystalId + "_001.img");		
			props.addPropertyValue("prop1", "prop1 value");			
			props.addPropertyValue("prop2", "prop2 value");			
			long uniqueId = 2000003;
			silManager.addCrystalImage(2000003, props);			
			
		} catch (NotWritablePropertyException e) {
			// Expect to get this exception
			String err = e.getMessage();
			if (err.indexOf("prop1") < 0) {
				e.printStackTrace();
				fail(e.getMessage());
			}
		}
	}
	
	public void testClearAllCrystalImages() throws Exception
	{
		int silId = 2;
		String crystalId = "A2";			

		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
		
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(2, crystal.getImages().size());
		long uniqueId = 2000098;
		silManager.clearAllCrystalImages(uniqueId);
		
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		assertNotNull(crystal);
		assertEquals(0, crystal.getImages().size());
	}
	
	// Test all methods that increments eventId.
	public void testEventManager() throws Exception 
	{
		int silId = 1;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		assertNotNull(silManager);
		Sil sil = silManager.getSil();
		
		assertEquals(-1, sil.getInfo().getEventId());
		
		// setCrystalProperties
		int row = 7;
		String crystalId = "A8";
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		long uniqueId = crystal.getUniqueId();
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("Comment", "HELLO HELLO");
		int eventId = silManager.setCrystalProperties(uniqueId, props);
		assertEquals(1, sil.getInfo().getEventId());
		
		// setPropertyForAllCrystals
		StringBuffer buf = new StringBuffer();
		buf.append("true");
		for (int i = 1; i < 96; ++i) {
			buf.append(" true");
		}
		eventId = silManager.selectCrystals(buf.toString());
		assertEquals(2, eventId);
		
		// addCrystal
		crystal = new Crystal();
		crystal.setPort("M1");
		crystal.setRow(96);
		crystal.setCrystalId("M1");
		crystal.setContainerId("unknown");
		crystal.setContainerType("cassette");
		eventId = silManager.addCrystal(crystal);
		assertEquals(3, eventId);
		
		// addCrystalImage
		props = new MutablePropertyValues();
		props.addPropertyValue("name", "A8_003.img");
		props.addPropertyValue("dir", "/data/annikas/images");
		props.addPropertyValue("group", "1");
		eventId = silManager.addCrystalImage(uniqueId, props);
		assertEquals(4, eventId);
		
		// addCrystalImage
		props = new MutablePropertyValues();
		props.addPropertyValue("name", "A8_004.img");
		props.addPropertyValue("dir", "/data/annikas/images");
		props.addPropertyValue("group", "1");
		eventId = silManager.addCrystalImage(uniqueId, props);
		assertEquals(5, eventId);
		
		// clearCrystalImagesInGroup
		eventId = silManager.clearCrystalImagesInGroup(uniqueId, "1");
		assertEquals(6, eventId);
		
		// clearAllCrystalImages
		eventId = silManager.clearAllCrystalImages(uniqueId);
		assertEquals(7, eventId);
		
		// clearAutoindexResult
		eventId = silManager.clearAutoindexResult(uniqueId);
		assertEquals(8, eventId);
		
		// clearAllSpotfinderResult
		eventId = silManager.clearAllSpotfinderResult(uniqueId);
		assertEquals(9, eventId);
		
		// clearSystemWarning
		eventId = silManager.clearSystemWarning(uniqueId);
		assertEquals(10, eventId);
		
		// setCrystal
		crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		Crystal modifiedCrystal = CrystalUtil.cloneCrystal(crystal);
		modifiedCrystal.getData().setComment("NOT SO GOOD CRYSTAL");
		eventId = silManager.setCrystal(modifiedCrystal);
		assertEquals(11, eventId);
		
		CrystalCollection col = silManager.getChangesSince(-1);
		assertTrue(col.containsAll());
		
		col = silManager.getChangesSince(4);
		assertEquals(1, col.size()); // 6 new events but all on the same crystal
		assertTrue(col.contains(uniqueId));
		assertFalse(col.contains(999999999));
		
	}
	
	public void testMoveCrystalToPort() throws Exception {
		
		int silId = 2;
		int row = 1;
		long uniqueId = 2000098;
		String port = "A2";
		String containerId = "unknown";
		String containerType = "cassette";
		String crystalId = "A2";
		String protein = null;
		
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
		
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, oldCrystal.getRow());
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(port, oldCrystal.getPort());
		assertEquals(containerId, oldCrystal.getContainerId());
		assertEquals(containerType, oldCrystal.getContainerType());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertNull(oldCrystal.getData().getProtein());
		assertEquals(2, oldCrystal.getImages().size());
		
		int anotherRow = 15;
		long anotherUniqueId = 100000000;
		String anotherPort = "A16";
		String anotherContainerId = "ALS123";
		String anotherContainerType = "puck";
		String anotherCrystalId = "myo30";	
		String anotherProtein = "Myoglobin 30";
		Crystal srcCrystal = new Crystal();
		srcCrystal.setRow(anotherRow);
		srcCrystal.setUniqueId(anotherUniqueId);
		srcCrystal.setPort(anotherPort);
		srcCrystal.setContainerId(anotherContainerId);
		srcCrystal.setContainerType(anotherContainerType);
		srcCrystal.setCrystalId(anotherCrystalId);
		srcCrystal.getData().setProtein(anotherProtein);


		silManager.moveCrystalToPort(port, srcCrystal);
		
		// Make sure that srcCrystal remains unchanged by moveCrystalToPort
		assertEquals(anotherRow, srcCrystal.getRow());
		assertEquals(anotherUniqueId, srcCrystal.getUniqueId());
		assertEquals(anotherPort, srcCrystal.getPort());
		assertEquals(anotherContainerId, srcCrystal.getContainerId());
		assertEquals(anotherContainerType, srcCrystal.getContainerType());
		assertEquals(anotherCrystalId, srcCrystal.getCrystalId());
		assertEquals(0, srcCrystal.getImages().size());
		
		// Make sure the crystal has been moved to row 1 correctly.
		Crystal newCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, newCrystal.getRow());
		assertEquals(anotherUniqueId, newCrystal.getUniqueId());
		assertEquals(port, newCrystal.getPort());
		assertEquals(containerId, newCrystal.getContainerId());
		assertEquals(containerType, newCrystal.getContainerType());
		assertEquals(anotherCrystalId, newCrystal.getCrystalId());
		assertEquals(anotherProtein, newCrystal.getData().getProtein());
		assertEquals(0, newCrystal.getImages().size());
		
	}

	public void testMoveCrystalToPortDuplicateCryatalId() throws Exception {
		
		int silId = 2;
		int row = 1;
		long uniqueId = 2000098;
		String port = "A2";
		String containerId = "unknown";
		String containerType = "cassette";
		String crystalId = "A2";
		String protein = null;
		
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
		
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, oldCrystal.getRow());
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(port, oldCrystal.getPort());
		assertEquals(containerId, oldCrystal.getContainerId());
		assertEquals(containerType, oldCrystal.getContainerType());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertNull(oldCrystal.getData().getProtein());
		assertEquals(2, oldCrystal.getImages().size());
		
		int anotherRow = 2;
		long anotherUniqueId = 100000000;
		String anotherPort = "A3";
		String anotherContainerId = "SSRL123";
		String anotherContainerType = "cassette";
		String anotherCrystalId = "A3";	
		String anotherProtein = "Myoglobin 30";
		Crystal srcCrystal = new Crystal();
		srcCrystal.setRow(anotherRow);
		srcCrystal.setUniqueId(anotherUniqueId);
		srcCrystal.setPort(anotherPort);
		srcCrystal.setContainerId(anotherContainerId);
		srcCrystal.setContainerType(anotherContainerType);
		srcCrystal.setCrystalId(anotherCrystalId);
		srcCrystal.getData().setProtein(anotherProtein);

		// A3 already exist in this sil
		silManager.moveCrystalToPort(port, srcCrystal);
		
		// Make sure that srcCrystal remains unchanged by moveCrystalToRow
		assertEquals(anotherRow, srcCrystal.getRow());
		assertEquals(anotherUniqueId, srcCrystal.getUniqueId());
		assertEquals(anotherPort, srcCrystal.getPort());
		assertEquals(anotherContainerId, srcCrystal.getContainerId());
		assertEquals(anotherContainerType, srcCrystal.getContainerType());
		assertEquals(anotherCrystalId, srcCrystal.getCrystalId());
		assertEquals(0, srcCrystal.getImages().size());
		
		// Make sure the crystal has been moved to row 1 correctly.
		String expectedCrystalId = "A3_1";
		Crystal newCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, newCrystal.getRow());
		assertEquals(anotherUniqueId, newCrystal.getUniqueId());
		assertEquals(port, newCrystal.getPort());
		assertEquals(containerId, newCrystal.getContainerId());
		assertEquals(containerType, newCrystal.getContainerType());
		assertEquals(expectedCrystalId, newCrystal.getCrystalId());
		assertEquals(anotherProtein, newCrystal.getData().getProtein());
		assertEquals(0, newCrystal.getImages().size());
		
	}
	
	public void testMoveCrystalToInvalidPort() throws Exception {
		
		int silId = 2;
		String port = "M1";
		
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
		
		int anotherRow = 2;
		long anotherUniqueId = 100000000;
		String anotherPort = "A3";
		String anotherContainerId = "SSRL123";
		String anotherContainerType = "cassette";
		String anotherCrystalId = "A3";	
		String anotherProtein = "Myoglobin 30";
		Crystal srcCrystal = new Crystal();
		srcCrystal.setRow(anotherRow);
		srcCrystal.setUniqueId(anotherUniqueId);
		srcCrystal.setPort(anotherPort);
		srcCrystal.setContainerId(anotherContainerId);
		srcCrystal.setContainerType(anotherContainerType);
		srcCrystal.setCrystalId(anotherCrystalId);
		srcCrystal.getData().setProtein(anotherProtein);
		
		try {
			// port M1 does not exist
			silManager.moveCrystalToPort(port, srcCrystal);
			fail("moveCrystalToRow should have failed.");
		} catch (Exception e) {
			assertEquals("Port " + port + " does not exist in sil " + silId, e.getMessage());
		}
		
		// Make sure that srcCrystal remains unchanged by moveCrystalToRow
		assertEquals(anotherRow, srcCrystal.getRow());
		assertEquals(anotherUniqueId, srcCrystal.getUniqueId());
		assertEquals(anotherPort, srcCrystal.getPort());
		assertEquals(anotherContainerId, srcCrystal.getContainerId());
		assertEquals(anotherContainerType, srcCrystal.getContainerType());
		assertEquals(anotherCrystalId, srcCrystal.getCrystalId());
		assertEquals(0, srcCrystal.getImages().size());
	}
	
	public void testMoveCrystalToPortDuplicateUniqueId() throws Exception {
		
		int silId = 2;
		int row = 1;
		long uniqueId = 2000098;
		String port = "A2";
		String containerId = "unknown";
		String containerType = "cassette";
		String crystalId = "A2";
		String protein = null;
		
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
		
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, oldCrystal.getRow());
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(port, oldCrystal.getPort());
		assertEquals(containerId, oldCrystal.getContainerId());
		assertEquals(containerType, oldCrystal.getContainerType());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertNull(oldCrystal.getData().getProtein());
		assertEquals(2, oldCrystal.getImages().size());
		
		int anotherRow = 2;
		long anotherUniqueId = uniqueId;
		String anotherPort = "A3";
		String anotherContainerId = "SSRL123";
		String anotherContainerType = "cassette";
		String anotherCrystalId = "myo30";	
		String anotherProtein = "Myoglobin 30";
		Crystal srcCrystal = new Crystal();
		srcCrystal.setRow(anotherRow);
		srcCrystal.setUniqueId(anotherUniqueId);
		srcCrystal.setPort(anotherPort);
		srcCrystal.setContainerId(anotherContainerId);
		srcCrystal.setContainerType(anotherContainerType);
		srcCrystal.setCrystalId(anotherCrystalId);
		srcCrystal.getData().setProtein(anotherProtein);
		
		try {
			// row 1000 does not exist
			silManager.moveCrystalToPort(port, srcCrystal);
			fail("moveCrystalToRow should have failed.");
		} catch (Exception e) {
			assertEquals("Unique id " + uniqueId + " already exists", e.getMessage());
		}
		
		// Make sure that srcCrystal remains unchanged by moveCrystalToRow
		assertEquals(anotherRow, srcCrystal.getRow());
		assertEquals(anotherUniqueId, srcCrystal.getUniqueId());
		assertEquals(anotherPort, srcCrystal.getPort());
		assertEquals(anotherContainerId, srcCrystal.getContainerId());
		assertEquals(anotherContainerType, srcCrystal.getContainerType());
		assertEquals(anotherCrystalId, srcCrystal.getCrystalId());
		assertEquals(0, srcCrystal.getImages().size());
		
		// Make sure that A2 is unaffected
		oldCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, oldCrystal.getRow());
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(port, oldCrystal.getPort());
		assertEquals(containerId, oldCrystal.getContainerId());
		assertEquals(containerType, oldCrystal.getContainerType());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertNull(oldCrystal.getData().getProtein());
		assertEquals(2, oldCrystal.getImages().size());
		
	}
	
	public void testRemoveCrystalFromRow() throws Exception {
		
		int silId = 2;
		int row = 1;
		long uniqueId = 2000098;
		String port = "A2";
		String containerId = "unknown";
		String containerType = "cassette";
		String crystalId = "A2";
		String protein = null;
		
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
		
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, oldCrystal.getRow());
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(port, oldCrystal.getPort());
		assertEquals(containerId, oldCrystal.getContainerId());
		assertEquals(containerType, oldCrystal.getContainerType());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertNull(oldCrystal.getData().getProtein());
		assertEquals(2, oldCrystal.getImages().size());

		silManager.removeCrystalFromPort(port);
		
		// Make sure the crystal has been moved to row 1 correctly.
		Crystal newCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, newCrystal.getRow());
		assertTrue(newCrystal.getPort() != port);
		assertEquals(containerId, newCrystal.getContainerId());
		assertEquals(containerType, newCrystal.getContainerType());
		assertEquals("Empty" + String.valueOf(row+1), newCrystal.getCrystalId());
		assertEquals(null, newCrystal.getData().getProtein());
		assertEquals(0, newCrystal.getImages().size());
	}
	
	public void testRemoveCrystalFromInvalidPort() throws Exception {
		
		int silId = 2;
		String port = "M1";
		
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
						
		try {
			// row 1000 does not exist
			silManager.removeCrystalFromPort(port);
			fail("removeCrystalFromRow should have failed.");
		} catch (Exception e) {
			assertEquals("Port " + port + " does not exist in sil " + silId, e.getMessage());
		}
		
	}

	public void testRemoveCrystalFromPortEmptyCrystalIdAlreadyExists() throws Exception {
		
		int silId = 2;
		int row = 1;
		long uniqueId = 2000098;
		String port = "A2";
		String containerId = "unknown";
		String containerType = "cassette";
		String crystalId = "A2";
		String protein = null;
		
		SilManager silManager = cache.getOrCreateSilManager(silId);
		Sil sil = silManager.getSil();
		
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, oldCrystal.getRow());
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(port, oldCrystal.getPort());
		assertEquals(containerId, oldCrystal.getContainerId());
		assertEquals(containerType, oldCrystal.getContainerType());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertNull(oldCrystal.getData().getProtein());
		assertEquals(2, oldCrystal.getImages().size());
		
		// Rename crystalId in A3 to Empty2 so that
		// When create an empty crystal in A2, the empty crystal name Empty2 
		// will have already existed.
		Crystal a3Crystal = SilUtil.getCrystalFromPort(sil, "A3");
		a3Crystal.setCrystalId("Empty2");
		SilUtil.setCrystal(sil, a3Crystal);

		silManager.removeCrystalFromPort(port);
		
		// Make sure the crystal has been moved to row 1 correctly.
		// CrystalId Empty2 will be renamed to Empty2_1 in port A2.
		Crystal newCrystal = SilUtil.getCrystalFromPort(sil, "A2");
		assertEquals(row, newCrystal.getRow());
		assertTrue(newCrystal.getPort() != port);
		assertEquals(containerId, newCrystal.getContainerId());
		assertEquals(containerType, newCrystal.getContainerType());
		assertEquals("Empty" + String.valueOf(row+1) + "_1", newCrystal.getCrystalId());
		assertEquals(null, newCrystal.getData().getProtein());
		assertEquals(0, newCrystal.getImages().size());
	}	
	
	public void testAddRunDefinition() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.1);
		props.addPropertyValue("beam_height", 0.1);
		silManager.addDefaultRepositionData(uniqueId, props);
				
		props = new MutablePropertyValues();
		props.addPropertyValue("startAngle", "10.0");
		props.addPropertyValue("endAngle", "190.0");
		silManager.addRunDefinition(uniqueId, 0, props);
		
		props = new MutablePropertyValues();
		props.addPropertyValue("startAngle", "90.0");
		props.addPropertyValue("endAngle", "220.0");
		silManager.addRunDefinition(uniqueId, 0, props);
		
		
		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(3, crystal.getEventId()); 
		assertEquals(2, crystal.getResult().getRuns().size());
		
		RunDefinition run = crystal.getResult().getRuns().get(0);
		assertEquals(1, run.getRunLabel());
		assertEquals(10.0, run.getStartAngle());
		assertEquals(190.0, run.getEndAngle());
		
		run = crystal.getResult().getRuns().get(1);
		assertEquals(2, run.getRunLabel());
		assertEquals(90.0, run.getStartAngle());
		assertEquals(220.0, run.getEndAngle());

	}
		
	public void testDeleteRunDefinition() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId); // crystalEventId = 4
		
		silManager.deleteRunDefinition(uniqueId, 2); // crystalEventId = 5
		
		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);
		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(6, crystal.getEventId());
		assertEquals(3, crystal.getResult().getRuns().size());
		assertEquals(1, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(2).getRunLabel());		
	}
	
	public void testGetNumRunDefitions() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);
		assertEquals(4, silManager.getNumRunDefinitions(uniqueId));
		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(5, crystal.getEventId());
	}
	
	public void testGetRunDefition() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);
		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(5, crystal.getEventId());
		
		RunDefinition run = silManager.getRunDefinition(uniqueId, 1);
		assertEquals(2, run.getRunLabel());
		assertEquals(90.0, run.getStartAngle());
		assertEquals(220.0, run.getEndAngle());
		
	}
	
	public void testMoveRunDefinition() throws Exception {
		
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);
		
		silManager.moveRunDefinition(uniqueId, 2, SilManager.MOVE_TO_TOP);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(6, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
		
		// Nothing will be moved since run 0 is already at the top of the list.
		silManager.moveRunDefinition(uniqueId, 0, SilManager.MOVE_TO_TOP);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(7, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
		
		silManager.moveRunDefinition(uniqueId, 1, SilManager.MOVE_TO_BOTTOM);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(8, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(3).getRunLabel());

		// Nothing will be moved since run 3 is already at the bottom of the list.
		silManager.moveRunDefinition(uniqueId, 3, SilManager.MOVE_TO_BOTTOM);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(9, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(3).getRunLabel());

		silManager.moveRunDefinition(uniqueId, 2, SilManager.MOVE_UP);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(10, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(3).getRunLabel());
		
		// Nothing will be moved since run 0 is already at the top of the list.
		silManager.moveRunDefinition(uniqueId, 0, SilManager.MOVE_UP);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(11, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(3, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(3).getRunLabel());
		
		silManager.moveRunDefinition(uniqueId, 0, SilManager.MOVE_DOWN);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(12, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(4, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(3).getRunLabel());
		
		// Nothing will be moved since run 3 is already at the bottom of the list.
		silManager.moveRunDefinition(uniqueId, 3, SilManager.MOVE_DOWN);

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(13, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(4, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(1, crystal.getResult().getRuns().get(3).getRunLabel());
	}
	
	public void testSetRunDefinitionPropertyValue() throws Exception {
		
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);
		
		silManager.setRunDefinitionPropertyValue(uniqueId, 2, "delta", "20.0");
		silManager.setRunDefinitionPropertyValue(uniqueId, 2, "attenuation", "90.0");

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(7, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());

		RunDefinition run = crystal.getResult().getRuns().get(0);
		assertEquals(1, run.getRunLabel());
		assertEquals(10.0, run.getStartAngle());
		assertEquals(190.0, run.getEndAngle());
		assertEquals(1.0, run.getDelta());
		assertEquals(50.0, run.getAttenuation());	
		
		run = crystal.getResult().getRuns().get(1);
		assertEquals(2, run.getRunLabel());
		assertEquals(90.0, run.getStartAngle());
		assertEquals(220.0, run.getEndAngle());
		assertEquals(2.0, run.getDelta());
		assertEquals(60.0, run.getAttenuation());	
		
		run = crystal.getResult().getRuns().get(2);
		assertEquals(3, run.getRunLabel());
		assertEquals(15.0, run.getStartAngle());
		assertEquals(85.0, run.getEndAngle());
		assertEquals(20.0, run.getDelta());
		assertEquals(90.0, run.getAttenuation());
		
		run = crystal.getResult().getRuns().get(3);
		assertEquals(4, run.getRunLabel());
		assertEquals(60.0, run.getStartAngle());
		assertEquals(120.0, run.getEndAngle());
		assertEquals(4.0, run.getDelta());
		assertEquals(80.0, run.getAttenuation());
		
	}
	
	public void testSetRunDefinitionProperties() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);
		int index = 1;
		
		RunDefinition run = silManager.getRunDefinition(uniqueId, index);
		assertNotNull(run);
		assertEquals(2, run.getRunLabel());
		assertEquals(90.0, run.getStartAngle());
		assertEquals(220.0, run.getEndAngle());
		assertEquals(2.0, run.getDelta());
		assertEquals(60.0, run.getAttenuation());

		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("next_Frame", 1);
		props.addPropertyValue("file_root", "test1");
		props.addPropertyValue("directory", "/data/penjitk/collect1");
		props.addPropertyValue("start_frame", 10);
		props.addPropertyValue("axis_motor", "phi");
		props.addPropertyValue("start_angle", 150.0);
		props.addPropertyValue("end_angle", 350.0);
		props.addPropertyValue("delta", 5.0);
		props.addPropertyValue("wedge_size", 180.0);
		props.addPropertyValue("dose_mode", 1);
		props.addPropertyValue("attenuation", 99.0);
		props.addPropertyValue("exposure_time", 10.0);
		props.addPropertyValue("photon_count", 100);
		props.addPropertyValue("resolution_mode", 1);
		props.addPropertyValue("resolution", 1.6);
		props.addPropertyValue("distance", 466.0);
		props.addPropertyValue("beam_stop", 33.0);
		props.addPropertyValue("num_energy", 5);
		props.addPropertyValue("energy1", 10001.0);
		props.addPropertyValue("energy2", 10002.0);
		props.addPropertyValue("energy3", 10003.0);
		props.addPropertyValue("energy4", 10004.0);
		props.addPropertyValue("energy5", 10005.0);
		props.addPropertyValue("detector_mode", 5);
		props.addPropertyValue("inverse_on", 1);
		props.addPropertyValue("repositionId", 1);
		
		int eventId = silManager.getLatestCrystalEventId(uniqueId);
		
		// Force getOrCreateSilManager() to reload of sil from file.
		cache.clearCache();
		silManager = cache.getOrCreateSilManager(silId);

		silManager.setRunDefinitionProperties(uniqueId, index, props);
		int newEventId = silManager.getLatestCrystalEventId(uniqueId);
		assertEquals(newEventId, eventId+1);
		
		run = silManager.getRunDefinition(uniqueId, index);
		assertNotNull(run);
		assertEquals(2, run.getRunLabel());
		assertEquals("test1", run.getFileRoot());
		assertEquals("/data/penjitk/collect1", run.getDirectory());
		assertEquals("phi", run.getAxisMotorName());
		assertEquals(150.0, run.getStartAngle());
		assertEquals(350.0, run.getEndAngle());
		assertEquals(5.0, run.getDelta());
		assertEquals(180.0, run.getWedgeSize());
		assertEquals(1, run.getDoseMode());
		assertEquals(99.0, run.getAttenuation());
		assertEquals(100, run.getPhotonCount());
		assertEquals(1, run.getResolutionMode());
		assertEquals(1.6, run.getResolution());
		assertEquals(466.0, run.getDistance());
		assertEquals(33.0, run.getBeamStop());
		assertEquals(5, run.getNumEnergy());
		assertEquals(10001.0, run.getEnergy1());
		assertEquals(10002.0, run.getEnergy2());
		assertEquals(10003.0, run.getEnergy3());
		assertEquals(10004.0, run.getEnergy4());
		assertEquals(10005.0, run.getEnergy5());
		assertEquals(5, run.getDetectorMode());
		assertEquals(1, run.getInverse());
		assertEquals(1, run.getRepositionId());
	}
	
	public void testSetRunDefinitionPropertiesSilent() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);
		int index = 1;
				
		RunDefinition run = silManager.getRunDefinition(uniqueId, index);
		assertNotNull(run);
		assertEquals(2, run.getRunLabel());
		assertEquals(90.0, run.getStartAngle());
		assertEquals(220.0, run.getEndAngle());
		assertEquals(2.0, run.getDelta());
		assertEquals(60.0, run.getAttenuation());

				
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("next_Frame", 1);
		props.addPropertyValue("file_root", "test1");
		props.addPropertyValue("directory", "/data/penjitk/collect1");
		props.addPropertyValue("start_frame", 10);
		props.addPropertyValue("axis_motor", "phi");
		props.addPropertyValue("start_angle", 150.0);
		props.addPropertyValue("end_angle", 350.0);
		props.addPropertyValue("delta", 5.0);
		props.addPropertyValue("wedge_size", 180.0);
		props.addPropertyValue("dose_mode", 1);
		props.addPropertyValue("attenuation", 99.0);
		props.addPropertyValue("exposure_time", 10.0);
		props.addPropertyValue("photon_count", 100);
		props.addPropertyValue("resolution_mode", 1);
		props.addPropertyValue("resolution", 1.6);
		props.addPropertyValue("distance", 466.0);
		props.addPropertyValue("beam_stop", 33.0);
		props.addPropertyValue("num_energy", 5);
		props.addPropertyValue("energy1", 10001.0);
		props.addPropertyValue("energy2", 10002.0);
		props.addPropertyValue("energy3", 10003.0);
		props.addPropertyValue("energy4", 10004.0);
		props.addPropertyValue("energy5", 10005.0);
		props.addPropertyValue("detector_mode", 5);
		props.addPropertyValue("inverse_on", 1);
		props.addPropertyValue("repositionId", 1);
		
		int eventId = silManager.getLatestCrystalEventId(uniqueId);
		
		// Force getOrCreateSilManager() to reload of sil from file.
		cache.clearCache();
		silManager = cache.getOrCreateSilManager(silId);
		
		silManager.setRunDefinitionProperties(uniqueId, index, props, true); // silent
		int newEventId = silManager.getLatestCrystalEventId(uniqueId);
		assertEquals(newEventId, eventId);
		
		run = silManager.getRunDefinition(uniqueId, index);
		assertNotNull(run);
		assertEquals(2, run.getRunLabel());
		assertEquals("test1", run.getFileRoot());
		assertEquals("/data/penjitk/collect1", run.getDirectory());
		assertEquals("phi", run.getAxisMotorName());
		assertEquals(150.0, run.getStartAngle());
		assertEquals(350.0, run.getEndAngle());
		assertEquals(5.0, run.getDelta());
		assertEquals(180.0, run.getWedgeSize());
		assertEquals(1, run.getDoseMode());
		assertEquals(99.0, run.getAttenuation());
		assertEquals(100, run.getPhotonCount());
		assertEquals(1, run.getResolutionMode());
		assertEquals(1.6, run.getResolution());
		assertEquals(466.0, run.getDistance());
		assertEquals(33.0, run.getBeamStop());
		assertEquals(5, run.getNumEnergy());
		assertEquals(10001.0, run.getEnergy1());
		assertEquals(10002.0, run.getEnergy2());
		assertEquals(10003.0, run.getEnergy3());
		assertEquals(10004.0, run.getEnergy4());
		assertEquals(10005.0, run.getEnergy5());
		assertEquals(5, run.getDetectorMode());
		assertEquals(1, run.getInverse());
		assertEquals(1, run.getRepositionId());
	}

	
	public void testSetRunDefinitionPropertyValueForAll() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);
		
		silManager.setRunDefinitionPropertyValue(uniqueId, "delta", "20.0");
		silManager.setRunDefinitionPropertyValue(uniqueId, "attenuation", "90.0");

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);

		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(7, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		
		RunDefinition run = crystal.getResult().getRuns().get(0);
		assertEquals(1, run.getRunLabel());
		assertEquals(10.0, run.getStartAngle());
		assertEquals(190.0, run.getEndAngle());
		assertEquals(20.0, run.getDelta());
		assertEquals(90.0, run.getAttenuation());	
		
		run = crystal.getResult().getRuns().get(1);
		assertEquals(2, run.getRunLabel());
		assertEquals(90.0, run.getStartAngle());
		assertEquals(220.0, run.getEndAngle());
		assertEquals(20.0, run.getDelta());
		assertEquals(90.0, run.getAttenuation());	
		
		run = crystal.getResult().getRuns().get(2);
		assertEquals(3, run.getRunLabel());
		assertEquals(15.0, run.getStartAngle());
		assertEquals(85.0, run.getEndAngle());
		assertEquals(20.0, run.getDelta());
		assertEquals(90.0, run.getAttenuation());
		
		run = crystal.getResult().getRuns().get(3);
		assertEquals(4, run.getRunLabel());
		assertEquals(60.0, run.getStartAngle());
		assertEquals(120.0, run.getEndAngle());
		assertEquals(20.0, run.getDelta());
		assertEquals(90.0, run.getAttenuation());
	}
	
	private void addRunDefinitions(SilManager silManager, long uniqueId) throws Exception {		
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.1);
		props.addPropertyValue("beam_height", 0.1);
		silManager.addDefaultRepositionData(uniqueId, props);
		
		props = new MutablePropertyValues();
		props.addPropertyValue("runStatus", "Aborted");
		props.addPropertyValue("startAngle", "10.0");
		props.addPropertyValue("repositionId", "0");
		props.addPropertyValue("endAngle", "190.0");
		props.addPropertyValue("delta", "1.0");
		props.addPropertyValue("attenuation", "50.0");
		silManager.addRunDefinition(uniqueId, 0, props);
		
		props = new MutablePropertyValues();
		props.addPropertyValue("runStatus", "Active");
		props.addPropertyValue("startAngle", "90.0");
		props.addPropertyValue("repositionId", "0");
		props.addPropertyValue("endAngle", "220.0");
		props.addPropertyValue("delta", "2.0");
		props.addPropertyValue("attenuation", "60.0");
		silManager.addRunDefinition(uniqueId, 0, props);

		props = new MutablePropertyValues();
		props.addPropertyValue("runStatus", "Inactive");
		props.addPropertyValue("startAngle", "15.0");
		props.addPropertyValue("repositionId", "0");
		props.addPropertyValue("endAngle", "85.0");
		props.addPropertyValue("delta", "3.0");
		props.addPropertyValue("attenuation", "70.0");
		silManager.addRunDefinition(uniqueId, 0, props);

		props = new MutablePropertyValues();
		props.addPropertyValue("runStatus", "Running");
		props.addPropertyValue("startAngle", "60.0");
		props.addPropertyValue("repositionId", "0");
		props.addPropertyValue("endAngle", "120.0");
		props.addPropertyValue("delta", "4.0");
		props.addPropertyValue("attenuation", "80.0");
		silManager.addRunDefinition(uniqueId, 0, props);
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
		assertEquals(5, crystal.getEventId());
		assertEquals(4, crystal.getResult().getRuns().size());
		assertEquals(1, crystal.getResult().getRuns().get(0).getRunLabel());
		assertEquals(2, crystal.getResult().getRuns().get(1).getRunLabel());
		assertEquals(3, crystal.getResult().getRuns().get(2).getRunLabel());
		assertEquals(4, crystal.getResult().getRuns().get(3).getRunLabel());
	}
	
	public void testGetLatestCrystalEventIds() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.1);
		props.addPropertyValue("beam_height", 0.1);
		silManager.addDefaultRepositionData(uniqueId, props);

		props = new MutablePropertyValues();
		props.addPropertyValue("distance", "100.0");
		props.addPropertyValue("repositionId", "0");
		silManager.addRunDefinition(uniqueId, 0, props); 
		
		props = new MutablePropertyValues();
		props.addPropertyValue("distance", "200.0");
		props.addPropertyValue("repositionId", "0");
		silManager.addRunDefinition(uniqueId, 0, props); 
		
		props = new MutablePropertyValues();
		props.addPropertyValue("distance", "300.0");
		props.addPropertyValue("repositionId", "0");
		silManager.addRunDefinition(uniqueId, 0, props); 

		props = new MutablePropertyValues();
		props.addPropertyValue("distance", "400.0");
		props.addPropertyValue("repositionId", "0");
		silManager.addRunDefinition(uniqueId, 0, props); 
		
		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);
		
		int[] eventIds = silManager.getLatestCrystalEventIds();
		assertEquals(64, eventIds.length);
		assertEquals(0, eventIds[0]);
		assertEquals(5, eventIds[1]);
		assertEquals(0, eventIds[4]);
		assertEquals(0, eventIds[7]);
		assertEquals(0, eventIds[63]);	
	}
	
	public void testGetRunDefinitionLabels() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);
		
		silManager.setRunDefinitionPropertyValue(uniqueId, "delta", "20.0");
		silManager.setRunDefinitionPropertyValue(uniqueId, "attenuation", "90.0");

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);
		int[] labels = silManager.getRunDefinitionLabels(uniqueId);
		assertEquals(4, labels.length);
		assertEquals(1, labels[0]);
		assertEquals(2, labels[1]);
		assertEquals(3, labels[2]);
		assertEquals(4, labels[3]);
	}
	
	public void testGetRunDefinitionStatusList() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		addRunDefinitions(silManager, uniqueId);
		
		silManager.setRunDefinitionPropertyValue(uniqueId, "delta", "20.0");
		silManager.setRunDefinitionPropertyValue(uniqueId, "attenuation", "90.0");

		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false/*forced*/);
		silManager = cache.getOrCreateSilManager(silId);
		String[] status = silManager.getRunDefinitionStatusList(uniqueId);
		assertEquals(4, status.length);
		assertEquals("Aborted", status[0]);
		assertEquals("Active", status[1]);
		assertEquals("Inactive", status[2]);
		assertEquals("Running", status[3]);
	}
	
	public void testAddDefaultRepositionData() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
				
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.6);
		props.addPropertyValue("beam_height", 0.5);
		props.addPropertyValue("reposition_x", 20.0);
		props.addPropertyValue("reposition_y", 30.0);
		props.addPropertyValue("reposition_z", 40.0);
		props.addPropertyValue("distance", 100.0);
		props.addPropertyValue("beamStop", 10.0);
		props.addPropertyValue("attenuation", 90.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_002.jpg");

		int repositionId = silManager.addDefaultRepositionData(uniqueId, props);
		assertEquals(0, repositionId);
		
		RepositionData actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
		assertEquals(0.6, actual.getBeamSizeX());
		assertEquals(0.5, actual.getBeamSizeY());
		assertEquals(20.0, actual.getOffsetX());
		assertEquals(30.0, actual.getOffsetY());
		assertEquals(40.0, actual.getOffsetZ());
		assertEquals(100.0, actual.getDistance());
		assertEquals(10.0, actual.getBeamStop());
		assertEquals(90.0, actual.getAttenuation());
		assertEquals("/data/penjitk/collect1/test1_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/penjitk/collect1/test1_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/penjitk/collect1/test1_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/penjitk/collect1/test1_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/penjitk/collect1/test1_001.jpg", actual.getImage1());
		assertEquals("/data/penjitk/collect1/test1_002.jpg", actual.getImage2());
	}
	
	public void testAddRepositionData() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 50.0);
		props.addPropertyValue("reposition_y", 60.0);
		props.addPropertyValue("reposition_z", 70.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg3.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg4.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box3.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box4.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_003.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_004.jpg");
		
		int repositionId = silManager.addDefaultRepositionData(uniqueId, props);
		assertEquals(0, repositionId);
				
		props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos1");
		props.addPropertyValue("beam_width", 0.6);
		props.addPropertyValue("beam_height", 0.5);
		props.addPropertyValue("reposition_x", 20.0);
		props.addPropertyValue("reposition_y", 30.0);
		props.addPropertyValue("reposition_z", 40.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_002.jpg");

		repositionId = silManager.addRepositionData(uniqueId, props);
		assertEquals(1, repositionId);
		
		RepositionData actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
				
		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false);
		silManager = cache.getOrCreateSilManager(silId);
				
		actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
		assertEquals(0.6, actual.getBeamSizeX());
		assertEquals(0.5, actual.getBeamSizeY());
		assertEquals(20.0, actual.getOffsetX());
		assertEquals(30.0, actual.getOffsetY());
		assertEquals(40.0, actual.getOffsetZ());
		assertEquals("/data/penjitk/collect1/test1_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/penjitk/collect1/test1_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/penjitk/collect1/test1_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/penjitk/collect1/test1_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/penjitk/collect1/test1_001.jpg", actual.getImage1());
		assertEquals("/data/penjitk/collect1/test1_002.jpg", actual.getImage2());
	}
	
	public void testAddRepositionDataDuplicateName() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 50.0);
		props.addPropertyValue("reposition_y", 60.0);
		props.addPropertyValue("reposition_z", 70.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg3.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg4.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box3.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box4.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_003.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_004.jpg");
		
		int repositionId = silManager.addDefaultRepositionData(uniqueId, props);
		assertEquals(0, repositionId);
				
		props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0"); // duplicate name
		props.addPropertyValue("beam_width", 0.6);
		props.addPropertyValue("beam_height", 0.5);
		props.addPropertyValue("reposition_x", 20.0);
		props.addPropertyValue("reposition_y", 30.0);
		props.addPropertyValue("reposition_z", 40.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_002.jpg");

		try {
			repositionId = silManager.addRepositionData(uniqueId, props);
		} catch (Exception e) {
			assertEquals("Reposition data label repos0 already exists.", e.getMessage());
		}
	}

	public void testSetRepositionData() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 50.0);
		props.addPropertyValue("reposition_y", 60.0);
		props.addPropertyValue("reposition_z", 70.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg3.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg4.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box3.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box4.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_003.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_004.jpg");
		
		int repositionId = silManager.addDefaultRepositionData(uniqueId, props);
		assertEquals(0, repositionId);
				
		props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos1");
		props.addPropertyValue("beam_width", 0.6);
		props.addPropertyValue("beam_height", 0.5);
		props.addPropertyValue("reposition_x", 20.0);
		props.addPropertyValue("reposition_y", 30.0);
		props.addPropertyValue("reposition_z", 40.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_002.jpg");

		repositionId = silManager.addRepositionData(uniqueId, props);
		assertEquals(1, repositionId);
		
		RepositionData actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
				
		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false);
		silManager = cache.getOrCreateSilManager(silId);
				
		actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
		assertEquals(0.6, actual.getBeamSizeX());
		assertEquals(0.5, actual.getBeamSizeY());
		assertEquals(20.0, actual.getOffsetX());
		assertEquals(30.0, actual.getOffsetY());
		assertEquals(40.0, actual.getOffsetZ());
		assertEquals("/data/penjitk/collect1/test1_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/penjitk/collect1/test1_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/penjitk/collect1/test1_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/penjitk/collect1/test1_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/penjitk/collect1/test1_001.jpg", actual.getImage1());
		assertEquals("/data/penjitk/collect1/test1_002.jpg", actual.getImage2());
		
		props = new MutablePropertyValues();
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 60.0);
		props.addPropertyValue("reposition_y", 70.0);
		props.addPropertyValue("reposition_z", 80.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect3/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect3/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect3/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect3/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect3/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect3/test1_002.jpg");
		silManager.setRepositionData(uniqueId, 1, props);
		
		cache.removeSil(silId, false);
		silManager = cache.getOrCreateSilManager(silId);
				
		actual = silManager.getRepositionData(uniqueId, 1);
		assertNotNull(actual);
		assertEquals(0.9, actual.getBeamSizeX());
		assertEquals(0.1, actual.getBeamSizeY());
		assertEquals(60.0, actual.getOffsetX());
		assertEquals(70.0, actual.getOffsetY());
		assertEquals(80.0, actual.getOffsetZ());
		assertEquals("/data/penjitk/collect3/test1_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/penjitk/collect3/test1_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/penjitk/collect3/test1_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/penjitk/collect3/test1_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/penjitk/collect3/test1_001.jpg", actual.getImage1());
		assertEquals("/data/penjitk/collect3/test1_002.jpg", actual.getImage2());

	}
	
	public void testSetRepositionDataCannotModifyLabel() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 50.0);
		props.addPropertyValue("reposition_y", 60.0);
		props.addPropertyValue("reposition_z", 70.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg3.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg4.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box3.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box4.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_003.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_004.jpg");
		
		int repositionId = silManager.addDefaultRepositionData(uniqueId, props);
		assertEquals(0, repositionId);
				
		props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos1");
		props.addPropertyValue("beam_width", 0.6);
		props.addPropertyValue("beam_height", 0.5);
		props.addPropertyValue("reposition_x", 20.0);
		props.addPropertyValue("reposition_y", 30.0);
		props.addPropertyValue("reposition_z", 40.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_002.jpg");

		repositionId = silManager.addRepositionData(uniqueId, props);
		assertEquals(1, repositionId);
		
		RepositionData actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
				
		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false);
		silManager = cache.getOrCreateSilManager(silId);
				
		actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
		assertEquals("repos1", actual.getLabel());
		assertEquals(0.6, actual.getBeamSizeX());
		assertEquals(0.5, actual.getBeamSizeY());
		assertEquals(20.0, actual.getOffsetX());
		assertEquals(30.0, actual.getOffsetY());
		assertEquals(40.0, actual.getOffsetZ());
		assertEquals("/data/penjitk/collect1/test1_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/penjitk/collect1/test1_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/penjitk/collect1/test1_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/penjitk/collect1/test1_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/penjitk/collect1/test1_001.jpg", actual.getImage1());
		assertEquals("/data/penjitk/collect1/test1_002.jpg", actual.getImage2());
		
		props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos2");
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 60.0);
		props.addPropertyValue("reposition_y", 70.0);
		props.addPropertyValue("reposition_z", 80.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect3/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect3/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect3/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect3/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect3/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect3/test1_002.jpg");
		try {
			silManager.setRepositionData(uniqueId, 1, props);
		} catch (Exception e) {
			assertEquals("Cannot modify reposition label.", e.getMessage());
		}
	}
	
	public void testSetRepositionDataCannotModifyRepositionId() throws Exception {
		int silId = 3;
		long uniqueId = 2000194;
		SilManager silManager = cache.getOrCreateSilManager(silId);
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 50.0);
		props.addPropertyValue("reposition_y", 60.0);
		props.addPropertyValue("reposition_z", 70.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg3.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg4.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box3.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box4.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_003.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_004.jpg");
		
		int repositionId = silManager.addDefaultRepositionData(uniqueId, props);
		assertEquals(0, repositionId);
				
		props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos1");
		props.addPropertyValue("beam_width", 0.6);
		props.addPropertyValue("beam_height", 0.5);
		props.addPropertyValue("reposition_x", 20.0);
		props.addPropertyValue("reposition_y", 30.0);
		props.addPropertyValue("reposition_z", 40.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect1/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect1/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect1/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect1/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect1/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect1/test1_002.jpg");

		repositionId = silManager.addRepositionData(uniqueId, props);
		assertEquals(1, repositionId);
		
		RepositionData actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
				
		// Reload sil from file to make sure that new data has been saved.
		cache.removeSil(silId, false);
		silManager = cache.getOrCreateSilManager(silId);
				
		actual = silManager.getRepositionData(uniqueId, repositionId);
		assertNotNull(actual);
		assertEquals("repos1", actual.getLabel());
		assertEquals(0.6, actual.getBeamSizeX());
		assertEquals(0.5, actual.getBeamSizeY());
		assertEquals(20.0, actual.getOffsetX());
		assertEquals(30.0, actual.getOffsetY());
		assertEquals(40.0, actual.getOffsetZ());
		assertEquals("/data/penjitk/collect1/test1_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/penjitk/collect1/test1_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/penjitk/collect1/test1_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/penjitk/collect1/test1_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/penjitk/collect1/test1_001.jpg", actual.getImage1());
		assertEquals("/data/penjitk/collect1/test1_002.jpg", actual.getImage2());
		
		props = new MutablePropertyValues();
		props.addPropertyValue("repositionId", "2");
		props.addPropertyValue("label", "repos2");
		props.addPropertyValue("beam_width", 0.9);
		props.addPropertyValue("beam_height", 0.1);
		props.addPropertyValue("reposition_x", 60.0);
		props.addPropertyValue("reposition_y", 70.0);
		props.addPropertyValue("reposition_z", 80.0);
		props.addPropertyValue("fileVSnapshot1", "/data/penjitk/collect3/test1_jpeg1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/penjitk/collect3/test1_jpeg2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/penjitk/collect3/test1_box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/penjitk/collect3/test1_box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/penjitk/collect3/test1_001.jpg");
		props.addPropertyValue("fileDiffImage2", "/data/penjitk/collect3/test1_002.jpg");
		try {
			silManager.setRepositionData(uniqueId, 1, props);
		} catch (Exception e) {
			assertEquals("Cannot modify repositionId.", e.getMessage());
		}
	}
	
	public void testGetRepositionData() throws Exception {
		
	}
	
	public void testGetAllRepositionData() throws Exception {
		
	}
	
	public void testGetAllRepositionDataEmpty() throws Exception {
		
	}
	
	public void testGetRepositionDataIndexOutOfRange() throws Exception {
		
	}

}
