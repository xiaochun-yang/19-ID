package webice.beans.dcs;



public class RobotCassette
{
	public CassetteStatus left = new CassetteStatus(0);
	public CassetteStatus middle = new CassetteStatus(1);
	public CassetteStatus right = new CassetteStatus(2);
	
	

	public static RobotCassette parse(String str)
		throws Exception
	{
		if (str.length() != 581)
			throw new Exception("robot_cassette content has " + str.length() + "(expected 581) characters");

		RobotCassette ret = new RobotCassette();
		
		ret.left.status = str.charAt(0);
		ret.middle.status = str.charAt(194);
		ret.right.status = str.charAt(388);
		
		for (int i = 0; i < 96; ++i) {
			ret.left.portStatus[i] = str.charAt(2 + i*2);
			ret.middle.portStatus[i] = str.charAt(196 + i*2);
			ret.right.portStatus[i] = str.charAt(390 + i*2);
		} 
		
		return ret;
	}
	
	public CassetteStatus getCassetteStatus(int pos)
	{
		if (pos == 1)
			return left;
		else if (pos == 2)
			return middle;
		else if (pos == 3)
			return right;
			
		return null;
	}
	
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append(left.toString());
		buf.append(" ");
		buf.append(middle.toString());
		buf.append(" ");
		buf.append(right.toString());	
		
		return buf.toString();	
	}
}	
