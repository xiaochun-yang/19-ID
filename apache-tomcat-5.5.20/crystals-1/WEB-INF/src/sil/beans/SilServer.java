package sil.beans;

import java.util.Hashtable;
import java.io.OutputStream;


/**
 */
public class SilServer
{
	/**
	 * The only SilServer for the application.
	 */
	private static SilServer theServer = null;

	private SilCache cache = null;

	/**
	 * Static method: get SilServer singleton.
	 */
	public static SilServer getInstance()
		throws Exception
	{
		if (theServer == null)
			theServer = new SilServer();

		return theServer;
	}


	/**
	 * Hide constructor
	 */
	private SilServer()
		throws Exception
	{
		cache = new SilCache();
	}

	/**
	 * Will be procssed immediately and not put in event queue.
	 */
/*	public void setCrystalInstantly(String silId, int row, Hashtable fields, String key)
		throws Exception
	{
		SilEvent ev = new SilEvent(SilEvent.SET_CRYSTAL, silId, row, fields);
		ev.setSilKey(key);
		cache.processEvent(ev);

	}*/


	/**
	 * Set crystal fields
	 */
	public int setCrystal(String silId, int row, Hashtable fields, String key)
		throws Exception
	{
		validateRowAndCrystalId(row, (String)fields.get("CrystalID"));

		SilEvent ev = new SilEvent(SilEvent.SET_CRYSTAL, silId, row, fields);
		ev.setSilent(false);
		ev.setSilKey(key);

		return cache.addEvent(ev, true); // validate row and CrystalID
	}


	/**
	 * Set crystal fields
	 */
	public int setCrystal(String silId,
				int row,
				Hashtable fields, 
				boolean isSilent,
				String key)
		throws Exception
	{
		validateRowAndCrystalId(row, (String)fields.get("CrystalID"));

		SilEvent ev = new SilEvent(SilEvent.SET_CRYSTAL, silId, row, fields);
		ev.setSilent(isSilent);
		ev.setSilKey(key);

		return cache.addEvent(ev, true); // validate row and CrystalID
	}


	/**
	 * Set a crystal field
	 */
	public int setCrystal(String silId,
				int row,
				String fieldName,
				String fieldValue,
				String key)
		throws Exception
	{

		Hashtable fields = new Hashtable();
		fields.put(fieldName, fieldValue);
		SilEvent ev = new SilEvent(SilEvent.SET_CRYSTAL,
					silId, row, fields);
		ev.setSilKey(key);
		return cache.addEvent(ev);

	}
	
	private void validateRowAndCrystalId(int row, String crystalId)
		throws Exception
	{
		if (row < 0) {
			if (crystalId == null)
				throw new Exception("Row number is not supplied and CrystalID is missing");
				
			if (crystalId.length() == 0)
				throw new Exception("Row number is not supplied and CrystalUD has zero length");
		}
	}

	/**
	 * Add a crystal image
	 */
	public int addCrystalImage(String silId, int row, Hashtable fields, String key)
		throws Exception
	{
		validateRowAndCrystalId(row, (String)fields.get("CrystalID"));
		
		SilEvent ev = new SilEvent(SilEvent.ADD_CRYSTAL_IMAGE,
					silId, row, fields);
		ev.setSilKey(key);
		return cache.addEvent(ev, true); // validate row before adding the event
	}


	/**
	 * Add a new crystal to the SIL
	 */
	public int addCrystal(String silId, Hashtable fields, String key)
		throws Exception
	{
		SilEvent ev = new SilEvent(SilEvent.ADD_CRYSTAL,
					silId, fields);
		ev.setSilKey(key);
		return cache.addEvent(ev);
	}


	/**
	 * Set fields of an existing crystal image
	 */
	public int setCrystalImage(String silId, int row, Hashtable fields, String key)
		throws Exception
	{
		validateRowAndCrystalId(row, (String)fields.get("CrystalID"));

		SilEvent ev = new SilEvent(SilEvent.SET_CRYSTAL_IMAGE,
					silId, row, fields);
		ev.setSilKey(key);
		return cache.addEvent(ev, true); // validate row and CrystalID
	}


	/**
	 * Clear all crystal images in this row.
	 */
	public int clearCrystalImages(String silId, int row, String key, String crystalId)
		throws Exception
	{
		validateRowAndCrystalId(row, crystalId);
		
		Hashtable hash = new Hashtable();
		if (crystalId != null)
			hash.put("CrystalID", crystalId);
	
		SilEvent ev = new SilEvent(SilEvent.CLEAR_CRYSTAL_IMAGES,
					silId, row, hash);
		ev.setSilKey(key);
		return cache.addEvent(ev, true); // validate row and CrystalID
	}

	/**
	 * Clear a crystal image in the group.
	 */
	public int clearCrystalImages(String silId, int row, int group, String key, String crystalId)
		throws Exception
	{
		validateRowAndCrystalId(row, crystalId);
		
		Hashtable fields = new Hashtable();
		fields.put("group", new Integer(group));
		if (crystalId != null)
			fields.put("CrystalID", crystalId);
		SilEvent ev = new SilEvent(SilEvent.CLEAR_CRYSTAL_IMAGES,
					silId, row, fields);
		ev.setSilKey(key);
		return cache.addEvent(ev, true); // validate row and CrystalID
	}

