package sil.managers;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Random;
import java.util.StringTokenizer;

import org.apache.commons.beanutils.BeanUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.BeanWrapper;
import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.PropertyValue;
import org.springframework.beans.PropertyValues;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.util.CrystalCollection;
import sil.beans.util.CrystalSortTool;
import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.ImageWrapper;
import sil.beans.util.SilUtil;
import sil.factory.SilFactory;

/**
 * 
 * @author penjitk
 * - Takes care of locking/unlocking sil before modifying the sil.
 * - Records events performed on the sil.
 * - Stores sil after an event takes place.
 */
public class SilManager implements InitializingBean {

	protected final Log logger = LogFactoryImpl.getLog(getClass()); 
	private Sil sil = new Sil();
	private SilStorageManager storageManager = null;
	private EventManager eventManager = null;
	private SilFactory silFactory = null;
	private CrystalSortTool crystalSortTool = null;
	
	static private Random ran = new Random(System.currentTimeMillis());
	static final private String hexChars = "ABCDEF0123456789";

	public SilManager() {}
	public SilManager(Sil sil) throws Exception {
		this.sil = sil;
		eventManager = silFactory.createEventManager(sil);
	}
	
	static final public int MOVE_TO_TOP = 1;
	static final public int MOVE_TO_BOTTOM = 2;
	static final public int MOVE_UP = 3;
	static final public int MOVE_DOWN = 4;
	
	public void loadSil(int silId)
		throws Exception
	{
		sil = storageManager.loadSil(silId);
		eventManager = silFactory.createEventManager(sil);
	}
	
	public int setCrystalProperties(long uniqueId, PropertyValues props)
		throws Exception
	{
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		return setCrystalProperties(crystal, props);
	}
	
	public int setCrystalPropertiesInRow(int row, PropertyValues props)
		throws Exception
	{
		
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Row " + row + " does not exist in sil " + sil.getId());
		
		return setCrystalProperties(crystal, props);
	}
		
/*	public int setCrystalProperties(String crystalId, PropertyValues props)
		throws Exception
	{
		
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		if (crystal == null)
			throw new Exception("Crystal id " + crystalId + " does not exist in sil " + sil.getId());
		
		return setCrystalProperties(crystal, props);
	}*/
	
	private int setCrystalProperties(Crystal crystal, PropertyValues props)
		throws Exception
	{
		
		CrystalWrapper wrapper = getSilFactory().createCrystalWrapper(crystal);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
	
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		
		return eventId;
	}
	
	// Get property value for the given propety name for all crystals in the sil.
	public List<String> getCrystalPropertyValues(String propertyName) throws Exception
	{		
		// List crystal by row numbers
		Collection sortedCrystals = crystalSortTool.sort(sil.getCrystals(), "row");		
		List<String> ret = new ArrayList<String>();
		
		Iterator it = sortedCrystals.iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			ret.add(String.valueOf(wrapper.getPropertyValue(propertyName)));
		}
		
