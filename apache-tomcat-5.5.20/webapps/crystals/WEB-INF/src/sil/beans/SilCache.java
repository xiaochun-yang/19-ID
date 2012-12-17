package sil.beans;

import java.util.Hashtable;
import java.util.Enumeration;
import cts.CassetteDB;

import java.io.OutputStream;
import java.util.Random;
import java.io.*;
import java.net.*;

public class SilCache
{

	/**
	 * Object for holding a list of SilEventQueue kept in memory.
	 * A sil is unloaded from memory if it is not used
	 * after a period of time.
	 */
	private Hashtable cache = new Hashtable();

	/**
	 * Object for handling db connection
	 */
	private CassetteDB dbConn = null;

	private int maxCacheSize = 10;
	
	private Random ran = new Random();
	final private String hexChars = "ABCDEF0123456789";

	/**
	 */
	public SilCache()
		throws Exception
	{
		dbConn = SilUtil.getCassetteDB();
	}

	/**
	 * Add an event to a SilEventQueue
	 */
	synchronized public int addEvent(SilEvent event)
		throws Exception
	{
		return addEvent(event, false);
	}
	
	/**
	 * Add an event to a SilEventQueue
	 */
	synchronized public int addEvent(SilEvent event, boolean validateRow)
		throws Exception
	{
		// Get an existing queue or create a new one
		// The sil is loaded from xml file
		// when a new queue is created
		SilEventQueue queue = getOrCreateSilEventQueue(event.getSilId());

		if (queue == null)
			throw new Exception("Sil " + event.getSilId() + " does not exist");

		String key = queue.getSilKey();
		if (queue.isSilLocked() && (key.length() > 0) && !key.equals(event.getSilKey()))
			throw new Exception("SilCache cannot add event because sil " + event.getSilId() 
						+ " is currently locked with another key.");

		return queue.addEvent(event, validateRow);

	}

	/**
	 * Returns an existing SilEventQueue from cache
	 */
	synchronized public void processEvent(SilEvent event)
		throws Exception
	{
		// Get an existing queue or create a new one
		// The sil is loaded from xml file
		// when a new queue is created
		SilEventQueue queue = getOrCreateSilEventQueue(event.getSilId());

		if (queue == null)
			throw new Exception("Sil " + event.getSilId() + " does not exist");

		String queueKey = queue.getSilKey();
		if (queue.isSilLocked() && (queueKey.length() > 0) && !queueKey.equals(event.getSilKey()))
			throw new Exception("SilCache cannot process event because sil " + event.getSilId() 
						+ " is currently locked with another key.");

		queue.processEvent(event);

	}

	/**
	 * Returns an existing SilEventQueue from cache
	 */
	synchronized private SilEventQueue getSilEventQueue(String silId)
	{
		return (SilEventQueue)cache.get(silId);
	}

	/**
	 * Returns an existing SilEventQueue from cache
	 * or create a new one an add it to cache.
	 */
	private SilEventQueue getOrCreateSilEventQueue(String silId)
		throws Exception
	{
		// Cleanup cache
//		removeInactiveQueues();

		if ((silId == null) || (silId.length() == 0))
			throw new Exception("Invalid silId " + silId);

		// Get event queue for this sil
		SilEventQueue queue = (SilEventQueue)cache.get(silId);

		// Create one if it does not exist
		if (queue == null) {

			if (isCacheFull()) {
				removeInactiveQueues();
			}

			// Get sil owner from db
			int id = 0;
			try {
				id = Integer.parseInt(silId);
			} catch (NumberFormatException e) {
				throw new Exception("Invalid silId " + silId);
			}

			// Load sil from file
			Sil sil = loadSil(silId);
			// create event queue for this sil
			queue = new SilEventQueue(sil);
			// Add queue to cache
			cache.put(silId, queue);
			// start event queue for this sil
			queue.start();

			SilLogger.info("Added sil " + silId + " to cache: cache size = " + cache.size());

		}
		
		return queue;

	}

	/**
	 * Get sil filename from sil id.
	 */
	private String getSilFileName(String silId, String owner)
		throws Exception
	{
		int id = -1;
		try {

		id = Integer.parseInt(silId);
		
		} catch (NumberFormatException e) {
			throw new Exception("Invalid sil id " + silId);
		}
		
		if (id <= 0) 
			throw new Exception("Invalid sil id " + silId);
		
		String fileName = dbConn.getCassetteFileName(id);

		if (SilUtil.isError(fileName))
			throw new Exception(SilUtil.parseError(fileName));

		// First construct root filename
		return SilConfig.getInstance().getCassetteDir() + owner
				+ "/" + fileName + "_sil.xml";
	}
	
