package webice.beans.dcs;

import java.util.*;
import webice.beans.*;

/**
 * Owner of cassette positions: no_cassette, left, middle, right
*/
public class CassetteOwner
{
	public String owner[] = new String[4];
	
	/**
 	 */
	public CassetteOwner()
		throws Exception
	{
		init();
	}

	/**
 	 */
	public CassetteOwner(String raw)
		throws Exception
	{
		parse(raw);
		
	}
	
	private void init()
	{
		for (int i = 0; i < 4; ++i) {
			owner[i] = "";
		}
	}
	
	public void copy(CassetteOwner other)
	{
		for (int i = 0; i < 4; ++i) {
			owner[i] = other.owner[i];
		}
	}
	
	public void parse(String raw)
		throws Exception
	{	
		init();

		if ((raw == null) || (raw.length() == 0))
			return;
						
		StringTokenizer tok = new StringTokenizer(raw);
		if (tok.countTokens() != 4)
			throw new Exception("Failed to parse cassette_owner string: expecting at 4 fields but got " + tok.countTokens());
			
		String tmp = "";
		for (int i = 0; i < 4; ++i) {
			tmp = tok.nextToken();
			if (!tmp.equals(""))
				owner[i] = tmp;
		}
					
	}
		
	/**
	 * collect_msg string
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < 4; ++i) {
			if (i > 0)
				buf.append(" ");
			if (owner[i].equals(""))
				buf.append("{}");
			else
				buf.append(owner[i]);
		}
			
		return buf.toString();
	}
	
}

