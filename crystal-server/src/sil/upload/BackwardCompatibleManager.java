package sil.upload;

public class BackwardCompatibleManager {
	private boolean addContainerId = false;
	private boolean addContainerType = false;
	
	public boolean isAddContainerId() {
		return addContainerId;
	}

	public void setAddContainerId(boolean addContainerId) {
		this.addContainerId = addContainerId;
	}

	public boolean isAddContainerType() {
		return addContainerType;
	}

	public void setAddContainerType(boolean addContainerType) {
		this.addContainerType = addContainerType;
	}

	public void makeBackwardCompatible(RawData rawData, UploadData uploadData) throws Exception
	{
		// 6.1 For backward compatibility 
		// Add containerType column if it does not exist.
		if (isAddContainerId()) {
			if (!rawData.hasColumnName("containerId")) {
				rawData.addColumn("containerId", "UNKNOWN");
			}
		}

		// 6.2 For backward compatibility 
		// Add containerType column if it does not exist.
		if (isAddContainerType()) {
			if (!rawData.hasColumnName("containerType")) {
				rawData.addColumn("containerType", uploadData.getContainerType());
			}
		}
		
		// Select all crystals
		if (!rawData.hasColumnName("selected")) {
			rawData.addColumn("selected", "true");
		}
		
	}

}
