package sil.upload;

import sil.exceptions.MissingColumnException;
import sil.AllTests;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;

public class ColumnValidatorTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
		
	public void testSsrlColumnValidator()
	{
		try {
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			ColumnValidator validator = (ColumnValidator)ctx.getBean("ssrlColumnValidator");
			
			logger.debug("START testSsrlColumnValidator");
			
			RawData rawData2 = new RawData();
			rawData2.addColumn("Port");
			rawData2.addColumn("CrystalID");
			rawData2.addColumn("ContainerID");
			validator.validateColumns(rawData2.getColumnNames());

			try {
				RawData rawData3 = new RawData();
				rawData3.addColumn("column1");
				rawData3.addColumn("column2");
				rawData3.addColumn("ContainerID");
				validator.validateColumns(rawData3.getColumnNames());
			} catch (MissingColumnException e) {
				if (!e.getMissingColumn().equals("Port"))
					fail(e.getMessage());
			}

			try {
				RawData rawData3 = new RawData();
				rawData3.addColumn("Port");
				rawData3.addColumn("column2");
				rawData3.addColumn("ContainerID");
				validator.validateColumns(rawData3.getColumnNames());
			} catch (MissingColumnException e) {
				if (!e.getMissingColumn().equals("CrystalID"))
					fail(e.getMessage());
			}
						
			try {
				RawData rawData3 = new RawData();
				rawData3.addColumn("Port");
				rawData3.addColumn("CrystalID");
				rawData3.addColumn("column3");
				validator.validateColumns(rawData3.getColumnNames());
			} catch (MissingColumnException e) {
				if (!e.getMissingColumn().equals("ContainerID"))
					fail(e.getMessage());
			}

			logger.debug("FINISH testSsrlColumnValidator");
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}

}