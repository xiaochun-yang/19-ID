/**
 * Javabean for SMB resources
 */
package webice.beans.strategy;
import webice.beans.*;
import java.util.*;

/**
 * @class TopNode
 * Bean class that represents a process viewer. Holds parameters for setting
 * up a display for data processing.
 */
public class TopNode extends NavNode
{

	private String status = "not_started";

	private TreeSet files = new TreeSet();

	private String wildcard = null;

	private StrategyViewer top = null;

	private String message = "OK";

	private Client client = null;

	private static final String allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890-_";

	/**
	 */
	public TopNode(String s, StrategyViewer v)
		throws Exception
	{
		// TopNode has no parent
		super(s, null);

		top = v;
		client = top.getClient();

		resetMessage();

		if (!client.getImperson().dirExists(getWorkDir()))
			client.getImperson().createDirectory(getWorkDir());

	}

	/**
	 * Override NavNode method
	 */
	public String getViewer()
	{
		return "showRuns";
	}

	public String getWorkDir()
	{
		return top.getWorkDir() + getPath();
	}

	/**
	 * Children of TopNode are RunNodes
	 */
	public void loadChildren()
	{
		try {


		resetMessage();

		removeChildren();

		TreeMap tmpDirs = new TreeMap();
		client.getImperson().listDirectory(getWorkDir(),
											null,
											tmpDirs,
											null);

		Object dirs[] = tmpDirs.keySet().toArray();

		if (dirs == null)
			return;

		int pos = 0;
		String dirName = null;
		for (int i = 0; i < dirs.length; ++i) {
				dirName = (String)dirs[i];
				try {
					LabelitNode child = new LabelitNode(dirName, this, top);
					addChild(child);
				} catch (Exception e) {
					message += "Failed to load node: " + dirName + ": " + e.getMessage() + "\n";
				}
		}

		} catch (Exception e) {
			System.out.println("TopNode::loadChildren: Imperson.listDirectory threw exception "
							+ e.getMessage());
			e.printStackTrace();
			message = "Failed to load runs: " + e.getMessage();
		}
	}

	/**
	 * Reload a child node. Delete old one, if exists, and
	 * replace it with a new one loaded from disk.
	 * @param s Child node name
	 * @exception Exception Thrown if reload fails.
	 */
	public NavNode reloadChild(String aName)
		throws Exception
	{
		// try to delete child node
		// If it does not exist then removeChild
		// does nothings
		removeChild(aName);


		// Create a new child node
		LabelitNode aNode = new LabelitNode(aName, this, top);
		addChild(aNode);

		return aNode;

	}

	public String getType()
	{
		return "top";
	}

	public String getDesc()
	{
		return "Autoindexing and Data Collection Strategy Calculations";
	}

	public Object[] getTabs()
	{
		return null;
	}

	/**
	 * Create a new run
	 */
	public NavNode createRun(String s)
	{
		try {

		resetMessage();

		if ((s == null) || (s.length() == 0)) {
			setMessage("Failed to create run: invalid name");
			return null;
		}

		for (int i = 0; i < s.length(); ++i) {
			if (allowed.indexOf(s.charAt(i)) < 0) {
				setMessage("Failed to create run: name contains invalid characters");
				return null;
			}
		}

		if (getChild(s) != null) {
			setMessage("Failed to create run: run " + s + " already exists");
			return null;
		}

		// Create subdir
		String subdir = getWorkDir() + "/" + s;

		// Check if dir already exists
		boolean test = client.getImperson().dirExists(subdir);

		// Don't mess up with it
		if (test) {
			setMessage("Failed to create run: dir " + subdir + " already exists");
			return null;
		}

		// Create the dir
		client.getImperson().createDirectory(subdir);

		// Copy input file fromt emplate
		client.getImperson().copyFile(ServerConfig.getScriptDir()
						+ "/autoindex_input.xml", subdir + "/input.xml");

		// Create RunNode
		LabelitNode child = new LabelitNode(s, this, top);
		addChild(child);


		return child;

		} catch (Exception e) {
			setMessage("Failed to create run: " + e.getMessage());
			return null;
		}
	}

	/**
	 * Delete a run
	 */
	public void deleteRun(String s)
	{
		try {

		resetMessage();

		LabelitNode aNode = (LabelitNode)getChild(s);

		if (aNode == null)
			throw new Exception("run " + s + " does not exist");

		if (aNode.isRunning())
			throw new Exception(s + " is running.");

		String subdir = getWorkDir() + "/" + s;

		// delete the dir
		client.getImperson().deleteDirectory(subdir);

		removeChild(s);

		} catch (Exception e) {
			message = "Failed to delete run " + s + ": " + e.getMessage();
		}
	}

	/**
	 */
	public String getMessage()
	{
		return message;
	}

	public void setMessage(String s)
	{
		message = s;
	}

	public void resetMessage()
	{
		message = "OK";
	}


}

