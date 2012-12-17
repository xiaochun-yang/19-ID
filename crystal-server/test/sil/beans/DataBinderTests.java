package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.*;

import sil.beans.util.CrystalWrapper;
import sil.TestData;

import java.util.*;

import junit.framework.TestCase;

public class DataBinderTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public DataBinderTests()
	{
	}
	
	public void testIndexedProperty() 
	{
		logger.info("START testIndexedProperty");
		try {	
			// Crystal properties
			MutablePropertyValues prop = new MutablePropertyValues();
			prop.addPropertyValue("port", "A1");
			prop.addPropertyValue("crystalId", "A1");
			prop.addPropertyValue("containerId", "SSRL001");
			prop.addPropertyValue("data.protein", "Myoglobin 1");
			prop.addPropertyValue("data.directory", "/data/penjitk/myo");
			prop.addPropertyValue("result.autoindexResult.unitCell", "90.0 91.0 92.0 100.0 101.0 102.0");
			// First image
			prop.addPropertyValue("images[0].name", "A1_001.img");
			prop.addPropertyValue("images[0].dir", "/data/penjitk/myo1");
			prop.addPropertyValue("images[0].group", "1");
			prop.addPropertyValue("images[0].result.spotfinderResult.numIceRings", 2);
			prop.addPropertyValue("images[0].data.jpeg", "A1_001.jpg");
			prop.addPropertyValue("images[0].result.spotfinderResult.score", 0.7882);
			// Second image
			prop.addPropertyValue("images[1].name", "A1_002.img");
			prop.addPropertyValue("images[1].dir", "/data/penjitk/myo1");
			prop.addPropertyValue("images[1].group", "2");
			prop.addPropertyValue("images[1].result.spotfinderResult.numIceRings", 0);
			prop.addPropertyValue("images[1].data.jpeg", "A1_002.jpg");
			prop.addPropertyValue("images[1].result.spotfinderResult.score", 0.975);
			
			List<String> columnNames = new ArrayList<String>();
			columnNames.add("images[0]");
			columnNames.add("images[1]");			
			
			CrystalWrapper wrapper = new CrystalWrapper(new Crystal());
			wrapper.setPropertyValues(prop);

			logger.debug("unit cell = " + wrapper.getCrystal().getResult().getAutoindexResult().getUnitCell().toString());
			
			
//			Crystal simpleCrystal = createSimpleCrystal();
			
			// crystal and simpleCrystal should be the same.
			
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		logger.info("FINISH testIndexedProperty");
	}
	
	// Map key must be string for this to work.
	public void testMappedProperty() 
	{
		logger.info("START testMappedProperty");
		try {	
			Sil sil = TestData.createSimpleSil();
			BeanWrapper wrapper = new BeanWrapperImpl(sil);
			assertEquals("A1", wrapper.getPropertyValue("crystals[100000000].port"));
			assertEquals("/data/annikas/A1/myo1", wrapper.getPropertyValue("crystals[100000000].data.directory"));
			assertEquals("A2", wrapper.getPropertyValue("crystals[100000001].port"));
			assertEquals("/data/annikas/A2/myo2", wrapper.getPropertyValue("crystals[100000001].data.directory"));
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		logger.info("FINISH testMappedProperty");
	}
	
}