package webice.beans.dcs;

import java.util.*;

/**
*/
public class RunExtra
{
	// Output: to be set by DCSS
	public String resultSp = "";
	public String resultStrategyFile = "";
	
	// webice run name
	public String runName = "";
	// 0=unknown,1=left, 2=middle, 3=right
	public int cassetteIndex = 0;
	// Port ID such as A1, A8
	public String crystalPort = "";

	// Laue group
	public String laueGroup = "";
	// Unit cell
	public double cellA = 0.0;
	public double cellB = 0.0;
	public double cellC = 0.0;
	public double cellAlpha = 0.0;
	public double cellBeta = 0.0;
	public double cellGamma = 0.0;
	
	// experiment type: Monochromatic, Anomalouse, MAD, SAD
	public String expType = "";
	
	// Where to put autoindex result
	public String workDir = "";
	
	public MadScan mad = new MadScan();
	
	// Parameters to be passed to the crystal-analsysis
	// if expType == MAD or SAD
	public double inflectionEn = 0.0;
	public double peakEn = 0.0;
	public double remoteEn = 0.0;
	
	public int numHeavyAtoms = 0;
	public int numResidues = 0;
	
	public String strategyMethod = "best";
	
	/**
	 * Run definition as in dcs message format
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append("{");
		buf.append("{}"); // resultSp
		buf.append(" {}"); // resultStrategyFile
		buf.append(" ");
		if ((runName == null) || (runName.length() == 0))
			buf.append("{}");
		else
			buf.append(runName); // runName
		
		// cassette index and port
		buf.append(" ");
		if (cassetteIndex == 1)
			buf.append("l");
		else if (cassetteIndex == 2)
			buf.append("m");
		else if (cassetteIndex == 3)
			buf.append("r");
		else
			buf.append("{}");
		buf.append(crystalPort);
		
		// laueGroup
		if (laueGroup != null)
			buf.append(" {" + laueGroup + "}");
		else
			buf.append(" {}");
			
		// Unit cell
		if (hasUnitCell()) {
			buf.append(" {");
			buf.append(String.valueOf(cellA));
			buf.append(",");
			buf.append(String.valueOf(cellB));
			buf.append(",");
			buf.append(String.valueOf(cellC));
			buf.append(",");
			buf.append(String.valueOf(cellAlpha));
			buf.append(",");
			buf.append(String.valueOf(cellBeta));
			buf.append(",");
			buf.append(String.valueOf(cellGamma));
			buf.append("}");
		} else {
			buf.append(" {}");
		}
		
		//expType	
		if (expType != null)
			buf.append(" {" + expType + "}");
		else
			buf.append(" {}");
			
		if (workDir.length() == 0)
			buf.append(" {}");
		else
			buf.append(" " + workDir);
			
		buf.append(" ");
		buf.append(mad.toString());
		
		buf.append(" {");
		if ((expType != null) && (expType.equals("MAD") || expType.equals("SAD"))) {
			Edge e = mad.getEdge();
			if (e.name.length() > 0)
				buf.append(mad.getEdge().name);
			else
				buf.append("{}");
			buf.append(" " + String.valueOf(inflectionEn));
			buf.append(" " + String.valueOf(peakEn));
			buf.append(" " + String.valueOf(remoteEn));			
		} else {
			buf.append(" {} 0.0 0.0 0.0");
		}
		buf.append("}");
		
		buf.append(" " + String.valueOf(numHeavyAtoms));
		buf.append(" " + String.valueOf(numResidues));
		buf.append(" " + strategyMethod);		
			
		buf.append("}");
		
		
		return buf.toString();
	}
	
	private boolean hasUnitCell()
	{
		if ((laueGroup != null) && (laueGroup.length() > 0) 
			&& (cellA > 0.0) && (cellB > 0.0) && (cellC > 0.0)
			&& (cellAlpha > 0.0) && (cellBeta > 0.0) && (cellGamma > 0.0))
			return true;
			
		return false;
	}
	
	public MadScan getMadScan()
	{
		return mad;
	}
	
}

