package sil.beans;

import java.util.*;
import java.lang.Thread;
import java.io.OutputStream;

/**
 */
public class SilEventQueue extends Thread
{

	/**
	 */
	private int maxEventLogSize = 100;

	/**
	 */
	private long maxIdleTime = 30*60*1000;	// 30 minutes
//	private long maxIdleTime = 2*60*1000;	// 2 minutes

	/**
	 */
	private Sil sil = null;

	/**
	 * Event log lookup table
	 */
	private SortedMap eventLog = Collections.synchronizedSortedMap(new TreeMap());
	/**
	 * Event queue
	 */
	private List queue = Collections.synchronizedList(new LinkedList());

	/**
	 * Current event id
	 */
	private int eventId = 0;

	/**
	 * Flag for determining whether the event
	 * thread should stop or not.
	 */
	private boolean queueStopped = false;

	/**
	 * Number of msec to wait for an event
	 * before looping back.
	 */
	private long waitTimeout = 5000;

	/**
	 * Accumulative idle time
	 */
	private long idleTime = 0;

	/**
	 * Constructor
	 */
	public SilEventQueue(Sil sil)
		throws Exception
	{
		this.sil = sil;

		eventId = sil.getEventId();

		// Create first event log
		SilEvent loadSilEvent = new SilEvent(SilEvent.LOAD_SIL, sil.getId());
		loadSilEvent.setId(eventId);
		logEvent(loadSilEvent);

	}

	/**
	 *
	 */
	public void finalize()
	{
		stopQueue();
	}

	/**
	 * Add a new event to the queue.
	 * Assign a unique id to the event.
	 */
	synchronized public int addEvent(SilEvent event)
		throws Exception
	{
		return addEvent(event, false);
	}
	
	/**
	 * Add a new event to the queue.
	 * Assign a unique id to the event.
	 */
	synchronized public int addEvent(SilEvent event, boolean validateRow)
		throws Exception
	{
		if (validateRow) {
				
		if (event.getRow() < 0) {
			String cId = event.getField("CrystalID");
			if (cId == null)
				throw new Exception("Cannot add event because row number < 0 and CrystalID field is missing");
						
			if (cId.length() == 0)
				throw new Exception("Cannot add event image because row number < 0 and CrystalID field has zero length");
						
			int r = sil.getCrystalRow("CrystalID", cId);
			if (r < 0)
				throw new Exception("Cannot add event image because row number < 0 and CrystalID " + cId + " does not exist in this SIL.");
						
			event.setRow(r);
				
		}
		
		} // validateRow

		// Give the event a unique id for this queue
		if (!event.isSilent()) {
			// Increment the event index
			nextEvent();
			event.setId(getEventId());
		}

		// Add event to the queue
		queue.add(event);

		// Wake up the thread from wait()
		notify();

		return getEventId();
	}


	/**
	 */
	synchronized public void start()
	{
		queueStopped = false;

		super.start();
	}

	/**
	 * Return the latest event id for this sil.
	 */
	synchronized public int getLatestEventId()
		throws Exception
	{
		resetIdleTime();
		return sil.getEventId();
	}

	/**
	 * Return a crystal
	 */
	synchronized public String getCrystal(int row)
		throws Exception
	{
		return getCrystal(row, "tcl");
	}

	/**
	 * Return a crystal
	 */
	synchronized public String getCrystal(int row, String format)
		throws Exception
	{
		resetIdleTime();
		Integer rows[] = new Integer[1];
		rows[0] = new Integer(row);
		if (format.equals("tcl")) {
			return sil.toTclString(rows);
		} else {
			return sil.toXmlString(rows);
		}
	}
	
	/**
	 * Return a crystal
	 */
	synchronized public String getCrystal(String crystalId)
		throws Exception
	{
		if (crystalId == null)
			throw new Exception("Null CrystalID");
			
		if (crystalId.length() == 0)
			throw new Exception("Zero length CrystalID");
			
		int row = sil.getCrystalRow("CrystalID", crystalId);
	
		if (row < 0)
			throw new Exception("CrystalID " + crystalId + " not found in sil " + sil.getId());
		
		return getCrystal(row, "tcl");
	}

	/**
	 * Return a crystal
	 */
	synchronized public String getCrystal(String crystalId, String format)
		throws Exception
	{
		int row = sil.getCrystalRow("CrystalID", crystalId);
		
		return getCrystal(row, format);
	}

	/**
	 * Return a clone of the crystal
	 */
	synchronized public Crystal cloneCrystal(int row)
		throws Exception
	{
		return sil.cloneCrystal(row);
		
	}

	/**
	 * Return a list of crystals which have been
	 * modified since the given event id.
	 */
	synchronized public String getEventLog(int fromId)
		throws Exception
	{
		return getEventLog(fromId, "tcl");
	}
	
