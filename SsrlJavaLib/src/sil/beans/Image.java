package sil.beans;

import java.io.File;

public class Image
{
	// Image identifiers
	private String name = null;
	private String dir = null;
	private String group = null;
	private int order = 0;
	
	protected ImageResult result = new ImageResult();
	protected ImageData data = new ImageData();
		
	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDir() {
		return dir;
	}

	public void setDir(String dir) {
		this.dir = dir;
	}

	public String getGroup() {
		return group;
	}

	public void setGroup(String group) {
		this.group = group;
	}

	public ImageResult getResult() {
		return result;
	}

	public void setResult(ImageResult result) {
		if (result != null)
			this.result = result;
	}

	public ImageData getData() {
		return data;
	}

	public void setData(ImageData data) {
		if (data != null)
			this.data = data;
	}
	
	public void setPath()
	{
		
	}
	
	public void setPath(String path) {
		if (path == null)
			return;
		int pos = path.lastIndexOf(File.separator);
		if (pos < 0) {
			setName(path);
		} else {
			setDir(path.substring(0, pos));
			if (pos < path.length()-1)
				setName(path.substring(pos+1));
		}
	}
	
	public String getPath() {
		if ((getDir() != null) && (getDir().length() > 0))
			return getDir() + File.separator + getName();
		return getName();
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((data == null) ? 0 : data.hashCode());
		result = prime * result + ((dir == null) ? 0 : dir.hashCode());
		result = prime * result + ((group == null) ? 0 : group.hashCode());
		result = prime * result + ((name == null) ? 0 : name.hashCode());
		result = prime * result
				+ ((this.result == null) ? 0 : this.result.hashCode());
		return result;
	}

	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		final Image other = (Image) obj;
		if (data == null) {
			if (other.data != null)
				return false;
		} else if (!data.equals(other.data))
			return false;
		if (dir == null) {
			if (other.dir != null)
				return false;
		} else if (!dir.equals(other.dir))
			return false;
		if (group == null) {
			if (other.group != null)
				return false;
		} else if (!group.equals(other.group))
			return false;
		if (name == null) {
			if (other.name != null)
				return false;
		} else if (!name.equals(other.name))
			return false;
		if (result == null) {
			if (other.result != null)
				return false;
		} else if (!result.equals(other.result))
			return false;
		return true;
	}

	public boolean equalsDebug(Object obj) {
		System.out.println("comparing 2 images");
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass()) {
			System.out.println("image class NOT equal");
			return false;
		}
		final Image other = (Image) obj;
		if (data == null) {
			if (other.data != null)
				return false;
		} else if (!data.equals(other.data)) {
			System.out.println("image.data NOT equal");
			return false;
		}
		if (dir == null) {
			if (other.dir != null)
				return false;
		} else if (!dir.equals(other.dir)) {
			System.out.println("image.dir NOT equal: left = '" 
					+ dir + "' right = '" + other.dir + "'");
			return false;
		}
		if (group == null) {
			if (other.group != null)
				return false;
		} else if (!group.equals(other.group)) {
			System.out.println("image.group NOT equal");
			return false;
		}
		if (name == null) {
			if (other.name != null)
				return false;
		} else if (!name.equals(other.name)) {
			System.out.println("image.name NOT equal");
			return false;
		}
		if (result == null) {
			if (other.result != null)
				return false;
		} else if (!result.equals(other.result)) {
			System.out.println("image.result NOT equal");
			return false;
		}
		return true;
	}

	public int getOrder() {
		return order;
	}

	public void setOrder(int order) {
		this.order = order;
	}

}

