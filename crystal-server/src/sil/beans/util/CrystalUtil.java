package sil.beans.util;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.apache.commons.beanutils.BeanUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import sil.beans.AutoindexResult;
import sil.beans.Crystal;
import sil.beans.CrystalData;
import sil.beans.CrystalResult;
import sil.beans.DcsStrategyResult;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.SpotfinderResult;
import sil.exceptions.RunDefinitionIndexOutOfRangeException;

public class CrystalUtil 
{
	static protected final Log logger = LogFactoryImpl.getLog(CrystalUtil.class);
	static private Image emptyImage = new Image();
	
	static public Crystal cloneCrystal(Crystal crystal) throws Exception
	{
		return (Crystal)BeanUtils.cloneBean(crystal);
	}
	
	static public void copyCrystal(Crystal target, Crystal src) throws Exception
	{
		BeanUtils.copyProperties(target, src);
	}
	
	static public void clearAutoindexWarning(Crystal crystal) 
	{
		crystal.getResult().getAutoindexResult().setWarning(null);
	}

	static public void addImage(Crystal crystal, Image image)
		throws Exception
	{
		Map<String, Image> images = crystal.getImages();
		Iterator<Image> it = images.values().iterator();
		String nextId = getNextImageId(crystal);
		while (it.hasNext()) {
			Image thisImage = (Image)it.next();
			if (image.getGroup() == null)
				throw new Exception("Invalid group");
			if (thisImage.getName().equals(image.getName()) && thisImage.getDir().equals(image.getDir()))
				throw new Exception("Image " + image.getName() + " already exists.");
		}
		image.setOrder(images.size());
		images.put(nextId, image);
	}
	
	static private String getNextImageId(Crystal crystal)
	{
		Map<String, Image> images = crystal.getImages();
		Iterator<String> it = images.keySet().iterator();
		int highestId = 0;
		int id = 0;
		while (it.hasNext()) {
			String key = it.next();
			try {
				id = Integer.parseInt(key);
			} catch (NumberFormatException e) {
				// ignore
				logger.debug("CrystalUtil failed to parse image index " + key);
			}
			if (id > highestId)
				highestId = id;
		}
		return String.valueOf(highestId+1);
	}
		
	static public void clearAllImages(Crystal crystal)
	{
		Map<String, Image> images = crystal.getImages();
		images.clear();
	}
	
	static public void clearAllSpotfinderResult(Crystal crystal) 
	{
		Map<String, Image> images = crystal.getImages();
		Iterator<String> it = images.keySet().iterator();
		while (it.hasNext()) {
			String index = it.next();
			Image thisImage = images.get(index);
			thisImage.getResult().setSpotfinderResult(new SpotfinderResult());
		}
	}
	
	static public void clearImagesInGroup(Crystal crystal, String groupName)
	{
		if ((groupName == null) || (groupName.length() == 0))
			return;
		Map<String, Image> images = crystal.getImages();
		boolean done = false;
		while ((images.size() > 0) && !done) {
			done = true;
			Iterator<String> it = images.keySet().iterator();
			while (it.hasNext()) {
				String index = it.next();
				Image thisImage = images.get(index);
				if (thisImage.getGroup().equals(groupName)) {
					images.remove(index);
					done = false;
					break;
				}
			}
		}
	}

	static public void clearImageFromPath(Crystal crystal, String imagePath)
	{
		if ((imagePath == null) || (imagePath.length() == 0))
			return;
		Map<String, Image> images = crystal.getImages();
		Iterator<String> it = images.keySet().iterator();
		while (it.hasNext()) {
			String index = it.next();
			Image thisImage = images.get(index);
			if (thisImage.getPath().equals(imagePath)) {
				images.remove(index);
				return;
			}
		}
	}
	
	static public void clear(Crystal crystal)
	{
		crystal.setData(new CrystalData());
		crystal.setResult(new CrystalResult());
	}
	
	static public void clearData(Crystal crystal)
	{
		crystal.setData(new CrystalData());
	}
	
	static public void clearResult(Crystal crystal)
	{
		crystal.setResult(new CrystalResult());
	}
	
	static public void clearAutoindexResult(Crystal crystal)
	{
		CrystalResult result = crystal.getResult();
		result.setReorientable(0);
		result.setReorientInfo(null);
		result.setReorientPhi(null);
		result.setDcsStrategyResult(new DcsStrategyResult());
		result.setAutoindexResult(new AutoindexResult());
		result.setRuns(new Vector<RunDefinition>());
		result.setRepositions(new ArrayList<RepositionData>());
	}
	
