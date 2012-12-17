package webice.beans.dcs;

import java.util.*;

/**
*/
public class CollectWebParam
{
	public RunDefinition def = null;
	public RunExtra extra = null;
	public RunOptions op = null;
	public String statusFile = "";
	
	public CollectWebParam()
	{
		def = new RunDefinition();
		extra = new RunExtra();
		op = new RunOptions();
	}
	
	public CollectWebParam(RunDefinition run, RunExtra extra, RunOptions op)
	{
		this.def = def;
		this.extra = extra;
		this.op = op;
	}
	
	/**
	 * Run definition as in dcs message format
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append("{");
		buf.append(def.toString(false));
		buf.append("}");
		buf.append(" ");
		buf.append(extra.toString());
		buf.append(" ");
		buf.append(op.toString());
		if (statusFile.length() == 0)	
			buf.append(" {}");
		else
			buf.append(" " + statusFile);
			
		return buf.toString();
	}
	
}

