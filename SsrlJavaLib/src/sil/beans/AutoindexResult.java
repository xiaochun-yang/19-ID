package sil.beans;

public class AutoindexResult {
	private String images = null;
	private double score = 0.0;
	private UnitCell unitCell = new UnitCell();
	private double mosaicity = 0.0;
	private double rmsd = 0.0;
	private String bravaisLattice = null;
	private double resolution = 0.0;
	private double isigma = 0.0;
	private String dir = null;
	private int bestSolution = -1;
	private String warning = null;
		
	public String getWarning() {
		return warning;
	}
	public void setWarning(String warning) {
		this.warning = warning;
	}
	public String getImages() {
		return images;
	}
	public void setImages(String images) {
		this.images = images;
	}
	public double getScore() {
		return score;
	}
	public void setScore(double score) {
		this.score = score;
	}
	public UnitCell getUnitCell() {
		return unitCell;
	}
	public void setUnitCell(UnitCell unitCell) {
		this.unitCell = unitCell;
	}
	public double getMosaicity() {
		return mosaicity;
	}
	public void setMosaicity(double mosaicity) {
		this.mosaicity = mosaicity;
	}
	public double getRmsd() {
		return rmsd;
	}
	public void setRmsd(double rmsd) {
		this.rmsd = rmsd;
	}
	public String getBravaisLattice() {
		return bravaisLattice;
	}
	public void setBravaisLattice(String bravaisLattice) {
		this.bravaisLattice = bravaisLattice;
	}
	public double getResolution() {
		return resolution;
	}
	public void setResolution(double resolution) {
		this.resolution = resolution;
	}
	public double getIsigma() {
		return isigma;
	}
	public void setIsigma(double sigma) {
		isigma = sigma;
	}
	public String getDir() {
		return dir;
	}
	public void setDir(String dir) {
		this.dir = dir;
	}

	public int getBestSolution() {
		return bestSolution;
	}
	public void setBestSolution(int bestSolution) {
		this.bestSolution = bestSolution;
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + bestSolution;
		result = prime * result
				+ ((bravaisLattice == null) ? 0 : bravaisLattice.hashCode());
		result = prime * result + ((dir == null) ? 0 : dir.hashCode());
		result = prime * result + ((images == null) ? 0 : images.hashCode());
		long temp;
		temp = Double.doubleToLongBits(isigma);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(mosaicity);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(resolution);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(rmsd);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(score);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		result = prime * result
				+ ((unitCell == null) ? 0 : unitCell.hashCode());
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
		final AutoindexResult other = (AutoindexResult) obj;
		if (bestSolution != other.bestSolution)
			return false;
		if (bravaisLattice == null) {
			if (other.bravaisLattice != null)
				return false;
		} else if (!bravaisLattice.equals(other.bravaisLattice))
			return false;
		if (dir == null) {
			if (other.dir != null)
				return false;
		} else if (!dir.equals(other.dir))
			return false;
		if (images == null) {
			if (other.images != null)
				return false;
		} else if (!images.equals(other.images))
			return false;
		if (Double.doubleToLongBits(isigma) != Double
				.doubleToLongBits(other.isigma))
			return false;
		if (Double.doubleToLongBits(mosaicity) != Double
				.doubleToLongBits(other.mosaicity))
			return false;
		if (Double.doubleToLongBits(resolution) != Double
				.doubleToLongBits(other.resolution))
			return false;
		if (Double.doubleToLongBits(rmsd) != Double
				.doubleToLongBits(other.rmsd))
			return false;
		if (Double.doubleToLongBits(score) != Double
				.doubleToLongBits(other.score))
			return false;
		if (unitCell == null) {
			if (other.unitCell != null)
				return false;
		} else if (!unitCell.equals(other.unitCell))
			return false;
		if (warning == null) {
			if (other.warning != null)
				return false;
		} else if (!warning.equals(other.warning))
			return false;
		return true;
	}
	// For testing only
	// To be removed
	public boolean equalsDebug(Object obj) {
		System.out.println("Comparing autoindex result");
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		final AutoindexResult other = (AutoindexResult) obj;
		if (bestSolution != other.bestSolution) {
			System.out.println("bestSolution not equal");
			return false;
		}
		System.out.println("Autoindex result NOT equal 0.3");
		if (bravaisLattice == null) {
			if (other.bravaisLattice != null)
				return false;
		} else if (!bravaisLattice.equals(other.bravaisLattice))
			return false;
		System.out.println("Autoindex result NOT equal 1");
		if (dir == null) {
			if (other.dir != null)
				return false;
		} else if (!dir.equals(other.dir))
			return false;
		if (images == null) {
			if (other.images != null)
				return false;
		} else if (!images.equals(other.images))
			return false;
		System.out.println("Autoindex result NOT equal 2");

		if (Double.doubleToLongBits(isigma) != Double
				.doubleToLongBits(other.isigma))
			return false;
		if (Double.doubleToLongBits(mosaicity) != Double
				.doubleToLongBits(other.mosaicity))
			return false;
		if (Double.doubleToLongBits(resolution) != Double
				.doubleToLongBits(other.resolution))
			return false;
		if (Double.doubleToLongBits(rmsd) != Double
				.doubleToLongBits(other.rmsd))
			return false;
		System.out.println("Autoindex result NOT equal 3");
		if (Double.doubleToLongBits(score) != Double
				.doubleToLongBits(other.score))
			return false;
		System.out.println("Autoindex result NOT equal 4");
		if (unitCell == null) {
			if (other.unitCell != null)
				return false;
		} else if (!unitCell.equals(other.unitCell))
			return false;
		System.out.println("Autoindex result NOT equal 5");
		if (warning == null) {
			if (other.warning != null)
				return false;
		} else if (!warning.equals(other.warning))
			return false;
		return true;
	}

}
