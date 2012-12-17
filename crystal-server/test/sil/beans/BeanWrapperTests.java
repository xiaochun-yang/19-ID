package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.*;
import org.springframework.context.ApplicationContext;

import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.MappableBeanWrapper;
import sil.beans.util.SilUtil;
import sil.factory.SilFactory;
import sil.AllTests;
import sil.TestData;

import java.util.*;
import junit.framework.TestCase;

public class BeanWrapperTests extends TestCase {
	
	private class SimpleBean
	{
		private String name = null;
		private String value = null;
		private String dir = null;
		
		public String getName() {
			return name;
		}
		public void setName(String name) {
			this.name = name;
		}
		public String getValue() {
			return value;
		}
		public void setValue(String value) {
			this.value = value;
		}
		
		public String toString()
		{
			return "[" + getName() + ", " + getValue() + ", " + getDir() + "]";
		}
		public String getDir() {
			return dir;
		}
		public void setDir(String dir) {
			this.dir = dir;
		}
		
	}
	
	private class MapCollectionBean
	{
		private Map collection = new Hashtable<String, SimpleBean>();
		public Map getCollection() {
			return collection;
		}
		public void setCollection(Map collection) {
			this.collection = collection;
		}		
	}
	
	private class ArrayCollectionBean
	{
		private SimpleBean collection[] = new SimpleBean[2];
		public ArrayCollectionBean()
		{
			collection[0] = new SimpleBean();
			collection[1] = new SimpleBean();
		}
		public SimpleBean[] getCollection() {
			return collection;
		}
		public void setCollection(SimpleBean[] collection) {
			this.collection = collection;
		}	
		public SimpleBean getCollection(int index) {
			if (index < collection.length)
				return collection[index];
			
			return null;
		}
		public void setCollection(int index, SimpleBean bean) {
			if (index < collection.length)
				collection[index] = bean;
		}
	}
	
	private class ListCollectionBean
	{
		private List collection = new ArrayList<SimpleBean>();
		public ListCollectionBean()
		{
			collection.add(new Image());
			collection.add(new Image());
		}
		public List getCollection() {
			return collection;
		}
		public void setCollection(List collection) {
			this.collection = collection;
		}
	}
	