	/**
	 * Return a list of crystals which have been
	 * modified since the given event id.
	 */
	synchronized public String getEventLog(int fromId, String format)
		throws Exception
	{
		resetIdleTime();
		
		// There is nothing new
		if (eventLog.isEmpty()) {
			if (fromId < sil.getEventId()) {
				if (format.equals("xml"))
					return sil.toXmlString();
				else
					return sil.toTclString();	// Return the whole sil
			} else {
				if (format.equals("xml"))
					return sil.toXmlString(null);	// Return empty
				else
					return sil.toTclString(null);	// Return empty
			}
		}


		Integer firstEvent = (Integer)eventLog.firstKey();
		int firstEventId = firstEvent.intValue();

		// If the given event is too old
		// then return all crystals of this sil.
		if (fromId < firstEventId) {
			if (format.equals("xml"))
				return sil.toXmlString();
			else
				return sil.toTclString();
		}

		// Get all events whose unique id is greater than fromId.
		SortedMap tail = eventLog.tailMap(new Integer(fromId));

		Collection values = tail.values();  // Needn't be in synchronized block

		TreeSet crystalIds = new TreeSet();
		SilEvent event = null;
		Integer rowInt = null;
		int row = -1;
		// Loop over events
		synchronized (eventLog) {  // Synchronizing on eventLog map, not tail map or or values!
			Iterator i = values.iterator(); // Must be in synchronized block
			while (i.hasNext()) {
				event = (SilEvent)i.next();
				row = event.getRow();
				// TODO: check if command is SORT
				// then send the whole sil
				if (!event.hasError() && (row >= 0)) {
					crystalIds.add(new Integer(row));
				}
			}

			// Nothing new
			if (crystalIds.size() == 0) {
				if (format.equals("xml"))
					return sil.toXmlString(null);
				else
					return sil.toTclString(null);
			}

			// Return modified crystals
			if (format.equals("xml"))
				return sil.toXmlString(crystalIds.toArray());
			else
				return sil.toTclString(crystalIds.toArray());

		}


	}

	/**
	 * Get the next event id
	 */
	synchronized private void nextEvent()
	{
		++eventId;

		sil.setEventId(eventId);
	}

	/**
	 * Get the current event id
	 */
	synchronized public int getEventId()
	{
		return eventId;
	}
	
	synchronized boolean isEmpty()
	{
		return queue.isEmpty();
	}

	/**
	 * Process the oldest event in the queue
	 */
	private void processEvents()
	{
		try {
		if (queue.isEmpty())
			sleep(1000);
		} catch (InterruptedException e) {
			// ignore
			SilLogger.info("Failed to sleep in processEvent because " + e.getMessage());
		}

		while (!queue.isEmpty()) {

			// Get first event in the queue
			SilEvent event = (SilEvent)queue.get(0);

			if (event == null)
				return;

			// Remove this event from the queue
			queue.remove(0);

			processEvent(event);

			// Add event to the log
			if (!event.isSilent())
				logEvent(event);
		}

	}

	/**
	 */
	private void logEvent(SilEvent event)
	{
		// Add it to the lookup table
		eventLog.put(new Integer(event.getId()), event);

		// Remove old logs
		while (eventLog.size() > maxEventLogSize) {
			// remove oldest event
			eventLog.remove(eventLog.firstKey());
		}

	}


	/**
	 * Process an event. In case of error,
	 * save it in the event object.
	 */
	synchronized public void processEvent(SilEvent event)
	{
		resetIdleTime();

		try {
			if (event.getCommand() == SilEvent.SET_CRYSTAL) {
				if ((event.getCrystal() != null) && (event.getRow() > -1)) {
					sil.setCrystal(event.getCrystal());
				} else {
					sil.setCrystal(event.getRow(), event.getFields());
				}
			} else if (event.getCommand() == SilEvent.ADD_CRYSTAL) {
				int newRow = sil.addCrystal(event.getFields());
				event.setRow(newRow);
			} else if (event.getCommand() == SilEvent.SET_CRYSTAL_IMAGE) {
				sil.setCrystalImage(event.getRow(), event.getFields());
			} else if (event.getCommand() == SilEvent.ADD_CRYSTAL_IMAGE) {
				sil.addCrystalImage(event.getRow(), event.getFields());
			} else if (event.getCommand() == SilEvent.CLEAR_CRYSTAL_IMAGES) {
				Hashtable fields = event.getFields();
				Integer group = (Integer)fields.get("group");
				if (group != null) {
					sil.clearCrystalImages(event.getRow(), group.intValue());
				} else {
					sil.clearCrystalImages(event.getRow());
				}
			} else if (event.getCommand() == SilEvent.CLEAR_CRYSTAL) {
				Hashtable fields = event.getFields();
				String clearField = (String)fields.get("clearField");
				String clearSystemWarning = (String)fields.get("clearSystemWarning");
				String clearImages = (String)fields.get("clearImages");
				String clearSpot = (String)fields.get("clearSpot");
				String clearAutoindex = (String)fields.get("clearAutoindex");
				if (clearSystemWarning.equals("true")) {
					sil.setCrystal(event.getRow(), "SystemWarning", "");
				}
				if (clearImages.equals("true") ||
					clearSpot.equals("true") ||
					clearAutoindex.equals("true")) {
					if (clearImages.equals("true")) // clear images also clears spotinder results
						sil.clearCrystalImages(event.getRow());
					else if (clearSpot.equals("true"))
						sil.clearSpotfinderResults(event.getRow());
					if (clearAutoindex.equals("true"))
						sil.clearAutoindexResults(event.getRow());
				}
				SilLogger.info("CLEAR_CRYSTAL silId = " + sil.getId() + " clearField = " + clearField);
				if ((clearField != null) && (clearField.length() > 0)) {
					sil.clearCrystal(event.getRow(), clearField);
				}
			} else if (event.getCommand() == SilEvent.CLEAR_ALL_CRYSTALS) {
				Hashtable fields = event.getFields();
				String clearImages = (String)fields.get("clearImages");
				String clearSpot = (String)fields.get("clearSpot");
				String clearAutoindex = (String)fields.get("clearAutoindex");
				if (clearImages.equals("true") ||
					clearSpot.equals("true") ||
					clearAutoindex.equals("true")) {
					if (clearImages.equals("true")) // clear images also clears spotinder results
						sil.clearCrystalImages(-1);
					else if (clearSpot.equals("true"))
						sil.clearSpotfinderResults(-1);
					if (clearAutoindex.equals("true"))
						sil.clearAutoindexResults(-1);
				}
			} else if (event.getCommand() == SilEvent.SET_CRYSTAL_ATTRIBUTE) {
				Hashtable fields = event.getFields();
				String attrName = (String)fields.get("attrName");
				String values = (String)fields.get("attrValues");
				sil.setCrystalAttribute(attrName, values);
			}
		} catch (Exception e) {
			SilLogger.error("SilEventQueue (" + sil.getId() + ") "
								+ toString() + ": processEvent error for event "
							+ event.getId()
							+ " " + e.getMessage());
			event.setError(e.getMessage());
		}
	}

