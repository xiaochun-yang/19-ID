package sil.beans;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

public class CrystalResult {

	private int reorientable;
	private String reorientInfo;
	private String reorientPhi;
	
	private AutoindexResult autoindexResult = new AutoindexResult();
	private DcsStrategyResult dcsStrategyResult = new DcsStrategyResult();
	
	private List<RunDefinition> runs = new Vector<RunDefinition>();
	private List<RepositionData> repositions = new ArrayList<RepositionData>();

	public AutoindexResult getAutoindexResult() {
		return autoindexResult;
	}

	public void setAutoindexResult(AutoindexResult autoindexResult) {
		if (autoindexResult != null)
			this.autoindexResult = autoindexResult;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((autoindexResult == null) ? 0 : autoindexResult.hashCode());
		result = prime
				* result
				+ ((dcsStrategyResult == null) ? 0 : dcsStrategyResult
						.hashCode());
		result = prime * result
				+ ((reorientInfo == null) ? 0 : reorientInfo.hashCode());
		result = prime * result
				+ ((reorientPhi == null) ? 0 : reorientPhi.hashCode());
		result = prime * result + reorientable;
		result = prime * result
				+ ((repositions == null) ? 0 : repositions.hashCode());
		result = prime * result + ((runs == null) ? 0 : runs.hashCode());
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
		final CrystalResult other = (CrystalResult) obj;
		if (autoindexResult == null) {
			if (other.autoindexResult != null)
				return false;
		} else if (!autoindexResult.equals(other.autoindexResult))
			return false;
		if (dcsStrategyResult == null) {
			if (other.dcsStrategyResult != null)
				return false;
		} else if (!dcsStrategyResult.equals(other.dcsStrategyResult))
			return false;
		if (reorientInfo == null) {
			if (other.reorientInfo != null)
				return false;
		} else if (!reorientInfo.equals(other.reorientInfo))
			return false;
		if (reorientPhi == null) {
			if (other.reorientPhi != null)
				return false;
		} else if (!reorientPhi.equals(other.reorientPhi))
			return false;
		if (reorientable != other.reorientable)
			return false;
		if (repositions == null) {
			if (other.repositions != null)
				return false;
		} else if (!repositions.equals(other.repositions))
			return false;
		if (runs == null) {
			if (other.runs != null)
				return false;
		} else if (!runs.equals(other.runs))
			return false;
		return true;
	}

	public int getReorientable() {
		return reorientable;
	}

	public void setReorientable(int reorientable) {
		this.reorientable = reorientable;
	}

	public String getReorientInfo() {
		return reorientInfo;
	}

	public void setReorientInfo(String reorientInfo) {
		this.reorientInfo = reorientInfo;
	}

	public String getReorientPhi() {
		return reorientPhi;
	}

	public void setReorientPhi(String reorientPhi) {
		this.reorientPhi = reorientPhi;
	}

	public DcsStrategyResult getDcsStrategyResult() {
		return dcsStrategyResult;
	}

	public void setDcsStrategyResult(DcsStrategyResult dcsStrategyResult) {
		this.dcsStrategyResult = dcsStrategyResult;
	}

	public List<RepositionData> getRepositions() {
		return repositions;
	}

	public void setRepositions(List<RepositionData> repositions) {
		this.repositions = repositions;
	}

	public List<RunDefinition> getRuns() {
		return runs;
	}

	public void setRuns(List<RunDefinition> runs) {
		this.runs = runs;
	}

}
