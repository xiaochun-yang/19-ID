package sil.beans;

public class ImageResult {
	
	private SpotfinderResult spotfinderResult = new SpotfinderResult();

	public SpotfinderResult getSpotfinderResult() {
		return spotfinderResult;
	}

	public void setSpotfinderResult(SpotfinderResult spotfinderResult) {
		if (spotfinderResult != null)
			this.spotfinderResult = spotfinderResult;
	}
	
	public boolean equals(ImageResult result)
	{
		if (!getSpotfinderResult().equals(result.getSpotfinderResult()))
			return false;
		return true;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime
				* result
				+ ((spotfinderResult == null) ? 0 : spotfinderResult.hashCode());
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
		final ImageResult other = (ImageResult) obj;
		if (spotfinderResult == null) {
			if (other.spotfinderResult != null)
				return false;
		} else if (!spotfinderResult.equals(other.spotfinderResult))
			return false;
		return true;
	}
}