	/**
	 * Tell the event thread to stop
	 */
	synchronized public void stopQueue()
	{
		// Set flag
		queueStopped = true;

		notify();
	}

	/**
	 * check if the event thread should stop
	 */
	synchronized private boolean isQueueStopped()
	{

		return queueStopped;
	}

	/**
	 * Clear all pending events in the queue
	 */
	synchronized private void clearEvents()
	{
		queue.clear();
	}


	/**
	 * Check if the given event is completed.
	 */
	synchronized public boolean isEventCompleted(int eventId)
		throws Exception
	{
		return ((sil.getEventId() > eventId)
				|| (eventLog.get(new Integer(eventId)) != null));
	}


	/**
	 * Save sil as excel Workbook and pipe it through the stream
	 */
	public void saveSilAsWorkbook(String sheetName, OutputStream stream)
		throws Exception
	{
		sil.saveAsWorkbook(sheetName, stream);
	}

	/**
	 * Save sil as excel Workbook and pipe it through the stream
	 */
	public void saveSil(OutputStream stream)
		throws Exception
	{
		sil.save(stream);
	}
	

	/**
	 * Thread method
	 */
	public void run()
	{
		try {

		SilLogger.info("SilEventQueue (" + sil.getId() + ") "
							+ toString() + ": thread started");

		// Loop until told to stop
		while (!isQueueStopped()) {

			if (queue.isEmpty()) {

				synchronized (this) {

					// Wait until notified
					// by addEvent method
					// that an event has arrived.
//					SilLogger.info("Waiting for a new event for sil " + sil.getId() + " queue size = " + queue.size());
					wait(waitTimeout);
					if (idleTime < maxIdleTime)
						idleTime += waitTimeout;

				}

			} else {
				// Process events in pending queue
//				SilLogger.info("Processing events for sil " + sil.getId());
				processEvents();
			}

		}

		SilLogger.info("SilEventQueue (" + sil.getId() + "):  thread finished");

		} catch (InterruptedException e) {
			SilLogger.error("SilEventQueue for sil " + sil.getId()
					+ ": wait() was interrupted");
		}


	}

	/**
	 */
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
	
	public String getSilKey()
	{
		return sil.getKey();
	}

	/**
	 * Lock sil without a key.
	 */
	public void lockSil()
		throws Exception
	{
		sil.setLock(true);
		sil.setKey("");
	}

	/**
	 *  Lock sil with a key.
	 * If the key is an empty string or null then
	 * it is the same as locking without a key.
	 */
	public void lockSil(String s)
		throws Exception
	{
		sil.setLock(true);
		if (s == null)
			s = "";
		sil.setKey(s);
	}
	
	/**
	 */
	public void unlockSil()
		throws Exception
	{
		sil.setLock(false);
		sil.setKey("");
	}
	
	/**
	 * Is this sil locked? 
	 */
	public boolean isSilLocked()
	{
		return sil.isLocked();	
	}
		
	/**
	 * Does this sil has a crystal with this id?
	 */
	public int getCrystalRow(String fieldName, String fieldValue)
	{
		return sil.getCrystalRow(fieldName, fieldValue);
	}
	
	public String getSilOwner()
	{
		return sil.getOwner();
	}
	
	public Crystal newCrystal()
	{
		return sil.newCrystal();
	}
}

