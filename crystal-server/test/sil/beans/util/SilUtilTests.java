package sil.beans.util;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.exceptions.CrystalDoesNotExistException;
import sil.TestData;

import junit.framework.TestCase;

public class SilUtilTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
			
	public void testGetCrystalFromRow() throws Exception
	{		
		Sil sil = TestData.createSimpleSil();
			
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		assertEquals("A1", crystal.getPort());
		assertEquals("myo1", crystal.getCrystalId());
					
	}	
	
	public void testGetCrystalFromCrystalId() throws Exception
	{
		Sil sil = TestData.createSimpleSil();
			
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, "myo2");
		assertEquals(1, crystal.getRow());
		assertEquals("A2", crystal.getPort());
	}	
	
	public void testGetCrystalFromPort() throws Exception
	{
		Sil sil = TestData.createSimpleSil();
			
		Crystal crystal = SilUtil.getCrystalFromPort(sil, "A2");
		System.out.println("testGetCrystalFromPort: row = " + crystal.getRow() + " crystalId = " + crystal.getCrystalId());
		assertEquals(1, crystal.getRow());
		assertEquals(1, crystal.getRow());
		assertEquals("myo2", crystal.getCrystalId());
	
	}		
	
	public void testGetCrystalFromUniqueId() throws Exception
	{
		Sil sil = TestData.createSimpleSil();
			
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, 100000001);
		assertEquals(1, crystal.getRow());
		assertEquals("A2", crystal.getPort());
	}
	
	public void testAddCrystal() throws Exception
	{
		Sil sil = new Sil();
		Crystal crystal = TestData.createSimpleCrystal();
			
		SilUtil.addCrystal(sil, crystal);
		
		Crystal newCrystal = SilUtil.getCrystalFromUniqueId(sil, 100000000);
		assertEquals(0, newCrystal.getRow());
		assertEquals("A1", newCrystal.getPort());
	
	}
	
	public void testSetCrystal() throws Exception
	{
		Sil sil = TestData.createSimpleSil();
		
		Crystal oldCrystal = SilUtil.getCrystalFromUniqueId(sil, 100000000);
		assertEquals(0, oldCrystal.getRow());
		assertEquals("A1", oldCrystal.getPort());
		assertEquals("myo1", oldCrystal.getCrystalId());
		assertEquals("large crystal", oldCrystal.getData().getComment());

		Crystal crystal = new Crystal();
		crystal.setRow(0);
		crystal.setUniqueId(100000000);
		crystal.setRow(0);
		crystal.setExcelRow(1);
		crystal.setCrystalId("hemo1");
		crystal.setPort("A6");
		crystal.getData().setComment("small crystal");
		SilUtil.setCrystal(sil, crystal);
		
		Crystal newCrystal = SilUtil.getCrystalFromUniqueId(sil, 100000000);
		assertEquals(0, newCrystal.getRow());
		assertEquals("A6", newCrystal.getPort());
		assertEquals("hemo1", newCrystal.getCrystalId());
		assertEquals("small crystal", newCrystal.getData().getComment());

	}
	
	public void testSetNonExistentCrystal() throws Exception
	{
		long id = 5555;
						
		Sil sil = TestData.createSimpleSil();
		Crystal oldCrystall = SilUtil.getCrystalFromUniqueId(sil, id);
		assertNull(oldCrystall);
		
		Crystal crystal = new Crystal();
		crystal.setRow(0);
		crystal.setUniqueId(5555);
		crystal.setRow(0);
		crystal.setExcelRow(1);
		crystal.setCrystalId("hemo1");
		crystal.setPort("A6");
		crystal.getData().setComment("small crystal");
		
		try {
			SilUtil.setCrystal(sil, crystal);
			fail("setCrystal should have failed.");
		} catch (CrystalDoesNotExistException e) {
			// expected this exception
		}
		
		Crystal newCrystal = SilUtil.getCrystalFromUniqueId(sil, id);
		assertNull(newCrystal);
			
	}
	
	public void testDeleteCrystal() throws Exception
	{
		Sil sil = new Sil();
			
		SilUtil.deleteCrystal(sil, 100000000);
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, 100000000);
		assertNull(crystal);
	}
	
	public void testDeleteNonExistentCrystal() throws Exception
	{
		Sil sil = new Sil();	
		SilUtil.deleteCrystal(sil, 5555);

	}
	
	public void testReplaceCrystalInRow() throws Exception {
		
		long uniqueId = 100000000;
		String port = "A1";
		int row = 0;
		String containerId = "SSRL001";
		String containerType = "cassette";
		String protein = "Myoglobin 1";
		String crystalId = "myo1";
		
		Sil sil = TestData.createSimpleSil();
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, port);
		
		assertNotNull(oldCrystal);
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertEquals(row, oldCrystal.getRow());
		assertEquals(2, oldCrystal.getImages().size());
		assertEquals(protein, oldCrystal.getData().getProtein());
		
		// New crystal
		int anotherUniqueId = 300000000;
		String anotherCrystalId = "myo30";
		String anotherProtein = "Myoglobin 30";
		Crystal crystal = new Crystal();
		crystal.setRow(row);
		crystal.setPort(port);
		crystal.setContainerId(containerId);
		crystal.setContainerType(containerType);
		crystal.setCrystalId(anotherCrystalId);
		crystal.setUniqueId(anotherUniqueId);
		crystal.getData().setProtein(anotherProtein);
		
		// Put new crystal in this row.
		SilUtil.replaceCrystalInPort(sil, crystal);
		
		// Make sure that old crystal has been deleted
		oldCrystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNull(oldCrystal);
		
		// Make sure that crystal in this row is set correctly.
		Crystal newCrystal = SilUtil.getCrystalFromPort(sil, port);
		assertNotNull(newCrystal);
		assertEquals(row, newCrystal.getRow()); // unchanged
		assertEquals(anotherUniqueId, newCrystal.getUniqueId()); // unchanged
		assertEquals(port, newCrystal.getPort()); // unchanged
		assertEquals(containerId, newCrystal.getContainerId()); // unchanged
		assertEquals(containerType, newCrystal.getContainerType()); // unchanged
		assertEquals(anotherCrystalId, newCrystal.getCrystalId()); // crystalId belongs to the other crystalId
		assertEquals(anotherProtein, newCrystal.getData().getProtein()); // crystalId belongs to the other protein
	}
	
	// OK
	public void testReplaceCrystalInNonExistentRow() throws Exception {
		
		long uniqueId = 100000000;
		String port = "A1";
		int row = 0;
		String containerId = "SSRL001";
		String containerType = "cassette";
		String protein = "Myoglobin 1";
		String crystalId = "myo1";
		
		Sil sil = TestData.createSimpleSil();
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, port);
		
		assertNotNull(oldCrystal);
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertEquals(row, oldCrystal.getRow());
		assertEquals(2, oldCrystal.getImages().size());
		assertEquals(protein, oldCrystal.getData().getProtein());
		
		// New crystal
		int anotherUniqueId = 300000000;
		int anotherRow = 30;
		String anotherCrystalId = "myo30";
		String anotherProtein = "Myoglobin 30";
		Crystal crystal = new Crystal();
		crystal.setRow(anotherRow);
		crystal.setPort(port);
		crystal.setContainerId(containerId);
		crystal.setContainerType(containerType);
		crystal.setCrystalId(anotherCrystalId);
		crystal.setUniqueId(anotherUniqueId);
		crystal.getData().setProtein(anotherProtein);
			
		// Put new crystal in non-existent row.
		SilUtil.replaceCrystalInPort(sil, crystal);
		
		// Make sure this port now has the new crystal
		Crystal newCrystal = SilUtil.getCrystalFromUniqueId(sil, anotherUniqueId);
		assertNotNull(newCrystal);
		assertEquals(row, newCrystal.getRow());
		assertEquals(anotherUniqueId, newCrystal.getUniqueId()); 
		assertEquals(port, newCrystal.getPort());
		assertEquals(containerId, newCrystal.getContainerId());
		assertEquals(containerType, newCrystal.getContainerType());
		assertEquals(anotherCrystalId, newCrystal.getCrystalId()); 
		assertEquals(anotherProtein, newCrystal.getData().getProtein()); 
	}
	
	// SilUtil does not garantee crystalId uniqueness. This is done in SilManager.
	public void testReplaceCrystalInRowDuplicateCrystalId() throws Exception {
		
		long uniqueId = 100000000;
		String port = "A1";
		int row = 0;
		String containerId = "SSRL001";
		String containerType = "cassette";
		String protein = "Myoglobin 1";
		String crystalId = "myo1";
		
		Sil sil = TestData.createSimpleSil();
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, port);
		
		assertNotNull(oldCrystal);
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertEquals(row, oldCrystal.getRow());
		assertEquals(2, oldCrystal.getImages().size());
		assertEquals(protein, oldCrystal.getData().getProtein());
		
		// New crystal
		int anotherUniqueId = 300000000;
		String anotherCrystalId = "myo2"; // already exist in sil row 1
		String anotherProtein = "Myoglobin 30";
		Crystal crystal = new Crystal();
		crystal.setRow(row);
		crystal.setPort(port);
		crystal.setContainerId(containerId);
		crystal.setContainerType(containerType);
		crystal.setCrystalId(anotherCrystalId);
		crystal.setUniqueId(anotherUniqueId);
		crystal.getData().setProtein(anotherProtein);
		
		// Put new crystal in this row.
		SilUtil.replaceCrystalInPort(sil, crystal);
		
		// Make sure that old crystal has been deleted
		oldCrystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		assertNull(oldCrystal);
		
		// Make sure that crystal in this row is set correctly.
		Crystal newCrystal = SilUtil.getCrystalFromPort(sil, port);
		assertNotNull(newCrystal);
		assertEquals(row, newCrystal.getRow()); 
		assertEquals(anotherUniqueId, newCrystal.getUniqueId()); 
		assertEquals(port, newCrystal.getPort()); 
		assertEquals(containerId, newCrystal.getContainerId()); 
		assertEquals(containerType, newCrystal.getContainerType()); 
		assertEquals(anotherCrystalId, newCrystal.getCrystalId()); // duplicate with crystal in row 1.
		assertEquals(anotherProtein, newCrystal.getData().getProtein()); 
	}
	
	// Error if uniqueId is not unique
	public void testReplaceCrystalInRowDuplicateUniqueId() throws Exception {
		
		long uniqueId = 100000000;
		String port = "A1";
		int row = 0;
		String containerId = "SSRL001";
		String containerType = "cassette";
		String protein = "Myoglobin 1";
		String crystalId = "myo1";
		
		Sil sil = TestData.createSimpleSil();
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, port);
		
		assertNotNull(oldCrystal);
		assertEquals(uniqueId, oldCrystal.getUniqueId());
		assertEquals(crystalId, oldCrystal.getCrystalId());
		assertEquals(row, oldCrystal.getRow());
		assertEquals(2, oldCrystal.getImages().size());
		assertEquals(protein, oldCrystal.getData().getProtein());
		
		// New crystal
		int anotherUniqueId = 100000001; // duplicate with the one in row 1.
		String anotherCrystalId = "myo30";
		String anotherProtein = "Myoglobin 30";
		Crystal crystal = new Crystal();
		crystal.setRow(row);
		crystal.setPort(port);
		crystal.setContainerId(containerId);
		crystal.setContainerType(containerType);
		crystal.setCrystalId(anotherCrystalId);
		crystal.setUniqueId(anotherUniqueId);
		crystal.getData().setProtein(anotherProtein);
		
		try {
		
			// Put new crystal in this row.
			SilUtil.replaceCrystalInPort(sil, crystal);
			fail("replaceCrystalInRow should have failed.");
		} catch (Exception e) {
			assertEquals("Unique id " + anotherUniqueId + " already exists", e.getMessage());
		}
		
		// Make sure that crystal in this row remains unchanged
		Crystal newCrystal = SilUtil.getCrystalFromPort(sil, port);
		assertNotNull(newCrystal);
		assertEquals(row, newCrystal.getRow());
		assertEquals(uniqueId, newCrystal.getUniqueId()); 
		assertEquals(port, newCrystal.getPort());
		assertEquals(containerId, newCrystal.getContainerId());
		assertEquals(containerType, newCrystal.getContainerType());
		assertEquals(crystalId, newCrystal.getCrystalId()); 
		assertEquals(protein, newCrystal.getData().getProtein()); 
	}
	
	public void testGetCrystalEventIds() throws Exception {
		
		Sil sil = new Sil(); // no crystal
		int[] events = SilUtil.getCrystalEventIds(sil);
		assertNull(events);
		
		sil = TestData.createSimpleSil();
		Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
		crystal.setEventId(200);
		crystal = SilUtil.getCrystalFromRow(sil, 1);
		crystal.setEventId(300);
		events = SilUtil.getCrystalEventIds(sil);
		assertEquals(2, events.length);
		assertEquals(200, events[0]);
		assertEquals(300, events[1]);
	}
	
}