	static public void clearImages(Crystal crystal)
	{
		crystal.getImages().clear();
	}	
	
	// Return last image of the given group
	static public Image getLastImageInGroup(Crystal crystal, String groupName)
	{
		if (groupName == null)
			return null;
		Image last = null;
		Map<String, Image> images = crystal.getImages();
		Iterator<Image> it = images.values().iterator();
		while (it.hasNext()) {
			Image image = (Image)it.next();
			String thisGroupName = image.getGroup();
			if ((thisGroupName == null) || !thisGroupName.equals(groupName))
				continue;
			if ((last == null) || (image.getOrder() > last.getOrder()))
				last = image;
		}
		return last;
	}
	
	static public int countImagesInGroup(Crystal crystal, String groupName)
	{
		int count = 0;
		Map<String, Image> images = crystal.getImages();
		Iterator<Image> it = images.values().iterator();
		while (it.hasNext()) {
			Image image = (Image)it.next();
			String thisGroupName = image.getGroup();
			if (!thisGroupName.equals(groupName))
				continue;
			++count;
		}
		return count;
	}
	
	// Helper for velocity
	static public Image getEmptyImage() {
		return emptyImage;
	}
	
	// Return last image of each group
	static public Map<String, Image> testGetLastImageInEachGroup(Crystal crystal)
	{
		Hashtable<String, Image> ret = new Hashtable<String, Image>();
		Hashtable<String, Integer> lookup = new Hashtable<String, Integer>(); // groupName/order
		Map<String, Image> images = crystal.getImages();
		Iterator<Image> it = images.values().iterator();
		while (it.hasNext()) {
			Image image = (Image)it.next();
			String groupName = image.getGroup();
			Image lastImageInGroup = ret.get(groupName);
			if ((lastImageInGroup == null) || (image.getOrder() > lastImageInGroup.getOrder()))
				ret.put(groupName, image);
		}
		return ret;
	}
	
	static public Image getImageFromPath(Crystal crystal, String path) 
	{
		if ((path == null) || (path.length() == 0))
			return null;
		Iterator<Image> it = crystal.getImages().values().iterator();
		while (it.hasNext()) {
			Image image = (Image)it.next();
			if (image.getPath().equals(path))
				return image;
		}
		return null;
	}
	
	static public Image getImageFromName(Crystal crystal, String name) 
	{
		if ((name == null) || (name.length() == 0))
			return null;
		Iterator<Image> it = crystal.getImages().values().iterator();
		while (it.hasNext()) {
			Image image = (Image)it.next();
			if (image.getName().equals(name))
				return image;
		}
		return null;
	}
/*	
	// Create default reposition data from existing reorientInfo for this crystal.
	static public int addDefaultRepositionData1(Crystal crystal, RepositionData data)
		throws Exception
	{
		if ((data.getLabel() == null) || (data.getLabel().length() == 0))
			throw new Exception("Invalid reposition data label.");
		List<RepositionData> positions = crystal.getResult().getRepositions();
		synchronized(positions) {
			if (positions.size() > 0)
				throw new Exception("Default reposition data already exists.");
			data.setRepositionId(0);
			Iterator<RepositionData> it = positions.iterator();
			while (it.hasNext()) {
				RepositionData item = it.next();
				if (item.getLabel().equals(data.getLabel()))
					throw new Exception("Reposition data label " + data.getLabel() + " already exists.");
			}
			positions.add(data);
		}
		return 0;
	}
	
	static public int addRepositionData1(Crystal crystal, RepositionData data)
		throws Exception
	{
		if ((data.getLabel() == null) || (data.getLabel().length() == 0))
			throw new Exception("Invalid reposition data label.");
		List<RepositionData> positions = crystal.getResult().getRepositions();
		int id = 0;
		synchronized(positions) {
			if (positions.size() == 0)
				throw new Exception("No default reposition data for this crystal.");
			Iterator<RepositionData> it = positions.iterator();
			while (it.hasNext()) {
				RepositionData item = it.next();
				if (item.getLabel().equals(data.getLabel()))
					throw new Exception("Reposition data label " + data.getLabel() + " already exists.");
			}
			positions.add(data);
			id = positions.size()-1;
			data.setRepositionId(id);
		}
		return id;
	}
*/	
	static public int getNumRepositionData(Crystal crystal) {
		return crystal.getResult().getRepositions().size();
	}
	
