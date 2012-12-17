package webice.beans.dcs;



public class RobotStatus
{
	
	public int cassetteIndex = -1;
	public String crystalPort = "";
	
	/**
	 */
	public RobotStatus(String str)
		throws Exception
	{
		parse(str);
	}
	
	/**
	 */
	public void parse(String str)
		throws Exception
	{	
		if (str == null)
			throw new Exception("Null robot_status string");
				
		int pos1 = str.indexOf("mounted: {");
		if (pos1 > 0) {
			int pos2 = str.indexOf("}", pos1);
			if (pos2 > pos1) {
				String mount = str.substring(pos1+10, pos2);
				if (mount.length() >= 5) {
					char tt = mount.charAt(0);
					if (tt == 'l')
						cassetteIndex = 1;
					else if (tt == 'm')
						cassetteIndex = 2;
					else if (tt == 'r')
						cassetteIndex = 3;
					crystalPort = String.valueOf(mount.charAt(4)) 
							+  String.valueOf(mount.charAt(2));
				} else {
					// No sample mounted
				}
			}
		}
		
	}
	
	/**
	 * Is sample mounted
	 */
	public boolean isMounted()
	{
		return ((cassetteIndex > 0) && (cassetteIndex < 4) && (crystalPort.length() > 0));
	}
	
}	
