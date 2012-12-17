package sil.managers;

import java.util.Vector;

import sil.beans.Sil;
import sil.beans.util.CrystalCollection;
import sil.factory.SilFactory;
import sil.managers.SilStorageManager;
import sil.SilTestCase;


public class EventManagerTests extends SilTestCase {
	
	public void testAddCrystalEvent() throws Exception
	{
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");

		Sil sil = storageManager.loadSil(1);
		assertNotNull(sil);
		EventManager eventManager = silFactory.createEventManager(sil);
		assertNotNull(eventManager);
		assertEquals(-1, sil.getInfo().getEventId());
		
		// First event is the current eventId of the sil
		assertEquals(1, eventManager.getEvents().size());		
		eventManager.addCrystalEvent(2000001);	
		assertEquals(2, eventManager.getEvents().size());		
		eventManager.addCrystalEvent(2000010);
		assertEquals(3, eventManager.getEvents().size());
		eventManager.addCrystalEvent(2000090);
		assertEquals(4, eventManager.getEvents().size());
		
		assertEquals(3, sil.getInfo().getEventId());
		Vector<CrystalEvent> events = eventManager.getEvents();
		assertEquals(-1, events.get(0).getId());
		assertEquals(-1, events.get(0).getCrystalUniqueId());
		assertEquals(1, events.get(1).getId());
		assertEquals(2000001, events.get(1).getCrystalUniqueId());
		assertEquals(2, events.get(2).getId());
		assertEquals(2000010, events.get(2).getCrystalUniqueId());
		assertEquals(3, events.get(3).getId());
		assertEquals(2000090, events.get(3).getCrystalUniqueId());

		// eventId -1 is older than oldest event in the eventManager (which is eventId 1).
		// In this case all crystals are included.
		// Do not rely on col.size().
		CrystalCollection col = eventManager.getChangesSince(-2);
		assertTrue(col.containsAll());
		assertTrue(col.contains(2000001));
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));
		assertTrue(col.contains(2000091));
		assertTrue(col.contains(2000092));
		
		col = eventManager.getChangesSince(-1);
		assertFalse(col.containsAll());
		assertTrue(col.contains(2000001));
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));
		assertFalse(col.contains(2000091));
		assertFalse(col.contains(2000092));
			
		col = eventManager.getChangesSince(0);
		assertFalse(col.containsAll());
		assertTrue(col.contains(2000001));
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));
		assertFalse(col.contains(2000091));
		assertFalse(col.contains(2000092));
		
		col = eventManager.getChangesSince(1);
		assertEquals(3, col.size());
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));

		col = eventManager.getChangesSince(2);
		assertEquals(2, col.size());
		assertTrue(col.contains(2000090));

		col = eventManager.getChangesSince(3);
		assertEquals(1, col.size());
	
		col = eventManager.getChangesSince(10);
		assertEquals(0, col.size());
	}
	
	public void testAddCrystalEvent1() throws Exception
	{
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
		
		// Preset event id to 345.
		int silId = 1;
		int eventId = 345;
		storageManager.getSilDao().setEventId(silId, eventId);

		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		EventManager eventManager = silFactory.createEventManager(sil);
		assertNotNull(eventManager);
		assertEquals(345, sil.getInfo().getEventId());
		
		eventManager.addCrystalEvent(2000001);	
		assertEquals(2, eventManager.getEvents().size());		
		eventManager.addCrystalEvent(2000010);
		assertEquals(3, eventManager.getEvents().size());
		eventManager.addCrystalEvent(2000090);
		assertEquals(4, eventManager.getEvents().size());
		
		assertEquals(348, sil.getInfo().getEventId());
		
		Vector<CrystalEvent> events = eventManager.getEvents();
		assertEquals(345, events.get(0).getId());
		assertEquals(-1, events.get(0).getCrystalUniqueId());
		assertEquals(346, events.get(1).getId());
		assertEquals(2000001, events.get(1).getCrystalUniqueId());
		assertEquals(347, events.get(2).getId());
		assertEquals(2000010, events.get(2).getCrystalUniqueId());
		assertEquals(348, events.get(3).getId());
		assertEquals(2000090, events.get(3).getCrystalUniqueId());

		// eventId -1 is older than oldest event in the eventManager (which is eventId 1).
		// In this case all crystals are included.
		// Do not rely on col.size().
		CrystalCollection col = eventManager.getChangesSince(-1);
		assertTrue(col.containsAll());
		assertTrue(col.contains(2000001));
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));
		assertTrue(col.contains(2000091));
		assertTrue(col.contains(2000092));
			
		col = eventManager.getChangesSince(345);
		assertFalse(col.containsAll());
		assertEquals(3, col.size());
		assertTrue(col.contains(2000001));
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));
		assertFalse(col.contains(2000091));
		assertFalse(col.contains(2000092));
		
		col = eventManager.getChangesSince(346);
		assertEquals(3, col.size());
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));

		col = eventManager.getChangesSince(347);
		assertEquals(2, col.size());
		assertTrue(col.contains(2000090));

		col = eventManager.getChangesSince(348);
		assertEquals(1, col.size());
	
	}
	
	// Add an event that will cause the whole sil to be sent.
	public void testAddSilEvent() throws Exception
	{
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		SilFactory silFactory = (SilFactory)ctx.getBean("silFactory");
		
		// Preset event id to 345.
		int silId = 1;
		int eventId = 345;
		storageManager.getSilDao().setEventId(silId, eventId);

		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		EventManager eventManager = silFactory.createEventManager(sil);
		assertNotNull(eventManager);
		assertEquals(345, sil.getInfo().getEventId());
		
		eventManager.addCrystalEvent(2000001);	
		eventManager.addCrystalEvent(2000010);
		eventManager.addCrystalEvent(2000090);
		
		assertEquals(348, sil.getInfo().getEventId());
		
		Vector<CrystalEvent> events = eventManager.getEvents();
		assertEquals(345, events.get(0).getId());
		assertEquals(-1, events.get(0).getCrystalUniqueId());
		assertEquals(346, events.get(1).getId());
		assertEquals(2000001, events.get(1).getCrystalUniqueId());
		assertEquals(347, events.get(2).getId());
		assertEquals(2000010, events.get(2).getCrystalUniqueId());
		assertEquals(348, events.get(3).getId());
		assertEquals(2000090, events.get(3).getCrystalUniqueId());
			
		CrystalCollection col = eventManager.getChangesSince(345);
		assertFalse(col.containsAll());
		assertEquals(3, col.size());
		assertTrue(col.contains(2000001));
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));
		assertFalse(col.contains(2000091));
		assertFalse(col.contains(2000092));
		
		col = eventManager.getChangesSince(346);
		assertEquals(3, col.size());
		assertTrue(col.contains(2000010));
		assertTrue(col.contains(2000090));

		col = eventManager.getChangesSince(347);
		assertEquals(2, col.size());
		assertTrue(col.contains(2000090));
		
		col = eventManager.getChangesSince(348);
		assertEquals(1, col.size());
		assertTrue(col.contains(2000090));

		// eventId = 348
		eventManager.addSilEvent();
		
		col = eventManager.getChangesSince(348);
		assertTrue(col.containsAll());		
	
	}	
}
