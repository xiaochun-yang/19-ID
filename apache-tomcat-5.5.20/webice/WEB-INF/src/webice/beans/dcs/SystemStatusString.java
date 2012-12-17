package webice.beans.dcs;

import java.util.*;
import webice.beans.*;

/**
*/
public class SystemStatusString
{
	public String status = "";
	public String fgColor = "";
	public String bgColor = "";
		
	/**
 	 */
	public SystemStatusString()
		throws Exception
	{
	
	}

	/**
 	 */
	public SystemStatusString(String raw)
		throws Exception
	{
	
		parse(raw);
	}
	
	public void copy(SystemStatusString other)
	{
		status = other.status;
		fgColor = other.fgColor;
		bgColor = other.bgColor;
	}
	
	public void parse(String raw)
		throws Exception
	{
	
		if ((raw == null) || (raw.length() == 0))
			return;
			
		StringTokenizer tok = new StringTokenizer(raw);
		if (tok.countTokens() < 3)
			throw new Exception("Failed to parse collect_msg string: expecting at least 3 fields but got " + tok.countTokens());
			
		// status
		// Does status contain more than one word?
		String tmp = tok.nextToken();	
		if (tmp.startsWith("{")) {
			// one word but surrounded by {}
			if (tmp.endsWith("}")) {
				status = tmp.substring(1, tmp.length()-1);
			} else { // multiple words
				status = tmp.substring(1);
				while (tok.hasMoreTokens()) {
					tmp = tok.nextToken().trim();
					if (tmp.endsWith("}")) {
						status += " " + tmp.substring(0, tmp.length()-1);
						break;
					} else {
						status += " " + tmp;
					}
				}
			}
		} else {
			status = tmp;
		}
					
		// foreground color in bluice, indicating error status	
		if (tok.hasMoreTokens())
			fgColor = tok.nextToken();
			
		// background color in bluice, indicating error status
		if (tok.hasMoreTokens())
			bgColor = tok.nextToken();

	}
		
	/**
	 * collect_msg string
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append("{" + status + "} ");
		buf.append(" ");
		buf.append(fgColor);
		buf.append(" ");
		buf.append(bgColor);		
			
		return buf.toString();
	}
	
}