	/**
	 * Load sil from file
	 */
	private Sil loadSil(String silId)
		throws Exception
	{
		int id = Integer.parseInt(silId);
		String owner = dbConn.getCassetteOwner(id);
		if (SilUtil.isError(owner))
			throw new Exception(SilUtil.parseError(owner));
		String fileName = getSilFileName(silId, owner);

		// Create a new sil from xml file
		Sil sil = new Sil(silId, owner, fileName);

		return sil;
	}

	/**
	 */
	synchronized public int getLatestEventId(String silId)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		return queue.getLatestEventId();
	}

	/**
	 * Returns an event log from the given event id
	 */
	synchronized public String getEventLog(String silId, int fromId, String format)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		return queue.getEventLog(fromId, format);
	}

	/**
	 * Returns an event log from the given event id
	 */
	synchronized public String getEventLog(String silId, int fromId)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		return queue.getEventLog(fromId);
	}

	/**
	 * Returns a Crystal
	 */
	public String getCrystal(String silId, int row)
		throws Exception
	{
		return getCrystal(silId, row, "tcl");
	}

	synchronized public String getCrystal(String silId, int row, String format)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		return queue.getCrystal(row, format);
	}

	/**
	 * Returns a Crystal
	 */
	public String getCrystal(String silId, String crystalId)
		throws Exception
	{
		return getCrystal(silId, crystalId, "tcl");
	}

	synchronized public String getCrystal(String silId, String crystalId, String format)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		return queue.getCrystal(crystalId, format);
	}

	/**
	 * Check if the given event is completed.
	 */
	synchronized public boolean isEventCompleted(String silId, int eventId)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		return queue.isEventCompleted(eventId);
	}

	/**
	 * Save sil as excel Workbook and pipe it through the stream
	 */
	synchronized public void saveSilAsWorkbook(String silId, String sheetName,
						OutputStream stream)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		queue.saveSilAsWorkbook(sheetName, stream);
	}


	/**
	 */
	public void getSil(String silId, OutputStream stream)
		throws Exception
	{
		SilEventQueue queue = getOrCreateSilEventQueue(silId);

		if (queue == null)
			throw new Exception("Sil " + silId + " does not exist");

		queue.saveSil(stream);
	}

	/**
	 * Remove queue which have stopped waiting for events
	 */
	private void removeInactiveQueues()
	{

		String queueName = "";
		SilEventQueue queue = null;
		int numRemoved = 0;
		boolean removedAny = false;

		while (isCacheFull()) {
			removedAny = false;
			SilLogger.info("Removing inactive queue from cache: cache size = " + cache.size());
			for (Enumeration keys = cache.keys(); keys.hasMoreElements() ;) {
				queueName = (String)keys.nextElement();
				queue = (SilEventQueue)cache.get(queueName);
//				SilLogger.info("queue " + queueName + " has been idle for " + queue.getIdleTime() + " msec");
				if (queue.isInactive()) {
					SilLogger.info("silCache: Removing queue " + queueName
										+ " due to inactivity");
					queue.stopQueue();
					cache.remove(queueName);
					// We have removed an entry from cache.
					// the current key enumeration is no longer
					// valid. Need to get a new one.
					++numRemoved;
					removedAny = true;
					break;
				}
			}
			// Loop through all entry but didn't remove any
			// This means the remaining sils in cache are still active.
			// Stop trying even if the cache is still full.
			if (!removedAny) {
				if (numRemoved > 0) {
					SilLogger.info("SilCache: Removed " + numRemoved + " from cache. Cache size = "
							+ cache.size());
				} else {
					// Didn't remove any since all sils are still active.
					SilLogger.info("SilCache: Did not remove any sil from cache. "
							+ " All sils are still active. cache size = "
							+ cache.size());
				}
				return;
			}

		}
	}


	private boolean isCacheFull()
	{
		return (cache.size() >= maxCacheSize);
	}
	
	/**
	 * Generate a 10-HEX-character string 
	 * used as a key for sil lock.
	 */
	private String generateKey()
	{
		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < 10; ++i) {
			buf.append(hexChars.charAt(ran.nextInt(16)));
		}
		return buf.toString();
	}
	
	/**
	 * Lock all sils on the list
	 * Return the key for this lock.
	 * Will throw an exeption if one of the sils
	 * is already locked.
	 */
	synchronized public String lockSil(String silList[], String lockType, String userName, boolean isStaff)
		throws Exception
	{
		if (silList == null)
			throw new Exception("Cannot lock sil because the list of sils is null");
			
		// By default, the sil will be locked without a key.
		String key = "";
		
		// Generate a unique key for this lock
		if ((lockType != null) && lockType.equals("full"))
			key = generateKey();
		
		// Make sure all sils are not busy and 
		// are not already locked.
		for (int i = 0; i < silList.length; ++i) {
			String silId = silList[i];
			if ((silId == null) || (silId.length() == 0))
				continue;
			// Find or load sil 
			SilEventQueue queue = getOrCreateSilEventQueue(silId);
			// User can only lock his own sil
			// Staff can lock any sil.
			if (!queue.getSilOwner().equals(userName) && !isStaff)
				throw new Exception("User " + userName + " is not the owner of sil " + silId);
			// Can not lock a sil that is already locked.
			// unlock must be called first
			if (queue.isSilLocked())
				throw new Exception("sil " + silId + " is already locked.");
			// Can not lock sil that is being used.
			if (!queue.isEmpty())
				throw new Exception("sil " + silId + " is currently busy and cannot be locked.");
		}
		
		// Lock all sils
		for (int i = 0; i < silList.length; ++i) {
			String silId = silList[i];
			if ((silId == null) || (silId.length() == 0))
				continue;
			// Find or load sil 
			SilEventQueue queue = getOrCreateSilEventQueue(silId);
			SilLogger.info("Locking sil " + silId);
			// Remove lock
			queue.lockSil(key);
		}
		
		return key;
	}

	/**
	 * Unlock all sils on the list
	 * Throw an exception if any of the sils
	 * is busy or is not locked with this key.
	 */
	synchronized public void unlockSil(String silList[], String key, boolean forced, String userName, boolean isStaff)
		throws Exception
	{
		if (silList == null)
			throw new Exception("Cannot unlock sil because the list of sils is null");
			
		// Make sure all queues are empty and sils locked 
		// by this key (or not locked).
		for (int i = 0; i < silList.length; ++i) {
		    String silId = silList[i];
		    if ((silId == null) || (silId.length() == 0))
			continue;
		    SilEventQueue queue = getOrCreateSilEventQueue(silId);
		    
		    // Sil is not locked
		    if (!queue.isSilLocked())
			continue;
			
		    // Do not unlock sil that is still busy processing events.
		    if (!queue.isEmpty())
		    	throw new Exception("sil " + silId + " is currently busy and cannot be locked.");
		    // User is not staff and is not sil owner
		    if (!isStaff && !userName.equals(queue.getSilOwner()))
			throw new Exception("User " + userName + " is not owner of sil " + silId);
		    // Only staff can force unlock
		    if (isStaff && forced)
		    	continue;
			
		    String silKey = queue.getSilKey();
		    
		    // Sil is locked with no key then owner of sill or staff can unlock it
		    if ((silKey == null) || silKey.length() == 0)
			continue;
			
		    if ((key == null) || (key.length() == 0))
			throw new Exception("sil " + silId + " must be unlocked with a key");
		    // sil is locked with this key?
		    if (!silKey.equals(key))
			throw new Exception("sil " + silId + " cannot be unlocked with this key.");
		
		}
				
		// unlock sils
		for (int i = 0; i < silList.length; ++i) {
			String silId = silList[i];
			if ((silId == null) || (silId.length() == 0))
				continue;
			// Find or load sil 
			SilEventQueue queue = getOrCreateSilEventQueue(silId);
			// Remove lock
			SilLogger.info("Unlocking sil " + silId);
			queue.unlockSil();
		}

	}
	
	/**
	 * Remove sil from cache.
	 */
	synchronized public void removeSil(String silId, boolean forced)
		throws Exception
	{
		SilEventQueue queue = null;
		
		// Try looking for the sil in cache
		// if not found then load it to cache
		// so that we can inspect whether 
		// the lock and key flags are set.
		try {	
			queue = getOrCreateSilEventQueue(silId);
		} catch (Exception e) {
			// Ignore load fail error
			SilLogger.warn("Cache:removeSil failed to load sil " + silId + " because " + e.getMessage());
			return;
		}
		
		// Make sure the queue is empty and sil
		// is not locked..	
		if (!forced) {
			if (!queue.isEmpty())
				throw new Exception("sil " + silId + " is currently busy and cannot be removed from cache");
			if (queue.isSilLocked())
				throw new Exception("sil " + silId + " is currently locked and cannot be removed from cache");
		}
		
		// Stop the queue if it is in the cache
		if (queue != null)
			queue.stopQueue();
			
		// Remove queue from the cache
		cache.remove(silId);
	}
	
	/**
	 * Move a row of crystal data from one sil to another.
	 * Must be unlocked or locked with this key. Event queue of both sils
	 * must be empty.
	 */
	synchronized public String moveCrystal(String srcSil, String srcPort,
				String destSil, String destPort, String key,
				boolean clearMove)
		throws Exception
	{
		// Keep track of what has been done
		// in order to be able to rollback if needed.
		boolean modifiedSrcCrystal = false;
		boolean modifiedDestCrystal = false;
				
		// Move operation must be done with a key lock.		
		if ((key == null) || (key.length() == 0))
			throw new Exception("invalid lock key. moveCrystal must be performed while the sils are locked with a key.");
			
		// Load sil in memory
		SilEventQueue srcQueue = null;
		SilEventQueue destQueue = null;
		
		// Save original crystal data for both source and destination 
		// sils for rollback.
		Crystal srcCrystal = null;
		Crystal destCrystal = null;
				
		// Save this data to be recorded in
		// the source sil.
		String srcCrystalId = "";
		String destCrystalId = "";
		
		int srcRow = -1;
		int destRow = -1;
				
		try {
		
		// There is a spreadsheet for source cassette
		if ((srcSil != null) && (srcSil.length() > 0)) {
		
			if ((srcPort == null) || (srcPort.length() == 0))
				throw new Exception("missing or invalid source port parameter");
				
			// Load sil into memory
			srcQueue = getOrCreateSilEventQueue(srcSil);
			// Make sure it is not locked
			if (!srcQueue.isSilLocked())
				throw new Exception("source sil " + srcSil + " must be locked for moveCrystal");
			String silKey = srcQueue.getSilKey();
			if ((silKey == null) || (silKey.length() == 0))
				throw new Exception("source sil " + srcSil + " must be locked with a key.");
			if (!silKey.equals(key))
				throw new Exception("source sil " + srcSil + " is locked with another key.");
			// Make sure it is not processing any events
			if (!srcQueue.isEmpty())
				throw new Exception("source sil " + srcSil + " is currently busy processing other events");
				
			srcRow = srcQueue.getCrystalRow("Port", srcPort);
			
			if (srcRow < 0)
				throw new Exception("cannot find port " + srcPort + " in source sil " + srcSil);
				
			// Get crystal to be moved. Save this data for rollback.
			// Source crystal data can be null which means that
			// the row in the spreadsheet is empty.
			srcCrystal = srcQueue.cloneCrystal(srcRow);
												
			if (srcCrystal != null) {						
				// Only copy crystal data if port id and crystal id are valid
				srcCrystalId = srcCrystal.getField("CrystalID");
				if ((srcCrystalId == null) || (srcCrystalId.length() == 0))
					throw new Exception("Invalid CrystalID in source sil + " + srcSil + " row " + srcRow);
			
			}

		}
		
		// There is a spreadsheet for destination cassette
		if ((destSil != null) && (destSil.length() > 0)) {
		
			if ((destPort == null) || (destPort.length() == 0))
				throw new Exception("missing or invalid destination port");
		
			// Load sil into memory
			destQueue = getOrCreateSilEventQueue(destSil);
			// Make sure it is not locked
			if (!destQueue.isSilLocked())
				throw new Exception("destination sil " + destSil + " must be locked for moveCrystal");
			String silKey = destQueue.getSilKey();
			if ((silKey == null) || (silKey.length() == 0))
				throw new Exception("destination sil " + destSil + " must be locked with a key.");
			if (!silKey.equals(key))
				throw new Exception("destination sil " + destSil + " is locked with another key.");
			// Make sure it is not processing any events
			if (!destQueue.isEmpty())
				throw new Exception("destination sil " + destSil 
						+ " is currently busy processing other events");
			
			// Get row number of the crystal of the given port.			
			destRow = destQueue.getCrystalRow("Port", destPort);
			
			if (destRow < 0)
				throw new Exception("cannot find port " + destPort + " in destination sil " + destSil);
												
			// Get crystal in the destination location.
			// Save this data for rollback.
			// This crystal can be null
			destCrystal = destQueue.cloneCrystal(destRow);
		}
		
		
														
			// If we have crystal from src sil 
			// then move it to this new row
			if (srcCrystal != null) {
				
				// Source crystal to be moved. We will modify fields of this crystal.
				Crystal newDestCrystal = srcCrystal.clone();
				destCrystalId = srcCrystalId;
				
				// Make sure that this crystal id is unique in the destination sil.
				// If not, then append a number to it.									
				int i = 0;
				while (i < 100) {
					++i;
					int existingRow = destQueue.getCrystalRow("CrystalID", destCrystalId);
					if ((existingRow < 0) || (existingRow == destRow))
						break;
					SilLogger.info("SilCache moveCrystal dest sil already has CrystalID " + destCrystalId);
					destCrystalId = srcCrystalId + "_" + i;
				}
								
				// Modify some fields
				newDestCrystal.setRow(destRow);
				newDestCrystal.setField("CrystalID", destCrystalId);
				newDestCrystal.setField("Port", destPort);
				if (clearMove) {
					newDestCrystal.setField("Move", "");
				} else {
					newDestCrystal.setField("Move", "from sil=" + srcSil + ",row=" + srcRow + ",Port=" + srcPort
						+ ",CrystalID=" + srcCrystalId);
				}
							
				// Replace crystal in dest sil with this crystal
				SilEvent ev = new SilEvent(SilEvent.SET_CRYSTAL, destSil, newDestCrystal);
				ev.setSilKey(key);
				destQueue.addEvent(ev);
			
				modifiedDestCrystal = true;
				
				// Remove data from src row except for the Move field
				Crystal newSrcCrystal = null;
				if (SilConfig.getInstance().getClearSrcCrystal()) {
					newSrcCrystal = srcQueue.newCrystal();
					newSrcCrystal.setRow(srcCrystal.getRow());
					newSrcCrystal.setField("Port", srcCrystal.getField("Port"));
					newSrcCrystal.setField("CrystalID", srcCrystal.getField("CrystalID"));
				} else {
					newSrcCrystal = srcCrystal.clone();
				}
				if (clearMove) {
					// clear Move field
					newSrcCrystal.setField("Move", "");
				} else {		
					// Set Move column of the source sil
					// to record where the crystal has been moved to.
					String movedTo = "to sil=" + destSil + ",row=" + destRow + ",Port=" + destPort + ",CrystalID=" + destCrystalId;
					newSrcCrystal.setField("Move", movedTo);
				}
				SilEvent ev1 = new SilEvent(SilEvent.SET_CRYSTAL, srcSil, newSrcCrystal);
				ev1.setSilKey(key);
				srcQueue.addEvent(ev1);
				modifiedSrcCrystal = true;
								
			} else { // crystal was moved but there is no src sil.
			
				// No crystal data to move from source spreadsheet to dest spreadsheet
				SilEvent ev = null;
				if (clearMove) {
					ev = SilEvent.createClearCrystalEvent(destSil, destRow, "Move");
				} else {
					// but we still want to record that the crystal has been moved to this spreadsheet.
					Crystal newDestCrystal = Sil.newCrystal();
					newDestCrystal.setRow(destRow);
					newDestCrystal.setField("Port", destPort);
					newDestCrystal.setField("Move", "from sil=" + srcSil + ",row=" + srcRow + ",Port=,CrystalID=");
					ev = new SilEvent(SilEvent.SET_CRYSTAL, destSil, newDestCrystal);
				}
				ev.setSilKey(key);
				destQueue.addEvent(ev);
				
				modifiedDestCrystal = true;
				
			}
			
		
		SilLogger.info("Moved crystal from sil=" + srcSil + ",row=" + srcRow + ",Port=" + srcPort
						+ ",CrystalID=" + srcCrystalId
						+ " to sil=" + destSil + ",row=" + destRow + ",Port=" + destPort
						+ ",CrystalID=" + destCrystalId);
						
		return destCrystalId;
		
						
		} catch (Exception e) {
		
			SilLogger.warn("MoveCrystal failed: " + e.getMessage());
		
			// ROLL BACK
		
			// Rollback crystal data in src sil
			if (modifiedSrcCrystal) {
				SilLogger.info("Rolling back source crystal sil " + srcSil + " row " + srcRow);
				SilEvent rollback = new SilEvent(SilEvent.SET_CRYSTAL, srcSil, srcCrystal);
				rollback.setSilKey(key);
				srcQueue.processEvent(rollback);
			}
				
			// Rollback crystal data in dest sil
			if (modifiedDestCrystal) {
				SilLogger.info("Rolling back destination crystal sil " + destSil + " row " + destCrystal);
				SilEvent rollback = new SilEvent(SilEvent.SET_CRYSTAL, destSil, destCrystal);
				rollback.setSilKey(key);
				destQueue.processEvent(rollback);
			}

			
			SilLogger.info("Rolled back crystal src sil=" + srcSil + ",row=" + srcRow + ",Port=" + srcPort
						+ " dest sil=" + destSil + ",row=" + destRow + ",Port=" + destPort
						+ ",CrystalID=" + destPort);
						
			// Still report the problem
			throw e;
						
		}
	}
	
}

