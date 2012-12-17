package webice.beans.dcs;

public class DcsMsg
{
	protected String command;
	protected String content;

	/**
	 * Construct a dcs message from
	 * a array of raw characters.
	 */
	public DcsMsg(char raw[])
		throws Exception
	{
		if (raw == null)
			throw new Exception("Cannot create DcsMsg from null array of characters");

//		WebiceLogger.debug("DcsMsg: creating dcs msg from string " + new String(raw));
		int len = raw.length;
		if (raw[raw.length-1] == '\0')
			len = raw.length-1;

		// Find the first space char
		int pos1 = -1;
		for (int i = 0; i < len; ++i) {
			if (raw[i] == ' ') {
				pos1 = i;
				break;
			}
		}
		if (pos1 < 0)
			pos1 = len;

		if (pos1 > 0)
			command = new String(raw, 0, pos1);

		content = new String(raw, pos1, len-pos1).trim();
		
//		WebiceLogger.debug("command = '" + command + "'");
//		WebiceLogger.debug("content = '" + content + "'");
		
	}


	/**
	 */
	public DcsMsg(String command, String content)
	{
		this.command = command;
		this.content = content;
	}

	/**
	 */
	public String getCommand()
	{
		return command;
	}

	/**
	 */
	public String getContent()
	{
		return content;
	}

	/**
	 */
	public String toString()
	{
		return command + " " + content;
	}
}

