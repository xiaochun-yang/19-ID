package sil.upload;

import sil.upload.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import junit.framework.TestCase;

public class RawDataTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public void testCreateRawData()
	{
		try {
			logger.debug("START testRawData");
			RawData rawData = UploadTestUtil.createSimpleRawData();
			
			System.out.println("testRawDataConverter: rawData numColumn = " + rawData.getColumnCount() + " numRow = " + rawData.getRowCount());
									
//			SilUtil.debugBean(rawData);	
			assertEquals(19, rawData.getColumnCount());
			assertEquals(2, rawData.getRowCount());
			assertEquals("A1", rawData.getData(0, 0));
			assertEquals("A2", rawData.getData(1, 0));
			assertEquals("0.975", rawData.getData(0, 18));
			assertEquals("0.916", rawData.getData(1, 18));
						
			logger.debug("FINISH testRawData");
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}	
	}
	
	public void testAddColumn()
	{
		try {
			logger.debug("START testAddColumn");
			RawData rawData = UploadTestUtil.createSimpleRawData();
			
			assertEquals(19, rawData.getColumnCount());
			
			rawData.addColumn("myNewColumn");
									
			assertEquals(20, rawData.getColumnCount());
			assertNull(rawData.getData(0, 19));		
			assertNull(rawData.getData(1, 19));	

			rawData.setData(0, 19, "my new content");
			assertEquals("my new content", rawData.getData(0, 19));
			rawData.setData(1, 19, "another new content");
			assertEquals("another new content", rawData.getData(1, 19));
						
			logger.debug("FINISH testAddColumn");
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}
	
	public void testCopyColumn()
	{
		try {
			logger.debug("START testCopyColumn");
			RawData rawData = UploadTestUtil.createSimpleRawData();
			
			assertEquals(rawData.getColumnCount(), 19);
			
			RawData newRawData = new RawData();
			newRawData.copyColumn(rawData, "CrystalID", "crystalId");
									
			assertEquals(1, newRawData.getColumnCount());
			assertNotNull(newRawData.getData(0, 0));		
			assertNotNull(newRawData.getData(1, 0));
			
			assertEquals("crystalId", newRawData.getColumnName(0));
						
			assertEquals("myo1", newRawData.getData(0, 0));
			assertEquals("myo2", newRawData.getData(1, 0));

			newRawData.setData(0, 0, "hemo1");
			assertEquals("hemo1", newRawData.getData(0, 0));
			newRawData.setData(1, 0, "hemo2");
			assertEquals("hemo2", newRawData.getData(1, 0));
			
			newRawData.copyColumn(rawData, "Score2", "images[2].result.spotfinderResult.score");	
			
			assertEquals(2, newRawData.getColumnCount());
			assertNotNull(newRawData.getData(0, 1));		
			assertNotNull(newRawData.getData(1, 1));	
			
			assertEquals("images[2].result.spotfinderResult.score", newRawData.getColumnName(1));

			assertEquals("0.975", newRawData.getData(0, 1));
			assertEquals("0.916", newRawData.getData(1, 1));
			
//			UploadTestUtil.debugRawData(newRawData);
						
			logger.debug("FINISH testCopyColumn");
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}


}