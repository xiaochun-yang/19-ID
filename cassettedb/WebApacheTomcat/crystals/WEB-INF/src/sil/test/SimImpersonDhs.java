package sil.test;

import java.util.*;
import java.net.*;
import java.io.*;

public class SimImpersonDhs extends Thread
{
	private int curRow = -1;
	private int curGroup = -1;

	private int maxRow = 96;
	private int maxGroup= 3;

	private boolean done = false;

	/**
	 */
	public SimImpersonDhs()
	{
	}

	/**
	 */
	public synchronized boolean isDone()
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
	private void log(String s)
	{
		System.out.println("SimImpersonDhs " + s);
	}

	/**
	 */
	public void run()
	{
		try {

			System.out.println("Started addCrystalImages for sil " + SimConfig.silId);
			// add images
			for (int r = 0; r < maxRow; ++r) {
				for (int g = 1; g <= maxGroup; ++g) {
					log("row = " + r + " group = " + g);
					addCrystalImage(r, g);
					sleep(4000);
					setCrystalImage(r, g);
					sleep(1000);
					setCrystal(r);
				}
			}
			System.out.println("Finished addCrystalImages for sil " + SimConfig.silId);

		} catch (Exception e) {
			log("Error in run: " + e.toString());
			e.printStackTrace();
		}
	}

	/**
	 */
	private void addCrystalImage(int row, int group)
		throws Exception
	{

		HttpURLConnection con = null;
		InputStreamReader reader = null;
		
		String urlStr = null;

		try {

			String imgName = "test_" + String.valueOf(row) + "_" + String.valueOf(group)
							+ "_00" + String.valueOf(group);

			urlStr = "http://" + SimConfig.host + ":" + SimConfig.port
							+ "/crystals-dev/addCrystalImage.do?silId=" + SimConfig.silId
							+ "&row=" + row
							+ "&userName=" + SimConfig.owner
							+ "&accessID=" + SimConfig.sessionId
							+ "&group=" + group
							+ "&name=" + imgName + ".img"
							+ "&dir=/data/penjitk/test"
							+ "&jpeg=" + imgName + ".jpeg";

			URL url = new URL(urlStr);
			con = (HttpURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				log("Failed in addCrystalImage: (" + responseCode + ")"
								+ " " + con.getResponseMessage()
								+ " url = " + urlStr);
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

			String str = body.toString();
			body = null;

			if (!str.startsWith("OK")) {
				log("addCrystalImage returns error: " + body);
			}

		} catch (NumberFormatException e) {
			log("Failed in addCrystalImage: " + e.toString());
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
	private void setCrystalImage(int row, int group)
		throws Exception
	{

		HttpURLConnection con = null;
		InputStreamReader reader = null;

		try {

			String imgName = "test_" + String.valueOf(row) + "_" + String.valueOf(group)
							+ "_00" + String.valueOf(group);

			String urlStr = "http://" + SimConfig.host + ":" + SimConfig.port
							+ "/crystals-dev/setCrystalImage.do?silId=" + SimConfig.silId
							+ "&row=" + row
							+ "&userName=" + SimConfig.owner
							+ "&accessID=" + SimConfig.sessionId
							+ "&group=" + group
							+ "&name=" + imgName + ".img"
							+ "&numOverloadSpots=20&resolution=1.9&spotShape=1&score=20&diffractionStrength=9.6&numSpots=300&iceRings=1";

//		 	log("setCrystalImage urlStr = " + urlStr);

			URL url = new URL(urlStr);
			con = (HttpURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				log("Failed in setCrystalImage: (" + responseCode + ")"
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

			String str = body.toString();
			body = null;

			if (!str.startsWith("OK")) {
				log("setCrystalImage returns error: " + body);
			}


		} catch (NumberFormatException e) {
			log("Failed in setCrystalImage: " + e.toString());
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
	private void setCrystal(int row)
		throws Exception
	{

		HttpURLConnection con = null;
		InputStreamReader reader = null;

		try {

			String urlStr = "http://" + SimConfig.host + ":" + SimConfig.port
							+ "/crystals-dev/setCrystal.do?silId=" + SimConfig.silId
							+ "&row=" + row
							+ "&userName=" + SimConfig.owner
							+ "&accessID=" + SimConfig.sessionId
							+ "&Score=0.8&Mosaicity=0.025&Rmsr=0.055&BravaisLattice=P4&Resolution=2.0&ISigma=20.8";

//		 	log("setCrystal urlStr = " + urlStr);

			URL url = new URL(urlStr);
			con = (HttpURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				log("Failed in setCrystal: (" + responseCode + ")"
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

			String str = body.toString();
			body = null;

			if (!str.startsWith("OK")) {
				log("setCrystal returns error: " + body);
			}


		} catch (NumberFormatException e) {
			log("Failed in setCrystal: " + e.toString());
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
