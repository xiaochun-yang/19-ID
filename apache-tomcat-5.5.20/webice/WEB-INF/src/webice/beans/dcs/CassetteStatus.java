package webice.beans.dcs;


public class CassetteStatus
{
	public int position;
	// 1=normal cassette, 2=calibration cassette, 3=puck adapter, u=unknown
	public char status = 'u';
	// For normal cassette: A1-A8, ..., L1-L8
	// For puck adapter: A1-A16, D1-D16
	public char portStatus[] = new char[96];
	
	public CassetteStatus(int pos)
	{
		position = pos;
	}
	
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append(status + " ");
		for (int i = 0; i < 96; ++i) {
			buf.append(" " + portStatus[i]);
		}
		
		return buf.toString();
	}
}