	static public int addDefaultRepositionData(Crystal crystal, RepositionData data)
		throws Exception
	{
		List<RepositionData> positions = crystal.getResult().getRepositions();
		synchronized(positions) {
			if (positions.size() > 0)
				throw new Exception("Default reposition data already exists.");
			return addRepositionData(positions, data);
		}
	}
	
	static public int addRepositionData(Crystal crystal, RepositionData data)
		throws Exception
	{
		List<RepositionData> positions = crystal.getResult().getRepositions();
		synchronized(positions) {
			if (positions.size() == 0)
				throw new Exception("No default reposition data for this crystal.");
			return addRepositionData(positions, data);
		}
	}
	
	static private int addRepositionData(List<RepositionData> positions, RepositionData data)
		throws Exception
	{
		if ((data.getLabel() == null) || (data.getLabel().length() == 0))
			throw new Exception("Invalid reposition data label.");
		Iterator<RepositionData> it = positions.iterator();
		while (it.hasNext()) {
			RepositionData item = it.next();
			if (item.getLabel().equals(data.getLabel()))
				throw new Exception("Reposition data label " + data.getLabel() + " already exists.");
		}
		positions.add(data);
		int id = positions.size()-1;
		data.setRepositionId(id);

		return id;
	}
	
	static public RepositionData getRepositionData(Crystal crystal, int repositionId) throws Exception {
		
		List<RepositionData> positions = crystal.getResult().getRepositions();
		synchronized(positions) {
			if (positions.size() == 0)
				return null;
			try {
				return positions.get(repositionId);
			} catch (IndexOutOfBoundsException e) {
				return null;
			}
		}
	}
	
	static public String[] getRepositionDataLabels(Crystal crystal) {
		if (crystal.getResult().getRepositions().size() == 0)
			return null;
		String[] labels = new String[crystal.getResult().getRepositions().size()];
		List<RepositionData> repositions = crystal.getResult().getRepositions();
		synchronized(repositions) {
			Iterator<RepositionData> it = repositions.iterator();
			int i = 0;
			while (it.hasNext()) {
				RepositionData item = it.next();
				labels[i] = item.getLabel();
				++i;
			}
		}
		
		return labels;
	}
	
	static public int[] getRepositionDataAutoindexable(Crystal crystal) {
		List<RepositionData> repositions = crystal.getResult().getRepositions();
		synchronized(repositions) {
			if (repositions.size() == 0)
				return null;
			int[] autoindexable = new int[repositions.size()];
			Iterator<RepositionData> it = repositions.iterator();
			int i = 0;
			while (it.hasNext()) {
				RepositionData item = it.next();
				autoindexable[i] = item.getAutoindexable();
				++i;
			}
			return autoindexable;
		}
	}
	
	static public RunDefinition newRunDefinition(Crystal crystal, int repositionId) throws Exception {
		
		if (repositionId < 0)
			throw new Exception("Invalid reposition id: " + repositionId);
		
		RepositionData repo = CrystalUtil.getRepositionData(crystal, repositionId);
		if (repo == null)
			throw new Exception("Reposition id " + repositionId + " does not exist.");

		RunDefinition run = new RunDefinition();
		// The source and target classes do not have to match or even be derived from each other, 
		// as long as the properties match. Any bean properties that the source bean exposes 
		// but the target bean does not will silently be ignored. 
		org.springframework.beans.BeanUtils.copyProperties(repo, run);
		run.setRepositionId(repositionId);
		return run;
	}
	
	static public int getNumRunDefinitions(Crystal crystal) {
		return crystal.getResult().getRuns().size();
	}

	// Returns index of the newly added item.
	static public int addRunDefinition(Crystal crystal, RunDefinition run)
		throws Exception
	{
		if (run.getRepositionId() < 0)
			throw new Exception("Invalid repositionId.");
		
		if (crystal.getResult().getRepositions().size() == 0)
			throw new Exception("No reposition data for this crystal.");
		
		RepositionData repo = CrystalUtil.getRepositionData(crystal, run.getRepositionId());
		if (repo == null)
			throw new Exception("Reposition id " + run.getRepositionId() + " does not exist.");
		
		List<RunDefinition> runs = crystal.getResult().getRuns();
		int newIndex = -1;
		synchronized(runs) {
			if (runs.size() > 0)
				run.setRunLabel(runs.get(runs.size()-1).getRunLabel() + 1);
			else
				run.setRunLabel(1);
			runs.add(run);
			newIndex = runs.size()-1;
		}
		return newIndex;
	}
	
