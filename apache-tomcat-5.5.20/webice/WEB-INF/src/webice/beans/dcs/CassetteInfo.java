package webice.beans.dcs;

import java.util.StringTokenizer;


public class CassetteInfo
{
	boolean undefined = true;
	public String xlsFile;
	public String owner;
	public String containerId;
	public String silId;
	
	public static CassetteInfo parse(String str)
		throws Exception
	{
		CassetteInfo info = new CassetteInfo();
		
		if (str.equals("undefined")) {
			info.undefined = true;
		} else {
			info.undefined = false;
			StringTokenizer tok1 = new StringTokenizer(str, "(|)");
			if (tok1.countTokens() == 4) {
				info.xlsFile = tok1.nextToken();
				info.owner = tok1.nextToken();
				info.containerId = tok1.nextToken();
				info.silId = tok1.nextToken();
			}
		}
		
		return info;
	}
	
}
