package sil.beans;

import java.io.File;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;

import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.Sil;
import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.ImageWrapper;
import sil.beans.util.SilUtil;
import sil.factory.SilFactory;
import sil.AllTests;
import sil.TestData;

import junit.framework.TestCase;

public class SsrlColumnMappingTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	// Test CrystalWrapper. Use SimpleBeanPropertyMapper to map an alias name to a bean property.
	public void testMapCrystalColumns() 
	{
		logger.info("START testMapCrystalColumns");
		try {
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilFactory factory = (SilFactory)ctx.getBean("silFactory");
			Sil sil = TestData.createSimpleSil();
			
			Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "myo1");
			CrystalWrapper wrapper1 = factory.createCrystalWrapper(crystal);
			
			crystal = SilUtil.getCrystalFromCrystalId(sil, "myo2");
			CrystalWrapper wrapper2 = factory.createCrystalWrapper(crystal);
			
			assertEquals("large crystal", wrapper1.getPropertyValue("Comment"));
			assertEquals(0.01, wrapper1.getPropertyValue("Score"));
			
			assertEquals("medium crystal", wrapper2.getPropertyValue("Comment"));
			assertEquals(0.99, wrapper2.getPropertyValue("Score"));
			
			wrapper1.setPropertyValue("Comment", "Pig Myoglobin");
			wrapper1.setPropertyValue("Score", "0.11");
			
			wrapper2.setPropertyValue("Comment", "Horse Myoglobin");
			wrapper2.setPropertyValue("Score", "0.22");

			assertEquals("Pig Myoglobin", wrapper1.getPropertyValue("Comment"));
			assertEquals(0.11, wrapper1.getPropertyValue("Score"));
			
			assertEquals("Horse Myoglobin", wrapper2.getPropertyValue("Comment"));
			assertEquals(0.22, wrapper2.getPropertyValue("Score"));
			
		
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		logger.info("FINISH testMapCrystalColumns");
	}

	// Test CrystalWrapper. Use SimpleBeanPropertyMapper to map an alias name to a bean property.
	public void testMapImageColumns() 
	{
		logger.info("START testMapImageColumns");
		try {
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			SilFactory factory = (SilFactory)ctx.getBean("silFactory");
			Sil sil = TestData.createSimpleSil();
			
			Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "myo1");
			CrystalWrapper wrapper1 = factory.createCrystalWrapper(crystal);
						
			assertEquals("/data/annikas/myo1" + File.separator + "A1_001.img", wrapper1.getPropertyValue("Image1"));
			assertEquals("A1_001.jpg", wrapper1.getPropertyValue("Jpeg1"));
			Double score1 = (Double)wrapper1.getPropertyValue("Score1");
			assertEquals(0.7882, score1);
			
			wrapper1.setPropertyValue("Jpeg1", "A1_005.jpg");
			wrapper1.setPropertyValue("Score1", "0.777");

			assertEquals("/data/annikas/myo1" + File.separator + "A1_001.img", wrapper1.getPropertyValue("Image1"));
			assertEquals("A1_005.jpg", wrapper1.getPropertyValue("Jpeg1"));
			score1 = (Double)wrapper1.getPropertyValue("Score1");
			assertEquals(0.777, score1);
								
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		logger.info("FINISH testMapImageColumns");
	}
	

}