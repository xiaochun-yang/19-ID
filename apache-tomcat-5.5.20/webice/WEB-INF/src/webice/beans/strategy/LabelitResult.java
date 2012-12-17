package webice.beans.strategy;

import java.util.*;

public class LabelitResult
{
	public double beamCenterX = 0.0;
	public double beamCenterY = 0.0;
	public double distance = 0.0;
	public String mosaicity = "";

	public Vector indexResults = new Vector();
	public Vector integrationResults = new Vector();


	public LabelitResult()
	{
	}

	public void clear()
	{
		beamCenterX = 0.0;
		beamCenterY = 0.0;
		distance = 0.0;
		mosaicity = "";

		indexResults.clear();
		integrationResults.clear();
	}

	/**
	 * Parse labelit.out file
	 */
	public void load(String content)
		throws Exception
	{

		int pos1 = 0;
		int pos2 = 0;

		// Beam center X
		pos1 = content.indexOf("Beam center x");
		if (pos1 < 0)
			throw new Exception("Could not find text 'Beam center x'");

		pos2 = content.indexOf("mm", pos1);
		if (pos2 < 0)
			throw new Exception("Could not find text 'mm'");

		this.beamCenterX = Double.parseDouble(content.substring(pos1+13, pos2).trim());

		// Beam center X
		pos1 = content.indexOf("y", pos2+2);
		if (pos1 < 0)
			throw new Exception("Could not find text 'y'");

		pos2 = content.indexOf("mm", pos1);
		if (pos2 < 0)
			throw new Exception("Could not find text 'mm'");

		this.beamCenterY = Double.parseDouble(content.substring(pos1+1, pos2).trim());


		// Distance
		pos1 = content.indexOf("distance", pos2+2);
		if (pos1 < 0)
			throw new Exception("Could not find text 'distance'");

		pos2 = content.indexOf("mm", pos1);
		if (pos2 < 0)
			throw new Exception("Could not find text 'mm'");

		this.distance = Double.parseDouble(content.substring(pos1+8, pos2).trim());

		// mosaicity
		pos1 = content.indexOf(";", pos2+2);
		if (pos1 < 0)
			throw new Exception("Could not find text ';'");

		pos2 = content.indexOf(".\n", pos1);
		if (pos2 < 0)
			throw new Exception("Could not find text end of line");

		this.mosaicity = content.substring(pos1+1, pos2).trim();

		// table header
		pos1 = content.indexOf("Solution", pos2+1);
		if (pos1 < 0)
			throw new Exception("Could not find text 'Solution'");

		pos2 = content.indexOf("\n", pos1);
		if (pos2 < 0)
			throw new Exception("Could not find text end of line");

		StringTokenizer tok = new StringTokenizer(content.substring(pos1, pos2));

		Vector headers = new Vector();
		while (tok.hasMoreTokens()) {
			headers.add(tok.nextToken());
		}

		pos1 = pos2+1;


		pos2 = content.indexOf("MOSFLM Integration", pos1);
		if (pos2 < 0)
			throw new Exception("Could not find 'MOSFLM Integration'");

		tok = null;
		tok = new StringTokenizer(content.substring(pos1, pos2), "\n");

		// Each row
		String cols[] = new String[15];
		while (tok.hasMoreTokens()) {
			StringTokenizer tok2 = new StringTokenizer(tok.nextToken());
			int i = 0;
			// each col
			while (tok2.hasMoreTokens()) {
				if (i < 15)
					cols[i] = tok2.nextToken();
				++i;
			}
			if (i < 14)
				throw new Exception("Expect at least 14 columns for indexing results but got " + i);

			IndexResult res = new IndexResult();

			res.good = false;
			if (i == 15) {
				if (cols[0].equals(":)"))
					res.good = true;
				i = 1;
			} else {
				i = 0;
			}



			res.solutionNum = Integer.parseInt(cols[i]); ++i;
			res.metricFit = Double.parseDouble(cols[i]); ++i;
			res.metricFitUnit = cols[i]; ++i;
			res.rmsd = Double.parseDouble(cols[i]); ++i;
			res.numSpots = Integer.parseInt(cols[i]); ++i;
			res.crystalSystemName = cols[i]; ++i;
			res.crystalSystemSymbol = cols[i]; ++i;
			res.unitCellA = Double.parseDouble(cols[i]); ++i;
			res.unitCellB = Double.parseDouble(cols[i]); ++i;
			res.unitCellC = Double.parseDouble(cols[i]); ++i;
			res.unitCellAlpha = Double.parseDouble(cols[i]); ++i;
			res.unitCellBeta = Double.parseDouble(cols[i]); ++i;
			res.unitCellGamma = Double.parseDouble(cols[i]); ++i;
			res.volumn = Integer.parseInt(cols[i]); ++i;

			indexResults.add(res);
		}

		// Integration results
		pos1 = content.indexOf("Solution", pos2);
		if (pos1 < 0)
			throw new Exception("Could not find 'Solution'");

		pos2 = content.indexOf("\n", pos1);
		if (pos2 < 0)
			throw new Exception("Could not find end of line");

		tok = null;
		tok = new StringTokenizer(content.substring(pos2+1), "\n");

		cols = null;
		cols = new String[9];
		while (tok.hasMoreTokens()) {
			String str = tok.nextToken();
			StringTokenizer tok2 = new StringTokenizer(str);
			int i = 0;
			while (tok2.hasMoreTokens()) {
				cols[i] = tok2.nextToken();
				++i;
			}

			if (i < 8)
				throw new Exception("Expect at least 8 columns for integeration result but got " + i);

			IntegrationResult res = new IntegrationResult();


			res.good = false;
			if (i == 9) {
				if (cols[0].equals(":)"))
					res.good = true;

				i = 1;

			} else {
				i = 0;
			}

			res.solutionNum = Integer.parseInt(cols[i]); ++i;
			res.spacegroup = cols[i]; ++i;
			res.beamCenterX = Double.parseDouble(cols[i]); ++i;
			res.beamCenterY = Double.parseDouble(cols[i]); ++i;
			res.distance = Double.parseDouble(cols[i]); ++i;
			res.resolution = Double.parseDouble(cols[i]); ++i;
			res.mosaicity = Double.parseDouble(cols[i]); ++i;
			res.rms = Double.parseDouble(cols[i]); ++i;

			StringBuffer tmpName = new StringBuffer();
			StringBuffer tmpSymbol = new StringBuffer();
			getCrystalSystem(res.solutionNum, tmpName, tmpSymbol);

			res.crystalSystemName = tmpName.toString();
			res.crystalSystemSymbol = tmpSymbol.toString();

			integrationResults.add(res);



		}


	}


	/**
	 */
	private void getCrystalSystem(int solNum, StringBuffer name, StringBuffer symbol)
	{
		for (int i = 0; i < indexResults.size(); ++i) {
				IndexResult res = (IndexResult)indexResults.elementAt(i);
				if (res.solutionNum == solNum) {
					name.append(res.crystalSystemName);
					symbol.append(res.crystalSystemSymbol);
					return;
				}
		}
	}

	/**
	 * Find out if the given solution has been integrated.
	 */
	public boolean isSolutionIntegrated(int solNum)
	{
		for (int i = 0; i < integrationResults.size(); ++i) {
			IntegrationResult res = (IntegrationResult)integrationResults.elementAt(i);
			if (res.solutionNum == solNum) {
				return true;
			}
		}

		return false;

	}

}

