package webice.beans.dcs;

import java.util.*;
import webice.beans.*;

/**
*/
public class CollectMsgString
{
	public int active = -1;
	public String msg = "";
	public int status = -1;
	public String beamline = "";
	public String userName = "";
	public String runName = "";
	public int runNumber = -1;
	public String image1 = "";
	public String image2 = "";
	
	static public int COLLECTWEB_STARTING = 0;
	static public int COLLECTWEB_MOUNTING = 1;
	static public int COLLECTWEB_LOOP_CENTERING = 2;
	static public int COLLECTWEB_CRYSTAL_CENTERING = 3;
	static public int COLLECTWEB_TEST_COLLECTING = 4; // taking 2 images
	static public int COLLECTWEB_AUTOINDEXING = 5; // autoindexing
	static public int COLLECTWEB_COLLECTING = 6; // collecting dataset
	
	
	public boolean hasError = false;
	
	/**
 	 */
	public CollectMsgString()
		throws Exception
	{
	
	}

	/**
 	 */
	public CollectMsgString(String raw)
		throws Exception
	{
	
		parse(raw);
	}
	
	public void copy(CollectMsgString other)
	{
		active = other.active;
		msg = other.msg;
		status = other.status;
		beamline = other.beamline;
		userName = other.userName;
		runName = other.runName;
		runNumber = other.runNumber;
		image1 = other.image1;
		image2 = other.image2;
	}
	
	public void parse(String raw)
		throws Exception
	{
	
		if ((raw == null) || (raw.length() == 0))
			return;
			
		StringTokenizer tok = new StringTokenizer(raw);
		if (tok.countTokens() < 7)
			throw new Exception("Failed to parse collect_msg string: expecting at least 7 fields but got " 
						+ tok.countTokens() + " fields (" + raw + ")");
			
		// Active or not
		String tmp = tok.nextToken().trim();
		if (tmp.equals("0"))
			active = 0;
		else if (tmp.equals("1"))
			active = 1;
			
		// Msg
		if (tok.hasMoreTokens())
			tmp = tok.nextToken().trim();
		else
			throw new Exception("CollectMsgString: missing msg field");
			
		// Does msg contain more than one word?	
		if (tmp.startsWith("{")) {
			// one word but surrounded by {}
			if (tmp.endsWith("}")) {
				msg = tmp.substring(1, tmp.length()-1);
			} else { // multiple words
				msg = tmp.substring(1);
				while (tok.hasMoreTokens()) {
					tmp = tok.nextToken().trim();
					if (tmp.endsWith("}")) {
						msg += " " + tmp.substring(0, tmp.length()-1);
						break;
					} else {
						msg += " " + tmp;
					}
				}
			}
		} else {
			msg = tmp;
		}
		
		// when it is done, it should complete
		// otherwise assume that there is an error
		if ((active == 0) && !msg.contains("complete"))
			hasError = true;
			
		// status	
		if (tok.hasMoreTokens())
			status = Integer.parseInt(tok.nextToken());
		else 
			throw new Exception("CollectMsgString: missing status field");
			
		// beamline
		if (tok.hasMoreTokens())
			beamline = tok.nextToken();
		else 
			throw new Exception("CollectMsgString: missing beamline field");

		// userName
		if (tok.hasMoreTokens())
			userName = tok.nextToken();
		else 
			throw new Exception("CollectMsgString: missing userName field");
			
		// runName
		if (tok.hasMoreTokens())
			runName = tok.nextToken();
		else 
			throw new Exception("CollectMsgString: missing runName field");
			
		// runNumber
		if (tok.hasMoreTokens()) {
			tmp = tok.nextToken();
			if (!tmp.equals("{}"))
				runNumber = Integer.parseInt(tmp);
		} else {
			throw new Exception("CollectMsgString: missing runNumber field");
		}
		
		// image1
		if (tok.hasMoreTokens()) {
			image1 = tok.nextToken();
			if (image1.equals("{}")) {
				image1 = "";
			}
			
		}
		
		// image2
		if ((image1.length() > 0) && tok.hasMoreTokens()) {
			image2 = tok.nextToken();
			if (image2.equals("{}")) {
				image2 = "";
			}
			
		}
		
				
	}
		
	/**
	 * collect_msg string
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append(String.valueOf(active));
		buf.append(" ");
		buf.append("{" + msg + "} ");
		buf.append(String.valueOf(status));
		buf.append(" ");
		buf.append(beamline);
		buf.append(" ");
		buf.append(userName);
		buf.append(" ");
		buf.append(runName);
		buf.append(" ");
		buf.append(String.valueOf(runNumber));
		buf.append(" ");
		buf.append(runName);
		buf.append(" ");
		buf.append(image1);
		buf.append(" ");
		buf.append(image2);
		
			
		return buf.toString();
	}
	
}

