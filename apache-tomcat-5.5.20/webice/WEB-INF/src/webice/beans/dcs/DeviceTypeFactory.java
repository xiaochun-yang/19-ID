package webice.beans.dcs;

import java.util.Vector;

public class DeviceTypeFactory
{

	public static final Vector types = new Vector();

	{
		types.add(DeviceType.BLANK);
		types.add(DeviceType.STEPPER_MOTOR);;
		types.add(DeviceType.PSEUDO_MOTOR);
		types.add(DeviceType.HARDWARE_HOST);
		types.add(DeviceType.ION_CHAMBER);
		types.add(DeviceType.OBSOLETE);
		types.add(DeviceType.SHUTTER);
		types.add(DeviceType.OBSOLETE2);
		types.add(DeviceType.RUN);
		types.add(DeviceType.RUNS);
		types.add(DeviceType.OBSOLETE3);
		types.add(DeviceType.OPERATION);
		types.add(DeviceType.ENCODER);
		types.add(DeviceType.STRING);
		types.add(DeviceType.OBJECT);
	}


	/**
	 */
	public static Vector getDeviceTypes()
	{
		return types;
	}

	/**
	 */
	public static DeviceType getDeviceType(int t)
	{
		for (int i = 0; i < types.size(); ++i) {
			if (((DeviceType)types.elementAt(i)).getInt() == t)
				return (DeviceType)types.elementAt(i);
		}

		return null;
	}

}