		return ret;
	}
	
	// Set a property for all crystals in the sil
	public int setCrystalPropertyValues(String propertyName, List<String> values) throws Exception
	{		
		// List crystal by row numbers
		Collection sortedCrystals = crystalSortTool.sort(sil.getCrystals(), "row");		
		if (values.size() < sortedCrystals.size())
			throw new Exception("Number of property values does not match number of crystals.");
		
		Iterator it = sortedCrystals.iterator();
		Iterator<String> vit = values.iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			String value = vit.next();
			wrapper.setPropertyValue(propertyName, value);
		}
		
		// Add event 
		int eventId = eventManager.addSilEvent();
		// Save to disk
		storeSil(sil);
		
		return eventId;
	}
	
	// Select crystals
	public int selectCrystals(String values) throws Exception
	{
		return selectCrystals("selected", values);
	}
	
	public int selectCrystals(String propertyName, String values) throws Exception
	{
		StringTokenizer tok = null;
		boolean value = false;
		if (values.equalsIgnoreCase("all"))
			value = true;
		else if (values.equalsIgnoreCase("none"))
			value = false;
		else
        	tok = new StringTokenizer(values, " ,;+&\t\n\r");
		
		// List crystal by row numbers
		Collection sortedCrystals = crystalSortTool.sort(sil.getCrystals(), "row");		
		if ((tok != null) && (tok.countTokens() < sortedCrystals.size()))
			throw new Exception("Number of attribute values does not match number of crystals.");
		
		Iterator it = sortedCrystals.iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			CrystalWrapper wrapper = silFactory.createCrystalWrapper(crystal);
			if (tok != null)
				value = getBoolean(tok.nextToken());
			wrapper.setPropertyValue(propertyName, value);
		}
		
		// Add event 
		int eventId = eventManager.addSilentEvent();
		// Save to disk
		storeSil(sil);
		
		return eventId;
	}
	
	private boolean getBoolean(String value) {
		return (value != null) && value.equals("1") || value.equalsIgnoreCase("true");
	}
	
	private void storeSil(Sil sil) throws Exception {
		if ((storageManager != null) && (sil.getId() > -1))
			storageManager.storeSil(sil);
		
	}
	
	public int addCrystal(Crystal crystal) throws Exception
	{
		// Modify sil in cache
		Crystal newCrystal = CrystalUtil.cloneCrystal(crystal);
		newCrystal.setUniqueId(storageManager.getNextCrystalUniqueId());
		SilUtil.addCrystal(sil, newCrystal);
		// Record event
		int eventId = eventManager.addSilEvent();
		// Save to disk
		storeSil(sil);
		return eventId;

	}
	// Create an empty crystal for this row and port.
	private Crystal createEmptyCrystal(Sil sil, int row, String port, String containerId, String containerType) {
		String crystalId = "Empty" + String.valueOf(row+1);
		String uniqueCrystalId = createUniqueCrystalId(crystalId);
		Crystal crystal = new Crystal();
		crystal.setRow(row);
		crystal.setPort(port);
		crystal.setContainerId(containerId);
		crystal.setContainerType(containerType);
		crystal.setCrystalId(uniqueCrystalId);
		return crystal;
	}
	
	// Create a unique crystalId for this sil. If the crystalId already exists then 
	// rename it.
	private String createUniqueCrystalId(String crystalId) {
		String uniqueCrystalId = crystalId;
		int i = 1;
		Crystal oldCrystal;
		int limit = 100;
		while ((i < limit) && ((oldCrystal=SilUtil.getCrystalFromCrystalId(sil, uniqueCrystalId)) != null)) {
			uniqueCrystalId = crystalId + "_" + i;
			++i;
		}
		
		return uniqueCrystalId;
	}
	
	// Replace old crystal in this row with a new crystal
	// Replace old crystal in this row with a new crystal
	public int moveCrystalToPort(String port, final Crystal srcCrystal) throws Exception {
		return moveCrystalToPort(port, srcCrystal, null);
	}
	public int moveCrystalToPort(String port, final Crystal srcCrystal, String moveHistory) throws Exception {
		
		Crystal crystal = CrystalUtil.cloneCrystal(srcCrystal);
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, port);
		if (oldCrystal == null)
			throw new Exception("Port " + port + " does not exist in sil " + sil.getId());
				
		crystal.setRow(oldCrystal.getRow());
		crystal.setPort(oldCrystal.getPort());
		crystal.setContainerId(oldCrystal.getContainerId());
		crystal.setContainerType(oldCrystal.getContainerType());	
		// Make sure that crystalId is unique in this sil.
		logger.info("moveCrystalToPort dest port = " + port + " src port = " + srcCrystal.getPort() + " src crystalId = " + srcCrystal.getCrystalId());
		String crystalId = createUniqueCrystalId(crystal.getCrystalId());
		logger.info("moveCrystalToPort dest port = " + port + " src port = " + srcCrystal.getPort() + " NEW src crystalId = " + crystalId);
		crystal.setCrystalId(crystalId);
		if (moveHistory != null)
			crystal.getData().setMove(moveHistory);

		SilUtil.replaceCrystalInPort(sil, crystal);
		
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	// replace old crystal in this row with an empty crystal
	public int removeCrystalFromPort(String port) throws Exception {
		
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, port);
		if (oldCrystal == null)
			throw new Exception("Port " + port + " does not exist in sil " + sil.getId());
		// Create a default empty crystal for this row
		Crystal crystal = createEmptyCrystal(sil, oldCrystal.getRow(), oldCrystal.getPort(), 
							oldCrystal.getContainerId(),
							oldCrystal.getContainerType());
		crystal.setUniqueId(storageManager.getNextCrystalUniqueId());
		SilUtil.replaceCrystalInPort(sil, crystal);
		
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int setCrystal(Crystal crystal) throws Exception
	{
		// Modify sil in cache
		Crystal newCrystal = CrystalUtil.cloneCrystal(crystal);
		SilUtil.setCrystal(sil, newCrystal);
		// Record event
		int eventId = eventManager.addCrystalEvent(newCrystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public String lockSil(String key) throws Exception {
		sil.getInfo().setLocked(true);
		sil.getInfo().setKey(key);
		// Save to disk
		storeSil(sil);		
		return key;
	}
	
	public String lockSil(boolean useKey) throws Exception {
		String key = null;
		if (useKey)
			key = generateKey();
		return lockSil(key);
	}
	public void unlockSil() throws Exception {
		sil.getInfo().setLocked(false);
		sil.getInfo().setKey(null);
		// Save to disk
		storeSil(sil);
	}
	
	public int addCrystalImage(long uniqueId, PropertyValues props)
		throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		Image image = new Image();
		ImageWrapper wrapper = getSilFactory().createImageWrapper(image);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
		CrystalUtil.addImage(crystal, image);
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int addCrystalImageInRow(int row, PropertyValues props)
		throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Crystal row " + row + " does not exist in sil " + sil.getId());
		
		return addCrystalImage(crystal, props);
	}
	
/*	public int addCrystalImage(String crystalId, PropertyValues props)
		throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		if (crystal == null)
			throw new Exception("Crystal id " + crystalId + " does not exist in sil " + sil.getId());
		
		return addCrystalImage(crystal, props);
	}*/
	
	private int addCrystalImage(Crystal crystal, PropertyValues props)
		throws Exception
	{		
		Image image = new Image();
		ImageWrapper wrapper = getSilFactory().createImageWrapper(image);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
		CrystalUtil.addImage(crystal, image);
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int setCrystalImage(long uniqueId, String name, PropertyValues props)
		throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		return setCrystalImage(crystal, name, props);
	}
	
	public int setCrystalImageInRow(int row, String name, PropertyValues props)
		throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Row " + row + " does not exist in sil " + sil.getId());
		
		return setCrystalImage(crystal, name, props);
	}
	
	private int setCrystalImage(Crystal crystal, String name, PropertyValues props)
		throws Exception
	{		
		Image image = CrystalUtil.getImageFromName(crystal, name);
		if (image == null)
			throw new Exception("Image name " + name + " does not exist");
		ImageWrapper wrapper = getSilFactory().createImageWrapper(image);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int clearCrystalImagesInGroup(long uniqueId, String groupName) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return clearCrystalImagesInGroup(crystal, groupName);
		
	}
	public int clearCrystalImagesInGroupInRow(int row, String groupName) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Row " + row + " does not exist in sil " + sil.getId());
		return clearCrystalImagesInGroup(crystal, groupName);
		
	}
