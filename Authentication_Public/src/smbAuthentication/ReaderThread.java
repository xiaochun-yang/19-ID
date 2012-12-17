package edu.stanford.slac.ssrl.smb.authentication;

import java.io.*;
import java.util.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class ReaderThread extends Thread
{
	private static final Log LOG = LogFactory.getLog(PamAuthMethod.class.getName());
	InputStream in = null;
	StringBuffer buf = new StringBuffer();
		
	public ReaderThread(InputStream in)
	{
		this.in = in;
	}
		
	public String getData()
	{
		return buf.toString();
	}
		
	public void run()
	{
		try {
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(in));
		String line = null;
		while ((line=reader.readLine()) != null) {
			if (buf.length() > 0)
				buf.append("\n");
			buf.append(line);
		}
		
//		in.close();
		
		} catch (IOException e) {
			LOG.warn("Error in ReaderThread: " + e.getMessage());
		} finally {
			try {
				if (in != null)
					in.close();
				in = null;
			} catch (Exception e) {
				LOG.warn("ReaderThread failed to close InputStream");
			}
		}
	}
}
