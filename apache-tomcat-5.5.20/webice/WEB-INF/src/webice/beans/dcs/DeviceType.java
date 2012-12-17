package webice.beans.dcs;

import java.util.Vector;

public class DeviceType
{
	/**
	 * Device types
	 */
	public static final DeviceType BLANK = new DeviceType(0);
	public static final DeviceType STEPPER_MOTOR = new DeviceType(1);
	public static final DeviceType PSEUDO_MOTOR = new DeviceType(2);
	public static final DeviceType HARDWARE_HOST = new DeviceType(3);
	public static final DeviceType ION_CHAMBER  = new DeviceType(4);
	public static final DeviceType OBSOLETE = new DeviceType(5);
	public static final DeviceType SHUTTER = new DeviceType(6);
	public static final DeviceType OBSOLETE2 = new DeviceType(7);
	public static final DeviceType RUN = new DeviceType(8);
	public static final DeviceType RUNS = new DeviceType(9);
	public static final DeviceType OBSOLETE3 = new DeviceType(10);
	public static final DeviceType OPERATION = new DeviceType(11);
	public static final DeviceType ENCODER = new DeviceType(12);
	public static final DeviceType STRING = new DeviceType(13);
	public static final DeviceType OBJECT = new DeviceType(14);

	/**
	 */
	private int type = -1;


	/**
	 * Hide constructor
	 */
	private DeviceType()
	{
	}

	/**
	 * Hide constructor
	 */
	private DeviceType(int t)
	{
		type = t;
	}

	/**
	 * Return type in integer
	 */
	public int getInt()
	{
		return type;
	}

	/**
	 */
	public boolean equals(int t)
	{
		return (type == t);
	}

}

