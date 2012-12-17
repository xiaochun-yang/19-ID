package webice.beans.dcs;

import java.io.*;
import webice.beans.WebiceLogger;

public class PeriodicTable
{
	private BasicElement table[][] = new BasicElement[10][19];
	
	public PeriodicTable()
	{
	}
	
	public BasicElement getElement(int row, int col)
	{
		if (row < 1)
			return null;
		if (row > 9)
			return null;
		if (col < 1)
			return null;
		if (col > 18)
			return null;
			
		return table[row][col];
	}
	
	/**
	 * Load periodic table from a file
	 */
	public void load(String fname)
		throws Exception
	{
		try {
		
		BufferedReader in = new BufferedReader(new FileReader(fname));
		
		String line = null;
		while ((line=in.readLine()) != null) {
			if (line.startsWith("#"))
				continue;
			line = line.trim();
			if (line.length() == 0)
				continue;
			BasicElement el = BasicElement.parse(line);
			if ((el.row < 1) || (el.row > 9) || (el.col < 1) || (el.col > 18))
				continue;
			table[el.row][el.col] = el;
		}
		
		} catch (Exception e) {
			WebiceLogger.error("Faileld to load periodictable from " + fname, e);
			throw e;
		}
		
	}
	
}

