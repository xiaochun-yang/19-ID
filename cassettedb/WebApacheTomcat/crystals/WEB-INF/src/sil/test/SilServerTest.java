package sil.test;

import sil.beans.*;

import java.io.*;

public class SilServerTest
{

	public static void main(String args[])
	{
		try {

		if (args.length != 3) {
			System.out.println("Usage: SilServerTest <userName> <sessionId> <silId>");
			System.exit(0);
		}

		String appDir = "/home/penjitk/software/jakarta-tomcat-4.1.31/webapps/crystals";

		// Create config
		SilConfig config = SilConfig.createSilConfig(appDir + "/config.prop");

		// Create server
		SilServer server = SilServer.getInstance();

		String user = args[0];
		String sessionId = args[1];
		String silId = args[2];

		// Make changes
		int eventId = -1;
		String value = "";
		for (int i = 0; i < 0; ++i) {

			if (i < 25) {
				value = "PROTEIN_" + String.valueOf(i);
				eventId = server.setCrystal(silId, i, "Protein", value, null);
			} else {
				value = "COMMENT_" + String.valueOf(i);
				eventId = server.setCrystal(silId, i, "Comment", value, null);
			}

			while (!server.isEventCompleted(silId, eventId)) {
				System.out.println("Waiting for sil event " + eventId + " to complete");
				Thread.sleep(300);
			}
			System.out.println("Done sil event " + eventId);
		}

		// Get all the changes from event number 50 onwards.
		String tclStr = server.getEventLog(silId, 1);

		System.out.println("HERE are the changes from event 50");
		System.out.println(tclStr);

		FileOutputStream out = new FileOutputStream("./test.xls");

		server.saveSilAsWorkbook(silId, "Sheet1", out);

		out.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

	}


}

