package webice.beans.dcs;

import java.util.Vector;
import java.util.StringTokenizer;
import webice.beans.*;

public class CollectDefault
{
	private double defOscRange = 1.0;
	private double defExposureTime = 1.0;
	private double defAttenuation = 100.0;
	private double minExposureTime;
	private double maxExposureTime;
	private double minAttenuation;
	private double maxAttenuation;
	
	public CollectDefault()
	{
	}
	
	public CollectDefault(String c)
		throws Exception
	{
		parseContents(c);
	}
		
	public double getDefOscRange()
	{
		return defOscRange;
	}
	
	public double getDefExposureTime()
	{
		return defExposureTime;
	}
	
	public double getDefAttenuation()
	{
		return defAttenuation;
	}
	
	public double getMinExposureTime()
	{
		return minExposureTime;
	}
	
	public double getMaxExposureTime()
	{
		return maxExposureTime;
	}
	
	public double getMinAttenuation()
	{
		return minAttenuation;
	}
	
	public double getMaxAttenuation()
	{
		return maxAttenuation;
	}
			
	public void parseContents(String content)
		throws Exception
	{
		try {
	
		StringTokenizer tok = new StringTokenizer(content, " ");
		if (tok.countTokens() < 3)
			throw new Exception("expected 3 or more fields for collect_default"); 

		defOscRange = Double.parseDouble(tok.nextToken());
		defExposureTime = Double.parseDouble(tok.nextToken());
		defAttenuation = Double.parseDouble(tok.nextToken());
		if (tok.countTokens() >= 4) {
			minExposureTime = Double.parseDouble(tok.nextToken());
			maxExposureTime = Double.parseDouble(tok.nextToken());
			minAttenuation = Double.parseDouble(tok.nextToken());
			maxAttenuation = Double.parseDouble(tok.nextToken());
		}
		
		} catch (NumberFormatException e) {
			throw new Exception("Invalid content for collect_default");
		}
	}
	
	public String toString()
	{
		return "defOscRange = " + defOscRange + " defExposure = " + defExposureTime
			+ " defAttentuation = " + defAttenuation
			+ " minExposure = " + minExposureTime
			+ " maxExposure = " + maxExposureTime
			+ " minAttenuation = " + minAttenuation
			+ " maxAttenuation = " + maxAttenuation;
	}
}

