package cts;

import java.util.Properties;
/**
 * Factory class
 */
public class CassetteDBFactory
{
	// Create a new CassetteDB from oracle or file 
	// implementation.
	public static CassetteDB getCassetteDB(String type, Properties prop)
		throws Exception
	{
		if ((type != null) && type.equals("oracle")) {
			return CassetteDBOracle.getCassetteDB(prop);
		}
	
		return CassetteDBSimple.getCassetteDB(prop);
	}
	
	// Create a new CassetteDB from oracle or file 
	// implementation.
	public static CassetteDB getCassetteDB(Properties prop)
		throws Exception
	{
		String type = (String)prop.get("dbType");
		if ((type != null) && type.equals("oracle")) {
			return CassetteDBOracle.getCassetteDB(prop);
		}
	
		return CassetteDBSimple.getCassetteDB(prop);
	}
}
