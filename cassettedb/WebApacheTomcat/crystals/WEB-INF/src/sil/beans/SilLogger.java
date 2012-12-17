package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class SilLogger
{
	private static Log theLogger = null;
	
	public static Log getLogger()
	{
		if (theLogger == null)
			theLogger = LogFactory.getLog("crystals");
			
		return theLogger;
	}
	
	public static void info(Object s)
	{
		getLogger().info(s);
	}
	
	public static void debug(Object s)
	{
		getLogger().debug(s);
	}
	
	public static void warn(Object s)
	{
		getLogger().warn(s);
	}

	public static void error(Object s)
	{
		getLogger().error(s);
	}
	
	public static void error(String s, Throwable e)
	{
		getLogger().error(s, e);
	}
	
	public static void fatal(Object s)
	{
		getLogger().fatal(s);
	}
}


