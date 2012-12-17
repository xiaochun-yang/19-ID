package edu.stanford.slac.http.test;

import java.io.*;
import java.net.*;
import java.lang.InterruptedException;

/**
 * @class Client
 *
 * A Client that sends an HTTP request to and receives an HTTP response from
 * an image server.
 */
public class Client extends Thread
{
	private String host = null;
	private int port = 0;
	private String userName = null;
	private String sessionId = null;
	private int numRequests = 1;
	private boolean done = false;

	// Run results

	/**
	 * @brief Size of the image in bytes received from the socket.
	 */
	private int size = 0;

	/**
	 * @brief Time when the command started in milliseconds
	 */
	private long start = 0;

	/**
	 * @brief Time when the command finsihed in milliseconds
	 */
	private long end = 0;

	/**
	 * @brief Amount of time in milliseconds it takes
	 * from start to end.
	 */
	private double dT = 0.0;

	/**
	 * Test status
	 */
	private boolean success = false;
	private String reason = null;


	static private String CRLF = "\012\015";


	/**
	 * @brief Constructor. Create a client for the image server
	 */
	public Client(String host, int port,
						String userName,
						String sessionId,
						int numRequests)
	{
		this.host = host;
		this.port = port;
		this.userName = userName;
		this.sessionId = sessionId;
		this.numRequests = numRequests;

	}

	public void run()
	{

		this.done = false;

		try {

		for (int i = 0; i < numRequests; ++i) {

			start = System.currentTimeMillis();


			String url = "GET http://" + host + String.valueOf(port)
						+ "/"
	//					+ "&userName=" + userName
	//					+ "&sessionId=" + sessionId
						+ " HTTP/1.1" // Request line
						+ CRLF;
			url += CRLF; // end of headers

			Socket socket = new Socket(host, port);

			// Write request
			BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));
			writer.write(url);
			writer.flush();
			socket.shutdownOutput();

			// Read response
			InputStream in = socket.getInputStream();


			// Read the headers
			BufferedReader reader = new BufferedReader(new InputStreamReader(in));

			String line = null;

			// Expect at least one line in the response
			line = reader.readLine();

			// Check the response status code first before trying
			// to read the rest of the message.
			if (line.indexOf("200 OK") < 0) {
				success = false;
				reason = line;
				return;
			}


			boolean forever = true;
			while (forever) {
				line = reader.readLine();
				// Header section ends with an empty line
				if (line.length() == 0)
					break;
				line = null;
			}


			// Now read the response body without interpretting
			// it as characters.

			byte[] arr = new byte[1000];
			int count = 0;
			size = 0;
			// Read until the func returns -1.
			while ((count = in.read(arr)) >= 0) {
				size += count;
			}
			arr = null;

			success = true;


			end = System.currentTimeMillis();

			dT = end - start;

			Thread.sleep(200);


		} // Loop over numRequests

		done = true;

		} catch (UnknownHostException e) {
			reason = e.getMessage();
			success = false;
		} catch (IOException e) {
			reason = e.getMessage();
			success = false;
		} catch (InterruptedException e) {
			reason = e.getMessage();
			success = false;
		}
	}

	/**
	 * @brief Returns the time in milliseconds between the
	 * the time at the start of the command  and midnight, January 1, 1970 UTC
	 * @return Time in milliseconds
	 */
	public long getStartTime()
	{
		return start;
	}

	/**
	 * @brief Returns the time in milliseconds between the
	 * the time at the end of the command  and midnight, January 1, 1970 UTC
	 * @return Time in milliseconds
	 */
	public long getEndTime()
	{
		return end;
	}


	/**
	 * @brief Returns the amount of time in milliseconds
	 * spent to retrieve the image.
	 *
	 * @return Amount of time in milliseconds
	 */
	public double getTime()
	{
		return dT;
	}

	/**
	 * @brief return the status of the transaction.
	 * @return true if the transaction complete successfully.
	 * @see getErrorReason() to find out why the transaction fails.
	 */
	public boolean isSuccessful()
	{
		return success;
	}

	/**
	 * @brief Returns the reason why the transaction fails.
	 * @return String explaining why the transaction fails.
	 *  null if the transaction is completed successfully.
	 */
	public String getError()
	{
		return reason;
	}


	/**
	 * @brief Get an image from an image server.
	 *
	 * The func does not actually inspect the content
	 * of the response but only checks the size of
	 * the response.
	 *
	 * @return Size of the image received in bytes.
	 */
	public int getSize()
	{
		return size;
	}

	public boolean isFinished()
	{
		return done;
	}



}

