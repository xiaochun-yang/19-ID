package webice.beans.dcs;

import java.util.Vector;
import java.util.StringTokenizer;
import webice.beans.*;

/**
 * String device
 */
public class StringDevice extends Device
{
	/**
	 * Target hardware host for this string
	 */
	private String hardwareHost = "";

	/**
	 * Target hardware name
	 */
	private String hardwareName = "";

	/**
	 * String to be sent
	 */
	private String contents = "";

	/**
	 * Hide default constructor
	 */
	protected StringDevice()
	{
	}

	/**
	 * Constructor
	 * @param n Device name
	 */
	public StringDevice(String n)
	{
		super(n, DeviceType.STRING);
	}

	/**
	 * Constructor
	 * @param n Device name
	 * @param hHost Hardware host
	 * @param hName Hardware name
	 * @param c String contents
	 */
	public StringDevice(String n, String hHost, String hName, String c)
	{
		super(n, DeviceType.STRING);

		hardwareHost = hHost;
		hardwareName = hName;
		contents = c;
	}
	
	/**
	 * Parse dcs msg, for example
	 * stog_configure_string run0 self inactive 0 0 test /data/blctl 1 gonio_phi 257.500000 258.5 1.0 180.0 1.0 420.002540 40.005080 1 12641.998779 0 0 0 0 0 0
	 * Do not parse string device content, leave it as a blob of text
	 */
	public void parseDcsMsg(String s)
		throws Exception
	{
		
		if ((s == null) || (s.length() == 0))
			return;
		
//		WebiceLogger.info("StringDevice::parseDcsMsg: rawStr = " + s);
			
		StringTokenizer tok = new StringTokenizer(s, " ");
		if (tok.countTokens() < 3) {
			WebiceLogger.info("StringDevice::parseDcsMsg: failed to parse rawStr = " + s);
			return;
		}
			
		String command = tok.nextToken();
		name = tok.nextToken();
		contents = "";
				
		if (command.equals("stog_configure_string")) {
			hardwareName = tok.nextToken();
			if (tok.hasMoreTokens())
				contents = tok.nextToken();
			while (tok.hasMoreTokens()) {
				contents += " " + tok.nextToken();
			}
		} else if (command.equals("stog_set_string_completed")) {
			String status = tok.nextToken();
			if (status.equals("normal")) {
				if (tok.hasMoreTokens())
					contents = tok.nextToken();
				while (tok.hasMoreTokens()) {
					contents += " " + tok.nextToken();
				}
			}
		}
		
//		WebiceLogger.info("StringDevice::parseDcsMsg: name = " + getName() + ", content = " + contents);
				
	}

	/**
	 */
	public void parseDcsDump(Vector params)
		throws Exception
	{

		// Must have 2 lines of params
		contents = "";
		int which_line = 3;
		if (params.size() == 4) {
			which_line = 3;
		} else if (params.size() == 6) {
			which_line = 5;
		} else if (params.size() == 5) { // line 6 is empty
			which_line = -1;
		} else {
			throw new Exception("Expecting 4 or 6 lines for string device but got " + params.size());
		}

		StringTokenizer tokenizer = new StringTokenizer((String)params.elementAt(2), " ");
		if (tokenizer.countTokens() != 2)
			throw new Exception("Missing hardwareHost or hardwareName for string device");

		setName((String)params.elementAt(0));
		hardwareHost = tokenizer.nextToken();
		hardwareName = tokenizer.nextToken();
		if (which_line > -1)
			contents = (String)params.elementAt(which_line);

//		WebiceLogger.info("StringDevice::parseDcsDump: name = " + getName() + ", content = " + contents);
	}

	/**
	 * Create a StringDevice from device name and raw parameter strings
	 * @param n Device name
	 * @param params Device parameters as raw strings
	 */
	public static StringDevice createDevice(Vector params)
		throws Exception
	{

		// Must have 2 lines of params
		int which_line = 3;
		if (params.size() == 4) {
			which_line = 3;
		} else if (params.size() == 6) {
			which_line = 5;
		} else {
			return null;
		}

		StringTokenizer tokenizer = new StringTokenizer((String)params.elementAt(2), " ");
		if (tokenizer.countTokens() != 2)
			throw new Exception("Missing hardwareHost or hardwareName for string device");

		String host = tokenizer.nextToken();
		String name = tokenizer.nextToken();

		return new StringDevice((String)params.elementAt(0),
								host, name,
								(String)params.elementAt(which_line));


	}


	/**
	 * Returns Hardware host
	 * @return Hardware host
	 */
	public String getHardwareHost()
	{
		return hardwareHost;
	}

	/**
	 * Sets Hardware host
	 * @param s Hardware host
	 * @exception Thrown if parameter s is invalid (e.g. empty string)
	 */
	public void setHardwareHost(String s) throws Exception
	{
		if (s.length() == 0)
			throw new Exception("Invalid hardware host for StringDevice");

		hardwareHost = s;
	}

	/**
	 * Returns Hardware name
	 * @return Hardware name
	 */
	public String getHardwareName()
	{
		return hardwareHost;
	}

	/**
	 * Sets Hardware name
	 * @param s Hardware name
	 * @exception Thrown if parameter s is invalid (e.g. empty string)
	 */
	public void setHardwareName(String s) throws Exception
	{
		if (s.length() == 0)
			throw new Exception("Invalid hardware name for StringDevice");

		hardwareName = s;
	}

	/**
	 * Returns string contents
	 * @return String contents
	 */
	public String getContents()
	{
		return contents;
	}

	/**
	 * Sets string contents
	 * @param s String contents
	 * @exception Thrown if parameter s is invalid (e.g. empty string)
	 */
	public void setContents(String s) throws Exception
	{
		contents = s;
	}

	/**
	 */
	public String toString()
	{
		String ret = super.toString();

		ret += "hardwareHost=" + hardwareHost + "\n";
		ret += "hardwareName=" + hardwareName + "\n";
		ret += "string=" + contents + "\n";

		return ret;

	}

}
