/**
 * Javabean for SMB resources
 */
package webice.beans.strategy;

import webice.beans.*;
import java.util.*;
import java.io.*;
import java.net.*;

/**
 * @class SpacegroupNode
 *
 */
public class SpacegroupNode extends NavNode
{

	private StrategyViewer top = null;
	private Client client = null;

	/**
	 */
	private Vector nodeViewerFiles = new Vector();

	private static String TAB_SUMMARY = "Strategy Results";
	private static String TAB_DETAILS = "Details";

	/**
	 * List of all result files
	 */
	private TreeMap resultFiles = new TreeMap();

	/**
	 * List of StrategyResults used in summary page
	 */
	private Vector results = new Vector();

	/**
	 */
	private double startPhi = 400.0;
	private double endPhi = -1.0;

	private String log = "";

	private boolean summaryLoaded = false;

	private boolean loaded = false;

	/**
	 * Constructor
	 */
	public SpacegroupNode(String n, NavNode p, StrategyViewer v)
		throws Exception
	{
		super(n, p);

		top = v;
		client = top.getClient();

		clearTabs();

		addTab(TAB_SUMMARY);
		addTab(TAB_DETAILS);

		setSelectedTab(TAB_SUMMARY);

	}

	public void load()
		throws Exception
	{
		if (loaded)
			return;

		loadSetup();

		loadSummary();

		loadDetails();

		loadChildren();

		loaded = true;

	}

	/**
	 * loadSetup
	 */
	public void loadSetup()
		throws Exception
	{
	}


	private void loadSummary()
		throws Exception
	{
		summaryLoaded = false;
		results.clear();

		// Read strategy.out
		StrategyResult res = readStrategyFile(top.getWorkDir() + getPath() + "/strategy.out");

		if (res != null) {
			res.name = StrategyResult.STRATEGY;
			res.desc = "Strategy";
			results.add(res);

			if (res.startPhi < startPhi)
				startPhi = res.startPhi;
			if (res.endPhi > endPhi)
				endPhi = res.endPhi;
		}


		// Read strategy_anom.out
		res = readStrategyFile(top.getWorkDir() + getPath() + "/strategy_anom.out");

		if (res != null) {
			res.name = StrategyResult.STRATEGY_ANOM;
			res.desc = "Anomalous Strategy";
			results.add(res);

			if (res.startPhi < startPhi)
				startPhi = res.startPhi;
			if (res.endPhi > endPhi)
				endPhi = res.endPhi;
		}

		// Read testgen.out
		res = readTestgenFile(top.getWorkDir() + getPath() + "/testgen.out");

		if (res != null) {
			res.name = StrategyResult.TESTGEN;
			res.desc = "Testgen";
			results.add(res);
		}

		summaryLoaded = true;

	}

	/**
	 * loadResult
	 */
	public void loadDetails()
		throws Exception
	{

		// Clear old results
		resultFiles.clear();

		TreeMap tmpFiles = new TreeMap();
		client.getImperson().listDirectory(getWorkDir(),
											null,
											null,
											tmpFiles);



		// Get result files
		Object values[] = tmpFiles.values().toArray();

		// Filter files of the known types
		if (values != null) {
			for (int i = 0; i < values.length; ++i) {
				FileInfo info = (FileInfo)values[i];
				info.type = FileHelper.getFileType(info.name);
				if (info.type != FileHelper.UNKNOWN) {
					resultFiles.put(info.name, info);
				}
			}
		}

	}

