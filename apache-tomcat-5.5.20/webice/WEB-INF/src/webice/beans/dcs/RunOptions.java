package webice.beans.dcs;

import java.util.*;

/**
*/
public class RunOptions
{
	private int masterSwitch = 1; // All must be 0 if masterSwitch is 0
	private int mountAllowed = 1; // mount must be false if mountAllowed is 0
	private int centerAllowed = 1; // center must be false if centerAllowed is 0 
	private int autoindexAllowed = 1; // autoindex must be false if autoindexAllowed is 0

	public boolean mount = false;
	public boolean center = false; // center crystal
	public boolean autoindex = false;
	public boolean stop = false; // stop after autoindex
	
	public boolean scan = false; // do mad scan scan or not
	
	/**
	 * Run definition as in dcs message format
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		
		buf.append("{");
		
		buf.append(String.valueOf(masterSwitch));
		buf.append(" " + String.valueOf(mountAllowed));
		buf.append(" " + String.valueOf(centerAllowed));
		buf.append(" " + String.valueOf(autoindexAllowed));
		
		buf.append(" ");
		if (mount)
			buf.append("1");
		else
			buf.append("0");
			
		if (center)
			buf.append(" 1");
		else
			buf.append(" 0");
			
		if (autoindex)
			buf.append(" 1");
		else
			buf.append(" 0");
			
		if (stop)
			buf.append(" 1");
		else
			buf.append(" 0");
			
		if (scan)
			buf.append(" 1");
		else
			buf.append(" 0");
			
			
		buf.append("}");
			
		return buf.toString();
	}
	
}

