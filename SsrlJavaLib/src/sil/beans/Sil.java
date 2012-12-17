package sil.beans;

import java.util.TreeMap;
import java.util.Map;

/**************************************************
 *
 * SilData
 *
 **************************************************/
public class Sil
{
	private int id = -1;
	private String version = "2.0";
	private SilInfo info = new SilInfo();
	
	// Crystal listed by port
	private Map<Long, Crystal> crystals = new TreeMap<Long, Crystal>();

	public int getId()
	{
		return id;
	}
	
	public void setId(int id)
	{
		this.id = id;
	}
	
	public void setVersion(String version)
	{
		this.version = version;
	}

	public String getVersion()
	{
		return version;
	}
	
	public Map<Long, Crystal> getCrystals() {
		return crystals;
	}
	
	public void setCrystals(Map<Long, Crystal> crystals) {
		if (crystals != null)
			this.crystals = crystals;
	}


	public boolean equalsDebug(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		final Sil other = (Sil) obj;
		if (crystals == null) {
			if (other.crystals != null)
				return false;
		} else if (crystals.size() != other.crystals.size()) {
			System.out.println("crystals size NOT equal");
			return false;
		} else if (!crystals.equals(other.crystals)) {
			System.out.println("crystals NOT equal");
			return false;
		}
		if (version == null) {
			if (other.version != null)
				return false;
		} else if (!version.equals(other.version))
			return false;
		return true;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((crystals == null) ? 0 : crystals.hashCode());
		result = prime * result + id;
		result = prime * result + ((info == null) ? 0 : info.hashCode());
		result = prime * result + ((version == null) ? 0 : version.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		final Sil other = (Sil) obj;
		if (crystals == null) {
			if (other.crystals != null)
				return false;
		} else if (!crystals.equals(other.crystals))
			return false;
		if (id != other.id)
			return false;
		if (info == null) {
			if (other.info != null)
				return false;
		} else if (!info.equals(other.info))
			return false;
		if (version == null) {
			if (other.version != null)
				return false;
		} else if (!version.equals(other.version))
			return false;
		return true;
	}

	public SilInfo getInfo() {
		return info;
	}

	public void setInfo(SilInfo info) {
		this.info = info;
	}
	
}

