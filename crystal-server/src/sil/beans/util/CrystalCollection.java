package sil.beans.util;

import java.util.*;

public class CrystalCollection {

	private boolean containsAllCrystals = false;
	private Set<Long> crystals = new HashSet<Long>();
		
	public void setContainsAll(boolean containsAllCrystals)
	{
		this.containsAllCrystals = containsAllCrystals;
	}
	
	public boolean containsAll()
	{
		return containsAllCrystals;
	}
	
	public void add(long id)
	{
		crystals.add(id);
	}
	
	public int size() {
		return crystals.size();
	}
	
	public boolean contains(long id)
	{
		if (containsAllCrystals)
			return true;	
		Iterator<Long> it = crystals.iterator();
		while (it.hasNext()) {
			Long uniqueId = it.next();
			if (uniqueId.longValue() == id)
				return true;
		}
		return false;
	}
}
