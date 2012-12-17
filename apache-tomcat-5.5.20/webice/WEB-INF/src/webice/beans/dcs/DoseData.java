package webice.beans.dcs;

import java.util.*;

public class DoseData
{
	public int standardDoseTime = 0;
	public double standardDose = 0.0;
	public int curDoseTime = 0;
	public double curDose = 0.0;
	
	public DoseData(String content)
		throws Exception
	{
		StringTokenizer tok = new StringTokenizer(content, " ");
		
		if (tok.countTokens() != 4)
			throw new Exception("Expect 4 items in dose_data string but got " +
				tok.countTokens());
				
		standardDoseTime = Integer.parseInt(tok.nextToken());
		standardDose = Double.parseDouble(tok.nextToken());
		curDoseTime = Integer.parseInt(tok.nextToken());
		curDose = Double.parseDouble(tok.nextToken());
	}
	
	public double getDoseFactor()
		throws Exception
	{
		if (curDose == 0.0)
			throw new Exception("Current ion chamber reading is 0");

		return standardDose/curDose;
	}
	
}

