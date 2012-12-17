package webice.beans.dcs;

import java.util.Vector;

public class DeviceFactory
{

	/**
	 * Device status
	 */
	public static int DCS_DEVICE_INACTIVE = 0;
	public static int DCS_DEVICE_MOVING = 1;
	public static int DCS_DEVICE_ABORTING = 2;
	public static int DCS_DEVICE_READING = 3;
	public static int DCS_DEVICE_COUNTING = 4;
	public static int DCS_DEVICE_TIMING = 5;
	public static int DCS_DEVICE_COLLECTING = 6;


	/**
	 * Create a new device from the name, type and params.
	 * @param params raw strings for constructing a device.
	 * @exception Thrown if a device can not be created
	 * because of an error in the params
	 */
	public static Device createDevice(Vector params) throws Exception
	{
		if (params.size() < 2)
			throw new Exception("Too few lines for a device");

		// Can throw NumberFormatException
		int type = Integer.parseInt((String)params.elementAt(1));

		if (type == DeviceType.BLANK.getInt()) {
		} else if (type == DeviceType.STEPPER_MOTOR.getInt()) {
			return StepperMotorDevice.createDevice(params);
		} else if (type == DeviceType.PSEUDO_MOTOR.getInt()) {
			return PseudoMotorDevice.createDevice(params);
		} else if (type == DeviceType.HARDWARE_HOST.getInt()) {
		} else if (type == DeviceType.ION_CHAMBER.getInt()) {
		} else if (type == DeviceType.OBSOLETE.getInt()) {
		} else if (type == DeviceType.SHUTTER.getInt()) {
		} else if (type == DeviceType.OBSOLETE2.getInt()) {
		} else if (type == DeviceType.RUN.getInt()) {
		} else if (type == DeviceType.RUNS.getInt()) {
			return Runs.createDevice(params);
		} else if (type == DeviceType.OBSOLETE3.getInt()) {
		} else if (type == DeviceType.OPERATION.getInt()) {
		} else if (type == DeviceType.ENCODER.getInt()) {
		} else if (type == DeviceType.STRING.getInt()) {
			return StringDevice.createDevice(params);
		} else if (type == DeviceType.OBJECT.getInt()) {
		}

		return null;
	}

}

