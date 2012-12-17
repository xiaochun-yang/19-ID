package webice.beans.dcs;

import java.util.*;
import java.io.*;

public class BasicElement
{
	public int atomic; // atomic number
	public int row; // position in the periodic table
	public int col; // position in the periodic table
	public String element = "";
	public Hashtable edges = new Hashtable(); // absorption edges
		
	/**
	 * Create BasicElement from a string
	 * Format: <atomic> <row> <col> <Element> <num edges> [<edge> <en1> <en2>]*
	 * e.g.: 40 5  4 Zr 2 K  17998.0 15775.1 L1  2532.0  2187.3
	 * atomic number = 40
	 * row = 5
	 * column = 4
	 * element = Zr
	 * has 2 absorption edges
	 * K absorption edge
	 * First absorption edge energy = 17998.0 for K
	 * Main associated esmission line = 15775.1 for K
	 * L1 absorption edge
	 * First absorption edge energy = 2532.0 for L1
	 * Main associated esmission line = 2187.3 for L1
	 */
	public static BasicElement parse(String s)
		throws Exception
	{
		if (s == null)
			throw new Exception("null string");
			
		if (s.length() == 0)
			throw new Exception("empty string");
			
		StringTokenizer tok = new StringTokenizer(s);
		
		int numToks = tok.countTokens();
		if (numToks < 5)
			throw new Exception("Expected at least 5 columns but got " + numToks + ": " + s);
			
		BasicElement el = new BasicElement();
		el.atomic = Integer.parseInt(tok.nextToken());
		el.row = Integer.parseInt(tok.nextToken());
		el.col = Integer.parseInt(tok.nextToken());
		el.element = tok.nextToken();
		int numEdges = Integer.parseInt(tok.nextToken());
		int expectedCols = 5+numEdges*3;
		if (numToks < expectedCols)
			throw new Exception("Expected " + expectedCols + " columns but got " + numToks + ": " + s);
		for (int i = 0; i < numEdges; ++i) {
			Edge edge = new Edge();
			edge.name = tok.nextToken();
			edge.en1 = Double.parseDouble(tok.nextToken());
			edge.en2 = Double.parseDouble(tok.nextToken());
			el.edges.put(edge.name, edge);
		}
		
		return el;
	}
	
	/**
 	 */
	public String toString()
	{
		StringBuffer ret = new StringBuffer();
		
		ret.append("el=" + element);
		ret.append(",atomic=" + atomic);
		ret.append(",row=" + row);
		ret.append(",col=" + col);
		ret.append(",num edges=" + edges.size());
		Enumeration en = edges.elements();
		while (en.hasMoreElements()) {
			Edge edge = (Edge)en.nextElement();
			ret.append(",[edge=" + edge.name + ",en1=" + edge.en1 + ",en2=" + edge.en2 + "]");
		}
		
		return ret.toString();
	}
}

