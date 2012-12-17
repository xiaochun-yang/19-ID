package sil.io;

import java.io.*;
import java.util.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import sil.beans.ColumnData;

public class ColumnLoader
{
	protected final Log logger = LogFactoryImpl.getLog(getClass()); 

	// Load column data from text file
	static public List<ColumnData> load(String file)
		throws Exception
	{
//		System.out.println("ColumnLoader: loading file " + file);
		return load(new File(file));
	}

	// Load column data from text file
	static public List<ColumnData> load(File file)
		throws Exception
	{
		List<ColumnData> columnDataList = new ArrayList<ColumnData>();
		
		String line = null;
		BufferedReader reader = new BufferedReader(new FileReader(file));
		String n1, n2, n3, n4;
		while ((line=reader.readLine()) != null) {
//			System.out.println("ColumnLoader: reading line " + line);
			StringTokenizer tok = new StringTokenizer(line, " ");
			if (tok.countTokens() < 1)
				continue;
			ColumnData col = new ColumnData();
			col.setName(tok.nextToken());
			columnDataList.add(col);
			if (!tok.hasMoreTokens())
				continue;
			n2 = tok.nextToken();
			// Strip double quotes.
			n2 = n2.replaceAll("\"", "");
			n3 = tok.nextToken();
			if (!n3.equals("hide"))
				n3 = "show";
			n4 = tok.nextToken();
			if (!n4.equals("readonly"))
				n4 = "editable";
			col.setFormat(n2);
			col.setHide(n3);
			col.setReadOnly(n4);
		}
		reader.close();
		reader = null;
		
		return columnDataList;

	}

}

