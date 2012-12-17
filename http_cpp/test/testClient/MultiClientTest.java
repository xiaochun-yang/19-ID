package edu.stanford.slac.http.test;

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
	private int numThreads = 0;
	private int numRequestPerThread = 0;

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
		numThreads = Integer.parseInt(settings.getProperty("numThreads"));
		numRequestPerThread = Integer.parseInt(settings.getProperty("numRequestPerThread"));


		System.out.println("Num threads = " + numThreads);
		System.out.println("Num request/thread = " + numRequestPerThread);


		if (host == null)
			throw new Exception("Invalid host in property file");

		if (userName == null)
			throw new Exception("Invalid userName in property file");

		if (sessionId == null)
			throw new Exception("Invalid sessionId in property file");

		for (int threadCount= 0; threadCount < numThreads; ++threadCount) {

			Thread.sleep(50);

			// Create a new client and run it in a new thread
			Client aClient = new Client(host, port,
										userName, sessionId,
										numRequestPerThread);

			clients.add(aClient);

			aClient.run();

		}


	}

	public void waitAllClients() throws InterruptedException
	{
		int count = 0;
		boolean done = false;
		while (!done) {

			count = 0;

			for (int i = 0; i < clients.size(); ++i) {

				Client aClient = (Client)clients.elementAt(i);

				if (aClient.isFinished()) {
					++count;
				}

			}

			// all done
			if (count == clients.size())
				break;

			Thread.sleep(1000); // sleep in msec
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
		System.out.println("Status" + tab + "Time" + tab + "Size");
		for (int i = 0; i < numClients; ++i) {

			Client aClient = (Client)clients.elementAt(i);
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
				line +=   tab + String.valueOf(dT) + tab + String.valueOf(aClient.getSize());
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

			test.waitAllClients();

			test.writeReport();

        } catch (Exception e) {
            System.err.println( "Exception: " + e );
            e.printStackTrace();
        }

    }

}

