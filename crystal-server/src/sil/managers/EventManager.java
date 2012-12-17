package sil.managers;

import sil.beans.*;
import sil.beans.util.CrystalCollection;

import java.util.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

public class EventManager
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	private int maxEventLogSize = 100;
	private long maxIdleTime = 30*60*1000;	// 30 minutes
	private Sil sil = null;
	private Vector<CrystalEvent> events = new Vector<CrystalEvent>();

	// Accumulative idle time
	private long idleTime = 0;

	public EventManager()
		throws Exception
	{		
	}
	
	// Add event which cause any crystal to be updated in getChangesSince.
	synchronized public int addSilentEvent() throws Exception
	{
		return addCrystalEvent(-1);
	}
	
	synchronized public int addCrystalEvent(long crystalUniqueId)
		throws Exception
	{
		if (events.size() >= maxEventLogSize) {
			events.remove(0);
		}
		
		// Increment the event index
		int eventId = nextEvent();
		CrystalEvent event = new CrystalEvent();
		event.setId(eventId);
		event.setCrystalUniqueId(crystalUniqueId);
		events.add(event);
		return event.getId();
	}
	
	synchronized public int addSilEvent()
		throws Exception
	{
		if (events.size() >= maxEventLogSize) {
			events.remove(0);
		}
		
		// Increment the event index
		int eventId = nextEvent();
		events.clear(); // clear events in the list to force the whole sil will be loaded by getChangesSince this event.
		CrystalEvent event = new CrystalEvent();
		event.setId(eventId);
		events.add(event);
		return eventId;
	}
	
	synchronized public int getLatestEventId()
		throws Exception
	{
		resetIdleTime();
		return sil.getInfo().getEventId();
	}
	
	synchronized private int nextEvent()
	{
		int id = sil.getInfo().getEventId();
		if (id < 0)
			id = 0;
		sil.getInfo().setEventId(id + 1);
		
		return sil.getInfo().getEventId();
	}

	// Returns list of crystals that have been 
	// modified since the given event id.
	synchronized public CrystalCollection getChangesSince(int eventId)
		throws Exception
	{
		resetIdleTime();
		
		CrystalCollection coll = new CrystalCollection();
		
		// return empty
		if (eventId > sil.getInfo().getEventId())
			return coll;
		
		CrystalEvent oldestEvent = events.firstElement();
	
		// If the given event is too old
		// then return all crystals of this sil.
		if (eventId < oldestEvent.getId()) {
			// Return the whole sil
			coll.setContainsAll(true);
			return coll;
		}
	
		// Get all events whose unique id is greater than or equals fromId.
		Iterator<CrystalEvent> it = events.iterator();
		while (it.hasNext()) {
			CrystalEvent ev = it.next();
			if (eventId <= ev.getId() && (ev.getCrystalUniqueId() > 0))
				coll.add(new Long(ev.getCrystalUniqueId()));
		}

		return coll;
	}

	synchronized public boolean isInactive()
	{
		return (idleTime >= maxIdleTime);
	}

	synchronized public long getIdleTime()
	{
		return idleTime;
	}

	private void resetIdleTime()
	{
		idleTime = 0;
	}

	public int getMaxEventLogSize() {
		return maxEventLogSize;
	}

	public void setMaxEventLogSize(int maxEventLogSize) {
		this.maxEventLogSize = maxEventLogSize;
	}

	public long getMaxIdleTime() {
		return maxIdleTime;
	}

	public void setMaxIdleTime(long maxIdleTime) {
		this.maxIdleTime = maxIdleTime;
	}

	public Sil getSil() {
		return sil;
	}

	synchronized public void setSil(Sil sil) {
		this.sil = sil;
		events.clear();
		CrystalEvent event = new CrystalEvent();
		event.setId(sil.getInfo().getEventId());
		events.add(event);
	}

	public Vector<CrystalEvent> getEvents() {
		return events;
	}

	public void setEvents(Vector<CrystalEvent> events) {
		this.events = events;
	}

}