/*	public int clearCrystalImagesInGroup(String crystalId, String groupName) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		if (crystal == null)
			throw new Exception("Crystal id " + crystalId + " does not exist in sil " + sil.getId());
		return clearCrystalImagesInGroup(crystal, groupName);
	}*/

	private int clearCrystalImagesInGroup(Crystal crystal, String groupName) throws Exception 
	{		
		CrystalUtil.clearImagesInGroup(crystal, groupName);
		
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int clearAllCrystalImages(long uniqueId) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		return clearAllCrystalImages(crystal);
	}
	
	public int clearAllCrystalImagesInRow(int row) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Row " + row + " does not exist in sil " + sil.getId());
		
		return clearAllCrystalImages(crystal);
	}
	
/*	public int clearAllCrystalImages(String crystalId) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		if (crystal == null)
			throw new Exception("Crystal id " + crystalId + " does not exist in sil " + sil.getId());
		
		return clearAllCrystalImages(crystal);
	}*/
	
	private int clearAllCrystalImages(Crystal crystal) throws Exception 
	{
		
		CrystalUtil.clearImages(crystal);
		
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int clearAutoindexResult(long uniqueId) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		return clearAutoindexResult(crystal);
	}

	public int clearAutoindexResultInRow(int row) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Row " + row + " does not exist in sil " + sil.getId());
		
		return clearAutoindexResult(crystal);
	}
	
