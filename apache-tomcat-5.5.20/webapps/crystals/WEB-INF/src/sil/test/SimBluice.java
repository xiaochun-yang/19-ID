package sil.test;

import java.util.*;
import java.io.*;
import java.net.*;


public class SimBluice extends Thread
{
	private String name = "";
	private boolean done = false;
	private volatile int eventId = -1;
	private volatile int prevId = -1;

	private String host = "";
	private String port = "";
	private String silId = "";

	/**
	 */
	public SimBluice(String name, String silId)
	{
		if ((name != null) && (name.length() > 0))
			this.name = name;
		else
			this.name = toString();

		this.silId = silId;
		log("silId = " + silId);
	}

	/**
	 */
	private synchronized boolean isDone()
	{
		return done;
	}

	/**
	 */
	public synchronized void setDone()
	{
		done = true;
	}

	/**
	 */
	public synchronized void setLatestEventId(int id)
	{
		eventId = id;
	}

	/**
	 */
	private void log(String s)
	{
		System.out.println(name + " " + s);
	}

	/**
	 */
	public void start()
	{
		super.start();
	}


	/**
	 */
	public void run()
	{
		try {

		getCrystalData();

		int id = -1;
		while (!isDone()) {
			if (eventId > prevId) {
				log("New Event id = " + eventId);
				getChangesSince(prevId);
				prevId = eventId;
			}
			sleep(1000);
		}

		} catch (Exception e) {
			log("Error in run: " + e.toString());
			e.printStackTrace();
		}

	}


	/**
	 */
	private void getChangesSince(int id)
		throws Exception
	{
		HttpURLConnection con = null;
		InputStreamReader reader = null;

		try {

			String urlStr = "http://" + SimConfig.host + ":" + SimConfig.port
							+ "/crystals-dev/getChangesSince.do?silId=" + silId
							+ "&eventId=" + eventId
							+ "&userName=" + SimConfig.owner
							+ "&accessID=" + SimConfig.sessionId;

			URL url = new URL(urlStr);
			con = (HttpURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				log("Failed in getChangesSince: (" + responseCode + ")"
									+ " " + con.getResponseMessage());
				con.disconnect();
				return;
			}

			reader = new InputStreamReader(con.getInputStream());
			char buf[] = new char[200];
			int num = 0;
			StringBuffer body = new StringBuffer();
			while ((num=reader.read(buf, 0, 200)) >= 0) {
				if (num > 0) {
					body.append(buf, 0, num);
				}
			}
			buf = null;

			log("getChangesSince body size = " + body.length());

			body = null;


		} catch (NumberFormatException e) {
			log("Failed in getLatestEventId: " + e.toString());
			e.printStackTrace();
		} finally {

			if (reader != null)
				reader.close();
			reader = null;

			if (con != null)
				con.disconnect();
			con = null;
		}


	}

	/**
	 */
	private void getCrystalData()
		throws Exception
	{
		HttpURLConnection con = null;
		InputStreamReader reader = null;

		try {

			String urlStr = "http://" + SimConfig.host + ":" + SimConfig.port
							+ "/crystals-dev/getCrystalData.do?silId=" + silId
							+ "&forBeamLine=" + SimConfig.beamline
							+ "&forCassetteIndex=" + SimConfig.cassetteIndex
							+ "&forUser=" + SimConfig.owner
							+ "&accessID=" + SimConfig.sessionId;

			URL url = new URL(urlStr);
			con = (HttpURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				log("Failed in getCrystalData: (" + responseCode + ")"
									+ " " + con.getResponseMessage());
				con.disconnect();
				return;
			}

			reader = new InputStreamReader(con.getInputStream());
			char buf[] = new char[200];
			int num = 0;
			StringBuffer body = new StringBuffer();
			while ((num=reader.read(buf, 0, 200)) >= 0) {
				if (num > 0) {
					body.append(buf, 0, num);
				}
			}
			buf = null;

			log("getCrystalData body size = " + body.length());

			body = null;


		} catch (NumberFormatException e) {
			log("Failed in getCrystalData: " + e.toString());
			e.printStackTrace();
		} finally {

			if (reader != null)
				reader.close();
			reader = null;

			if (con != null)
				con.disconnect();
			con = null;
		}


	}

}