	private class ImageListBean
	{
		private List images = new ArrayList<Image>();
		public ImageListBean()
		{
			images.add(new Image());
			images.add(new Image());
		}
		public List getImages() {
			return images;
		}
		public void setImages(List images) {
			this.images = images;
		}
	}
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public BeanWrapperTests()
	{
	}
	
	
	// This test shows that we can use bean wrapper to set value 
	// of an entry in a collection.
	public void testMapCollectionBean()
	{
		try {
			SimpleBean simpleBean1 = new SimpleBean();
			simpleBean1.setName("oldName1"); simpleBean1.setValue("oldValue1");
			SimpleBean simpleBean2 = new SimpleBean();
			simpleBean2.setName("oldName2"); simpleBean2.setValue("oldValue2");
		
			SimpleBean newBean = new SimpleBean();
			newBean.setName("newName1");
			newBean.setValue("newvalue1");
			
			MapCollectionBean colBean = new MapCollectionBean();
			Hashtable<String, SimpleBean> hash = new Hashtable<String, SimpleBean>();
			hash.put("entry1", simpleBean1);
			hash.put("entry2", simpleBean2);
			colBean.setCollection(hash);
			
			BeanWrapper wrapper = new BeanWrapperImpl(colBean);
			logger.info("testMapCollectionBean: before collection[entry1] = " + wrapper.getPropertyValue("collection[entry1]"));
			logger.info("testMapCollectionBean: before collection[entry2] = " + wrapper.getPropertyValue("collection[entry2]"));
			wrapper.setPropertyValue("collection[entry1]", newBean);
			logger.info("testMapCollectionBean: after collection[entry1] = " + wrapper.getPropertyValue("collection[entry1]"));
			
			wrapper.setPropertyValue("collection[entry2].name", "newName2");
			wrapper.setPropertyValue("collection[entry2].value", "newValue2");
			logger.info("testMapCollectionBean: after collection[entry2] = " + wrapper.getPropertyValue("collection[entry2]"));

			// Expect NullValueInNestedPathException since entry3 does not exist.
			try {
			wrapper.setPropertyValue("collection[entry3].name", "newName3");
			wrapper.setPropertyValue("collection[entry3].value", "newValue3");
			logger.info("testMapCollectionBean: after collection[entry3] = " + wrapper.getPropertyValue("collection[entry3]"));
			} catch (NullValueInNestedPathException e) {
				logger.error("testMapCollectionBean: cannot set non existing entry in collection " + e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
	}
		
	public void testArrayCollectionBean()
	{
		try {
			
			SimpleBean simpleBean1 = new SimpleBean();
			simpleBean1.setName("oldName1"); simpleBean1.setValue("oldValue1");
			SimpleBean simpleBean2 = new SimpleBean();
			simpleBean2.setName("oldName2"); simpleBean2.setValue("oldValue2");
		
			SimpleBean newBean = new SimpleBean();
			newBean.setName("newName1");
			newBean.setValue("newvalue1");
			
			ArrayCollectionBean colBean = new ArrayCollectionBean();
			colBean.setCollection(0, simpleBean1);
			colBean.setCollection(1, simpleBean2);
			
			BeanWrapper wrapper = new BeanWrapperImpl(colBean);
			logger.info("testArrayCollectionBean: before collection[0] = " + wrapper.getPropertyValue("collection[0]"));
			logger.info("testArrayCollectionBean: before collection[1] = " + wrapper.getPropertyValue("collection[1]"));
			wrapper.setPropertyValue("collection[0]", newBean);
			logger.info("testArrayCollectionBean: after collection[0] = " + wrapper.getPropertyValue("collection[0]"));
			
			wrapper.setPropertyValue("collection[1].name", "newName2");
			wrapper.setPropertyValue("collection[1].value", "newValue2");
			logger.info("testArrayCollectionBean: after collection[1] = " + wrapper.getPropertyValue("collection[1]"));
		
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}	
	}
		
	public void testListCollectionBean()
	{
		try {
			
			SimpleBean newBean = new SimpleBean();
			newBean.setName("newImageName0");
			newBean.setDir("newImageDir0");
			
			ListCollectionBean bean = new ListCollectionBean();
			
			BeanWrapper wrapper = new BeanWrapperImpl(bean);
			logger.info("testListCollectionBean: after collection[0].name = " + wrapper.getPropertyValue("collection[0].name") 
					+ " dir = " + wrapper.getPropertyValue("collection[0].dir"));
			logger.info("testListCollectionBean: after collection[1].name = " + wrapper.getPropertyValue("collection[1].name") 
					+ " dir = " + wrapper.getPropertyValue("collection[1].dir"));
			
			wrapper.setPropertyValue("collection[0]", newBean);
			logger.info("testListCollectionBean: after collection[0].name = " + wrapper.getPropertyValue("collection[0].name") 
						+ " dir = " + wrapper.getPropertyValue("collection[0].dir"));
			
			wrapper.setPropertyValue("collection[1].name", "newImageName1");
			wrapper.setPropertyValue("collection[1].dir", "newImageDir1");
			logger.info("testListCollectionBean: after collection[1].name = " + wrapper.getPropertyValue("collection[1].name") 
					+ " dir = " + wrapper.getPropertyValue("collection[1].dir"));
		
			// Expect InvalidPropertyException since index 2 does not exist.
			try {
			wrapper.setPropertyValue("collection[2].name", "newName3");
			wrapper.setPropertyValue("collection[2].value", "newValue3");
			logger.info("testListCollectionBean: after collection[2] = " + wrapper.getPropertyValue("collection[2]"));
			} catch (InvalidPropertyException e) {
				logger.error("testListCollectionBean: cannot set non existing entry in collection " + e.getMessage());
			}

		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}
	
	public void testImageListBean()
	{
		try {
			Image newImage = new Image();
			newImage.setName("newImageName0");
			newImage.setDir("newImageDir0");
			
			ImageListBean bean = new ImageListBean();
			
			BeanWrapper wrapper = new BeanWrapperImpl(bean);
			logger.info("testImageListBean: after images[0].name = " + wrapper.getPropertyValue("images[0].name") 
					+ " dir = " + wrapper.getPropertyValue("images[0].dir"));
			logger.info("testImageListBean: after images[1].name = " + wrapper.getPropertyValue("images[1].name") 
					+ " dir = " + wrapper.getPropertyValue("images[1].dir"));
			
			wrapper.setPropertyValue("images[0]", newImage);
			logger.info("testImageListBean: after images[0].name = " + wrapper.getPropertyValue("images[0].name") 
						+ " dir = " + wrapper.getPropertyValue("images[0].dir"));
			
			wrapper.setPropertyValue("images[1].name", "newImageName1");
			wrapper.setPropertyValue("images[1].dir", "newImageDir1");
			logger.info("testImageListBean: after images[1].name = " + wrapper.getPropertyValue("images[1].name") 
					+ " dir = " + wrapper.getPropertyValue("images[1].dir"));
		
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}
	
	// Check that we can map property names
	// by using various overloading setProperty methods.
	public void testSetMappedPropertyWithAliasName()
	{
		try {
			
			Crystal crystal = new Crystal();
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			wrapper.setPropertyValue("uniqueId", "100000000");
			wrapper.setPropertyValue("port", "A1");
			wrapper.setPropertyValue("containerId", "SSRL1111");
			wrapper.setPropertyValue("crystalId", "A1");
			wrapper.setPropertyValue("Image1.name", "A1_001.img");
			wrapper.setPropertyValue("Jpeg1", "A1_0deg_001.jpg");
			
			PropertyValue prop1 = new PropertyValue("Image2.name", "A1_002.img");
			wrapper.setPropertyValue(prop1);
			PropertyValue prop2 = new PropertyValue("Jpeg2", "A1_90deg_002.jpg");
			wrapper.setPropertyValue(prop2);
			
			MutablePropertyValues props = new MutablePropertyValues();
			props.addPropertyValue(new PropertyValue("Image3.name", "A1_003.img"));
			props.addPropertyValue(new PropertyValue("Jpeg3", "A1_180deg_003.jpg"));
			wrapper.setPropertyValues(props);
			
			Image image1 = CrystalUtil.getLastImageInGroup(crystal, "1");
			Image image2 = CrystalUtil.getLastImageInGroup(crystal, "2");
			Image image3 = CrystalUtil.getLastImageInGroup(crystal, "3");
			
			assertEquals("A1_001.img", image1.getName());
			assertEquals("A1_0deg_001.jpg", image1.getData().getJpeg());
			assertEquals("A1_002.img", image2.getName());
			assertEquals("A1_90deg_002.jpg", image2.getData().getJpeg());
			assertEquals("A1_003.img", image3.getName());
			assertEquals("A1_180deg_003.jpg", image3.getData().getJpeg());
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	// Set property that does not exist in the bean.
	public void testIgnoreUnknownIgnoreInvalidProperty()
	{
		try {
			
			boolean ignoreUnknown = true;
	        boolean ignoreInvalid = true;

	        Crystal crystal = new Crystal();
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			
			MutablePropertyValues props = new MutablePropertyValues();
			wrapper.setPropertyValue("images[2].name", "image2name");
			props.addPropertyValue(new PropertyValue("XXXX", "A1_003.img"));
//			wrapper.setPropertyValues(props);
			wrapper.setPropertyValues(props, ignoreUnknown, ignoreInvalid);
			
			assertEquals("image2name", wrapper.getPropertyValue("images[2].name"));
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	// Demonstrate that CrystalWrapper can add a new image 
	// if the image does not exist when calling setPropertyValue.
	public void testSetMappedProperty()
	{
		try {
			
			Crystal crystal = new Crystal();
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			wrapper.setPropertyValue("uniqueId", "100000000");
			wrapper.setPropertyValue("port", "A1");
			wrapper.setPropertyValue("containerId", "SSRL1111");
			wrapper.setPropertyValue("crystalId", "A1");
			wrapper.setPropertyValue("images[0].name", "image0name");
			wrapper.setPropertyValue("images[0].dir", "image0dir");
			
			PropertyValue prop1 = new PropertyValue("images[1].name", "image1name");
			wrapper.setPropertyValue(prop1);
			PropertyValue prop2 = new PropertyValue("images[1].dir", "image1dir");
			wrapper.setPropertyValue(prop2);
			
			MutablePropertyValues props = new MutablePropertyValues();
			props.addPropertyValue(new PropertyValue("images[2].name", "image2name"));
			props.addPropertyValue(new PropertyValue("images[2].dir", "image2dir"));
			wrapper.setPropertyValues(props);
			
			Image image0 = CrystalUtil.getLastImageInGroup(crystal, "0");
			Image image1 = CrystalUtil.getLastImageInGroup(crystal, "1");
			Image image2 = CrystalUtil.getLastImageInGroup(crystal, "2");
			
			assertEquals("image0name", image0.getName());
			assertEquals("image0dir", image0.getDir());
			assertEquals("image1name", image1.getName());
			assertEquals("image1dir", image1.getDir());
			assertEquals("image2name", image2.getName());
			assertEquals("image2dir", image2.getDir());
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}

	// Check empty string property value.
	public void testEmptyStringForNumberProperty()
	{
		try {
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
			
			Crystal crystal = new Crystal();
			// Get CrystalWrapper from SilFactory so that it can handle alias property name.
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			wrapper.setPropertyValue("uniqueId", "100000000");
			wrapper.setPropertyValue("port", "A1");
			wrapper.setPropertyValue("containerId", "SSRL1111");
			wrapper.setPropertyValue("crystalId", "myo1");
			wrapper.setPropertyValue("data.protein", "myoglobin");
			wrapper.setPropertyValue("result.autoindexResult.score", "0.888");
			wrapper.setPropertyValue("result.autoindexResult.mosaicity", "");
			wrapper.setPropertyValue("result.autoindexResult.unitCell", "150.0 160.0 170.0 90.0 80.0 89.0");
			wrapper.setPropertyValue("images[1].result.spotfinderResult.spotShape", "1.3");
			wrapper.setPropertyValue("images[1].result.spotfinderResult.numOverloadSpots", "500");
			wrapper.setPropertyValue("images[1].result.spotfinderResult.numIceRings", "3");
			wrapper.setPropertyValue("images[1].result.spotfinderResult.numSpots", "");
//			wrapper.setPropertyValue("images[1].result.spotfinderResult.integratedIntensity", "");
			
			MutablePropertyValues props = new MutablePropertyValues();
			props.addPropertyValue(new PropertyValue("images[1].result.spotfinderResult.integratedIntensity", ""));
			wrapper.setPropertyValues(props);
			
			UnitCell unitCell = new UnitCell();
			unitCell.setA(150.0);
			unitCell.setB(160.0);
			unitCell.setC(170.0);
			unitCell.setAlpha(90.0);
			unitCell.setBeta(80.0);
			unitCell.setGamma(89.0);
			
			assertEquals("A1", crystal.getPort());
			assertEquals("myo1", crystal.getCrystalId());
			assertEquals("SSRL1111", crystal.getContainerId());
			assertEquals("myoglobin", crystal.getData().getProtein());
			assertEquals(0.888, crystal.getResult().getAutoindexResult().getScore());
			boolean test = crystal.getResult().getAutoindexResult().getMosaicity() == 0.0;
			assertTrue(test);
			assertEquals(crystal.getResult().getAutoindexResult().getUnitCell(), unitCell);
			Image image = CrystalUtil.getLastImageInGroup(crystal, "1");
			assertNotNull(image);
			assertEquals(1.3, image.getResult().getSpotfinderResult().getSpotShape());
			assertEquals(500, image.getResult().getSpotfinderResult().getNumOverloadSpots());
			assertEquals(3, image.getResult().getSpotfinderResult().getNumIceRings());
			assertEquals(0, image.getResult().getSpotfinderResult().getNumSpots());
			assertEquals(0.0, image.getResult().getSpotfinderResult().getIntegratedIntensity());
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	
	// Cannot set image[2] since it does not exist in sil.
	public void testSetImageProperty() 
	{
		logger.info("START testSetImage");
		try {	
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
			
			Crystal crystal = TestData.createSimpleCrystal();
			// Get CrystalWrapper from SilFactory so that it can handle alias property name.
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			wrapper.setPropertyValue("images[1].name", "A1_002_new.img");
			wrapper.setPropertyValue("images[2].name", "A1_003.img");
			
			Image image1 = CrystalUtil.getLastImageInGroup(crystal, "1");
			assertEquals("A1_002_new.img", image1.getName());
			Image image2 = CrystalUtil.getLastImageInGroup(crystal, "2");
			assertEquals("A1_003.img", image2.getName());

		} catch (Exception e) {
			logger.info("Nested image must exist before its property can be set.");
			e.printStackTrace();
			fail(e.getMessage());
		}
		logger.info("FINISH testSetImage");
	}

	// Map key must be string for this to work.
	public void testWrapSilBean() 
	{
		logger.info("START testMappedProperty");
		try {	
			Sil sil = TestData.createSimpleSil();
			MappableBeanWrapper wrapper = new MappableBeanWrapper(sil);
			Crystal crystal = SilUtil.getCrystalFromPort(sil, "A1");
			assertNotNull(crystal);
			Long key = crystal.getUniqueId();
			String prefix = "crystals[" + key + "]";
			logger.info(prefix + ".port = " + wrapper.getPropertyValue(prefix + ".port"));
			logger.info(prefix + ".data.directory = " + wrapper.getPropertyValue(prefix + ".data.directory"));
			logger.info(prefix + ".port = " + wrapper.getPropertyValue(prefix + ".port"));
			logger.info(prefix + ".data.directory = " + wrapper.getPropertyValue(prefix + ".data.directory"));
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			fail(e.getMessage());
		}
		logger.info("FINISH testMappedProperty");
	}
	
	public void testRunDefinitionWrapper() throws Exception {
		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("status", "active");
		props.addPropertyValue("next_frame", 2);
		props.addPropertyValue("run_label", 10);
		props.addPropertyValue("file_root", "test1");
		props.addPropertyValue("directory", "/data/annikas");
		props.addPropertyValue("start_frame", 4);
		props.addPropertyValue("axis_motor", "phi");
		props.addPropertyValue("start_angle", 90.0);
		props.addPropertyValue("end_angle", 120.0);
		props.addPropertyValue("delta", 1.0);
		props.addPropertyValue("wedge_size", 180.0);
		props.addPropertyValue("dose_mode", 1);
		props.addPropertyValue("attenuation", 50.0);
		props.addPropertyValue("exposure_time", 3.0);
		props.addPropertyValue("photon_count", 1);
		props.addPropertyValue("resolution_mode", 1);
		props.addPropertyValue("resolution", 1.6);
		props.addPropertyValue("distance", 400.0);
		props.addPropertyValue("beam_stop", 30.0);
		props.addPropertyValue("num_energy", 5);
		props.addPropertyValue("energy1", 12001.0);
		props.addPropertyValue("energy2", 12002.0);
		props.addPropertyValue("energy3", 12003.0);
		props.addPropertyValue("energy4", 12004.0);
		props.addPropertyValue("energy5", 12005.0);
		props.addPropertyValue("detector_mode", 2);
		props.addPropertyValue("inverse_on", 1);
		props.addPropertyValue("repositionId", 5);

		RunDefinition run = new RunDefinition();
		BeanWrapper wrapper = silFactory.createRunDefinitionWrapper(run);
		wrapper.setPropertyValues(props);
		
		assertEquals("active", run.getRunStatus());
		assertEquals(2, run.getNextFrame());
		assertEquals(10, run.getRunLabel());
		assertEquals("test1", run.getFileRoot());
		assertEquals("/data/annikas", run.getDirectory());
		assertEquals(4, run.getStartFrame());
		assertEquals("phi", run.getAxisMotorName());
		assertEquals(90.0, run.getStartAngle());
		assertEquals(120.0, run.getEndAngle());
		assertEquals(1.0, run.getDelta());
		assertEquals(180.0, run.getWedgeSize());
		assertEquals(1, run.getDoseMode());
		assertEquals(50.0, run.getAttenuation());
		assertEquals(3.0, run.getExposureTime());
		assertEquals(1, run.getPhotonCount());
		assertEquals(1, run.getResolutionMode());
		assertEquals(1.6, run.getResolution());
		assertEquals(400.0, run.getDistance());
		assertEquals(30.0, run.getBeamStop());
		assertEquals(5, run.getNumEnergy());
		assertEquals(12001.0, run.getEnergy1());
		assertEquals(12002.0, run.getEnergy2());
		assertEquals(12003.0, run.getEnergy3());
		assertEquals(12004.0, run.getEnergy4());
		assertEquals(12005.0, run.getEnergy5());
		assertEquals(2, run.getDetectorMode());
		assertEquals(1, run.getInverse());
		assertEquals(5, run.getRepositionId());
	}
	
	public void testRepositionDataWrapper() throws Exception {
		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("delta", 1.0);
		props.addPropertyValue("attenuation", 50.0);
		props.addPropertyValue("exposure_time", 3.0);
		props.addPropertyValue("distance", 400.0);
		props.addPropertyValue("beam_stop", 30.0);
		props.addPropertyValue("energy", 12001.0);
		props.addPropertyValue("detector_mode", 2);
		props.addPropertyValue("flux", 10.0);
		props.addPropertyValue("i2", 20.0);
		props.addPropertyValue("camera_zoom", 80.0);
		props.addPropertyValue("scaling_factory", 5.0);
		props.addPropertyValue("detector_mode", 2);
		props.addPropertyValue("beamline", "BL9-1");
		
		props.addPropertyValue("beam_width", 0.4);
		props.addPropertyValue("beam_height", 0.6);
		props.addPropertyValue("reposition_x", 10.0);
		props.addPropertyValue("reposition_y", 20.0);
		props.addPropertyValue("reposition_z", 30.0);
		props.addPropertyValue("fileVSnapshot1", "/data/annikas/test1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/annikas/test2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/annikas/box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/annikas/box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/annikas/test1.mccd");
		props.addPropertyValue("fileDiffImage2", "/data/annikas/test2.mccd");
		props.addPropertyValue("reorientInfo", "/data/annikas/run1/reorient_info");
		props.addPropertyValue("autoindexable", 1);
		
		// Old style
		props.addPropertyValue("autoindexDir", "/data/annikas/webice/autoindex/test1");
		props.addPropertyValue("autoindexImages", "/data/annikas/test1.mccd /data/annikas/test2.mccd");
		props.addPropertyValue("score", 20.0);
		props.addPropertyValue("unitCell", "50.0 60.0 70.0 80.0 90.0 100.0");
		props.addPropertyValue("mosaicity", 0.7);
		props.addPropertyValue("rmsd", 0.99);
		props.addPropertyValue("bravaisLattice", "C22");
		props.addPropertyValue("resolution", 1.87);
		props.addPropertyValue("isigma", 0.8);
		props.addPropertyValue("bestSolution", 9);
		props.addPropertyValue("warning", "High mosaicity");

		RepositionData data = new RepositionData();
		BeanWrapper wrapper = silFactory.createRepositionDataWrapper(data);
		wrapper.setPropertyValues(props);
		
		assertEquals("BL9-1", data.getBeamline());
		assertEquals("repos0", data.getLabel());
		assertEquals(1.0, data.getDelta());
		assertEquals(50.0, data.getAttenuation());
		assertEquals(3.0, data.getExposureTime());
		assertEquals(400.0, data.getDistance());
		assertEquals(30.0, data.getBeamStop());
		assertEquals(12001.0, data.getEnergy());
		assertEquals(2, data.getDetectorMode());
		assertEquals(10.0, data.getFlux());
		assertEquals(20.0, data.getI2());
		assertEquals(80.0, data.getCameraZoom());
		assertEquals(5.0, data.getScalingFactor());
		assertEquals(2, data.getDetectorMode());
		assertEquals(0.4, data.getBeamSizeX());
		assertEquals(0.6, data.getBeamSizeY());
		assertEquals(10.0, data.getOffsetX());
		assertEquals(20.0, data.getOffsetY());
		assertEquals(30.0, data.getOffsetZ());
		assertEquals("/data/annikas/test1.jpg", data.getJpeg1());
		assertEquals("/data/annikas/test2.jpg", data.getJpeg2());
		assertEquals("/data/annikas/box1.jpg", data.getJpegBox1());
		assertEquals("/data/annikas/box2.jpg", data.getJpegBox2());
		assertEquals("/data/annikas/test1.mccd", data.getImage1());
		assertEquals("/data/annikas/test2.mccd", data.getImage2());
		assertEquals("/data/annikas/run1/reorient_info", data.getReorientInfo());
		assertEquals(1, data.getAutoindexable());
		AutoindexResult result = data.getAutoindexResult();
		assertEquals("/data/annikas/webice/autoindex/test1", result.getDir());
		assertEquals("/data/annikas/test1.mccd /data/annikas/test2.mccd", result.getImages());
		assertEquals(20.0, result.getScore());
		assertEquals("50.0 60.0 70.0 80.0 90.0 100.0", result.getUnitCell().toString());
		assertEquals(0.7, result.getMosaicity());
		assertEquals(0.99, result.getRmsd());
		assertEquals("C22", result.getBravaisLattice());
		assertEquals(1.87, result.getResolution());
		assertEquals(0.8, result.getIsigma());
		assertEquals(9, result.getBestSolution());
		assertEquals("High mosaicity", result.getWarning());
	}

	public void testRepositionDataWrapperOldStyleAliasNames() throws Exception {
		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
		
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("label", "repos0");
		props.addPropertyValue("delta", 1.0);
		props.addPropertyValue("attenuation", 50.0);
		props.addPropertyValue("exposure_time", 3.0);
		props.addPropertyValue("distance", 400.0);
		props.addPropertyValue("beam_stop", 30.0);
		props.addPropertyValue("energy", 12001.0);
		props.addPropertyValue("detector_mode", 2);
		props.addPropertyValue("flux", 10.0);
		props.addPropertyValue("i2", 20.0);
		props.addPropertyValue("camera_zoom", 80.0);
		props.addPropertyValue("scaling_factory", 5.0);
		props.addPropertyValue("detector_mode", 2);
		props.addPropertyValue("beamline", "BL9-1");
		
		props.addPropertyValue("beam_width", 0.4);
		props.addPropertyValue("beam_height", 0.6);
		props.addPropertyValue("reposition_x", 10.0);
		props.addPropertyValue("reposition_y", 20.0);
		props.addPropertyValue("reposition_z", 30.0);
		props.addPropertyValue("fileVSnapshot1", "/data/annikas/test1.jpg");
		props.addPropertyValue("fileVSnapshot2", "/data/annikas/test2.jpg");
		props.addPropertyValue("fileVSnapshotBox1", "/data/annikas/box1.jpg");
		props.addPropertyValue("fileVSnapshotBox2", "/data/annikas/box2.jpg");
		props.addPropertyValue("fileDiffImage1", "/data/annikas/test1.mccd");
		props.addPropertyValue("fileDiffImage2", "/data/annikas/test2.mccd");
		props.addPropertyValue("reorientInfo", "/data/annikas/run1/reorient_info");
		props.addPropertyValue("autoindexable", 1);
		
		// Old style
		props.addPropertyValue("AutoindexDir", "/data/annikas/webice/autoindex/test1");
		props.addPropertyValue("AutoindexImages", "/data/annikas/test1.mccd /data/annikas/test2.mccd");
		props.addPropertyValue("Score", 20.0);
		props.addPropertyValue("UnitCell", "50.0 60.0 70.0 80.0 90.0 100.0");
		props.addPropertyValue("Mosaicity", 0.7);
		props.addPropertyValue("Rmsr", 0.99);
		props.addPropertyValue("BravaisLattice", "C22");
		props.addPropertyValue("Resolution", 1.87);
		props.addPropertyValue("ISigma", 0.8);
		props.addPropertyValue("Solution", 9);
		props.addPropertyValue("SystemWarning", "High mosaicity");

		RepositionData data = new RepositionData();
		BeanWrapper wrapper = silFactory.createRepositionDataWrapper(data);
		wrapper.setPropertyValues(props);
		
		assertEquals("BL9-1", data.getBeamline());
		assertEquals("repos0", data.getLabel());
		assertEquals(1.0, data.getDelta());
		assertEquals(50.0, data.getAttenuation());
		assertEquals(3.0, data.getExposureTime());
		assertEquals(400.0, data.getDistance());
		assertEquals(30.0, data.getBeamStop());
		assertEquals(12001.0, data.getEnergy());
		assertEquals(2, data.getDetectorMode());
		assertEquals(10.0, data.getFlux());
		assertEquals(20.0, data.getI2());
		assertEquals(80.0, data.getCameraZoom());
		assertEquals(5.0, data.getScalingFactor());
		assertEquals(2, data.getDetectorMode());
		assertEquals(0.4, data.getBeamSizeX());
		assertEquals(0.6, data.getBeamSizeY());
		assertEquals(10.0, data.getOffsetX());
		assertEquals(20.0, data.getOffsetY());
		assertEquals(30.0, data.getOffsetZ());
		assertEquals("/data/annikas/test1.jpg", data.getJpeg1());
		assertEquals("/data/annikas/test2.jpg", data.getJpeg2());
		assertEquals("/data/annikas/box1.jpg", data.getJpegBox1());
		assertEquals("/data/annikas/box2.jpg", data.getJpegBox2());
		assertEquals("/data/annikas/test1.mccd", data.getImage1());
		assertEquals("/data/annikas/test2.mccd", data.getImage2());
		assertEquals("/data/annikas/run1/reorient_info", data.getReorientInfo());
		assertEquals(1, data.getAutoindexable());
		AutoindexResult result = data.getAutoindexResult();
		assertEquals("/data/annikas/webice/autoindex/test1", result.getDir());
		assertEquals("/data/annikas/test1.mccd /data/annikas/test2.mccd", result.getImages());
		assertEquals(20.0, result.getScore());
		assertEquals("50.0 60.0 70.0 80.0 90.0 100.0", result.getUnitCell().toString());
		assertEquals(0.7, result.getMosaicity());
		assertEquals(0.99, result.getRmsd());
		assertEquals("C22", result.getBravaisLattice());
		assertEquals(1.87, result.getResolution());
		assertEquals(0.8, result.getIsigma());
		assertEquals(9, result.getBestSolution());
		assertEquals("High mosaicity", result.getWarning());
	}

}
