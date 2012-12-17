package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;

import sil.beans.util.CrystalValidator;
import sil.exceptions.DuplicateCrystalIdException;
import sil.exceptions.DuplicatePortException;
import sil.exceptions.DuplicateUniqueIdException;
import sil.exceptions.InvalidCrystalIdException;
import sil.exceptions.InvalidPortException;
import sil.exceptions.InvalidUniqueIdException;
import sil.AllTests;
import sil.TestData;

import junit.framework.TestCase;

public class CrystalValidatorTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
			
	public void templateTest()
	{
		logger.info("XXXX: START");
		try {
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("XXXX: DONE");
	}	

	private CrystalValidator getSsrlCrystalValidator() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();		
		return (CrystalValidator)ctx.getBean("ssrlCrystalValidator");
		
	}

	private CrystalValidator getPuckCrystalValidator() throws Exception
	{
		ApplicationContext ctx = AllTests.getApplicationContext();		
		return (CrystalValidator)ctx.getBean("puckCrystalValidator");
		
	}

	public void testSsrlCrystalValidatorOK()
	{
		logger.info("testSsrlCrystalValidatorOK: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B1");
			crystal.setCrystalId("B1");
			
			crystalValidator.validateCrystal(sil, crystal);
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testSsrlCrystalValidatorOK: DONE");
	}	
	
	public void testSsrlPortTooSmall()
	{
		logger.info("testSsrlPortTooSmall: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B0");
			crystal.setCrystalId("B0");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (InvalidPortException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testSsrlPortTooSmall: DONE");
	}	
	
	public void testSsrlPortTooBig()
	{
		logger.info("testSsrlPortTooBig: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B9");
			crystal.setCrystalId("B9");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (InvalidPortException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testSsrlPortTooBig: DONE");
	}
	
	public void testSsrlInvalidPortPrefix()
	{
		logger.info("testSsrlInvalidPortPrefix: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("M1");
			crystal.setCrystalId("M1");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (InvalidPortException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testSsrlInvalidPortPrefix: DONE");
	}	
	
	public void testSsrlCrystalIdOk()
	{
		logger.info("testSsrlCrystalIdOk: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B1");
				
			crystal.setCrystalId("B1_new");
			crystalValidator.validateCrystal(sil, crystal);
			crystal.setCrystalId("B1-new");
			crystalValidator.validateCrystal(sil, crystal);
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testSsrlCrystalIdOk: DONE");
	}	

	public void testSsrlInvalidCrystalId()
	{
		logger.info("testSsrlInvalidCrystalId: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B1");
			crystal.setCrystalId("B1 new");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				crystal.setCrystalId("B1:new");
				crystalValidator.validateCrystal(sil, crystal);
				crystal.setCrystalId("B1$new");
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (InvalidCrystalIdException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testSsrlInvalidCrystalId: DONE");
	}	
	
	public void testPuckPortTooSmall()
	{
		logger.info("testPuckPortTooSmall: START");
		try {
			CrystalValidator crystalValidator = getPuckCrystalValidator();		
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B18");
			crystal.setCrystalId("B18");
			
			try {
			
			crystalValidator.validateCrystal(sil, crystal);
			
			} catch (InvalidPortException e) {
				logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testPuckPortTooSmall: DONE");
	}	

	public void testPuckPortTooBig()
	{
		logger.info("testPuckPortTooBig: START");
		try {
			CrystalValidator crystalValidator = getPuckCrystalValidator();		
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B0");
			crystal.setCrystalId("B0");
			
			try {
			
			crystalValidator.validateCrystal(sil, crystal);
			
			} catch (InvalidPortException e) {
				logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testPuckPortTooBig: DONE");
	}
	
	public void testPuckInvalidPortPrefix()
	{
		logger.info("testPuckInvalidPortPrefix: START");
		try {
			CrystalValidator crystalValidator = getPuckCrystalValidator();		
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("L1");
			crystal.setCrystalId("L1");
			
			try {
			
			crystalValidator.validateCrystal(sil, crystal);
			
			} catch (InvalidPortException e) {
				logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testPuckInvalidPortPrefix: DONE");
	}
	
	public void testPuckOk()
	{
		logger.info("testPuckOk: START");
		try {
			CrystalValidator crystalValidator = getPuckCrystalValidator();		
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("D16");
			crystal.setCrystalId("D16");
			
			try {
			
			crystalValidator.validateCrystal(sil, crystal);
			
			} catch (InvalidPortException e) {
				logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testPuckOk: DONE");
	}
	
	public void testInvalidUniqueId()
	{
		logger.info("testInvalidUniqueId: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(0);
			crystal.setRow(0);
			crystal.setPort("A1");
			crystal.setCrystalId("MyCrystal");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (InvalidUniqueIdException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testInvalidUniqueId: DONE");
	}	

	public void testDuplicateUniqueId()
	{
		logger.info("testDuplicateUniqueId: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(100000000);
			crystal.setRow(0);
			crystal.setPort("A1");
			crystal.setCrystalId("MyCrystal");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (DuplicateUniqueIdException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testDuplicateUniqueId: DONE");
	}	
	
	public void testDuplicatePort()
	{
		logger.info("testDuplicatePort: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("A1");
			crystal.setCrystalId("MyCrystal");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (DuplicatePortException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testDuplicatePort: DONE");
	}	
	
	public void testDuplicateCrystalId()
	{
		logger.info("testDuplicateCrystalId: START");
		try {
			CrystalValidator crystalValidator = getSsrlCrystalValidator();
			Sil sil = TestData.createSimpleSil();
			Crystal crystal = new Crystal();
			crystal.setUniqueId(1000);
			crystal.setRow(0);
			crystal.setPort("B1");
			crystal.setCrystalId("A1");
			
			try {
				
				crystalValidator.validateCrystal(sil, crystal);
				
			} catch (DuplicateCrystalIdException e) {
					logger.info(e.getMessage());
			}
			
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}		
		logger.info("testDuplicateCrystalId: DONE");
	}	

}