/*	public int clearAutoindexResult(String crystalId) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		if (crystal == null)
			throw new Exception("Crystal id " + crystalId + " does not exist in sil " + sil.getId());
		
		return clearAutoindexResult(crystal);
	}*/
	
	private int clearAutoindexResult(Crystal crystal) throws Exception 
	{		
		CrystalUtil.clearAutoindexResult(crystal);
		
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int clearAllSpotfinderResult(long uniqueId) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		CrystalUtil.clearAllSpotfinderResult(crystal);
		
		return clearAllSpotfinderResult(crystal);
	}

	public int clearAllSpotfinderResultInRow(int row) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Row " + row + " does not exist in sil " + sil.getId());
		
		CrystalUtil.clearAllSpotfinderResult(crystal);
		
		return clearAllSpotfinderResult(crystal);
	}
	
/*	public int clearAllSpotfinderResult(String crystalId) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		if (crystal == null)
			throw new Exception("Crystal id " + crystalId + " does not exist in sil " + sil.getId());
		
		return clearAllSpotfinderResult(crystal);
	}*/
	
	private int clearAllSpotfinderResult(Crystal crystal) throws Exception 
	{		
		CrystalUtil.clearAllSpotfinderResult(crystal);
		
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
	}
	
	public int clearSystemWarning(long uniqueId) throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		return clearSystemWarning(crystal);
		
	}
	
	public int clearSystemWarningInRow(int row) throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Row " + row + " does not exist in sil " + sil.getId());
		
		return clearSystemWarning(crystal);
		
	}
	
/*	public int clearSystemWarning(String crystalId) throws Exception
	{
		Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
		if (crystal == null)
			throw new Exception("Crystal id " + crystalId + " does not exist in sil " + sil.getId());
		
		return clearSystemWarning(crystal);
		
	}*/
	
	private int clearSystemWarning(Crystal crystal) throws Exception
	{	
		CrystalUtil.clearAutoindexWarning(crystal);
		
		// Record event
		int eventId = eventManager.addCrystalEvent(crystal.getUniqueId());
		// Save to disk
		storeSil(sil);
		return eventId;
		
	}
	
	public CrystalCollection getChangesSince(int eventId) throws Exception {
		return getEventManager().getChangesSince(eventId);
	}
	
	///////////////////////////////////////////////////////
	// Position
	///////////////////////////////////////////////////////
	public int addDefaultRepositionData(long uniqueId, PropertyValues props) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());

		RepositionData data = new RepositionData();
		BeanWrapper wrapper = getSilFactory().createRepositionDataWrapper(data);
		wrapper.setPropertyValues(props, true, true);
		int id = CrystalUtil.addDefaultRepositionData(crystal, data);
		
		incrementCrystalEventId(crystal);
		storeSil(sil);
		
		return id;
	}
	
