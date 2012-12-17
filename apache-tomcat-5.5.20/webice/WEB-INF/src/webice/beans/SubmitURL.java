package webice.beans;

import java.util.*;
import java.net.*;
import java.io.*;

/**
 * Submit a url to the server.
 * Used for resubmitting an analyzeCrystal or autoindex job 
 * to the crystal-analysis.
 */
public class SubmitURL
{
	static public void main(String args[])
	{
		if (args.length != 1) {
			System.out.println("Usage: SubmitURL <url>");
			return;
		}
		
		try {
		
		String urlStr = args[0];
		

		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		con.setConnectTimeout(10000); // set timeout to 10 seconds
		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200) {
			// cannot load the image
			System.out.println("ERROR: " + String.valueOf(response) + " " + con.getResponseMessage());
			// Close socket
			con.disconnect();
								
		}

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line = null;
		while ((line=reader.readLine()) != null) {
			System.out.println(line);
		}

		reader.close();
		con.disconnect();
		
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
	}
}

