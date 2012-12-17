package cts;

public class BeamlineInfo
{
	private int bId;
	private String str;
	private String name = "";
	private String position = "";
	
	public BeamlineInfo(int bId, String str)
	{
		this.bId = bId;
		this.str = str;
		int pos = str.indexOf(" ");
		if (pos > 0) {
			name = str.substring(0, pos);
			position = str.substring(pos+1);
		} else {
			name = str;
		}
		
		if (str == null)
			str = "";
	}
	
	public int getId() { return bId; }
	public String getBeamlineName() { return name; }
	public String getCassettePosition() { return position; }
	public String toString() { return str; }
	
	public void dump()
	{
		System.out.println("bid=" + bId + " bname=" + name + " bposition=" + position);
	}
}

