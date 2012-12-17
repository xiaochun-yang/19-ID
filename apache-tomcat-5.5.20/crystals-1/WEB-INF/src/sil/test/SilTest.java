package sil.test;

import sil.beans.*;

import java.io.*;
import java.util.Hashtable;

public class SilTest
{
	static public void testAddCrystalImage(Sil sil)
		throws Exception
	{
		// addCrystalImage
		Hashtable fields = new Hashtable();
		fields.put("group", "1");
		fields.put("name", "test1.img");
		fields.put("dir", "/data/penjitk/images");
		fields.put("jpeg", "video1.jpg");
		fields.put("small", "test1_small.jpg");
		fields.put("medium", "test1_medium.jpg");
		fields.put("large", "test1_large.jpg");
		fields.put("quality", "quality1");
		fields.put("spotShape", "1.0");
		fields.put("resolution", "1.0");
		fields.put("iceRings", "1");
		fields.put("diffractionStrength", "10.0");
		fields.put("score", "0.1");
		fields.put("numSpots", "100");
		fields.put("numOverloadSpots", "10");
		sil.addCrystalImage(1, fields);

		fields.put("group", "2");
		fields.put("name", "test2.img");
		fields.put("dir", "/data/penjitk/images");
		fields.put("jpeg", "video2.jpg");
		fields.put("small", "test2_small.jpg");
		fields.put("medium", "test2_medium.jpg");
		fields.put("large", "test2_large.jpg");
		fields.put("quality", "quality2");
		fields.put("spotShape", "2.0");
		fields.put("resolution", "2.0");
		fields.put("iceRings", "2");
		fields.put("diffractionStrength", "20.0");
		fields.put("score", "0.2");
		fields.put("numSpots", "200");
		fields.put("numOverloadSpots", "20");
		sil.addCrystalImage(1, fields);


		fields.put("group", "2");
		fields.put("name", "test3.img");
		fields.put("dir", "/data/penjitk/images");
		fields.put("jpeg", "video3.jpg");
		fields.put("small", "test3_small.jpg");
		fields.put("medium", "test3_medium.jpg");
		fields.put("large", "test3_large.jpg");
		fields.put("quality", "quality3");
		fields.put("spotShape", "3.0");
		fields.put("resolution", "3.0");
		fields.put("iceRings", "3");
		fields.put("diffractionStrength", "30.0");
		fields.put("score", "0.3");
		fields.put("numSpots", "300");
		fields.put("numOverloadSpots", "30");
		sil.addCrystalImage(1, fields);
	}

	static public void testSetCrystalImage(Sil sil)
		throws Exception
	{
		// setCrystalImage
		Hashtable fields = new Hashtable();
		fields.put("group", "2");
		fields.put("name", "test3.img");
		fields.put("dir", "/data/penjitk/images");
		fields.put("jpeg", "video33.jpg");
		fields.put("small", "test33_small.jpg");
		fields.put("medium", "test33_medium.jpg");
		fields.put("large", "test33_large.jpg");
		fields.put("quality", "quality33");
		fields.put("spotShape", "33.0");
		fields.put("resolution", "33.0");
		fields.put("iceRings", "33");
		fields.put("diffractionStrength", "330.0");
		fields.put("score", "0.33");
		fields.put("numSpots", "3300");
		fields.put("numOverloadSpots", "330");
		sil.setCrystalImage(1, fields);
	}

	public static void main(String args[])
	{
		try {


		String appDir = "/home/penjitk/software/jakarta-tomcat-4.1.31/webapps/crystals-dev";
		String orgSilFilePath = appDir + "/data/cassettes/penjitk/org_test2482_2614_sil.xml";
		String silFilePath = appDir + "/data/cassettes/penjitk/test2482_2614_sil.xml";

		// Copy sil file
		FileInputStream fi = new FileInputStream(orgSilFilePath);
		FileOutputStream fo = new FileOutputStream(silFilePath);
		byte bb[] = new byte[1000];
		int n = -1;
		while ((n=fi.read(bb)) > -1) {
			if (n > 0) {
				fo.write(bb, 0, n);
			}
		}
		fo.close();
		fi.close();

		// Create config
		SilConfig config = SilConfig.createSilConfig(appDir + "/config.prop");

		String silId = "2482";
		String owner = "penjitk";

		System.out.println("TEST loading");

		Sil sil = new Sil(silId, owner, silFilePath);

		if (!sil.getId().equals("2681"))
			throw new Exception("getId failed");

		if (!sil.getOwner().equals("penjitk"))
			throw new Exception("getOwner failed");

		if (!sil.getFileName().equals(silFilePath))
			throw new Exception("getSilFileName failed");

		// SAVE
		FileOutputStream out = new FileOutputStream("./test1.xml");
		sil.save(out);
		out.close();

		System.out.print("Hit a key to proceed:");
		System.in.read();
		System.out.println("\n");
		System.out.println("TEST addCrystalImages");


		testAddCrystalImage(sil);

		// SAVE
		out = new FileOutputStream("./test2.xml");
		sil.save(out);
		out.close();

		System.out.print("Hit a key to proceed:");
		System.in.read();
		System.out.println("\n");
		System.out.println("TEST setCrystalImages");

		testSetCrystalImage(sil);


		// SAVE
		out = new FileOutputStream("./test3.xml");
		sil.save(out);
		out.close();

		System.out.print("Hit a key to proceed:");
		System.in.read();
		System.out.println("\n");
		System.out.println("TEST clearCrystalImages");

		// clearCrystalImages
		sil.clearCrystalImages(1, 1);

		// SAVE
		out = new FileOutputStream("./test4.xml");
		sil.save(out);
		out.close();

		System.out.print("Hit a key to proceed:");
		System.in.read();
		System.out.println("\n");
		System.out.println("TEST clearCrystalImages");

		// clearCrystalImages
		sil.clearCrystalImages(1);

		// SAVE
		out = new FileOutputStream("./test5.xml");
		sil.save(out);
		out.close();

		System.out.print("Hit a key to proceed:");
		System.in.read();
		System.out.println("\n");
		System.out.println("TEST setCrystalImage");

		// setCrystal
		testSetCrystalImage(sil);

		// SAVE
		out = new FileOutputStream("./test6.xml");
		sil.save(out);
		out.close();

		System.out.print("Hit a key to proceed:");
		System.in.read();
		System.out.println("\n");
		System.out.println("TEST save sil");

		// Add it again to test save to excel.
		testAddCrystalImage(sil);

		// SAVE
		out = new FileOutputStream("./test.xml");
		sil.save(out);
		out.close();

		// SAVE TCL
		FileWriter writer = new FileWriter("./test.tcl");
		String tclStr = sil.toTclString();
		writer.write(tclStr, 0, tclStr.length());
		writer.close();

		// SAVE TCL (some rows);


		// SAVE EXCEL
		out = new FileOutputStream("./test.xls");
		sil.saveAsWorkbook("Sheet1", out);
		out.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

	}


}

