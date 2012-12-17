/**
 * Javabean for SMB resources
 */
package webice.beans.process;

import webice.beans.*;
import java.util.TreeMap;

/**
 * @class ProcessViewer
 * Bean class that represents a process viewer. Holds parameters for setting
 * up a display for data processing.
 */
public class ProcessViewer implements PropertyListener
{

	/**
	 * Client
	 */
	private Client client = null;

	/**
	 * Sorted map
	 */
	private TreeMap datasets = new TreeMap();

	/**
	 */
	private DatasetViewer selectedDataset = null;

	private String command = ProcessViewer.COMMAND_SHOW;

	public static final String COMMAND_SHOW = "showDatasets";
	public static final String COMMAND_LOAD = "loadDatasets";
	public static final String COMMAND_SAVE = "saveDatasets";


	/**
	 * Bean constructor
	 */
	public ProcessViewer()
	{
		init();
	}

	/**
	 * Constructor
	 */
	public ProcessViewer(Client c)
	{
		client = c;

		init();
	}

	/**
	 * Initializes variables
	 */
	private void init()
	{
/*		Dataset set1 = new Dataset("example1");
		set1.setTarget("target1");
		set1.setCrystalId("2000");
		set1.setFile("/data/penjitk/process/example1.xml");

		Dataset set2 = new Dataset("example2");
		set2.setTarget("target1");
		set2.setCrystalId("2001");
		set2.setFile("/data/penjitk/process/example2.xml");

		Dataset set3 = new Dataset("example3");
		set3.setTarget("target1");
		set3.setCrystalId("2003");
		set3.setFile("/data/penjitk/process/example3.xml");

		addDataset(set1);
		addDataset(set2);
		addDataset(set3);*/

	}

	/**
	 */
	public void propertyChanged(String name, String val)
		throws Exception
	{
	}

	/**
	 * Set the client
	 */
	public void setClient(Client c)
	{
		client = c;
	}

	/**
	 * Returns array of Dataset objects this viewer holds
	 * @return array of Dataset objects. Null if there is no Dataset.
	 */
	public Object[] getDatasetViewers()
	{
		return datasets.values().toArray();
	}

	/**
	 * Returns array of names of Dataset objects this viewer holds
	 * @return array names of Dataset objects. Null if there is no Dataset.
	 */
	public Object[] getDatasetNames()
	{

		return datasets.keySet().toArray();
	}

	/**
	 * Add a new dataset to the hashtable. If datasets of the same name exists,
	 * it will be replaced.
	 * @param New dataset to be added
	 */
	public void addDataset(Dataset s)
	{
		if (s == null)
			return;

		DatasetViewer v = getDatasetViewer(s.getName());

		if (v != null) {
			v.setDataset(s);
		} else {
			DatasetViewer viewer = new DatasetViewer(s);
			datasets.put(viewer.getName(), viewer);
		}
	}

	/**
	 * Remove dataset of the given name
	 * @param dataset name
	 */
	public void removeDataset(String name)
	{

		if (datasets.containsKey(name))
			datasets.remove(name);
	}

	/**
	 * Returns dataset viewer of the given name. Can be null if not found.
	 * @returns DatsetViewer
	 */
	public DatasetViewer getDatasetViewer(String name)
	{
		return (DatasetViewer)datasets.get(name);
	}

	/**
	 * Returns dataset of the given name. Can be null if not found.
	 * @returns Datset
	 */
	public Dataset getDataset(String name)
	{
		DatasetViewer viewer = getDatasetViewer(name);

		if (viewer != null)
			return viewer.getDataset();

		return null;
	}

	/*
	 * Check if the viewer contains datset of the given name or not.
	 * @param Datset name
	 * @return true if the viewer contains datset of the given name
	 */
	public boolean hasDataset(String name)
	{
		return datasets.containsKey(name);
	}

	/**
	 * Change the dataset selection
	 * @param Dataset to be displayed
	 */
	public void setSelectedDatasetName(String name)
	{
		selectedDataset = getDatasetViewer(name);

	}

	/**
	 * Returns the selected dataset.
	 * @return Selected dataset.
	 */
	public String getSelectedDatasetName()
	{
		if (selectedDataset != null)
			return selectedDataset.getName();

		return null;
	}

	/**
	 * Returns the selected dataset.
	 * @return Selected dataset.
	 */
	public DatasetViewer getSelectedDatasetViewer()
	{
		return selectedDataset;

	}

	/**
	 * Returns the selected dataset.
	 * @return Selected dataset.
	 */
	public Dataset getSelectedDataset()
	{
		if (selectedDataset != null)
			return selectedDataset.getDataset();

		return null;

	}

	/**
	 */
	public void setSelectedDataset(Dataset d)
	{
		if (d == null) {
			setSelectedDatasetName("");
			return;
		}

		setSelectedDatasetName(d.getName());
	}

	/**
	 */
	public void addDatasets(Dataset newSets[])
	{
		if (newSets == null)
			return;

		for (int i = 0; i < newSets.length; ++i) {
			addDataset(newSets[i]);
		}
	}

	public void setDatasetsCommand(String c)
	{
		if (c == null)
			c = ProcessViewer.COMMAND_SHOW;

		command = c;
	}

	public String getDatasetsCommand()
	{
		return command;
	}


}


