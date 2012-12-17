/**
 * Javabean for SMB resources
 */
package webice.beans;


import java.util.*;
import java.net.*;
import java.io.*;
import java.util.regex.Pattern;
/**
 * @class FileBrowser
 * List a files/directories using the impersonation server
 */
public class FileBrowser
{
	/**
	 */
	Client client = null;

	private String curDir = null;
	private String curFilter = "";
	private TreeMap dirs = new TreeMap();
	private TreeMap files = new TreeMap();

	private boolean showImageFilesOnly = true;


	/**
	 * Constructor
	 */
	public FileBrowser(Client c)
	{
		client = c;
	}


	/**
	 * Returns sub directories of the current dir.
	 */
	public Object[] getSubDirectories()
	{
		return dirs.values().toArray();
	}

	/**
	 * Returns sub files of the current dir.
	 */
	public Object[] getFiles()
	{
		return files.values().toArray();
	}

	public Object[] getFileNames()
	{
		return files.keySet().toArray();
	}

	/**
	 */
	public String getDirectory()
	{
		return curDir;
	}

	public String getFilter()
	{
		return curFilter;
	}


	public void setShowImageFilesOnly(boolean s)
	{
		showImageFilesOnly = s;
	}

	public boolean getShowImageFileOnly()
	{
		return showImageFilesOnly;
	}

	/**
	 * Changes the current directory and retrieves sub directories.
	 */
	public void reloadDirectory()
		throws Exception
	{
		changeDirectory(curDir, curFilter, true);
	}

	/**
	 */
	public void changeToParentDirectory()
		throws Exception
	{
		changeToParentDirectory(curFilter);
	}

	/**
	 */
	public void changeToParentDirectory(String filter)
		throws Exception
	{
		int pos = curDir.lastIndexOf("/");
		if (pos < 0)
			return;

		String parentDir = curDir.substring(0, pos);
		changeDirectory(parentDir, filter, true);
	}

	/**
	 * Changes the current directory and retrieves sub directories.
	 */
	public void changeDirectory(String dir)
		throws Exception
	{
		changeDirectory(dir, curFilter, false);
	}

	/**
	 * Changes the current directory and retrieves sub directories.
	 */
	public void changeDirectory(String dir, String filter)
		throws Exception
	{
		changeDirectory(dir, filter, false);
	}

	/**
	 * Changes the current directory and retrieves sub directories.
	 */
	public void changeDirectory(String dir, String filter, boolean forced)
		throws Exception
	{
		if (dir == null)
			return;

		if (filter == null)
			filter = curFilter;
			
		// Remove the last trailing slash
		if (dir.endsWith("/") && (dir.length() > 1)) {
			dir = dir.substring(0, dir.length()-1);
		}

		int count = 0;
		while (dir.endsWith("/..")) {
			dir = dir.substring(0, dir.length()-3);
			++count;
		}

		while (count > 0) {
			int pos = dir.lastIndexOf('/');
			if (pos == 0) {
				dir = "/";
			} else if (pos > 0) {
				dir = dir.substring(0, pos);
			}
			--count;
		}

		if (!forced && (curDir != null)
			&& curDir.equals(dir) && curFilter.equals(filter))
			return;
			
		if (dir.indexOf("//") == 0)
			dir = dir.substring(1);

		TreeMap newDirs = new TreeMap();
		TreeMap newFiles = new TreeMap();

		// List files and dirs via the impersonation server
		// Inlcude symlinks.
		client.getImperson().listDirectory(dir, filter, newDirs, newFiles, true);

		// Filter imageg types
		if (showImageFilesOnly && (newFiles.size() > 0)) {
			String regex = client.getImageFiltersRegex();
			if ((regex != null) && (regex.length() > 0)) {
				TreeMap filteredFiles = new TreeMap();
				Iterator iter = newFiles.values().iterator();
				while (iter.hasNext()) {
					FileInfo info = (FileInfo)iter.next();
					if (Pattern.matches(regex, info.name))
						filteredFiles.put(info.name, info);
				}
				newFiles = filteredFiles;
			}

		}


		curDir = dir;
		curFilter = filter;

		dirs = null;
		files = null;

		dirs = newDirs;
		files = newFiles;

		newDirs = null;
		newFiles = null;
	}


}

