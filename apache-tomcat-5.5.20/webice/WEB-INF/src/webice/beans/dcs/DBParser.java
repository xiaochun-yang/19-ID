package webice.beans.dcs;

import java.util.Hashtable;
import java.util.Vector;
import java.io.FileReader;
import java.io.BufferedReader;
import webice.beans.WebiceLogger;

/**
 * Parse dcss database dump
 */
public class DBParser
{
	/**
	 * Lookup table for devices to be created
	 * if found in the database dump file
	 */
	private Vector wantedTypes = new Vector();



	/**
	 * Constructor
	 */
	public DBParser()
	{
	}

	/**
	 * Create a parser that only
	 * creates a subset of devices
	 * whose types are in the lookup table.
	 * @param types Lookup table of device types to be created.
	 */
	public DBParser(Vector types)
	{
		wantedTypes = (Vector)types.clone();
	}

	/**
	 * Add device type
	 */
	public void addDeviceType(DeviceType device)
	{
		wantedTypes.add(device);
	}

	/**
	 * Remove device type
	 */
	public void removeDeviceType(DeviceType device)
	{
		wantedTypes.remove(device);
	}


	/**
	 * Remove all device types
	 */
	public void clearDeviceTypes()
	{
		wantedTypes.clear();
	}


	/**
	 * Parses the database dump file and
	 * @param fileName Name of the database dump file
	 * @return a list of devices
	 */
	public Hashtable getDevices(String fileName)
		throws Exception
	{
		Hashtable devices = new Hashtable();
		
		parse(fileName, devices, true);
		
		return devices;
	}
	/**
	 * Parses the database dump file and
	 * @param fileName Name of the database dump file
	 * @param devices returned devices
	 * @param create Whether or not to create a new device and add it to the hash table if not already exist
	 * @return a list of devices
	 */
	public void parse(String fileName, Hashtable devices, boolean create)
		throws Exception
	{
		// Open file
		BufferedReader reader = null;
		String line = "";
		String deviceName = "";
		String deviceTypeStr = "";
		int deviceType = -1;
		Vector params = new Vector();
		boolean endoffile = false;
		boolean endofdevice = false;

		try {

		reader = new BufferedReader(new FileReader(fileName));

		while (!endoffile) {

			// For each device
			params.clear();
			while (!endoffile) {

				line = reader.readLine().trim();

				if (line == null)
					throw new Exception("Unexpected end of file");

				// End of device
				if (line.length() == 0) {
					if (params.size() > 1)
						break;
					else
						continue;
				}

				// End of file
				if (line.equals("END")) {
					endoffile = true;
					break;
				}

				params.add(line);
			}


			// Found a device
			if (params.size() < 2) {
				if (endoffile)
					break;
				else
					throw new Exception("Too few lines for a device");
			}
			
			deviceName = (String)params.elementAt(0);
			deviceTypeStr = (String)params.elementAt(1);
			
			try {

			// Can throw NumberFormatException
			deviceType = Integer.parseInt(deviceTypeStr);
						
			} catch (NumberFormatException e) {
				WebiceLogger.warn("Device " + deviceName
					+ " has invalid type: " + deviceTypeStr);
				continue;
			}

			// Skip this device type
			if (!isWantedDevice(deviceType))	
				continue;

			try {
				// Replace content
				Device s = (Device)devices.get(deviceName);
				if (s != null) {
					s.parseDcsDump(params);
				} else {
					// Create new device and add it to hashtable
					if (create) {
						Device aDevice = createDevice(params);
						devices.put(aDevice.getName(), aDevice);
					}
				}
					
			} catch (Exception e) {
				WebiceLogger.warn("Failed to parse dcs dump for device " + deviceName + ": " + e.getMessage());
			}

			// Construct a dive from device name,
			// type and params
			// null value is returned if
			// device type is unknown or
			// params are invalid
			Device aDevice = createDevice(params);

			// Add device to the lookup table
			if (aDevice != null)
				devices.put(aDevice.getName(), aDevice);

		}

		reader.close();
		reader = null;

		} catch (Exception e) {
			WebiceLogger.error("DBParser.getDevices: " + e.getMessage());
			throw e;
		} finally {
			if (reader != null)
				reader.close();
			reader = null;
		}

	}

	/**
	 * Determines whether or not to create device of this type
	 * @return true if this device type is in the
	 * wantedTypes lookup table.
	 */
	private boolean isWantedDevice(int type)
	{
		for (int i = 0; i < wantedTypes.size(); ++i) {
			if (((DeviceType)wantedTypes.elementAt(i)).getInt() == type)
				return true;
		}
		return false;
	}

	/**
	 * Create a new device for the given name,
	 * type and params.
	 */
	private Device createDevice(Vector params) throws Exception
	{
		return DeviceFactory.createDevice(params);
	}


}