	static public int copyRunDefinition(Crystal crystal, int runIndex)
		throws Exception
	{
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {
			if (runs.size() == 0)
				throw new Exception("No existing run definition for this crystal.");
			RunDefinition lastRun = runs.get(runs.size()-1);
			RunDefinition oldRun = getRunDefinition(crystal, runIndex);
			if (oldRun == null)
				throw new Exception("runIndex out of range.");
			RunDefinition newRun = new RunDefinition();
			copyRunDefinition(newRun, oldRun);
			newRun.setRunLabel(lastRun.getRunLabel() + 1);
			runs.add(newRun);
			int newIndex = runs.size()-1;
			return newIndex;
		}
	}

	static public void deleteRunDefinition(Crystal crystal, int index)
		throws Exception
	{
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {
			if ((index < 0) || (index > runs.size()-1))
				throw new Exception("Invalid run index " + index);
			runs.remove(index);
		}
	}
	
	static public int[] getRunDefinitionLabels(Crystal crystal) {
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {
			if (runs.size() == 0)
				return null;
			int[] labels = new int[runs.size()];
			Iterator<RunDefinition> it = runs.iterator();
			int i = 0;
			while (it.hasNext()) {
				RunDefinition item = it.next();
				labels[i] = item.getRunLabel();
				++i;
			}
			return labels;
		}	
	}
	
	static public String[] getRunDefinitionStatusList(Crystal crystal) {
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {
			if (runs.size() == 0)
				return null;
			String[] statusArray = new String[runs.size()];
			Iterator<RunDefinition> it = runs.iterator();
			int i = 0;
			while (it.hasNext()) {
				RunDefinition item = it.next();
				statusArray[i] = item.getRunStatus();
				++i;
			}
			return statusArray;
		}	
	}
	
	static public List<RunDefinition> getRunDefinitions(Crystal crystal)
	{
		return crystal.getResult().getRuns();
	}
	
	static public RunDefinition getRunDefinition(Crystal crystal, int index) throws Exception
	{
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized (runs) {
			if (crystal.getResult().getRuns().size() == 0)
				return null;
			try {
				return crystal.getResult().getRuns().get(index);
			} catch (IndexOutOfBoundsException e) {
				return null;
			}
		}
	}
	
	static public RunDefinition cloneRunDefinition(Crystal crystal, int index) throws Exception 
	{
		RunDefinition run = getRunDefinition(crystal, index);
		return (RunDefinition)BeanUtils.cloneBean(run);
	}
	
	static public void copyRunDefinition(RunDefinition target, RunDefinition src) throws Exception
	{
		BeanUtils.copyProperties(target, src);
	}
	
	static public void moveRunDefinitionToTop(Crystal crystal, int index)
		throws Exception
	{
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {
			if ((index < 0) || (index > runs.size()-1))
				throw new Exception("Run definition index out of range.");
		
			// Already at the first position
			if (index == 0)
				return;
		
			// Remove run from the current position
			RunDefinition run = runs.remove(index);
			// Add it to the first position
			runs.add(0, run);	
		}
	}
	
	static public void moveRunDefinitionToBottom(Crystal crystal, int index)
		throws Exception
	{
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {		
			if ((index < 0) || (index > runs.size()-1))
				throw new Exception("Run definition index out of range.");
		
			// Already at the last position
			if (index == runs.size()-1)
				return;
		
			// Remove run from the current position
			RunDefinition run = runs.remove(index);
			// Add it to the first position
			runs.add(run);
		}
	}
	
	// Move up by one (closer to first position)
	static public void moveRunDefinitionUp(Crystal crystal, int index)
		throws Exception
	{
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {
			if ((index < 0) || (index > runs.size()-1))
				throw new Exception("Run definition index out of range.");
		
			// Already at the first position
			if (index == 0)
				return;
		
			// Remove run from the current position
			RunDefinition run = runs.remove(index);
			// Add it to the new position
			runs.add(index-1, run);
		}
	}
	
	// Move down by one (farther from first position)
	static public void moveRunDefinitionDown(Crystal crystal, int index)
		throws Exception
	{
		List<RunDefinition> runs = crystal.getResult().getRuns();
		synchronized(runs) {
			if ((index < 0) || (index > runs.size()-1))
				throw new Exception("Run definition index out of range.");
		
			// Already at the last position
			if (index == runs.size()-1)
				return;
		
			// Remove run from the current position
			RunDefinition run = runs.remove(index);
			// Add it to the new position
			runs.add(index+1, run);
		}
	}
}
