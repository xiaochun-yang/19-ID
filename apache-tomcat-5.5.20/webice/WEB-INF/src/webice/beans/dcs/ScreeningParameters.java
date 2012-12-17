package webice.beans.dcs;

import java.util.*;

public class ScreeningParameters
{
	public String step[] = null;
	
	public int detectorMode = 0;
	public String directory = "";
	public double distance = 0.0;
	public double beamStop = 0.0;
	
	public ScreeningParameters(String content)
		throws Exception
	{
		StringTokenizer tok = new StringTokenizer(content, " ");
		
		if (tok.countTokens() != 18)
			throw new Exception("Expect 18 items in screeningParameters string but got " +
				tok.countTokens());
				
		step = new String[14];
		for (int i = 0; i < 14; ++i) {
			step[i] = tok.nextToken();
		}
		detectorMode = Integer.parseInt(tok.nextToken());
		directory = tok.nextToken();
		distance = Double.parseDouble(tok.nextToken());
		beamStop = Double.parseDouble(tok.nextToken());
	}
	
}