	private StrategyResult readStrategyFile(String s)
		throws Exception
	{
		StrategyResult ret = new StrategyResult();


		String content = client.getImperson().readFile(s);

		int pos1 = 0;
		int pos2 = 0;

		// Search for summary text
		pos1 = content.indexOf("axis is closest");

		if (pos1 < 0)
			throw new Exception("Could not find text 'axis is closest' in file " + s);

		while (pos1 > 0) {
			if (content.charAt(pos1) == '\n')
				break;
			--pos1;
		}
		++pos1;

		if (pos1 <= 1)
			throw new Exception("Could not find end of line before 'axis is closest' in file " + s);

		pos2 = content.indexOf(" Start", pos1);

		if (pos2 < 0)
			throw new Exception("Count not find text 'Start' in file " + s);

		ret.summary = content.substring(pos1, pos2);

		pos1 = content.indexOf(" Optimum", pos2);

		if (pos1 < 0)
			throw new Exception("Could not find text 'Optimum' in file " + s);

		pos2 = content.indexOf(" Type", pos1);

		if (pos2 < 0)
			throw new Exception("Count not find text 'Type' in file " + s);

		ret.summary += content.substring(pos1, pos2);

		// Search for statistics

		pos1 = content.indexOf(" The number", pos2);

		if (pos1 < 0)
			throw new Exception("Could not find text 'The number' in file " + s);

		pos2 = content.indexOf(" COMPLETE", pos1);

		if (pos2 < 0)
			throw new Exception("Count not find text 'COMPLETE' in file " + s);



		ret.statistics = " UNIQUE DATA\n ===========\n"
						+ content.substring(pos1, pos2);



		// Search for start phi
		pos1 = ret.summary.indexOf("From");

		if (pos1 < 0)
			throw new Exception("Could not find start phi in file " + s);

		pos2 = ret.summary.indexOf("to", pos1);

		ret.startPhi = Double.parseDouble(ret.summary.substring(pos1+4, pos2).trim());

		// Search for end phi
		pos1 = pos2 + 2;

		pos2 = ret.summary.indexOf("degrees", pos1);

		if (pos2 < 0)
			throw new Exception("Could not find end phi in file " + s);

		ret.endPhi = Double.parseDouble(ret.summary.substring(pos1, pos2).trim());


		return ret;



	}

	/**
	 * Read testgen.out
	 */
	private StrategyResult readTestgenFile(String s)
		throws Exception
	{
		StrategyResult ret = new StrategyResult();

		Client client = top.getClient();

		String content = client.getImperson().readFile(s);

		int pos1 = 0;
		int pos2 = 0;

		// Search for summary text
		pos1 = content.indexOf(" TESTGEN");

		if (pos1 < 0)
			throw new Exception("Could not find text 'TESTGEN' in file " + s);

		pos2 = content.indexOf(" ***** IMPORTANT", pos1);

		if (pos2 < 0)
			throw new Exception("Count not find text ' ***** IMPORTANT' in file " + s);

		ret.summary = content.substring(pos1, pos2);


		return ret;

	}

	/**
	 * loadChildren
	 */
	public void loadChildren()
		throws Exception
	{
	}

	public String getType()
	{
		return "spacegroup";
	}

	public String getDesc()
	{
		return "Strategy for Point Group";
	}


	public String getWorkDir()
	{
		return top.getWorkDir() + getPath();
	}


	public Object[] getResultFiles()
	{
		return resultFiles.values().toArray();
	}

	/**
	 * Returns a result for summary page
	 */
	public StrategyResult getResult(String which)
	{
		for (int i = 0; i < results.size(); ++i) {
			StrategyResult res = (StrategyResult)results.elementAt(i);
			if (res.name.equals(which))
				return res;
		}

		return null;
	}

	/**
	 * Returns all results for summary page
	 */
	public Object[] getResults()
	{
		return results.toArray();
	}

	public String getLog()
	{
		return log;
	}

	public void setLog(String s)
	{
		log = s;
	}

	public void resetLog()
	{
		log = "OK";
	}

	/**
	 * Whether or not the tab is ready to display
	 * contents.
	 */
	public boolean isTabViewable(String tabName)
	{
		if (tabName.equals(TAB_SUMMARY)) {
			return summaryLoaded;
		} else if (tabName.equals(TAB_DETAILS)) {
			return true;
		}

		return false;
	}

}

