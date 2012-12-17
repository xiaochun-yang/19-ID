package sil.managers;

import java.util.Hashtable;
import java.util.Enumeration;
import sil.factory.SilFactory;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

public class SilCacheManager
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private SilFactory silFactory = null;

	/**
	 * Object for holding a list of SilEventQueue kept in memory.
	 * A sil is unloaded from memory if it is not used
	 * after a period of time. XXXXX
	 */
	private Hashtable<String, SilManager> cache = new Hashtable<String, SilManager>();
	private int maxCacheSize = 30;
	
	synchronized public SilManager getOrCreateSilManager(int silId)
		throws Exception
	{
		if (silId <= 0)
			throw new Exception("Invalid silId (" + silId + ")");
		
		SilManager silManager = cache.get(String.valueOf(silId));
		if (silManager != null)
			return silManager;
		
		return addSilManager(silId);
	}
	
	synchronized public SilManager getSilManager(int silId)
		throws Exception
	{
		if (silId <= 0)
			throw new Exception("Invalid silId (" + silId + ")");
	
		return cache.get(String.valueOf(silId));
	}

	synchronized public void removeSil(int silId, boolean forced)
		throws Exception
	{
		// Make sure the queue is empty and sil
		// is not locked..	
		if (!forced) {
			
			SilManager silManager = null;
		
			// Try looking for the sil in cache
			// if not found then load it to cache
			// so that we can inspect whether 
			// the lock and key flags are set.
			try {	
				silManager = cache.get(String.valueOf(silId));
				// sil not in cache.
				if (silManager == null)
					return;
			} catch (Exception e) {
				// Ignore load fail error
				logger.warn("Cannot get sil " + silId + " from cache because " + e.getMessage());
				return;
			}	
	
			if (silManager.getSilLocked())
				throw new Exception("sil " + silId + " is currently locked and cannot be removed from cache");
		}
			
		// Remove queue from the cache
		cache.remove(String.valueOf(silId));
	}

	private SilManager addSilManager(int silId)
		throws Exception
	{
		SilManager silManager = cache.get(String.valueOf(silId));
		if (silManager != null)
			return silManager;
	
		if (isCacheFull())
			removeInactiveEntries();
			
		silManager = silFactory.createSilManager(silId);
	
		cache.put(String.valueOf(silId), silManager);
	
		return silManager;
	}

	private void removeInactiveEntries()
	{
		int numRemoved = 0;
		boolean removedAny = false;

		while (isCacheFull()) {
			removedAny = false;
			for (Enumeration<String> keys = cache.keys(); keys.hasMoreElements() ;) {
				String silId = (String)keys.nextElement();
				SilManager silManager = cache.get(silId);
				EventManager eventManager = silManager.getEventManager();
				if (eventManager.isInactive()) {
					logger.info("silCache: Removing queue " + silId + " due to inactivity");
					cache.remove(silId);
					// We have removed an entry from cache.
					// the current key enumeration is no longer
					// valid. Need to get a new one.
					++numRemoved;
					removedAny = true;
					break;
				}
			}
			// Loop through all entries but didn't remove any
			// This means the remaining sils in cache are still active.
			// Stop trying even if the cache is still full.
			if (!removedAny) {
				if (numRemoved > 0) {
					logger.info("SilCache: Removed " + numRemoved + " from cache. Cache size = "
							+ cache.size());
				} else {
					// Didn't remove any since all sils are still active.
					logger.info("SilCache: Did not remove any sil from cache. "
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

	public int getMaxCacheSize() {
		return maxCacheSize;
	}

	public void setMaxCacheSize(int maxCacheSize) {
		this.maxCacheSize = maxCacheSize;
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}
		
	// Needed for junit tests
	public void clearCache() {
		cache.clear();
	}
}

