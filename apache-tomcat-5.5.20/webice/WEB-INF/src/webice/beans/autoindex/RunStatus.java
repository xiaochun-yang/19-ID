/**
 * Javabean for SMB resources
 */
package webice.beans.autoindex;

import webice.beans.*;

public class RunStatus
{
	/**
	 * Is the process running
 	 */
	private boolean running = false;

	/**
	 * Last update timestamp
 	 */
	private String lastUpdate = "";

	/**
	 * Process start time
 	 */
	private String stime = "";

	/**
	 * Process id
	 */
	private int pid = 0;

	/**
	 */
	private String type = "";

	/**
	 * Constructor
 	 */
	public RunStatus()
	{
	}

	private void init()
	{
		running = false;
		lastUpdate = "";
		stime = "";
		pid = 0;
		type = "";
	}

	/**
	 * Package-level protection
	 */
	public void setRunning(boolean s)
	{
		running = s;

		if (!isRunning()) {
			init();
		}
	}

	public boolean isRunning()
	{
		return running;
	}

/*	public void setLastUpdate(String s)
	{
		lastUpdate = s;
	}*/

	public String getLastUpdate()
	{
		return lastUpdate;
	}

	/**
	 * Package-level protection
	 */
	void setStartTime(String s)
	{
		stime = s;
	}

	public String getStartTime()
	{
		return stime;
	}

/*	public void setPid(int id)
	{
		pid = id;
	}*/

	public int getPid()
	{
		return pid;
	}

	/**
	 * Parse the status string
	 * Expected format:
	 * running: pid=xxx stime=xxx
	 * not running: explanation
	 */
	public void parseStatus(String s)
	{
		if ((s == null) || (s.length() == 0))
			return;

		try {

		if (s.indexOf("running:") == 0) {

			int pos1 = s.indexOf("pid=");
			if (pos1 < 0)
				return;
			int pos2 = s.indexOf("stime=");
			if (pos2 < pos1)
				return;
			int id = Integer.parseInt(s.substring(pos1+4, pos2-1));

			pid = id;
			stime = s.substring(pos2+6);
			running = true;

		} else if (s.indexOf("not running:") == 0) {
			running = false;
		} else {
			// can not determine the status
			// Leave the status as it is.
		}

		} catch (NumberFormatException e) {
			// Ignore. Status not updated.
		}

	}

}

