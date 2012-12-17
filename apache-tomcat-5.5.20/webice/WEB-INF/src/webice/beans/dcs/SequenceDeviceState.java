package webice.beans.dcs;

import java.util.StringTokenizer;
import webice.beans.WebiceLogger;


public class SequenceDeviceState
{
	public String user;
	public int cassetteIndex = -1;
	public CassetteInfo cassette[] = new CassetteInfo[4];
	
	public static SequenceDeviceState parse(String str)
		throws Exception
	{
		SequenceDeviceState ret = new SequenceDeviceState();
		
		int pos = str.indexOf(" ");
		if (pos < 0)
			throw new Exception("Cannot find user parameter in sequenceDeviceState string");
		
		ret.user = str.substring(0, pos);
		
		int pos1 = pos+1;
		pos = str.indexOf(" ", pos1);
		
		if (pos < 0)
			throw new Exception("Cannot find active cassette status in sequenceDeviceState string");
		
		ret.cassetteIndex = -1;
		try {
			ret.cassetteIndex = Integer.parseInt(str.substring(pos1, pos));
		} catch (NumberFormatException e) {
			WebiceLogger.error("Invalid cassette index in sequenceDeviceState string: " 
						+ str.substring(pos1, pos));
			throw new Exception("Invalid cassette index in sequenceDeviceState string: " 
						+ str.substring(pos1, pos));
		}	
		
		pos1 = str.indexOf("{", pos+1);
		pos= str.indexOf("}", pos1+1);
		
		StringTokenizer tok = new StringTokenizer(str.substring(pos1, pos).trim(), " {}");
		
		if (tok.countTokens() != 4) {
			WebiceLogger.error("SequenceDeviceState = '" + str + "'");
			WebiceLogger.error("SequenceDeviceState substr = '" + str.substring(pos1, pos) + "'");
			throw new Exception("Found info of " + tok.countTokens() + " cassettes (expected 4)");
		}
		
		ret.cassette[0] = CassetteInfo.parse(tok.nextToken());	
		ret.cassette[1] = CassetteInfo.parse(tok.nextToken());	
		ret.cassette[2] = CassetteInfo.parse(tok.nextToken());	
		ret.cassette[3] = CassetteInfo.parse(tok.nextToken());	
		
		return ret;
	}
	
	public String getCassettePosition()
	{
		return getCassettePosition(cassetteIndex);
	}
		
	static public String getCassettePosition(int i)
	{
		String cassettePosition = "unknown";
		switch (i) {
		    case 0:
			cassettePosition = "No cassette";
			break;
		    case 1:
			cassettePosition = "left";
			break;
		    case 2:
			cassettePosition = "middle";
			break;
		    case 3:
			cassettePosition = "right";
			break;
		}
		return cassettePosition;
	}	
}

