package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import sil.beans.*;
import sil.TestData;

import java.util.*;

import junit.framework.TestCase;

public class BeanTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
			
	public void testCrystalEqual()
	{
		logger.info("testCrystalEqual: START");
		try {
						
			Crystal crystal1 = TestData.createCrystal();
			Crystal crystal2 = TestData.createCrystal();
						
			if (!crystal1.equals(crystal2))
				throw new Exception("Crystal.equals() does not work: crystal1 and crystal2 are expected to be the same");
			
			crystal2.setContainerId("XXXXXX");
			
			if (crystal1.equals(crystal2))
				throw new Exception("Crystal.equals() does not work: crystal1 and crystal2 are expected to be the different 1");
			
			crystal2 = TestData.createCrystal();
			Map<String, Image> images = crystal2.getImages();
			Image image1 = images.get("1");
			image1.setDir("/data/blctl/screening");
			
			if (crystal1.equals(crystal2))
				throw new Exception("Crystal.equals() does not work: crystal1 and crystal2 are expected to be the different 2");			
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}		
		logger.info("testCrystalEqual: DONE");
	}	
	
}