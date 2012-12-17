package sil.beans;

public class ImageData {

	private String jpeg = null;
	private String small = null;
	private String medium = null;
	private String large = null;
	
	public String getJpeg() {
		return jpeg;
	}
	public void setJpeg(String jpeg) {
		this.jpeg = jpeg;
	}
	public String getSmall() {
		return small;
	}
	public void setSmall(String small) {
		this.small = small;
	}
	public String getMedium() {
		return medium;
	}
	public void setMedium(String medium) {
		this.medium = medium;
	}
	public String getLarge() {
		return large;
	}
	public void setLarge(String large) {
		this.large = large;
	}
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((jpeg == null) ? 0 : jpeg.hashCode());
		result = prime * result + ((large == null) ? 0 : large.hashCode());
		result = prime * result + ((medium == null) ? 0 : medium.hashCode());
		result = prime * result + ((small == null) ? 0 : small.hashCode());
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
		final ImageData other = (ImageData) obj;
		if (jpeg == null) {
			if (other.jpeg != null)
				return false;
		} else if (!jpeg.equals(other.jpeg))
			return false;
		if (large == null) {
			if (other.large != null)
				return false;
		} else if (!large.equals(other.large))
			return false;
		if (medium == null) {
			if (other.medium != null)
				return false;
		} else if (!medium.equals(other.medium))
			return false;
		if (small == null) {
			if (other.small != null)
				return false;
		} else if (!small.equals(other.small))
			return false;
		return true;
	}


}
