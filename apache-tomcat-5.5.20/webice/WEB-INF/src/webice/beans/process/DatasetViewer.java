/**
 * Javabean for SMB resources
 */
package webice.beans.process;

import webice.beans.*;

/**
 * @class ProcessViewer
 * Bean class that represents a process viewer. Holds parameters for setting
 * up a display for data processing.
 */
public class DatasetViewer
{
	private Dataset dataset = null;

	private String viewer = "setup";

	public DatasetViewer(Dataset d)
	{
		dataset = d;
	}

	public String getName()
	{
		return dataset.getName();
	}

	public void setViewer(String v)
	{
		if (v != null)
			viewer = v;
	}


	public String getViewer()
	{
		return viewer;
	}

	public void setDataset(Dataset d)
	{
		dataset = d;
	}

	public Dataset getDataset()
	{
		return dataset;
	}


}

