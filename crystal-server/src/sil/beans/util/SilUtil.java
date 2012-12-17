package sil.beans.util;

import java.beans.XMLEncoder;
import java.io.BufferedOutputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import sil.beans.Crystal;
import sil.beans.Sil;
import sil.exceptions.CrystalDoesNotExistException;
/**
 * 
 * @author penjitk
 * Utility class to set/add/delete crystal in a sil. 
 * Application is responsible for sanity check 
 * of the data.
 *
 */
public class SilUtil {
	
	static private Log logger = LogFactory.getLog("SilUtil");
	
	// Return crystal from the given row.
	static public Crystal getCrystalFromRow(Sil sil, int row)
	{
		if (row < 0)
			return null;
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			if (crystal.getRow() == row) {
				return crystal;
			}
		}
		return null;
	}
	
	// Return crystal for the given crystalId.
	static public Crystal getCrystalFromCrystalId(Sil sil, String crystalId)
	{
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			if ((crystal.getCrystalId() != null) && crystal.getCrystalId().equals(crystalId)) {
				return crystal;
			}
		}
		return null;
	}

	// Return crystal from the given port.
	static public Crystal getCrystalFromPort(Sil sil, String port)
	{
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			if ((crystal.getPort() != null) && crystal.getPort().equals(port)) {
				return crystal;
			}
		}
		return null;
	}
	
	// Return crystal from the given port.
	static public Crystal getCrystalFromUniqueId(Sil sil, long uniqueId)
	{
		return getCrystalFromUniqueId(sil, Long.valueOf(uniqueId));
	}
	
	// Return crystal from the given port.
	static public Crystal getCrystalFromUniqueId(Sil sil, Long uniqueId)
	{
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			if (crystal.getUniqueId() == uniqueId) {
				return crystal;
			}
		}
		return null;
	}

	static public int getCrystalCount(Sil sil)
	{
		return sil.getCrystals().size();
	}
	
	static private int getMaxRow(Sil sil) {
		int maxRow = -1;
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			if (crystal.getRow() > maxRow)
				maxRow = crystal.getRow();
		}	
		return maxRow;
	}
	
	// Add a new crystal to the sil. Throw and exception if 
	// crystal with the same id already exists.
	static public int addCrystal(Sil sil, Crystal crystal)
			throws Exception 
	{
		boolean oldRowExists = false;
		if (crystal.getRow() < 0) {
			int maxRow = getMaxRow(sil);
			crystal.setRow(maxRow + 1);
		} else {
			Crystal oldCrystal = getCrystalFromRow(sil, crystal.getRow());
			if (oldCrystal != null)
				oldRowExists = true;
		}
			
		Long uniqueKey = Long.valueOf(crystal.getUniqueId());
		if (sil.getCrystals().get(uniqueKey) != null)
				throw new Exception("Unique id " + uniqueKey + " already exists");
		
		// Increment row number by one for all rows higher than inserted row.
		if (oldRowExists) {
			Iterator<Crystal> it = sil.getCrystals().values().iterator();
			while (it.hasNext()) {
				Crystal oldCrystal = (Crystal)it.next();
				if (oldCrystal.getRow() >= crystal.getRow())
					oldCrystal.setRow(oldCrystal.getRow() + 1);
			}
		}
		sil.getCrystals().put(uniqueKey, crystal);
		
		return crystal.getRow();
	}
	
	// Put this crystal in the lookup table. The unique id 
	// for this crystal must already exist in the sil.
	static public void setCrystal(Sil sil, Crystal crystal)
		throws Exception
	{
		if (crystal == null)
			throw new Exception("Crystal is null");
		
		Long uniqueKey = Long.valueOf(crystal.getUniqueId());
		if (sil.getCrystals().get(uniqueKey) == null)
			throw new CrystalDoesNotExistException("Crystal does not exist");
		
		sil.getCrystals().put(uniqueKey, crystal);
		
	}
	
	// Remove this crystal from the sil.
	static public void deleteCrystal(Sil sil, long uniqueId)
		throws Exception
	{		
		sil.getCrystals().remove(uniqueId);
	}
	
	// Put this crystal in the lookup table. The unique id 
	// for this crystal must already exist in the sil.
	static public void replaceCrystalInPort(Sil sil, Crystal crystal)
		throws Exception
	{
		if (crystal == null)
			throw new Exception("Crystal is null");
		
		// Remove current crystal from row
		Crystal oldCrystal = SilUtil.getCrystalFromPort(sil, crystal.getPort());
		if (oldCrystal == null)
			throw new Exception("Port " + crystal.getPort() + " does not exist");
		
		int oldRow = oldCrystal.getRow();

		// Add new crystal to this row
		Long uniqueKey = Long.valueOf(crystal.getUniqueId());
		if (sil.getCrystals().get(uniqueKey) != null)
			throw new Exception("Unique id " + uniqueKey + " already exists");
		crystal.setRow(oldRow);
		
		deleteCrystal(sil, oldCrystal.getUniqueId());		
		
		sil.getCrystals().put(uniqueKey, crystal);
		
	}
	
	// Return crystal for the given list of rows.
	static public List<Crystal> getCrystals(Sil sil, int rows[])
	{
		List<Crystal> ret = new ArrayList<Crystal>();
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			for (int i = 0; i < rows.length; ++i) {
				if (crystal.getRow() == rows[i]) {
					ret.add(crystal);
					break;
				}
			}
		}
		return ret;
	}
	
	// Return crystal for the given list of rows.
	static public List<Crystal> getCrystalsFromCrystalCollection(Sil sil, CrystalCollection col)
	{
		List<Crystal> ret = new ArrayList<Crystal>();
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			if (col.contains(crystal.getUniqueId())) {
				ret.add(crystal);
			}
		}
		return ret;
	}
	
	static public List<Crystal> getCrystals(Sil sil)
	{
		List<Crystal> ret = new ArrayList<Crystal>();
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			ret.add(crystal);
		}
		return ret;
	}	
	// Print object as xml to stdout.
	static public void debugBean(Object obj)
		throws Exception
	{	
		XMLEncoder encoder = new XMLEncoder(new BufferedOutputStream(System.out));
		encoder.writeObject(obj);
		encoder.flush();
	}	
	
	static public int[] getCrystalEventIds(Sil sil) {
		if (sil.getCrystals().size() == 0)
			return null;
		int[] ret = new int[sil.getCrystals().size()];
		int i = 0;
		Iterator<Crystal> it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			ret[i] = crystal.getEventId();
			++i;
		}
		return ret;		
	}
}
