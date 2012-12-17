package sil.upload;

import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.Sil;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;
import sil.AllTests;
import sil.TestData;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;

public class RawDataConverterTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
		
	public void testRawDataConverter()
	{
		try {
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			
			logger.debug("START testRawDataConverter");

			RawData rawData = UploadTestUtil.createRawData1();
				
			RawDataConverter converter = (RawDataConverter)ctx.getBean("rawDataConverter");
			
			List<String> warnings = new ArrayList<String>();
			List<Crystal> crystals = converter.convertToCrystalList(rawData);
			
			Crystal crystal = crystals.get(0);
			assertEquals("A1", crystal.getPort());
			assertEquals("myo1", crystal.getCrystalId());
			assertEquals("myo1", crystal.getCrystalId());
			assertEquals(0.88, crystal.getResult().getAutoindexResult().getIsigma());	
			Image image1 = CrystalUtil.getLastImageInGroup(crystal, "1");
			assertNotNull(image1);
			assertEquals("/data/penjitk/myo1" + File.separator + "A1_001.img", image1.getPath());
			assertEquals("/data/penjitk/myo1", image1.getDir());
			assertEquals("A1_001.img", image1.getName());

			Sil sil2 = UploadTestUtil.createSil1();
			
			// Compare silFromRawData.xml and simpleSil.xml. The files should be identicle.
			assertEquals(crystals.size(), sil2.getCrystals().size());
			Crystal anotherCrystal = crystals.get(0);
			assertEquals("A1", anotherCrystal.getPort());
			assertEquals("myo1", anotherCrystal.getCrystalId());
			assertEquals("myo1", anotherCrystal.getCrystalId());
			assertEquals(0.88, anotherCrystal.getResult().getAutoindexResult().getIsigma());	
			Image anotherImage1 = CrystalUtil.getLastImageInGroup(anotherCrystal, "1");
			assertNotNull(anotherImage1);
			assertEquals("A1_001.img", anotherImage1.getName());
			
			assertEquals(crystal, anotherCrystal);
			
			logger.debug("FINISH testRawDataConverter");
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}

}