/*	public int addBlankRepositionData(long uniqueId) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		RepositionData data = new RepositionData();
		int id = CrystalUtil.addRepositionData(crystal, data);
		
		incrementCrystalEventId(crystal);
		storeSil(sil);
		
		return id;
	}*/
	
	public int addRepositionData(long uniqueId, PropertyValues props) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		RepositionData data = new RepositionData();
		BeanWrapper wrapper = getSilFactory().createRepositionDataWrapper(data);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
		int id = CrystalUtil.addRepositionData(crystal, data);
		
		incrementCrystalEventId(crystal);
		storeSil(sil);
		
		return id;
	}
	
	public RepositionData getRepositionData(long uniqueId, int repositionId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		return CrystalUtil.getRepositionData(crystal, repositionId);
	}
	
	public void setRepositionData(long uniqueId, int repositionId, RepositionData modified) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		RepositionData data = CrystalUtil.getRepositionData(crystal, repositionId);
		if (data == null)
			throw new Exception("Reposition data id " + repositionId + " does not exist.");
		if (data.getRepositionId() != modified.getRepositionId())
			throw new Exception("Cannot modify repositionId.");
		
		// Copy properties from modified to data.
		BeanUtils.copyProperties(data, modified);
		
		incrementCrystalEventId(crystal);
		storeSil(sil);
	}
	
	public void setRepositionDataForRow(int row, int repositionId, PropertyValues props) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Crystal row " + row + " does not exist in sil " + sil.getId());
		setRepositionData(crystal.getUniqueId(), repositionId, props);
	}
	public void setRepositionData(long uniqueId, int repositionId, PropertyValues props) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());

		RepositionData data = CrystalUtil.getRepositionData(crystal, repositionId);
		if (data == null)
			throw new Exception("Reposition data id " + repositionId + " does not exist.");
		PropertyValue prop = props.getPropertyValue("label");
		String label = null;
		if (prop != null)
			label = (String)prop.getValue();
		prop = props.getPropertyValue("repositionId");
		if (prop != null)
			repositionId = Integer.parseInt((String)prop.getValue());
		if ((repositionId > -1) && (data.getRepositionId() != repositionId))
			throw new Exception("Cannot modify repositionId.");
		BeanWrapper wrapper = silFactory.createRepositionDataWrapper(data);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
		
		incrementCrystalEventId(crystal);
		storeSil(sil);
	}
	
	public String[] getRepositionDataLabels(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return CrystalUtil.getRepositionDataLabels(crystal);
	}
	
	public int[] getRepositionDataAutoindexable(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return CrystalUtil.getRepositionDataAutoindexable(crystal);
	}
	
	///////////////////////////////////////////////////////
	// Run definition
	///////////////////////////////////////////////////////	
	public int addRunDefinition(long uniqueId, int repositionId) throws Exception {
		return addRunDefinition(uniqueId, repositionId, new MutablePropertyValues());
	}
	public int addRunDefinition(long uniqueId, int repositionId, PropertyValues props) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return addRunDefinition(crystal, repositionId, props);
	}
	
	public int addRunDefinitionForRow(int row, int repositionId, PropertyValues props) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Crystal row " + row + " does not exist in sil " + sil.getId());
		return addRunDefinition(crystal, repositionId, props);
	}
	
	private int addRunDefinition(Crystal crystal, int repositionId, PropertyValues props) throws Exception {
		
		// Create run definition from an existing reposition data.
		// Copy properties from reposition data to run definition.
		RunDefinition run = CrystalUtil.newRunDefinition(crystal, repositionId);
		
		// Override run definition properties with the given property values.
		BeanWrapper wrapper = getSilFactory().createRunDefinitionWrapper(run);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);

		int index = CrystalUtil.addRunDefinition(crystal, run);
		
		incrementCrystalEventId(crystal);	
		storeSil(sil);
		
		return index;
	}
	
	public int copyRunDefinition(long uniqueId, int runIndex) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		int newRunIndex = CrystalUtil.copyRunDefinition(crystal, runIndex);
		
		incrementCrystalEventId(crystal);	
		storeSil(sil);
		
		return newRunIndex;
	}	
	
	public void deleteRunDefinition(long uniqueId, int index) throws Exception {	
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		
		deleteRunDefinition(crystal, index);
	}

	private void deleteRunDefinition(Crystal crystal, int index) throws Exception {
		CrystalUtil.deleteRunDefinition(crystal, index);	
		incrementCrystalEventId(crystal);
		storeSil(sil);	
	}
	
	public int getNumRepositionData(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return crystal.getResult().getRepositions().size();
	}
	
	public List<RepositionData> getRepositions(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return crystal.getResult().getRepositions();
	}
	
	public int getNumRunDefinitions(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return getNumRunDefinitions(crystal);
	}

	private int getNumRunDefinitions(Crystal crystal) throws Exception {
		return crystal.getResult().getRuns().size();
	}
	
	public RunDefinition getRunDefinition(long uniqueId, int index) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return getRunDefinition(crystal, index);
	}
		
	private RunDefinition getRunDefinition(Crystal crystal, int index) throws Exception {
		return CrystalUtil.getRunDefinition(crystal, index);
	}
	
	public int[] getRunDefinitionLabels(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return CrystalUtil.getRunDefinitionLabels(crystal);
	}
	
	public String[] getRunDefinitionStatusList(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return CrystalUtil.getRunDefinitionStatusList(crystal);
	}
	
	public void moveRunDefinition(long uniqueId, int index, int move) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		moveRunDefinition(crystal, index, move);
	}
		
	private void moveRunDefinition(Crystal crystal, int index, int move) throws Exception {
		switch (move) {
		case MOVE_TO_TOP:
			CrystalUtil.moveRunDefinitionToTop(crystal, index);
			break;
		case MOVE_TO_BOTTOM:
			CrystalUtil.moveRunDefinitionToBottom(crystal, index);
			break;
		case MOVE_UP:
			CrystalUtil.moveRunDefinitionUp(crystal, index);
			break;
		case MOVE_DOWN:
			CrystalUtil.moveRunDefinitionDown(crystal, index);
			break;
		}
		
		incrementCrystalEventId(crystal);
		storeSil(sil);	
	}
	
	// Set many properties of a run definitions. Ignore unrecognized properties in props.
	public void setRunDefinitionProperties(long uniqueId, int index, PropertyValues props) throws Exception {
		setRunDefinitionProperties(uniqueId, index, props, false);
	}
	
	public void setRunDefinitionPropertiesForRow(int row, int index, PropertyValues props, boolean silent) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
		if (crystal == null)
			throw new Exception("Crystal row " + row + " does not exist in sil " + sil.getId());
		setRunDefinitionProperties(crystal.getUniqueId(), index, props, silent);
	}
	
	public void setRunDefinitionProperties(long uniqueId, int index, PropertyValues props, boolean silent) throws Exception {
		
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		RunDefinition run = CrystalUtil.getRunDefinition(crystal, index);
		BeanWrapper wrapper = silFactory.createRunDefinitionWrapper(run);
		wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
		
		if (!silent) {
			incrementCrystalEventId(crystal);
		}
		storeSil(sil);
	}
	
	// Set a property of a run defintion.
	public void setRunDefinitionPropertyValue(long uniqueId, int index, String propertyName, String propertyValue) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		setRunDefinitionPropertyValue(crystal, index, propertyName, propertyValue);
	}
	
	// Replace all properties of an existing run definition with those of newRun.
	// Make sure that run label matches.
	public void setRunDefinition(long uniqueId, int index, RunDefinition newRun) throws Exception 
	{
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());

		RunDefinition run = CrystalUtil.getRunDefinition(crystal, index);
		if (run.getRunLabel() != newRun.getRunLabel())
			throw new Exception("Run label cannot be modified.");
		CrystalUtil.copyRunDefinition(run, newRun);
		
		incrementCrystalEventId(crystal);
		storeSil(sil);	
	}
	
	// Set a property for all run definitions.
	private void setRunDefinitionPropertyValue(Crystal crystal, int index, String propertyName, String propertyValue) throws Exception
	{		
		RunDefinition run = CrystalUtil.getRunDefinition(crystal, index);
		BeanWrapper wrapper = silFactory.createRunDefinitionWrapper(run);
		wrapper.setPropertyValue(propertyName, propertyValue);
		
		incrementCrystalEventId(crystal);
		storeSil(sil);
	}
	
	public void setRunDefinitionPropertyValue(long uniqueId, String propertyName, String propertyValue) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		setRunDefinitionPropertyValue(crystal, propertyName, propertyValue);
	}
	
	// Set a property for all run definitions.
	private void setRunDefinitionPropertyValue(Crystal crystal, String propertyName, String propertyValue) throws Exception
	{		
		Iterator<RunDefinition> it = crystal.getResult().getRuns().iterator();
		while (it.hasNext()) {
			RunDefinition run = it.next();
			BeanWrapper wrapper = silFactory.createRunDefinitionWrapper(run);
			wrapper.setPropertyValue(propertyName, propertyValue);
		}
		
		incrementCrystalEventId(crystal);
		storeSil(sil);
	}

	public EventManager getEventManager() {
		return eventManager;
	}

	public boolean getSilLocked()
	{
		return sil.getInfo().isLocked();
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

	public void afterPropertiesSet() throws Exception {
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for SilManager bean");
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for SilManager bean");
		if (crystalSortTool == null)
			throw new BeanCreationException("Must set 'sortTool' property for SilManager bean");	
	}

	public Sil getSil() {
		return sil;
	}
	
	public Collection sortCrystalByProperties(List<String> propertyNames, boolean ascending) {
		// CrystalSortTool knows how to map display column name to crystal property,
		// and can sort ascending or descending.
		crystalSortTool.setAscending(ascending);
		return crystalSortTool.sort(sil.getCrystals(), propertyNames);		
	}
	public CrystalSortTool getCrystalSortTool() {
		return crystalSortTool;
	}
	public void setCrystalSortTool(CrystalSortTool crystalSortTool) {
		this.crystalSortTool = crystalSortTool;
	}

	// Generate a 10-HEX-character string 
	// used as a key for sil lock.
	static public String generateKey()
	{
		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < 10; ++i) {
			buf.append(hexChars.charAt(ran.nextInt(16)));
		}
		return buf.toString();
	}
	
	public int getLatestEventId() {
		return sil.getInfo().getEventId();
	}
	
	public int getCrystalRowFromUniqueId(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return crystal.getRow();
	}
	
	public int[] getLatestCrystalEventIds() {
		return SilUtil.getCrystalEventIds(sil);
	}
	
	public int getLatestCrystalEventId(long uniqueId) throws Exception {
		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new Exception("Crystal uniqueId " + uniqueId + " does not exist in sil " + sil.getId());
		return crystal.getEventId();
	}
	
	// Do not go pass 4 digits so that we can send all event ids to dcss
	// via dcs protocol without making the dcs message too big.
	private int incrementCrystalEventId(Crystal crystal) {
		int newEventId = crystal.getEventId() + 1;
		if (newEventId > 9999)
			newEventId = 1;
		crystal.setEventId(newEventId);	
		return newEventId;
	}

}
