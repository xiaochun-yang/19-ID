package webice.beans.dcs;

import java.util.*;

public class Runs extends Device
{
	public int count = 0;
	public int current = 0;
	public boolean doseMode = false;
	
	/**
	 * "<num runs> <cur run> <active> <dose mode>"
	 */
	public Runs(String n, String c)
		throws Exception
	{
		super(n, DeviceType.RUNS);

		StringTokenizer tok = new StringTokenizer(c);
		if (tok.countTokens() < 2)
			throw new Exception("Wrong number of params for Runs device: expecting at least 2 but got " + tok.countTokens());
			
		count = Integer.parseInt(tok.nextToken());
		current = Integer.parseInt(tok.nextToken());
		doseMode = Integer.parseInt(tok.nextToken()) == 1;
	}
	
	
	public static Runs createDevice(Vector params)
		throws Exception
	{
		// Must have 2 lines of params
		int which_line = 3;
		if (params.size() != 6)
			throw new Exception("Cannot create Runs device: expecting 6 lines but got " + params.size());
		
		String tmp = (String)params.elementAt(1);
		int deviceType = 0;
		try {	
			deviceType = Integer.parseInt(tmp);
		} catch (Exception e) {
		} 
	
		if (deviceType != 13)
			throw new Exception("Wrong device type for Run: expecting type 13 but got " + tmp);

		StringTokenizer tokenizer = new StringTokenizer((String)params.elementAt(2));
		if (tokenizer.countTokens() != 2)
			throw new Exception("Missing hardwareHost or hardwareName for Runs device");

		return new Runs((String)params.elementAt(0), (String)params.elementAt(5));
	}

}

