package webice.beans.dcs;

import java.util.Vector;
import java.util.StringTokenizer;

import webice.beans.WebiceLogger;
/**
 * String device
 */
public class PseudoMotorDevice extends Device
{
	/**
	 * Target hardware host for this string
	 */
	private String dhs = "";

	/**
	 * Target hardware name
	 */
	private String externalMotorName = "";

	private double position = 0.0;
	private double upperLimit = 0.0;
	private double lowerLimit = 0.0;
	private int lowerLimitOn = 0;
	private int upperLimitOn = 0;
	private int motorLockOn = 0;
	private int circleMode = 0;
	private String unit = "unknown"; // mm|deg|eV|counts
	
	private String status = "";

	/**
	 * Hide default constructor
	 */
	protected PseudoMotorDevice()
	{
	}

	/**
	 * Constructor
	 * @param n Device name
	 */
	public PseudoMotorDevice(String n)
	{
		super(n, DeviceType.PSEUDO_MOTOR);
	}

	/**
	 * Constructor
	 * @param n Device name
	 * @param hHost Hardware host
	 * @param hName Hardware name
	 * @param c String contents
	 */
	public PseudoMotorDevice(String n, String dhs, String externalMotorName, String c)
		 throws Exception
	{
		super(n, DeviceType.PSEUDO_MOTOR);

		this.dhs = dhs;
		this.externalMotorName = externalMotorName;
		
		StringTokenizer tok = new StringTokenizer(c, " ");
		
		parseContent(tok);
	}
	
	/**
	 */
	private void parseContent(StringTokenizer tok)
		throws Exception 
	{
		try {
		int count = tok.countTokens();
		if (count < 7)
			throw new Exception("Expected at least 7 parameters for a pseudo motor device but got " 
			+ count);
			position = Double.parseDouble(tok.nextToken());
			upperLimit = Double.parseDouble(tok.nextToken());
			lowerLimit = Double.parseDouble(tok.nextToken());
			lowerLimitOn = Integer.parseInt(tok.nextToken());
			upperLimitOn =Integer.parseInt(tok.nextToken());
			motorLockOn =Integer.parseInt(tok.nextToken());
			circleMode = Integer.parseInt(tok.nextToken());
			if (tok.hasMoreTokens())
				unit = tok.nextToken();
				
		} catch (Exception e) {
			throw new Exception("Failed to parse parameters for peudo motor device "  + name);
		}
	}

	/**
	 * Parse dcs msg, for example:
	 * stog_configure_pseudo_motor doseStoredCounts self standardVirtualMotor 3173.684869 100.000000 -100.000000 1 1 0 0
	 */
	public void parseDcsMsg(String s)
		throws Exception
	{
		
		if ((s == null) || (s.length() == 0))
			return;
						
		StringTokenizer tok = new StringTokenizer(s);
		if (tok.countTokens() < 4)
			return;
			
		String command = tok.nextToken();
		name = tok.nextToken();
				
		if (command.equals("stog_configure_pseudo_motor")) {
			dhs = tok.nextToken();
			externalMotorName = tok.nextToken();
			parseContent(tok);
		} else if (command.equals("stog_motor_move_completed")) {
			position = Double.parseDouble(tok.nextToken());
			// normal, aborted, moving, cw_hw_limit, ccw_hw_limit, both_hw_limits, or unknown
			status = tok.nextToken();
		}
		
//		WebiceLogger.info("PseudoMotorDevice::parseDcsMsg: name = " + name + " position = " + position);
	}

	/**
	 * Create a PseudoMotorDevice from device name and raw parameter strings
	 * @param n Device name
	 * @param params Device parameters as raw strings
	 */
	public void parseDcsDump(Vector params)
		throws Exception
	{

		// Must have 8 lines of params
		if (params.size() != 8) {
			throw new Exception("Expecting 8 lines for pseudo motor but got " + params.size());
		}

		StringTokenizer tokenizer = new StringTokenizer((String)params.elementAt(2));

		if (tokenizer.countTokens() != 2)
			throw new Exception("Missing hardwareHost or hardwareName for pseudo motor device");

		setName((String)params.elementAt(0));
		dhs = tokenizer.nextToken();
		externalMotorName = tokenizer.nextToken();
		
		// Old format: data is on line 4
		String str = (String)params.elementAt(3);
		if (str.length() == 9) {
			// new format: data is on line 7
			str = (String)params.elementAt(6);
		}

		StringTokenizer tok = new StringTokenizer(str, " ");
		parseContent(tok);

//		WebiceLogger.info("PseudoMotorDevice::parseDcsDump: name = " + name + " position = " + position);

	}

	/**
	 * Create a PseudoMotorDevice from device name and raw parameter strings
	 * @param n Device name
	 * @param params Device parameters as raw strings
	 */
	public static PseudoMotorDevice createDevice(Vector params)
		throws Exception
	{

		// Must have 8 lines of params
		if (params.size() != 8) {
			WebiceLogger.warn("Failed to create pseudo motor device " + params.elementAt(0));
			return null;
		}

		StringTokenizer tokenizer = new StringTokenizer((String)params.elementAt(2));

		if (tokenizer.countTokens() != 2)
			throw new Exception("Missing hardwareHost or hardwareName for pseudo motor device");

		String dhs = tokenizer.nextToken();
		String externalName = tokenizer.nextToken();
		
		// Old format: data is on line 4
		String str = (String)params.elementAt(3);
		if (str.length() == 9) {
			// new format: data is on line 7
			str = (String)params.elementAt(6);
		}

		return new PseudoMotorDevice((String)params.elementAt(0),
						dhs, externalName, str);


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
			throw new Exception("Invalid dhs host for PseudoMotorDevice");

		dhs = s;
	}

	/**
	 * Returns Hardware name
	 * @return Hardware name
	 */
	public String getExternalMotorName()
	{
		return externalMotorName;
	}

	/**
	 * Sets Hardware name
	 * @param s Hardware name
	 * @exception Thrown if parameter s is invalid (e.g. empty string)
	 */
	public void setExternalMotorname(String s) throws Exception
	{
		if (s.length() == 0)
			throw new Exception("Invalid external motor name for PseudoMotorDevice");

		externalMotorName = s;
	}
	
	public double getPosition()
	{
		return position;
	}
	
	public double getUpperLimit()
	{
		return upperLimit;
	}
	
	public double getLowerLimit()
	{
		return lowerLimit;
	}
	

	/**
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append(super.toString());
		buf.append("dhs=" + dhs + "\n");
		buf.append("externalMotorName=" + externalMotorName + "\n");
		buf.append("position=" + position);
		buf.append("upperLimit=" + upperLimit);
		buf.append("lowerLimit=" + lowerLimit);
		buf.append("lowerLimitOn=" + lowerLimitOn);
		buf.append("upperLimitOn=" + upperLimitOn);
		buf.append("motorLockOn=" + motorLockOn);
		buf.append("circleMode=" + circleMode);
		buf.append("unit=" + unit);

		return buf.toString();

	}

}
