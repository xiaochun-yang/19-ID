package sil.managers;

import java.util.List;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.factory.SilFactory;

// Represents a collection of sils owned by this user.
public class SilCollectionManager implements InitializingBean {

	private String userName = null;
	private SilStorageManager storageManager = null;
	private SilFactory silFactory = null;
	
	public List getSilCollection()
		throws Exception
	{
		return getStorageManager().getSilDao().getSilList(userName);
	}
	
	public List getSilCollection(SilCollectionFilter filter)
		throws Exception
	{
		// TODO
		return null;
	}
	
/*	public void addDefaultSil()
		throws Exception
	{
		SilInfo silInfo = new SilInfo();
		silInfo.setOwner(userName);
//		silInfo.setUploadFileName(XXXX);
		getStorageManager().getSilDao().addSil(silInfo);
	}*/
	
	public void deleteSil(String silId)
		throws Exception
	{
		// TODO
	}
	
	public SilManager getSilManager(int silId)
		throws Exception
	{
		SilInfo silInfo = getStorageManager().getSilDao().getSilInfo(silId);
		
		SilCacheManager cache = silFactory.getSilCacheManager();
		SilManager manager = cache.getOrCreateSilManager(silId);
		
		return manager;
	}
	
	public void assignToBeamline(BeamlineInfo beamlineInfo)
		throws Exception
	{
		
	}

	public void afterPropertiesSet() 
		throws Exception 
	{	
		if (storageManager == null)
			throw new BeanCreationException("Must specify 'silStorage' property for SilCollectionManager");
		
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

	public String getUserName() {
		return userName;
	}

	public void setUserName(String userName) {
		this.userName = userName;
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}
}
