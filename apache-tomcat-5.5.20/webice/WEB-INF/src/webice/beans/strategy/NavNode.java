package webice.beans.strategy;

import java.util.*;

/**
 * Base class for all nodes that can be displayed
 * In the navigation tree.
 */
public abstract class NavNode
{
	/**
	 * Node name. Used as display string
	 * in navigation tree.
	 */
	private String name = null;

	/**
	 * Is node expanded.
	 * When node is expanded, children are visible.
	 */
	private boolean expanded = false;

	/**
	 * Parent of this node. Top node has null parent.
	 */
	private NavNode parent = null;

	/**
	 * Children. Sorted by name
	 */
	private TreeMap children = new TreeMap();

	/**
	 * Currently selected tab name
	 */
	private String selectedTab = "";

	/**
	 */
	private Vector tabs = new Vector();

	/**
	 * Constructor. Node parent is set to null.
	 * @param n Name of the node
	 */
	public NavNode(String n)
	{
		name = n;
	}

	/**
	 * Constructor
	 * @param n Name of the node
	 * @param p Parent of the node
	 */
	public NavNode(String n, NavNode p)
	{
		name = n;
		parent = p;
	}

	/**
	 * Returns Node type.
	 */
	public abstract String getType();

	/**
	 * Returns node description
	 */
	public abstract String getDesc();

	/**
	 * Set node name.
	 * @param s Name of the node
	 */
	public void setName(String s)
	{
		name = s;
	}

	/**
	 * Returns node name.
	 * @return Node name
	 */
	public String getName()
	{
		return name;
	}

	/**
	 * Return true if this node is expanded.
	 * @return True if the node is expanded.
	 */
	public boolean isExpanded()
	{
		return expanded;
	}

	/**
	 * Set open state of this node.
	 * @param s Set the node state to expanded or not.
	 */
	public void setExpanded(boolean s)
	{

		expanded = s;

		if (expanded && (parent != null))
			parent.setExpanded(true);
	}

	/**
	 * Add a child to this node. Set parent attribute of the
	 * child to this node.
	 * @param node Child to be added to this node.
	 */
	public void addChild(NavNode node)
	{
		node.setParent(this);
		children.put(node.getName(), node);
	}

	/**
	 * Remove child from this node. Do not report error
	 * if this node does not contain the child of this name.
	 * @param name Name of the child to be removed.
	 */
	public void removeChild(String name)
	{
		NavNode foundNode = (NavNode)children.remove(name);


		if (foundNode == null)
			return;

		foundNode.setParent(null);
		foundNode = null;
	}

	/**
	 * Remove all children from this node.
	 */
	public void removeChildren()
	{
		children.clear();
	}

	/**
	 * Return child of the given name.
	 * @param s Name of the child
	 */
	public NavNode getChild(String s)
	{
		return (NavNode)children.get(s);
	}

	/**
	 * Return a list of children of this node
	 * @return Array of NavNode objects
	 */
	public Object[] getChildren()
	{
		return children.values().toArray();
	}

	/**
	 * Return children names.
	 * @return Array of string
	 */
	public Object[] getChildrenNames()
	{
		return children.keySet().toArray();
	}

	/**
	 * Return number of children.
	 * @return Number of children.
	 */
	public int getChildrenCount()
	{
		return children.size();
	}

	/**
	 * Return full path to this node
	 * @return Full path to this node from root node
	 *  each node depth is separated by a /.
	 */
	public String getPath()
	{
		String ret = "/" + getName();
		NavNode p = getParent();
		while (p != null) {
			ret = "/" + p.getName() + ret;
			p = p.getParent();
		}

		return ret;
	}

	/**
	 * Return parent of this node.
	 * @return Parent of this node as NavNode.
	 */
	public NavNode getParent()
	{
		return parent;
	}

	/**
	 * Set parent of this node.
	 * @param p New parent of thos node.
	 */
	public void setParent(NavNode p)
	{
		parent  = p;
	}

	/**
	 * Load children for this node.
	 * @exception Exception Thrown if load fails.
	 */
	public abstract void loadChildren()
		throws Exception;

	/**
	 * Reload a child node
	 * @param s Child node name
	 * @exception Exception Thrown if reload fails.
	 */
	public NavNode reloadChild(String s)
		throws Exception
	{
		return null;
	}

	/**
	 * Returns true if this node contains the given child name.
	 * @param s Child name.
	 * @return True or false.
	 */
	public boolean hasChild(String s)
	{
		return (children.get(s) != null);
	}

	/**
	 * Returns true if this node is an ancester of the given node.
	 * A node is an acester if it appear
	 */
	public boolean isAncestorOf(NavNode other)
	{
		return isAncestorOf(other.getPath());
	}

	/**
	 * Returns true if this node is an ancester of node
	 * of the given path.
	 */
	public boolean isAncestorOf(String path)
	{
		String thisPath = getPath();
		int pos = path.indexOf(thisPath);

		if (pos != 0)
			return false;

		if (path.length() == thisPath.length())
			return false;

		if (path.charAt(thisPath.length()) != '/')
			return false;

		return true;
	}

	/**
	 * Return an array of tab names for this node.
	 * Tab name is an identifier for a display for this node.
	 * Each node can have more than one types of display.
	 * There is onyl one type of display (one tab)
	 * visible at a time.
	 * @return Array of tab names.
	 */
	public Object[] getTabs()
	{
		return tabs.toArray();
	}

	/**
	 * Returns the selected tab name.
	 * @return Name of selected tab.
	 */
	public String getSelectedTab()
	{
		return selectedTab;
	}

	/**
	 * Set selected tab.
	 * @param s Selected tab.
	 */
	public void setSelectedTab(String s)
	{
		if (s == null)
			return;

		selectedTab = s;

	}

	/**
	 */
	protected void addTab(String tab)
	{
		tabs.add(tab);
	}

	/**
	 */
	protected void clearTabs()
	{
		tabs.clear();
	}

	/**
	 * Returns the currently selected viewer.
	 * @return Name of the viewer currently
	 *  selected for this node.
	 */
	public String getViewer()
	{
		return getType() + getSelectedTab().replace(' ', '_');
	}

	/**
	 * Whether or not the tab is ready to display
	 * contents.
	 */
	public boolean isTabViewable(String tabName)
	{
		return false;
	}

	public boolean isSelectedTabViewable()
	{
		return isTabViewable(getSelectedTab());
	}

	/**
	 */
	public void load()
		throws Exception
	{
	}

}
