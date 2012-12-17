/**
 * Javabean for SMB resources
 */
package webice.beans.strategy;

import java.util.TreeMap;
import webice.beans.*;
import java.net.*;
import java.io.*;
import java.util.*;

/**
 * @class StrategyViewer
 * Bean class that represents a process viewer. Holds parameters for setting
 * up a display for data processing.
 */
public class StrategyViewer implements PropertyListener
{

	/**
	 * Client
	 */
	private Client client = null;


	/**
	 */
	private TopNode topNode = null;

	/**
	 */
	private NavNode selectedNode = null;

	/**
	 * Last image dir
	 */
	private String defImageDir = "";

	private boolean defUseGlobalImageDir = true;

	private String lastError = "";

	private FileBrowser fileBrowser = null;


	/**
	 * Bean constructor
	 */
	public StrategyViewer()
		throws Exception
	{
		init();
	}

	/**
	 * Constructor
	 */
	public StrategyViewer(Client c)
		throws Exception
	{
		client = c;

		init();
	}

	/**
	 * Initializes variables
	 */
	private void init()
		throws Exception
	{
		defImageDir = "/data/" + client.getUser();
		defUseGlobalImageDir = true;

		if (isUseGlobalImageDir())
			fileBrowser = client.getFileBrowser();
		else
			fileBrowser = new FileBrowser(client);

		if (!client.getImperson().dirExists(getWorkDir()))
			client.getImperson().createDirectory(getWorkDir());

		// Create TopNode
		topNode = new TopNode("Runs", this);

		try {

		topNode.loadChildren();

		// Set default selection to top node.
		setSelectedNode(topNode);

		} catch (Exception e) {
			System.out.println("StrategyViewer::init: topNode.loadChildren failed:"
						+ e.getMessage());
		}

	}

	/**
	 * Callback when a config value is changed
	 */
	public void propertyChanged(String name, String val)
		throws Exception
	{
		// Work dir has changed
		if (name.equals("top.workDir")) {
			// Create webice top dir
			if (!client.getImperson().dirExists(getWorkDir())) {
				client.getImperson().createDirectory(getWorkDir());
			}
		} else if (name.equals("top.imageDir") && isUseGlobalImageDir()) {
			setImageDir(val);

		} else if (name.equals("strategy.useGlobalImageDir")) {
			if (isUseGlobalImageDir())
				fileBrowser = client.getFileBrowser();
			else if (fileBrowser == client.getFileBrowser())
				fileBrowser = new FileBrowser(client);
		}
	}


	/**
	 * Return top node
	 */
	public TopNode getTopNode()
	{
		return topNode;
	}


	/**
	 * Remove run of the given name
	 * @param run name
	 */
	public void removeRun(String name)
	{
		topNode.removeChild(name);
	}

	/**
	 * Returns run viewer of the given name. Can be null if not found.
	 * @returns DatsetViewer
	 */
	public NavNode getNode(String path)
	{

		if (!path.startsWith(topNode.getPath())) {
			return null;
		}

		if (path.length() == topNode.getPath().length())
			return topNode;


		return getNode(path, topNode);
	}

	/**
	 * Recurve routine
	 */
	private NavNode getNode(String path, NavNode parent)
	{

		Object children[] = parent.getChildren();

		if (children == null)
			return null;

		NavNode child = null;
		String childPath = null;
		for (int i = 0; i < children.length; ++i) {
			child = (NavNode)children[i];
			childPath = child.getPath();
			if (path.equals(childPath)) {
				return child;
			} else if (path.startsWith(childPath + "/")) {
				return getNode(path, child);
			}
		}

		return null;

	}

	/**
	 * Return the top work dir of this viewer
	 */
	public String getWorkDir()
	{

		return client.getWorkDir() + "/strategy";
	}


	/**
	 * Return the client this viewer is associated with
	 */
	public Client getClient()
	{
		return client;
	}

	/**
	 * Set the client
	 */
	public void setClient(Client c)
	{
		client = c;
	}

	/**
	 * Check if this is the selected node
	 */
	public boolean isSelectedNode(NavNode node)
	{
		return (node == selectedNode);
	}

	/**
	 * Select a node.
	 * Only one node can be selected at any time
	 */
	public void setSelectedNode(NavNode node)
	{
		try {

		// can be null
		selectedNode = node;

		// Load the node if needed
		selectedNode.load();

		node.setExpanded(true);


		// Parent must be expanded so that
		// we can see the selected node
		// in the tree
		if (node.getParent() != null)
			node.getParent().setExpanded(true);

		} catch (Exception e) {
			setLastError("Failed to select node " + node.getName() + ": " + e.getMessage());
		}

	}

	public void setSelectedNode(String path)
	{
		NavNode node = getNode(path);

		if (node != null)
			setSelectedNode(node);
	}

	/**
	 * Returns the selected node
	 * There is only one selected node at any time
	 */
	public NavNode getSelectedNode()
	{
		return selectedNode;
	}

	/**
	 * Returns last error
	 */
	public String getLastError()
	{
		return lastError;
	}

	/**
	 * Set last error
	 */
	public void setLastError(String s)
	{
		lastError = s;
	}

	public FileBrowser getFileBrowser()
	{
		return fileBrowser;
	}

	private boolean isUseGlobalImageDir()
	{
		return client.getProperties().getPropertyBoolean("strategy.useGlobalImageDir", defUseGlobalImageDir);
	};

	public String getImageDir()
	{

		if (isUseGlobalImageDir())
			return client.getImageDir();

		return client.getProperties().getProperty("strategy.imageDir", defImageDir);
	}

	public void setImageDir(String s)
	{

		client.getProperties().setProperty("strategy.imageDir", s);
		if (!s.equals(client.getImageDir()) && isUseGlobalImageDir())
			client.setImageDir(s);

	}

	/**
	 * Reload existing node
	 */
	public NavNode reloadNode(String path)
	{
		try {

			NavNode node = getNode(path);

			if (node == null)
				throw new Exception("Cannot find node " + path);

			NavNode parent = node.getParent();

			// top node has no parent.
			// Simply reload its children.
			if (parent == null) {
				node.loadChildren();
				return node;
			}

			return parent.reloadChild(node.getName());

		} catch (Exception e) {
			setLastError("Reload failed: " + e.getMessage());
			return null;
		}

	}

}


