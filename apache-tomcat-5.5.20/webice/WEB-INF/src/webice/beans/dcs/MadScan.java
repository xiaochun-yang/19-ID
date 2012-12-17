package webice.beans.dcs;

public class MadScan
{
	private String dir = "";
	private String rootName = "";
	private Edge edge = new Edge();
	private double time = 0.0;
	
	public MadScan()
	{
	}
	
	public MadScan(String dir, String rootName,
				String edgeName,
				double en1,
				double en2,
				double time)
	{
		this.dir = dir;
		this.rootName = rootName;
		edge.name = edgeName;
		edge.en1 = en1;
		edge.en2 = en2;
		this.time = time;
	}
	
	public void reset()
	{
		dir = "";
		rootName = "";
		edge.name = "";
		edge.en1 = 0.0;
		edge.en2 = 0.0;
		time = 0.0;
	}
	
	public void copy(MadScan other)
	{
		dir = other.getDir();
		rootName = other.getRootName();
		edge.copy(other.getEdge());
		time = other.getTime();
	}
	
	public void setDir(String d)
	{
		dir = d;
		if (dir == null)
			dir = "";
	}
	
	public String getDir()
	{
		return dir;
	}
	
	public void setRootName(String d)
	{
		rootName = d;
		if (rootName == null)
			rootName = "";
	}
	
	public String getRootName()
	{
		return rootName;
	}
	
	public void setEdge(String n, double en1, double en2)
	{
		edge.name = n;
		if (edge.name == null)
			edge.name = "";
		edge.en1 = en1;
		edge.en2 = en2;
	}
	
	public void setEdge(Edge e)
	{
		if (e == null)
			return;
		setEdge(e.name, e.en1, e.en2);
	}
	
	public Edge getEdge()
	{
		return edge;
	}
	
	public String getEdgeName()
	{
		return edge.name;
	}
	
	public double getEdgeEnergy()
	{
		return edge.en1;
	}
	
	public double getEdgeCutoff()
	{
		return edge.en2;
	}
	
	public void setTime(double t)
	{
		time = t;
		
		if (time < 0.0)
			time = 0.0;
	}
	
	public double getTime()
	{
		return time;
	}
	
	// { directory_ fileRoot_ selectedEdge_ edgeEnergy_ edgeCutoff_ scanTime_ }
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		
		buf.append("{");
		if (dir.length() == 0)
			buf.append(" {}");
		else
			buf.append(" " + dir);
			
		if (rootName.length() == 0)
			buf.append(" {}");
		else
			buf.append(" " + rootName);
		
		if (edge.name.length() == 0)
			buf.append(" {}");
		else
			buf.append(" " + edge.name);
			
		buf.append(" " + String.valueOf(edge.en1));
		buf.append(" " + String.valueOf(edge.en2));
		buf.append(" " + String.valueOf(time));
		
		buf.append(" }");
		
		return buf.toString();
	}
}

