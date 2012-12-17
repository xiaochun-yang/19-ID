package edu.stanford.slac.imgsrv.test;

import java.io.*;
import java.util.*;

/**
 * @class MultiClientTest
 *
 * A test suite for running multiple clients that send and receive
 * messages to/from an image server simultaneouly on multiple threads;
 * each transaction runs on a its own thread.
 *
 * Test the data integrity, error conditions and performance.
 */
public class MultiClientTest
{

	private String propertyFilename = "./setup.properties";

	private String host = null;
	private int port = 0;

	private String userName = null;
	private String sessionId = null;
	private int startIndex = 0;
	private int numFiles = 0;
	private int numRepeatPerFile = 0;
	private String command = null;

	Vector clients = new Vector();


	/**
	 * @brief Constructor. Creates MultiClientTest object with
	 * default settings loaded from setup.properties file
	 * in the current directory.
	 */
	public MultiClientTest()
	{
	}

	/**
	 * @brief Constructor. Creates MultiClientTest object with
	 * default settings loaded from the given property file.
	 * @param propertyFilename Name of the property file to be loaded.
	 */
	public MultiClientTest(String propertyFilename)
	{
		this.propertyFilename = propertyFilename;
	}

	/**
	 * @brief Creates clients to handle each transaction on a new thread.
	 */
	public void run() throws Exception
	{


		FileInputStream stream = new FileInputStream(propertyFilename);
		Properties settings = new Properties();
		settings.load(stream);
		stream.close();

		host = settings.getProperty("host");
		port = Integer.parseInt(settings.getProperty("port"));

		userName = settings.getProperty("userName");
		sessionId = settings.getProperty("sessionId");
		startIndex = Integer.parseInt(settings.getProperty("startIndex"));
		numFiles = Integer.parseInt(settings.getProperty("numFiles"));
		numRepeatPerFile = Integer.parseInt(settings.getProperty("repeatPerFile"));
		command = settings.getProperty("command");

		String tmp = settings.getProperty("isSaveFile");
		boolean isSaveFile = false;

		String savedFileDir = null;
		if (tmp.equals("true")) {
			isSaveFile = true;
			savedFileDir = settings.getProperty("savedFileDir");
		}

		Enumeration names = settings.propertyNames();

		if (numRepeatPerFile < 1)
			numRepeatPerFile = 1;


		if (host == null)
			throw new Exception("Invalid host in property file");

		if (userName == null)
			throw new Exception("Invalid userName in property file");

		if (sessionId == null)
			throw new Exception("Invalid sessionId in property file");

		if (command == null)
			throw new Exception("Invalid command in property file");

		int fileCount = 0;
		String savedFileName = null;
		while ((fileCount < numFiles) && (names.hasMoreElements())) {

			String name = (String)names.nextElement();
			if (name.indexOf("file") == 0) {
				int index = -1;
				try {
					// Get index number from property
					// fileXXX=filepath
					index = Integer.parseInt(name.substring(4));
				} catch (NumberFormatException e) {
					System.out.println("Skipping invalid property: " + name);
				}
				// Only want index from startIndex
				if (index < startIndex) {
					continue;
				}

				// Get the actual filename
				String fileName = settings.getProperty(name);

				// Create multiple clients to get the same image
				int repeatCount = 0;
				while (repeatCount < numRepeatPerFile) {

					// Add filename to the list
					ImgSrvClient aClient = new ImgSrvClient(host, port, userName,
															sessionId, fileName,
															command);

					// Save image using the same file name but
					// in the designated output directory.
					if (isSaveFile && (savedFileDir != null)) {
						int pos = fileName.lastIndexOf(File.separatorChar);
						if ((pos >= 0) && (fileName.length() > pos+1)) {
							savedFileName = savedFileDir + File.separatorChar
											+ fileName.substring(pos+1);
							aClient.setSavedFileName(savedFileName);
						}
					}
					clients.add(aClient);

					++repeatCount;
				}

				++fileCount;

			}
		}

		// Now loop over the files
		for (int i = 0; i < clients.size(); ++i) {

			ImgSrvClient aClient = (ImgSrvClient)clients.elementAt(i);
			aClient.run();

		}


	}

	/**
	 * @brief report the results of the runs
	 *
	 */
	public void writeReport()
	{
		System.out.println("host = " + host);
		System.out.println("port = " + String.valueOf(port));
		System.out.println("userName = " + userName);
		System.out.println("sessionId = " + sessionId);
		String tab = "\t";

		int failureCount = 0;
		double minDT = 0;
		double maxDT = 0;
		double aveDT = 0;
		double sumDT = 0;

		int numClients = clients.size();

		// Now loop over the files
		System.out.println("Status" + tab + "Time" + tab + "Size" + tab + "File name");
		for (int i = 0; i < numClients; ++i) {

			ImgSrvClient aClient = (ImgSrvClient)clients.elementAt(i);
			String line = String.valueOf(aClient.isSuccessful());
			if (!aClient.isSuccessful()) {
				line += tab + aClient.getError();
				++failureCount;
			} else {
				double dT = aClient.getTime();
				sumDT += dT;
				if (i == 0) {
					minDT = dT;
					maxDT = dT;
				}
				if (minDT > dT)
					minDT = dT;
				if (maxDT < dT)
					maxDT = dT;
				line +=   tab + String.valueOf(dT)
						+ tab + String.valueOf(aClient.getImageSize())
						+ tab + aClient.getFileName();
			}
			System.out.println(line);
		}

		int successCount = numClients-failureCount;
		if (successCount > 0)
			aveDT = sumDT/successCount;

		System.out.println("Number of runs = " + numClients);
		System.out.println("Success = " + successCount);
		System.out.println("Failure = " + failureCount);
		System.out.println("Min dT = " + minDT);
		System.out.println("Max dT = " + maxDT);
		System.out.println("Ave dT = " + aveDT);

	}



	/**
	 * @brief Main routine for this test application.
	 * @param args Command line rguments for this application.
	 */
    public static void main( String[] args )
    {
        try {
			String propertyFilename = "./test.properties";

			if (args.length >= 1) {
				propertyFilename = args[0];
			}

			MultiClientTest test = new MultiClientTest(propertyFilename);

			test.run();

			test.writeReport();

        } catch (Exception e) {
            System.err.println( "Exception: " + e );
            e.printStackTrace();
        }

    }

}

