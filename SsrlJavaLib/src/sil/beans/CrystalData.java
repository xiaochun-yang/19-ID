package sil.beans;

public class CrystalData {
	
	private String protein = null;
	private String comment = null;
	private String freezingCond = null;
	private String crystalCond = null;
	private String metal = null;
	private String priority = null;
	private String crystalUrl = null;
	private String proteinUrl = null;
	private String directory = null;
	private String person = null;
	private String move = null;
	
	public String getProtein() {
		return protein;
	}
	public void setProtein(String protein) {
		this.protein = protein;
	}
	public String getComment() {
		return comment;
	}
	public void setComment(String comment) {
		this.comment = comment;
	}
	public String getFreezingCond() {
		return freezingCond;
	}
	public void setFreezingCond(String freezingCond) {
		this.freezingCond = freezingCond;
	}
	public String getCrystalCond() {
		return crystalCond;
	}
	public void setCrystalCond(String crystalCond) {
		this.crystalCond = crystalCond;
	}
	public String getMetal() {
		return metal;
	}
	public void setMetal(String metal) {
		this.metal = metal;
	}
	public String getPriority() {
		return priority;
	}
	public void setPriority(String priority) {
		this.priority = priority;
	}
	public String getCrystalUrl() {
		return crystalUrl;
	}
	public void setCrystalUrl(String crystalUrl) {
		this.crystalUrl = crystalUrl;
	}
	public String getProteinUrl() {
		return proteinUrl;
	}
	public void setProteinURL(String proteinUrl) {
		this.proteinUrl = proteinUrl;
	}
	public String getDirectory() {
		return directory;
	}
	public void setDirectory(String directory) {
		this.directory = directory;
	}
	public String getPerson() {
		return person;
	}
	public void setPerson(String person) {
		this.person = person;
	}
	public String getMove() {
		return move;
	}
	public void setMove(String move) {
		this.move = move;
	}
	public void setProteinUrl(String proteinUrl) {
		this.proteinUrl = proteinUrl;
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((comment == null) ? 0 : comment.hashCode());
		result = prime * result
				+ ((crystalCond == null) ? 0 : crystalCond.hashCode());
		result = prime * result
				+ ((crystalUrl == null) ? 0 : crystalUrl.hashCode());
		result = prime * result
				+ ((directory == null) ? 0 : directory.hashCode());
		result = prime * result
				+ ((freezingCond == null) ? 0 : freezingCond.hashCode());
		result = prime * result + ((metal == null) ? 0 : metal.hashCode());
		result = prime * result + ((move == null) ? 0 : move.hashCode());
		result = prime * result + ((person == null) ? 0 : person.hashCode());
		result = prime * result
				+ ((priority == null) ? 0 : priority.hashCode());
		result = prime * result + ((protein == null) ? 0 : protein.hashCode());
		result = prime * result
				+ ((proteinUrl == null) ? 0 : proteinUrl.hashCode());
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
		final CrystalData other = (CrystalData) obj;
		if (comment == null) {
			if (other.comment != null)
				return false;
		} else if (!comment.equals(other.comment))
			return false;
		if (crystalCond == null) {
			if (other.crystalCond != null)
				return false;
		} else if (!crystalCond.equals(other.crystalCond))
			return false;
		if (crystalUrl == null) {
			if (other.crystalUrl != null)
				return false;
		} else if (!crystalUrl.equals(other.crystalUrl))
			return false;
		if (directory == null) {
			if (other.directory != null)
				return false;
		} else if (!directory.equals(other.directory))
			return false;
		if (freezingCond == null) {
			if (other.freezingCond != null)
				return false;
		} else if (!freezingCond.equals(other.freezingCond))
			return false;
		if (metal == null) {
			if (other.metal != null)
				return false;
		} else if (!metal.equals(other.metal))
			return false;
		if (move == null) {
			if (other.move != null)
				return false;
		} else if (!move.equals(other.move))
			return false;
		if (person == null) {
			if (other.person != null)
				return false;
		} else if (!person.equals(other.person))
			return false;
		if (priority == null) {
			if (other.priority != null)
				return false;
		} else if (!priority.equals(other.priority))
			return false;
		if (protein == null) {
			if (other.protein != null)
				return false;
		} else if (!protein.equals(other.protein))
			return false;
		if (proteinUrl == null) {
			if (other.proteinUrl != null)
				return false;
		} else if (!proteinUrl.equals(other.proteinUrl))
			return false;
		return true;
	}

}
