package sil.beans;

import java.util.Hashtable;
import java.util.Iterator;
import java.util.Map;

public class Crystal
{	
	private int row = -1;
	private int excelRow = -1;
	private boolean selected = false;
	private boolean selectedForQueue = false;
	
	private long uniqueId = 0;
	private int eventId = 0;
	
	// Basic data
	private String port = null;
	private String crystalId = null;
	private String containerId = null;
	private String containerType = null;
	
	private Map<String, Image> images = new Hashtable<String, Image>();	
	private CrystalResult result = new CrystalResult();
	private CrystalData data = new CrystalData();
	
	// Used by BeanUtils.copyProperties to copy
	// properties of 2 crystals.
	// Can copy only if getName() of the 2 crystals
	// return the same string.
	public String getName()
	{
		return getCrystalId();
	}
	
	public void setName(String name)
	{
		setCrystalId(name);
	}
			
	public String getPort() {
		return port;
	}

	public void setPort(String port) {
		this.port = port;
	}

	public String getCrystalId() {
		return crystalId;
	}

	public void setCrystalId(String crystalId) {
		this.crystalId = crystalId;
	}

	public String getContainerId() {
		return containerId;
	}

	public void setContainerId(String containerId) {
		this.containerId = containerId;
	}
	
	public int getRow()
	{
		return row;
	}
	
	public void setRow(int r)
	{
		row = r;
	}

	public int getExcelRow()
	{
		return excelRow;
	}
	
	public void setExcelRow(int r)
	{
		excelRow = r;
	}

	public boolean getSelected()
	{
		return selected;
	}

	public void setSelected(boolean l)
	{
		selected = l;
	}

	public void setSelected(String n)
	{
		if (n == null)
			return;

		if (n.equals("1"))
			selected = true;
		else if (n.equals("0"))
			selected = false;
		else if (n.equalsIgnoreCase("true"))
			selected = true;
		else if (n.equalsIgnoreCase("false"))
			selected = false;
	}

	public CrystalResult getResult() {
		return result;
	}

	public void setResult(CrystalResult result) {
		if (result != null)
			this.result = result;
	}

	public CrystalData getData() {
		return data;
	}

	public void setData(CrystalData data) {
		if (data != null)
			this.data = data;
	}

	public Map<String, Image> getImages() {
		return images;
	}

	public void setImages(Map<String, Image> images) {
		this.images = images;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((containerId == null) ? 0 : containerId.hashCode());
		result = prime * result
				+ ((containerType == null) ? 0 : containerType.hashCode());
		result = prime * result
				+ ((crystalId == null) ? 0 : crystalId.hashCode());
		result = prime * result + ((data == null) ? 0 : data.hashCode());
		result = prime * result + eventId;
		result = prime * result + excelRow;
		result = prime * result + ((images == null) ? 0 : images.hashCode());
		result = prime * result + ((port == null) ? 0 : port.hashCode());
		result = prime * result
				+ ((this.result == null) ? 0 : this.result.hashCode());
		result = prime * result + row;
		result = prime * result + (selected ? 1231 : 1237);
		result = prime * result + (selectedForQueue ? 1231 : 1237);
		result = prime * result + (int) (uniqueId ^ (uniqueId >>> 32));
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
		final Crystal other = (Crystal) obj;
		if (containerId == null) {
			if (other.containerId != null)
				return false;
		} else if (!containerId.equals(other.containerId))
			return false;
		if (containerType == null) {
			if (other.containerType != null)
				return false;
		} else if (!containerType.equals(other.containerType))
			return false;
		if (crystalId == null) {
			if (other.crystalId != null)
				return false;
		} else if (!crystalId.equals(other.crystalId))
			return false;
		if (data == null) {
			if (other.data != null)
				return false;
		} else if (!data.equals(other.data))
			return false;
		if (eventId != other.eventId)
			return false;
		if (excelRow != other.excelRow)
			return false;
		if (images == null) {
			if (other.images != null)
				return false;
		} else if (!images.equals(other.images))
			return false;
		if (port == null) {
			if (other.port != null)
				return false;
		} else if (!port.equals(other.port))
			return false;
		if (result == null) {
			if (other.result != null)
				return false;
		} else if (!result.equals(other.result))
			return false;
		if (row != other.row)
			return false;
		if (selected != other.selected)
			return false;
		if (selectedForQueue != other.selectedForQueue)
			return false;
		if (uniqueId != other.uniqueId)
			return false;
		return true;
	}

	public boolean equalsDebug(Object obj) {
		if (this == obj)
			return true;
		if (obj == null) {
			System.out.println("other crystal is null");
			return false;
		}
		if (getClass() != obj.getClass()) {
			System.out.println("different crystal class");
			return false;
		}
		final Crystal other = (Crystal) obj;
		if (containerId == null) {
			System.out.println("crystal.containerId is null");
			if (other.containerId != null) {
				System.out.println("other crystal.containerId is NOT null");
				return false;
			}
		} else if (!containerId.equals(other.containerId)) {
			System.out.println("crystal.containerId NOT equal");
			return false;
		}
		if (crystalId == null) {
			if (other.crystalId != null)
				return false;
		} else if (!crystalId.equals(other.crystalId)) {
			System.out.println("crystal.crystalId NOT equal");
			return false;
		}
		if (data == null) {
			if (other.data != null)
				return false;
		} else if (!data.equals(other.data)) {
			System.out.println("crystal.data NOT equal");
			return false;
		}
		if (excelRow != other.excelRow)
			return false;
		if (images == null) {
			if (other.images != null)
				return false;
		} else if (images.size() != other.images.size()) {
			System.out.println("images.size NOT equal");
			return false;
		} else if (!images.equals(other.images)) {
			if (other.images == null)
				System.out.println("other.images is null");
			Iterator<String> it = images.keySet().iterator();
			while (it.hasNext()) {
				String key = it.next();
				Image image = images.get(key);
				Image otherImage = other.images.get(key);
				if (otherImage == null) {
					System.out.println("other crystal does not have image index " + key + " name = " + image.getPath());
					return false;
				}
				if (!image.equals(otherImage)) {
					System.out.println("image index " + key + " are NOT equal");
					return false;
				}
			}
			System.out.println("crystal.images NOT equal");
			return false;
		}
		if (port == null) {
			if (other.port != null)
				return false;
		} else if (!port.equals(other.port))
			return false;
		if (result == null) {
			if (other.result != null)
				return false;
		} else if (!result.equals(other.result)) {
			System.out.println("crystal.result NOT equal");
			return false;
		}
		if (row != other.row)
			return false;
		if (selected != other.selected)
			return false;
		if (uniqueId != other.uniqueId) {
			System.out.println("crystal.uniqueId NOT equal");
			return false;
		}
		return true;
	}

	public String getContainerType() {
		return containerType;
	}

	public void setContainerType(String containerType) {
		this.containerType = containerType;
	}

	public long getUniqueId() {
		return uniqueId;
	}

	public void setUniqueId(long uniqueId) {
		this.uniqueId = uniqueId;
	}

	public int getEventId() {
		return eventId;
	}

	public void setEventId(int eventId) {
		this.eventId = eventId;
	}

	public boolean isSelectedForQueue() {
		return selectedForQueue;
	}

	public void setSelectedForQueue(boolean selectedForQueue) {
		this.selectedForQueue = selectedForQueue;
	}

}


