package webice.beans.dcs;

import java.util.Vector;
import java.util.StringTokenizer;
import webice.beans.*;

/**
 * String device
 */
public class ShutterDevice extends Device
{
	/**
	 * Target hardware host for this string
	 */
	private String dhs = "";

	/**
	 * Target hardware name
	 */
	private String externalShutterName = "";

	private int state = 0;

	/**
	 * Hide default constructor
	 */
	protected ShutterDevice()
	{
	}

	/**
	 * Constructor
	 * @param n Device name
	 */
	public ShutterDevice(String n)
	{
		super(n, DeviceType.SHUTTER);
	}

	/**
	 * Constructor
	 * @param n Device name
	 * @param content: <dhs> <shutter state> <external shutter name>
	 */
	public ShutterDevice(String n, String content)
		 throws Exception
	{
		super(n, DeviceType.SHUTTER);
		
		parseContent(content);
	}
	
	/**
	 * Parse 3rd line of shutter device in dump file
	 */
	private void parseContent(String content)
		throws Exception
	{	
		StringTokenizer tok = new StringTokenizer(content, " ");		
		int count = tok.countTokens();
		if (count != 3)
			throw new Exception("Expected 3 parameters for a shutter device but got " 
			+ count);

			dhs = tok.nextToken();
			setState(tok.nextToken());
			externalShutterName = tok.nextToken();
	}
	
	/**
	 * Parse shutter state: 0 or closed, 1 or open.
	 */
	private void setState(String s)
		throws Exception
	{
		if (s.equals("1"))
			state = 1;
		else if (s.equals("0"))
			state = 0;
		else if (s.equals("open"))
			state = 1;
		else if (s.equals("closed"))
			state = 0;
		else
			throw new Exception("Invalid shutter state: " + s);
	}
	
	/**
	 * Parse dcs msg, for example:
	 * stog_configure_shutter Al_32 simDhs open
	 * stog_configure_shutter shutter simDhs closed
	 */
	public void parseDcsMsg(String s)
		throws Exception
	{
		
		if ((s == null) || (s.length() == 0))
			throw new Exception("Null or zero length dcs message");
			
		StringTokenizer tok = new StringTokenizer(s);
		if (tok.countTokens() < 4)
			throw new Exception("Invalid dcs message for shutter device");
			
		String command = tok.nextToken();				
		if (command.equals("stog_configure_shutter")) {
			WebiceLogger.info("ShutterDevice parseDcsMsg: msg=" + s);
			setName(tok.nextToken());
			dhs = tok.nextToken();
			setState(tok.nextToken());
		}
	}

	/**
	 * Create a StepperMotorDevice from device name and raw parameter strings
	 * @param n Device name
	 * @param params Device parameters as raw strings
	 */
	public void parseDcsDump(Vector params)
		throws Exception
	{

		// Must have 3 lines of params
		if (params.size() != 5)
			throw new Exception("Expecting 5 lines for shutter device but got " + params.size());

		parseContent((String)params.elementAt(2));
				
	}

	/**
	 * Create a ShutterDevice from device name and raw parameter strings
	 * @param n Device name
	 * @param params Device parameters as raw strings
	 */
	public static ShutterDevice createDevice(Vector params)
		throws Exception
	{

		// Must have 5 lines of params
		if (params.size() != 5)
			return null;
			
		return new ShutterDevice((String)params.elementAt(0), (String)params.elementAt(2));
	}


	/**
	 * Returns Hardware host
	 * @return Hardware host
	 */
	public String getDhs()
	{
		return dhs;
	}

	/**
	 * Sets Hardware host
	 * @param s Hardware host
	 * @exception Thrown if parameter s is invalid (e.g. empty string)
	 */
	public void setDhs(String s) throws Exception
	{
		if (s.length() == 0)
			throw new Exception("Invalid dhs host for StepperMotorDevice");

		dhs = s;
	}

	/**
	 * Returns Hardware name
	 * @return Hardware name
	 */
	public String getExternalShutterName()
	{
		return externalShutterName;
	}

	/**
	 * Sets Hardware name
	 * @param s Hardware name
	 * @exception Thrown if parameter s is invalid (e.g. empty string)
	 */
	public void setExternalShuttername(String s)
		throws Exception
	{
		if (s.length() == 0)
			throw new Exception("Invalid external shutter name for ShutterDevice");

		externalShutterName = s;
	}
	
	
	public int getState()
	{
		return state;
	}
	
	public boolean isOpen()
	{
		return (state == 1);
	}
	
	public boolean isClosed()
	{
		return (state == 0);
	}

	/**
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append(super.toString());
		buf.append("dhs=" + dhs + "\n");
		buf.append("externalSutterName=" + externalShutterName + "\n");
		buf.append("state=" + state);

		return buf.toString();

	}

}
