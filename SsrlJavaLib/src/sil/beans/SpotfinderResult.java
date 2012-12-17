package sil.beans;

public class SpotfinderResult {

	private double integratedIntensity;
	private int numOverloadSpots;
	private double score;
	private double resolution;
	private int numIceRings;
	private int numSpots;
	private int numBraggSpots;
	private double spotShape;
	private double quality;
	private double diffractionStrength;
	private String dir;
	private String warning;
	private int cellEdge;
	
	public double getIntegratedIntensity() {
		return integratedIntensity;
	}
	public void setIntegratedIntensity(double integratedIntensity) {
		this.integratedIntensity = integratedIntensity;
	}
	public int getNumOverloadSpots() {
		return numOverloadSpots;
	}
	public void setNumOverloadSpots(int numOverloadSpots) {
		this.numOverloadSpots = numOverloadSpots;
	}
	public double getScore() {
		return score;
	}
	public void setScore(double score) {
		this.score = score;
	}
	public double getResolution() {
		return resolution;
	}
	public void setResolution(double resolution) {
		this.resolution = resolution;
	}
	public int getNumSpots() {
		return numSpots;
	}
	public void setNumSpots(int numSpots) {
		this.numSpots = numSpots;
	}
	public double getQuality() {
		return quality;
	}
	public void setQuality(double quality) {
		this.quality = quality;
	}
	public double getDiffractionStrength() {
		return diffractionStrength;
	}
	public void setDiffractionStrength(double diffractionStrength) {
		this.diffractionStrength = diffractionStrength;
	}
	public String getDir() {
		return dir;
	}
	public void setDir(String dir) {
		this.dir = dir;
	}
	public String getWarning() {
		return warning;
	}
	public void setWarning(String warning) {
		this.warning = warning;
	}
	public int getNumIceRings() {
		return numIceRings;
	}
	public void setNumIceRings(int numIceRings) {
		this.numIceRings = numIceRings;
	}
	public double getSpotShape() {
		return spotShape;
	}
	public void setSpotShape(double spotShape) {
		this.spotShape = spotShape;
	}
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		long temp;
		temp = Double.doubleToLongBits(diffractionStrength);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		result = prime * result + ((dir == null) ? 0 : dir.hashCode());
		temp = Double.doubleToLongBits(integratedIntensity);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		result = prime * result + numIceRings;
		result = prime * result + numOverloadSpots;
		result = prime * result + numSpots;
		temp = Double.doubleToLongBits(quality);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(resolution);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(score);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(spotShape);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		result = prime * result + ((warning == null) ? 0 : warning.hashCode());
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
		final SpotfinderResult other = (SpotfinderResult) obj;
		if (Double.doubleToLongBits(diffractionStrength) != Double
				.doubleToLongBits(other.diffractionStrength))
			return false;
		if (dir == null) {
			if (other.dir != null)
				return false;
		} else if (!dir.equals(other.dir))
			return false;
		if (Double.doubleToLongBits(integratedIntensity) != Double
				.doubleToLongBits(other.integratedIntensity))
			return false;
		if (numIceRings != other.numIceRings)
			return false;
		if (numOverloadSpots != other.numOverloadSpots)
			return false;
		if (numSpots != other.numSpots)
			return false;
		if (Double.doubleToLongBits(quality) != Double
				.doubleToLongBits(other.quality))
			return false;
		if (Double.doubleToLongBits(resolution) != Double
				.doubleToLongBits(other.resolution))
			return false;
		if (Double.doubleToLongBits(score) != Double
				.doubleToLongBits(other.score))
			return false;
		if (Double.doubleToLongBits(spotShape) != Double
				.doubleToLongBits(other.spotShape))
			return false;
		if (warning == null) {
			if (other.warning != null)
				return false;
		} else if (!warning.equals(other.warning))
			return false;
		return true;
	}
	public int getNumBraggSpots() {
		return numBraggSpots;
	}
	public void setNumBraggSpots(int numBraggSpots) {
		this.numBraggSpots = numBraggSpots;
	}
	public int getCellEdge() {
		return cellEdge;
	}
	public void setCellEdge(int cellEdge) {
		this.cellEdge = cellEdge;
	}


}
