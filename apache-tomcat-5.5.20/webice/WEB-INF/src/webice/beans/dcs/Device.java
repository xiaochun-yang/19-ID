package webice.beans.dcs;

import java.util.Vector;
/**
 * Base class for all devices
 */
public class Device
{
	/**
	 * Name of the device
	 */
	protected String name = "";

	/**
	 * Type of the device
	 */
	protected DeviceType type = DeviceType.BLANK;

	/**
	 */
	protected int status = DeviceFactory.DCS_DEVICE_INACTIVE;

	/**
	 */
	public Device(String n, DeviceType t)
	{
		name = n;
		type = t;
	}

	/**
	 * Hide default constructor
	 */
	protected Device()
	{
	}
	
	public void setName(String s)
	{
		name = s;
	}

	/**
	 */
	public String getName()
	{
		return name;
	}

	/**
	 */
	public DeviceType getType()
	{
		return type;
	}

	/**
	 */
	public int getStatus()
	{
		return status;
	}
	
	public void parseDcsMsg(String raw)
		throws Exception
	{
		// Leave it to derived classes.
	}
	
	public void parseDcsDump(Vector params)
		throws Exception
	{
		// Leave it to derived classes.
	}

	/**
	 */
	public void setStatus(int s) throws Exception
	{
		if ((s < DeviceFactory.DCS_DEVICE_INACTIVE) ||
			(s > DeviceFactory.DCS_DEVICE_COLLECTING))
			throw new Exception("Invalid device status " + s);

		status = s;
	}

	/**
	 */
	public String toString()
	{
		String ret = "name=" + name + "\n";
		ret += "type=" + type.getInt() + "\n";

		return ret;
	}

}

