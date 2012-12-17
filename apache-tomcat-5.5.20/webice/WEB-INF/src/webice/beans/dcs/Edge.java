package webice.beans.dcs;

public class Edge
{
	public String name = "";
	public double en1 = 0.0;
	public double en2 = 0.0;
	
	public Edge()
	{
	}
	
	public Edge(String name, double en1, double en2)
	{
		this.name = name;
		this.en1 = en1;
		this.en2 = en2;
	}
	
	public void copy(Edge other)
	{
		name = other.name;
		en1 = other.en1;
		en2 = other.en2;
	}
	
	public String getAtom()
	{
		if ((name == null) || (name.length() == 0))
			return "";
			
		int pos = name.indexOf("_"); // under score
		if (pos < 1)
			pos = name.indexOf("-"); // dash
		if (pos < 1)
			return "";
		return name.substring(0, pos);
	}
	
	public String getEdge()
	{
		if ((name == null) || (name.length() == 0))
			return "";
			
		int pos = name.indexOf("_"); // under score
		if (pos < 1)
			pos = name.indexOf("-"); // dash
		if (pos < 1)
			return "";
		return name.substring(pos+1);
	}
}

