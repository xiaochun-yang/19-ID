package sil.beans;

import java.io.*;
import java.util.*;

public class SilHeader
{
	private static Vector headers = new Vector();

	static {

		SilConfig silConfig = SilConfig.getInstance();

		String fname = silConfig.getTemplateDir() + "/" + "silTclHeader.txt";
		String line = null;
		BufferedReader reader = null;

		try {

			reader = new BufferedReader(new FileReader(fname));
			String n1, n3, n4;
			int n2;
			while ((line=reader.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(line, " ");
				if (tok.countTokens() < 4)
					continue;
				n1 = tok.nextToken();
				try {
					n2 = Integer.parseInt(tok.nextToken());
				} catch (NumberFormatException e) {
					n2 = 10;
				}
				n3 = tok.nextToken();
				if (!n3.equals("hide"))
					n3 = "show";
				n4 = tok.nextToken();
				if (!n4.equals("readonly"))
					n4 = "editable";
				headers.add(new HeaderData(n1, n2, n3, n4));
			}
			reader.close();
			reader = null;

		} catch (FileNotFoundException e) {
			SilLogger.error("Failed to open file " + fname + ": " + e.toString(), e);
		} catch (IOException e) {
			SilLogger.error("Failed to read file " + fname + ": " + e.toString(), e);
		} finally {
			try {
			if (reader != null)
				reader.close();
			} catch (Exception e) {
				SilLogger.error("Failed to close BufferedReader for " 
					+ fname + ": " + e.getMessage(), e);
			}
			reader = null;
		}

	}

	static Vector getHeaders()
	{
		return headers;
	}
	
	static void toTclString(StringBuffer buf)
	{
		buf.append("  {\n");
		HeaderData hh = null;
		for (int i = 0; i < headers.size(); ++i) {
			hh = (HeaderData)headers.elementAt(i);
			buf.append("    {" + hh.name + " " + hh.width
						+ " {" + hh.hide + " " + hh.readOnly + "}}\n");
		}
		buf.append("  }\n");
	}


}