	/**
	 * Clear some fields for the crystal.
	 */
	public int clearCrystal(String silId,
				int row,
				boolean clearImages,
				boolean clearSpot,
				boolean clearAutoindex,
				boolean clearSystemWarning,
				String key,
				String crystalId,
				String clearField)
		throws Exception
	{
		validateRowAndCrystalId(row, crystalId);

		Hashtable fields = new Hashtable();
		if (crystalId != null)
			fields.put("CrystalID", crystalId);
		fields.put("clearSystemWarning", String.valueOf(clearSystemWarning));
		fields.put("clearImages", String.valueOf(clearImages));
		fields.put("clearSpot", String.valueOf(clearSpot));
		fields.put("clearAutoindex", String.valueOf(clearAutoindex));
		if (clearField != null)
			fields.put("clearField", clearField);
		SilEvent ev = new SilEvent(SilEvent.CLEAR_CRYSTAL,
					silId, row, fields);
		ev.setSilKey(key);
		return cache.addEvent(ev, true); // validate row and CrystalID
	}

	/**
	 * Clear some fields for all crystals in this SIL.
	 */
	public int clearAllCrystals(String silId,
				boolean clearImages,
				boolean clearSpot,
				boolean clearAutoindex,
				String key)
		throws Exception
	{
		Hashtable fields = new Hashtable();
		fields.put("clearImages", String.valueOf(clearImages));
		fields.put("clearSpot", String.valueOf(clearSpot));
		fields.put("clearAutoindex", String.valueOf(clearAutoindex));
		SilEvent ev = new SilEvent(SilEvent.CLEAR_ALL_CRYSTALS,
					silId, fields);
		ev.setSilKey(key);
		return cache.addEvent(ev);
	}

	/**
	 * Set a crystal attribute
	 */
	public int setCrystalAttribute(String silId, String attrName,
					String values,
					String key)
		throws Exception
	{
		Hashtable fields = new Hashtable();
		fields.put("attrName", attrName);
		fields.put("attrValues", values);
		SilEvent ev = new SilEvent(SilEvent.SET_CRYSTAL_ATTRIBUTE, silId, 0, fields);
		ev.setSilent(true);
		ev.setSilKey(key);
		return cache.addEvent(ev);
	}


	/**
	 */
	public int getLatestEventId(String silId)
		throws Exception
	{
		return cache.getLatestEventId(silId);
	}


	/**
	 */
	public String getEventLog(String silId, int fromId, String format)
		throws Exception
	{
		return cache.getEventLog(silId, fromId, format);
	}

	/**
	 */
	public String getEventLog(String silId, int fromId)
		throws Exception
	{
		return cache.getEventLog(silId, fromId);
	}

	/**
	 */
	public String getCrystal(String silId, int row)
		throws Exception
	{
		return getCrystal(silId, row, "tcl");
	}

	/**
	 */
	public String getCrystal(String silId, int row,
				String format)
		throws Exception
	{
		return cache.getCrystal(silId, row, format);
	}

	/**
	 */
	public String getCrystal(String silId, String crystalId)
		throws Exception
	{
		return cache.getCrystal(silId, crystalId, "tcl");
	}

	/**
	 */
	public String getCrystal(String silId, String crystalId,
				String format)
		throws Exception
	{
		return cache.getCrystal(silId, crystalId, format);
	}
	/**
	 * Check if the given event is completed.
	 */
	public boolean isEventCompleted(String silId, int eventId)
		throws Exception
	{
		return cache.isEventCompleted(silId, eventId);
	}

	/**
	 * Save sil as excel Workbook pipe it through the stream
	 */
	public void saveSilAsWorkbook(String silId, OutputStream stream)
		throws Exception
	{
		cache.saveSilAsWorkbook(silId, "Sheet1", stream);
	}

	/**
	 * Save sil as excel Workbook pipe it through the stream
	 */
	public void saveSilAsWorkbook(String silId, String sheetName, OutputStream stream)
		throws Exception
	{
		cache.saveSilAsWorkbook(silId, sheetName, stream);
	}

	/**
	 */
	public void getSil(String silId, OutputStream stream)
		throws Exception
	{
		cache.getSil(silId, stream);
	}
	
	/**
	 * Lock the sils. Returns a key if it is a full lock.
	 * Throw an exception if any of the SIL on the list 
	 * has already been locked.
	 */
	public String lockSil(String silList[], String lockType, String userName, boolean isStaff)
		throws Exception
	{
		return cache.lockSil(silList, lockType, userName, isStaff);
	}

	/**
	 * Unlock sil
	 */
	public void unlockSil(String silList[], String key, boolean forced, String userName, boolean isStaff)
		throws Exception
	{
		cache.unlockSil(silList, key, forced, userName, isStaff);
	}
	
	/**
	 * Terminate sil event queue and remove sil from cache. 
	 * Will throw an exeption if this sil is locked
	 * or event queue is not empty unless forced.
	 */
	public void removeSil(String silId, boolean forced)
		throws Exception
	{		
		// Remove sil from cache
		cache.removeSil(silId, forced);

	}
	
	/**
	 * Move a row of crystal data from one sil to another.
	 */
	public String moveCrystal(String srcSil, String srcPort,
				String destSil, String destPort,
				String key, boolean clearMove)
		throws Exception
	{
		return cache.moveCrystal(srcSil, srcPort, destSil, destPort, key, clearMove);
	}

}
