package webice.beans.dcs;

import java.util.Vector;
import java.util.StringTokenizer;
import webice.beans.*;

/**
 * String device
 */
public class StepperMotorDevice extends Device
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
	private double scaleFactor = 0.0;
	private double speed = 0.0;
	private double acceleration = 0.0;
	private int backlash = 0;
	private int lowerLimitOn = 0;
	private int upperLimitOn = 0;
	private int motorLockOn = 0;
	private int backlashOn = 0;
	private int reverseOn = 0;
	private int circleMode = 0;
	private String unit = "unknown"; // mm|deg|eV|counts
	
	private String status = "";

	/**
	 * Hide default constructor
	 */
	protected StepperMotorDevice()
	{
	}

	/**
	 * Constructor
	 * @param n Device name
	 */
	public StepperMotorDevice(String n)
	{
		super(n, DeviceType.STEPPER_MOTOR);
	}

	/**
	 * Constructor
	 * @param n Device name
	 * @param hHost Hardware host
	 * @param hName Hardware name
	 * @param c String contents
	 */
	public StepperMotorDevice(String n, String dhs, String externalMotorName, String c)
		 throws Exception
	{
		super(n, DeviceType.STEPPER_MOTOR);

		this.dhs = dhs;
		this.externalMotorName = externalMotorName;
		
		StringTokenizer tok = new StringTokenizer(c, " ");

		parseContent(tok);
		
	}
	
	/**
	 */
	public void parseContent(StringTokenizer tok)
		throws Exception
	{
			
		try {
		
		int count = tok.countTokens();
		if (count < 13)
			throw new Exception("Expected 14 parameters for a step motor device but got " 
			+ count);

			position = Double.parseDouble(tok.nextToken());
			upperLimit = Double.parseDouble(tok.nextToken());
			lowerLimit = Double.parseDouble(tok.nextToken());
			scaleFactor = Double.parseDouble(tok.nextToken());
			speed = Double.parseDouble(tok.nextToken());
			acceleration = Double.parseDouble(tok.nextToken());
			backlash = Integer.parseInt(tok.nextToken());
			lowerLimitOn = Integer.parseInt(tok.nextToken());
			upperLimitOn =Integer.parseInt(tok.nextToken());
			motorLockOn =Integer.parseInt(tok.nextToken());
			backlashOn = Integer.parseInt(tok.nextToken());
			reverseOn = Integer.parseInt(tok.nextToken());
			circleMode = Integer.parseInt(tok.nextToken());
			if (tok.hasMoreTokens())
				unit = tok.nextToken();
		} catch (Exception e) {
			throw new Exception("Failed to parse parameters for stepper motor device "  + name);
		}
	}
	
	/**
	 * Parse dcs msg, for example:
	 * stog_configure_real_motor gonio_z simDhs gonioz 549.929480 805.000000 540.000000 78.701000 500 300 39 1 1 0 1 1 0
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
				
		if (command.equals("stog_configure_real_motor")) {
			dhs = tok.nextToken();
			externalMotorName = tok.nextToken();
			parseContent(tok);
		} else if (command.equals("stog_motor_move_completed")) {
			position = Double.parseDouble(tok.nextToken());
			// normal, aborted, moving, cw_hw_limit, ccw_hw_limit, both_hw_limits, or unknown
			status = tok.nextToken();
		}
		
//		WebiceLogger.info("StepperMotorDevice::parseDcsMsg: name = " + name + " position = " + position);
	}

	/**
	 * Create a StepperMotorDevice from device name and raw parameter strings
	 * @param n Device name
	 * @param params Device parameters as raw strings
	 */
	public void parseDcsDump(Vector params)
		throws Exception
	{

		// Must have 7 lines of params
		if (params.size() != 7)
			throw new Exception("Expecting 7 lines for stepper motor device but got " + params.size());

		StringTokenizer tokenizer = new StringTokenizer((String)params.elementAt(2));

		if (tokenizer.countTokens() != 2)
			throw new Exception("Missing hardwareHost or hardwareName for stepper motor device");

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
		
//		WebiceLogger.info("StepperMotorDevice::parseDcsDump: name = " + name + " position = " + position);

	}

	/**
	 * Create a StepperMotorDevice from device name and raw parameter strings
	 * @param n Device name
	 * @param params Device parameters as raw strings
	 */
	public static StepperMotorDevice createDevice(Vector params)
		throws Exception
	{

		// Must have 7 lines of params
		if (params.size() != 7)
			return null;

		StringTokenizer tokenizer = new StringTokenizer((String)params.elementAt(2));

		if (tokenizer.countTokens() != 2)
			throw new Exception("Missing hardwareHost or hardwareName for stepper motor device");

		String dhs = tokenizer.nextToken();
		String externalName = tokenizer.nextToken();
		
		// Old format: data is on line 4
		String str = (String)params.elementAt(3);
		if (str.length() == 9) {
			// new format: data is on line 7
			str = (String)params.elementAt(6);
		}

		return new StepperMotorDevice((String)params.elementAt(0),
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
			throw new Exception("Invalid dhs host for StepperMotorDevice");

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
			throw new Exception("Invalid external motor name for StepperMotorDevice");

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
	
	public double getSpeed()
	{
		return speed;
	}
	
	public double getScaleFactor()
	{
		return scaleFactor;
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
		buf.append("scaleFactor=" + scaleFactor);
		buf.append("speed=" + speed);
		buf.append("acceleration=" + acceleration);
		buf.append("lowerLimitOn=" + lowerLimitOn);
		buf.append("upperLimitOn=" + upperLimitOn);
		buf.append("motorLockOn=" + motorLockOn);
		buf.append("backlashOn=" + backlashOn);
		buf.append("backlashOn=" + backlashOn);
		buf.append("reverseOn=" + reverseOn);
		buf.append("circleMode=" + circleMode);
		buf.append("unit=" + unit);

		return buf.toString();

	}

}
