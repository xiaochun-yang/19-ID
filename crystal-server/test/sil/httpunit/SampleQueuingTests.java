package sil.httpunit;

import java.beans.XMLDecoder;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Properties;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.PropertyValue;
import org.springframework.beans.PropertyValues;
import org.springframework.context.ApplicationContext;

import sil.AllTests;
import sil.beans.AutoindexResult;
import sil.beans.Crystal;
import sil.beans.CrystalResult;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.SpotfinderResult;
import sil.beans.UnitCell;
import junit.framework.TestCase;

// 
public class SampleQueuingTests extends TestCase  {
	
	private ApplicationContext ctx;
	private Properties config;
	private String userName;
	private String sessionId;
	private String baseUrl = "http://smb.slac.stanford.edu/crystal-server-dev";
	private String caBaseUrl = "http://smb.slac.stanford.edu/crystal-analysis-dev";
	private String beamline = "SIM9-1";
	static private int silId;
	private boolean hasCaServer = true;
	
	@Override
	protected void setUp() throws Exception {
		ctx = AllTests.getApplicationContext();
		config = (Properties)ctx.getBean("config");
		
		userName = System.getProperty("user.name");
		sessionId = AllTests.readFile("/home/" + userName + "/.bluice/session").trim();
		
		if (silId == 0) {
			silId = AllTests.createSil(baseUrl, userName, sessionId);
			System.out.println("setUp: silId = " + silId);
		}
	}
	
	public void testQueueCrystal() throws Exception {
		
		int row = 0;
		Crystal crystal = getCrystalBeanFromRow(row);
		
		String spotfinderDir = "/data/" + userName + "/webice/screening/" + silId + "/" + crystal.getCrystalId() + "/spotfinder";
		String autoindexDir = "/data/" + userName + "/webice/screening/" + silId + "/" + crystal.getCrystalId() + "/autoindex";
		String collectDir = "/data/" + userName + "/collect";
		String imageRootName1 = "A1_001";
		String imageRootName2 = "A1_002";
		String imageDir = "/home/penjitk/workspace/crystal-server/data/sample_queuing/A1";
		String imageName1 = imageRootName1 + ".img";
		String imageName2 = imageRootName2 + ".img";
		
		String screeningDir = imageDir;
			
		Image image1 = new Image();
		image1.setDir(imageDir);
		image1.setName(imageName1);
		image1.setGroup("1");
		image1.getData().setJpeg(imageRootName1 + ".jpg");

		Image image2 = new Image();
		image2.setDir(imageDir);
		image2.setName(imageName2);
		image2.setGroup("2");
		image2.getData().setJpeg(imageRootName2 + ".jpg");
						
		// 1. Dcss delete all results when user mounts the crystal during screening.
		clearCrystal(crystal);
		
		// 2. Dcss adds 2 images during screening.
		addCrystalImage(crystal, image1.getGroup(), image1.getDir(), image1.getName());
		addCrystalImage(crystal, image2.getGroup(), image2.getDir(), image2.getName());

		// 2. Dcss runs spotfinder via the crystal-analysis server.
		// Crystal-analysis-server sets spotfinder results
		if (hasCaServer) {
			// TODO: run spotfinder for each image
		} else {
			image1.getResult().getSpotfinderResult().setDir(screeningDir);
			image1.getResult().getSpotfinderResult().setIntegratedIntensity(0.9);
			image1.getResult().getSpotfinderResult().setNumOverloadSpots(2);
			image1.getResult().getSpotfinderResult().setResolution(1.9);
			image1.getResult().getSpotfinderResult().setNumIceRings(4);
			image1.getResult().getSpotfinderResult().setNumSpots(500);
			image1.getResult().getSpotfinderResult().setNumBraggSpots(100);
			image1.getResult().getSpotfinderResult().setDir(spotfinderDir);

			setSpotfinderResult(crystal, image1);

			image2.getResult().getSpotfinderResult().setDir(screeningDir);
			image2.getResult().getSpotfinderResult().setIntegratedIntensity(0.8);
			image2.getResult().getSpotfinderResult().setNumOverloadSpots(1);
			image2.getResult().getSpotfinderResult().setResolution(1.8);
			image2.getResult().getSpotfinderResult().setNumIceRings(4);
			image2.getResult().getSpotfinderResult().setNumSpots(600);
			image2.getResult().getSpotfinderResult().setNumBraggSpots(200);
			image2.getResult().getSpotfinderResult().setDir(spotfinderDir);

			setSpotfinderResult(crystal, image2);
		}
		
		// Test getRunDefinition when there is no reposition data and no run definitions
		List<String> lines = getRunDefinition(crystal, 1);
		String expected = silId + " " + row + " " + crystal.getUniqueId();
		assertEquals(8, lines.size());
		if (!lines.get(0).startsWith(expected))
			fail("Incorrect line 1: '" + lines.get(0) + "' expected '" + expected + "'");
		assertEquals("{}", lines.get(1));
		assertEquals("{}", lines.get(2));
		assertEquals("{}", lines.get(3));	
		
		// 3. Dcss saves reorientable=0, set reorientInfo to file 
		// and add default reposition data (repositionId = 0) to sil.
		int reorientable = 0;
		String reorientInfo = screeningDir + "/reorient_info";
		RepositionData defRepos = new RepositionData();
		defRepos.setLabel("position0");
		defRepos.getAutoindexResult().setDir(autoindexDir);
		defRepos.setBeamSizeX(0.1);
		defRepos.setBeamSizeY(0.1);
		defRepos.setImage1(imageDir + "/" + imageName1);
		defRepos.setImage2(imageDir + "/" + imageName2);
		defRepos.setJpeg1(imageDir + "/" + imageRootName1 + ".jpg");
		defRepos.setJpeg2(imageDir + "/" + imageRootName2 + ".jpg");
		defRepos.setJpegBox1(imageDir + "/" + imageRootName1 + "_box.jpg");
		defRepos.setJpegBox2(imageDir + "/" + imageRootName2 + "_box.jpg");
		defRepos.setEnergy(12000.0);
		defRepos.setDistance(300.0);
		defRepos.setBeamStop(20.0);
		defRepos.setDelta(1.0);
		defRepos.setAttenuation(0.0);
		defRepos.setExposureTime(2.0);
		defRepos.setDetectorMode(0);
		defRepos.setAutoindexable(reorientable);
		defRepos.setReorientInfo(reorientInfo);
		defRepos.setBeamline(beamline);
		addDefaultRepositionData(crystal, defRepos, reorientable, reorientInfo);
		
		// Autoindex job should finish within this amount of time.
		int maxWaitInSeconds = 300;
		
		// 4. Dcss runs autoindex and strategy for the initial 2 images via crystal-analysis server.
		// repositionId=0 is passed to crystal-analysis server.
		// Crystal-analysis server saves autoindex results and reorientable to sil.
		// It also saves the same autoindex results to RepositionData 0 and
		// sets autoindexable=1 for RepositionData 0.
		// Must use strategyMethod=mosflm.
		if (hasCaServer) {
			autoindex(silId, crystal.getRow(), crystal.getUniqueId(), crystal.getCrystalId(), 0/*repositionId*/,
					image1.getDir() + "/" + image1.getName(), image2.getDir() + "/" + image2.getName(), 
					beamline);
			waitForJob(beamline, autoindexDir, maxWaitInSeconds);			
			
		} else {
			CrystalResult result = new CrystalResult();
			AutoindexResult autoindexResult = new AutoindexResult();
			result.setReorientable(1);
			autoindexResult.setBestSolution(9);
			autoindexResult.setBravaisLattice("C2");
			autoindexResult.setDir(autoindexDir);
			autoindexResult.setImages(imageDir + "/" + image1 + " " + imageDir + "/" + image2);
			autoindexResult.setMosaicity(0.002);
			autoindexResult.setResolution(1.8);
			autoindexResult.setRmsd(0.7);
			autoindexResult.setScore(15.0);
			setCrystalResult(crystal, result, autoindexResult);		
		}
		
		// Check that autoindex results have been saved to sil.
		int maxTries = 5;
		int numTries = 0;
		while (numTries <= maxTries) {
			try {
				Crystal test = getCrystalBeanFromRow(row);
				AutoindexResult res = test.getResult().getAutoindexResult();
				if (test.getResult().getReorientable() != 1)
					throw new Exception("reorientable != 1");
				if (!autoindexDir.equals(res.getDir()))
					throw new Exception("Wrong autoindexDir");
				if (!res.getImages().equals(image1.getDir() + "/" + image1.getName() + " " + image2.getDir() + "/" + image2.getName()))
					throw new Exception("Wrong autoindex images");
				if (res.getScore() == 0.0)
					throw new Exception("Wrong score");
				
				RepositionData testRepos = test.getResult().getRepositions().get(0);
				res = testRepos.getAutoindexResult();
				if (testRepos.getAutoindexable() != 1)
					throw new Exception("Autoindexable != 1");
				if (!autoindexDir.equals(res.getDir()))
					throw new Exception("Wrong autoindexDir");
				if (!res.getImages().equals(image1.getDir() + "/" + image1.getName() + " " + image2.getDir() + "/" + image2.getName()))
					throw new Exception("Wrong autoindex images");
				if (res.getScore() == 0.0)
					throw new Exception("Wrong score");
				
				System.out.println("Got autoidex result");
				break;
				} catch (Exception e) {
					if (numTries >= maxTries)
						fail(e.getMessage());
					System.out.println("Waiting for autoidex result");
					Thread.sleep(5000);
					++numTries;
			}
			Thread.sleep(5000); // sleep for 5 seconds
		}

		if (numTries > maxTries)
			fail("Time out: autoindex result in sil not updated.");
				
		// 5. Dcss clears reorientPhi in sil.
		clearReorientPhi(crystal);
		
		String reautoindexImageDir = imageDir + "/reorient";
		String reautoindexImageRootName1 = "A1_reorient_001";
		String reautoindexImageRootName2 = "A1_reorient_002";		
		String reautoindexImage1 = reautoindexImageRootName1 + ".img";
		String reautoindexImage2 = reautoindexImageRootName2 + ".img";
		String reautoindexDir = autoindexDir + "/REMOUNT";

		// 6. Dcss collects 2 more images and runs reautoindex via crystal-analysis server.
		// Crystal-analysis-server sets reorientPhi to a number or warning message.
		if (hasCaServer) {
			reautoindex(silId, crystal.getRow(), crystal.getUniqueId(), crystal.getCrystalId(), 
					reautoindexImageDir + "/" + reautoindexImage1,
					reautoindexImageDir + "/" + reautoindexImage2,
					beamline);
			waitForJob(beamline, reautoindexDir, maxWaitInSeconds);
		} else {
			CrystalResult result = new CrystalResult();
			result.setReorientPhi("58.0");
			setReorientPhi(crystal, result);
		}
		
		// Check that reorientPhi has been saved to sil.
		numTries = 0;
		while (numTries <= maxTries) {
			try {
				Crystal test = getCrystalBeanFromRow(row);
				if (test.getResult().getReorientPhi().isEmpty())
					throw new Exception("reorientPhi not updated");
				System.out.println("Got reautoindex result");
				break;
			} catch (Exception e) {
				if (numTries >= maxTries)
					fail(e.getMessage());
				System.out.println("Waiting for reautoidex result");
				Thread.sleep(5000);
				++numTries;
			}
		}
		if (numTries > maxTries)
			fail("Time out: reorientPhi in sil not updated.");
		
		// 7. Dcss or webice adds rundef 1 using repositionId = 0.
		// Crystal-server creates a new RunDefinition by copying properties
		// from RepositionData 0. Then override RunDefinition properties 
		// with the properties sent from dcss.
		RunDefinition run = new RunDefinition();
		run.setAttenuation(50.0);
		run.setAxisMotorName("phi");
		run.setBeamStop(40.0);
		run.setDelta(1.0);
		run.setDetectorMode(0);
		run.setDirectory(collectDir);
		run.setDistance(300.0);
		run.setDoseMode(1);
		run.setEndAngle(300.0);
		run.setEnergy1(12000.0);
		run.setExposureTime(2.0);
		run.setFileRoot("test1");
		run.setInverse(0);
		run.setNextFrame(1);
		run.setNumEnergy(1);
		run.setResolution(1.8);
		run.setRunStatus("inactive");
		run.setStartAngle(1.0);
		run.setStartFrame(1);
		run.setWedgeSize(180.0);
		run.setRepositionId(0);
		addRunDefinition(crystal, run);
		
		// 8. Dcss or webice modifies rundef 1 properties (distance, energies...)
		MutablePropertyValues props = new MutablePropertyValues();
		props.addPropertyValue("distance", 400.0);
		props.addPropertyValue("fileRoot", "run1");
		props.addPropertyValue("directory", collectDir + "/run1");
		props.addPropertyValue("start_angle", 10.0);
		props.addPropertyValue("end_angle", 360.0);
		props.addPropertyValue("exposure_time", 5.0);
		setRunDefinitionProperties(crystal, 0, props);
		
		// 9. User clicks "Mount and Reposition".
		// dcss adds blank RepositionData. This new RepositionData
		// will be given repositionId = 1.
		String label = "repos1";
		addBlankRepositionData(crystal, label);
		int repositionId = 1;
		
		// 10. User has moved position, change beam size and etc.
		// User clicks OK. Dcss then collect 2 images for the new position.
		// Dcss sets reposition data.
		String reposImageDir = imageDir + "/checked_positions/position" + repositionId;
		String reposImageRootName1 = "A1_position1_001";
		String reposImageRootName2 = "A1_position1_002";		
		String reposImage1 = reposImageRootName1 + ".img";
		String reposImage2 = reposImageRootName2 + ".img";
		String reposAutoindexDir = autoindexDir + "/position" + repositionId;
		
		RepositionData repos = new RepositionData();
		repos.setLabel(label);
		repos.setBeamSizeX(0.1);
		repos.setBeamSizeY(0.1);
		repos.setImage1(reposImageDir + "/" + reposImage1);
		repos.setImage2(reposImageDir + "/" + reposImage2);
		repos.setJpeg1(reposImageDir + "/" + reposImageRootName1 + ".jpg");
		repos.setJpeg2(reposImageDir + "/" + reposImageRootName2 + ".jpg");
		repos.setJpegBox1(reposImageDir + "/" + reposImageRootName1 + "_box.jpg");
		repos.setJpegBox2(reposImageDir + "/" + reposImageRootName2 + "_box.jpg");
		repos.setEnergy(12000.0);
		repos.setDistance(300.0);
		repos.setBeamStop(20.0);
		repos.setDelta(1.0);
		repos.setAttenuation(0.0);
		repos.setExposureTime(2.0);
		repos.setDetectorMode(0);
		repos.setBeamline(beamline);
		repos.setReorientInfo(reposImageDir + "/reorient_info");
		setRepositionData(crystal, repositionId, repos);
		
		// 11. Dcss autoindex the 2 images collected for this position and asks 
		// the crystal-analysis to autoindex the images. repositionId=1 is passed to 
		// the crystal-analysis server.
		// Crystal-analysis server saves autoindex results to RepositionData
		// and sets autoindexable=1 for this position.
		if (hasCaServer) {
			// dcss call crystal-analysis to autoindex.do?repositionId=1
			autoindex(silId, crystal.getRow(), crystal.getUniqueId(), crystal.getCrystalId(), 
					repositionId, repos.getImage1(), repos.getImage2(), repos.getBeamline());
			waitForJob(beamline, reposAutoindexDir, maxWaitInSeconds);
		} else {
			// Then crystal-analysis sets autoindexDir for reposition data
			int autoindexable = 1;
			autoindexDir = autoindexDir + "/run1";
			AutoindexResult reposResult = new AutoindexResult();
			reposResult.setBestSolution(9);
			reposResult.setBravaisLattice("C2");
			reposResult.setDir(reposAutoindexDir);
			reposResult.setImages(repos.getImage1() + " " + repos.getImage2());
			reposResult.setIsigma(0.99);
			reposResult.setMosaicity(0.05);
			reposResult.setResolution(1.64);
			reposResult.setRmsd(0.89);
			reposResult.setScore(14.7);
			UnitCell cell = new UnitCell();
			cell.setA(80.0); cell.setB(90.0); cell.setC(100.0); cell.setAlpha(110.0); cell.setBeta(120.0); cell.setGamma(130.0);
			reposResult.setUnitCell(cell);
			setRepositionData(crystal, repositionId, autoindexable, reposResult);
		}
		
		// Check that repos1 autoindex results have been saved to sil.
		numTries = 0;
		while (numTries <= maxTries) {
			try {
				Crystal test = getCrystalBeanFromRow(row);
				RepositionData testRepos = test.getResult().getRepositions().get(repositionId);
				AutoindexResult res = testRepos.getAutoindexResult();
				if (testRepos.getAutoindexable() != 1)
					throw new Exception("Autoindexable != 1");
				if (!reposAutoindexDir.equals(res.getDir()))
					throw new Exception("Wrong autoindexDir");
				if (!res.getImages().equals(repos.getImage1() + " " + repos.getImage2()))
					throw new Exception("Wrong autoindex images");
				if (res.getScore() == 0.0)
					throw new Exception("Wrong score");
				System.out.println("Got repos autoidex result");
				break;
			} catch (Exception e) {
				if (numTries >= maxTries)
					fail(e.getMessage());
				System.out.println("Waiting repos autoidex result");
				Thread.sleep(5000);
				++numTries;
			}
		}
		if (numTries > maxTries)
			fail("Time out: repos autoindex result in sil not updated.");

		// Crystal-analysis sets strategy file. so that dcss will monitor.
		
		// 12. Dcss applies reposition1 to rundef1.
		// Originally rundef1 refers to repositionId=0.
		// Returns error if repositionData.autoindexable != true
		// rundef 1 now refers to repositionId=1.
		setRunDefRepositionData(crystal, 0, repositionId);
		
		// 13. Dcss copies rundef1 to rundef2. 
		// Rundef2 also refers to repositionId=1.
		int newRunIndex = copyRunDefinition(crystal, 0);
		
		// Test getAllRepositionData
		String tcl = getAllRepositionData(crystal);
		
		// Test getRepositionData where repositionId=1
		tcl = getRepositionData(crystal, 1);
		
		// Test getRunDefinition runIndex=1
		lines = getRunDefinition(crystal, 1);
	}
	
	private void addCrystalImage(Crystal crystal, String groupName, String imageDir, String imageName) throws Exception {
		
		int pos = imageName.lastIndexOf(".");
		String imageRootName = imageName.substring(0, pos);
		String urlStr = baseUrl + "/addCrystalImage.do"
						+ "?userName=" + userName 
						+ "&SMBSessionID=" + sessionId
						+ "&silId=" + silId
						+ "&row=" + crystal.getRow()
						+ "&uniqueId=" + crystal.getUniqueId()
						+ "&group=" + groupName
						+ "&dir=" + imageDir
						+ "&name=" + imageName
						+ "&jpeg=" + imageRootName + ".jpg";

		System.out.println("addCrystalImage: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("addCrystalImage returns " + con.getResponseCode() + " " + con.getResponseMessage());
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
	}
	
	private void setSpotfinderResult(Crystal crystal, Image image) throws Exception {
		
		SpotfinderResult result = image.getResult().getSpotfinderResult();
		String urlStr = baseUrl + "/setCrystalImage.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&group=" + image.getGroup()
				+ "&name=" + image.getName()
				+ "&integratedIntensity=" + image.getResult().getSpotfinderResult()
				+ "&numOverloadSpots=" + result.getNumOverloadSpots()
				+ "&score=" + result.getScore()
				+ "&resolution=" + result.getResolution()
				+ "&iceRings=" + result.getNumIceRings()
				+ "&numSpots=" + result.getNumSpots()
				+ "&numBraggSpots=" + result.getNumBraggSpots()
				+ "&spotfinderDir=" + result.getDir()
				+ "&warning=" + result.getWarning();
		
		System.out.println("setSpotfinderResult: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setCrystalImage returns " + con.getResponseCode() + " " + con.getResponseMessage());		
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void clearCrystal(Crystal crystal) throws Exception {

		String urlStr = baseUrl + "/clearCrystal.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&clearImages=true"
				+ "&clearSpot=true"
				+ "&clearAutoindex=true"
				+ "&clearSystemWarning=true"
				+ "&ReOrientable=0"
				+ "&ReOrientInfo="
				+ "&ReOrientPhi=";
		
		System.out.println("clearCrystal: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setCrystal returns " + con.getResponseCode() + " " + con.getResponseMessage());		
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void setCrystalResult(Crystal crystal, CrystalResult result, AutoindexResult autoindexResult) throws Exception {
		
		String urlStr = baseUrl + "/setCrystal.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&Score=" + autoindexResult.getScore()
				+ "&Rmsr=" + autoindexResult.getRmsd()
				+ "&Mosaicity=" + autoindexResult.getMosaicity()
				+ "&Resolution=" + autoindexResult.getResolution()
				+ "&AutoindexDir=" + autoindexResult.getDir()
				+ "&AutoindexImages=" + URLEncoder.encode(autoindexResult.getImages())
				+ "&BravaisLattice=" + autoindexResult.getBravaisLattice()
				+ "&ReOrientable=" + result.getReorientable();
		
		System.out.println("setCrystalResult: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setCrystal returns " + con.getResponseCode() + " " + con.getResponseMessage());		
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void clearReorientPhi(Crystal crystal) throws Exception {
		
		String urlStr = baseUrl + "/setCrystal.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&ReOrientPhi=";
		
		System.out.println("clearReorientPhi: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setCrystal returns " + con.getResponseCode() + " " + con.getResponseMessage());		
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void setReorientPhi(Crystal crystal, CrystalResult result) throws Exception {
		
		String urlStr = baseUrl + "/setCrystal.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&ReOrientPhi=" + result.getReorientPhi();
		
		System.out.println("setReorientPhi: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setCrystal returns " + con.getResponseCode() + " " + con.getResponseMessage());		
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void addDefaultRepositionData(Crystal crystal, RepositionData data, int reorientable, String reorientInfo) throws Exception {
		
		String urlStr = baseUrl + "/addDefaultRepositionData.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&label=" + data.getLabel()
				+ "&beam_width=" + data.getBeamSizeX()
				+ "&beam_height=" + data.getBeamSizeY()
				+ "&reposition_x=" + data.getOffsetX()
				+ "&reposition_y=" + data.getOffsetY()
				+ "&reposition_z=" + data.getOffsetZ()
				+ "&fileVSnapshot1=" + data.getJpeg1()
				+ "&fileVSnapshot2=" + data.getJpeg2()
				+ "&fileVSnapshotBox1=" + data.getJpegBox1()
				+ "&fileVSnapshotBox2=" + data.getJpegBox2()
				+ "&fileDiffImage1=" + data.getImage1()
				+ "&fileDiffImage2=" + data.getImage2()
				+ "&autoindexDir=" + data.getAutoindexResult().getDir()
				+ "&energy=" + data.getEnergy()
				+ "&distance=" + data.getDistance()
				+ "&beamStop=" + data.getBeamStop()
				+ "&delta=" + data.getDelta()
				+ "&attenuation=" + data.getAttenuation()
				+ "&exposureTime=" + data.getExposureTime()
				+ "&flux=" + data.getFlux()
				+ "&i2=" + data.getI2()
				+ "&cameraZoom=" + data.getCameraZoom()
				+ "&scalingFactor=" + data.getScalingFactor()
				+ "&detectorMode=" + data.getDetectorMode()
				+ "&autoindexable=" + data.getAutoindexable()
				+ "&ReOrientable=" + reorientable
				+ "&ReOrientInfo=" + reorientInfo;			

		System.out.println("addDefaultRepositionData: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("addDefaultRepositionData returns " + con.getResponseCode() + " " + con.getResponseMessage());				
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + " " + con.getResponseMessage());
		con.disconnect();
	}
	
	private void addRunDefinition(Crystal crystal, RunDefinition run) throws Exception {
		
		String urlStr = baseUrl + "/addRunDefinition.do";
		
		String form = "userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&file_root=" + run.getFileRoot()
				+ "&next_frame=" + run.getNextFrame()
				+ "&directory=" + run.getDirectory()
				+ "&status=" + run.getRunStatus()
				+ "&start_frame=" + run.getStartFrame()
				+ "&axis_motor=" + run.getAxisMotorName()
				+ "&start_angle=" + run.getStartAngle()
				+ "&end_angle=" + run.getEndAngle()
				+ "&wedge_size=" + run.getWedgeSize()
				+ "&dose_mode=" + run.getDoseMode()
				+ "&attenuation=" + run.getAttenuation()
				+ "&exposure_time=" + run.getExposureTime()
				+ "&resolution=" + run.getResolution()
				+ "&distance=" + run.getDistance()
				+ "&beam_stop=" + run.getBeamStop()
				+ "&num_energy=" + run.getNumEnergy()
				+ "&energy1=" + run.getEnergy1()
				+ "&energy2=" + run.getEnergy2()
				+ "&energy3=" + run.getEnergy3()
				+ "&energy4=" + run.getEnergy4()
				+ "&energy5=" + run.getEnergy5()
				+ "&detector_mode=" + run.getDetectorMode()
				+ "&inverse_on=" + run.getInverse()
				+ "&repositionId=" + run.getRepositionId();
		
		System.out.println("addRunDefinition: url = " + urlStr);
		System.out.println("addRunDefinition: form = " + form);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		con.setDoOutput(true);
		con.setRequestMethod("POST");
		con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
		
		con.getOutputStream().write(form.getBytes());
		con.getOutputStream().flush();
		
		System.out.println("addRunDefinition returns " + con.getResponseCode() + " " + con.getResponseMessage());			
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line = null;
		while ((line=reader.readLine()) != null) {
			System.out.println("response body=" + line);
		}
		reader.close();	
		con.disconnect();
	}
	
	private void setRunDefinitionProperties(Crystal crystal, int runIndex, PropertyValues props) throws Exception {
		
		String urlStr = baseUrl + "/setRunDefinitionProperties.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&runIndex=" + runIndex;
		
		PropertyValue[] arr = props.getPropertyValues();
		if (arr != null) {
			for (int i = 0; i < arr.length; ++i) {
				PropertyValue prop = arr[i];
				urlStr += "&" + prop.getName() + "=" + prop.getValue();
			}
		} 
		
		System.out.println("setRunDefinitionProperties: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setRunDefinitionProperties returns " + con.getResponseCode() + " " + con.getResponseMessage());			
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	// Returns tcl string
	private String getAllRepositionData(Crystal crystal) throws Exception {
		
		String urlStr = baseUrl + "/getAllRepositionData.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId();

		System.out.println("getAllRepositionData: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("getAllRepositionData returns " + con.getResponseCode() + " " + con.getResponseMessage());
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			buf.append(line + "\n");
		}
		reader.close();
		con.disconnect();
		return buf.toString();
	}
	
	// Returns tcl string
	private String getRepositionData(Crystal crystal, int repositionId) throws Exception {
		
		String urlStr = baseUrl + "/getRepositionData.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&repositionId=" + repositionId;

		System.out.println("getRepositionData: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("getRepositionData returns " + con.getResponseCode() + " " + con.getResponseMessage());
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			buf.append(line + "\n");
		}
		reader.close();
		con.disconnect();
		return buf.toString();
	}
	
	// Returns tcl string
/*	private String getRunDefinition(Crystal crystal, int runIndex) throws Exception {
		
		String urlStr = baseUrl + "/getRunDefinition.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&runIndex=" + runIndex;

		System.out.println("getRunDefinition: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("getRunDefinition returns " + con.getResponseCode() + " " + con.getResponseMessage());
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			buf.append(line + "\n");
		}
		reader.close();
		con.disconnect();
		return buf.toString();
	}*/
	
	private int addBlankRepositionData(Crystal crystal, String label) throws Exception {
		
		String urlStr = baseUrl + "/addBlankRepositionData.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&label=" + label;

		System.out.println("addBlankRepositionData: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("addBlankRepositionData returns " + con.getResponseCode() + " " + con.getResponseMessage());
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line;
		int repositionId = -1;
		while ((line=reader.readLine()) != null) {
			if (line.startsWith("OK")) {
				repositionId = Integer.parseInt(line.substring(3).trim());
			}
		}
		reader.close();
		con.disconnect();
		return repositionId;
	}
	
	private void setRepositionData(Crystal crystal, int repositionId, RepositionData data) throws Exception {
		
		String urlStr = baseUrl + "/setRepositionData.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&repositionId=" + repositionId
				+ "&beam_width=" + data.getBeamSizeX()
				+ "&beam_height=" + data.getBeamSizeY()
				+ "&reposition_x=" + data.getOffsetX()
				+ "&reposition_y=" + data.getOffsetY()
				+ "&reposition_z=" + data.getOffsetZ()
				+ "&fileVSnapshot1=" + data.getJpeg1()
				+ "&fileVSnapshot2=" + data.getJpeg2()
				+ "&fileVSnapshotBox1=" + data.getJpegBox1()
				+ "&fileVSnapshotBox2=" + data.getJpegBox2()
				+ "&fileDiffImage1=" + data.getImage1()
				+ "&fileDiffImage2=" + data.getImage2()
				+ "&autoindexDir=" + data.getAutoindexResult().getDir()
				+ "&energy=" + data.getEnergy()
				+ "&distance=" + data.getDistance()
				+ "&beamStop=" + data.getBeamStop()
				+ "&delta=" + data.getDelta()
				+ "&attenuation=" + data.getAttenuation()
				+ "&exposureTime=" + data.getExposureTime()
				+ "&flux=" + data.getFlux()
				+ "&i2=" + data.getI2()
				+ "&cameraZoom=" + data.getCameraZoom()
				+ "&scalingFactor=" + data.getScalingFactor()
				+ "&detectorMode=" + data.getDetectorMode()
				+ "&beamline=" + data.getBeamline()
				+ "&ReOrientInfo=" + data.getReorientInfo();

		System.out.println("setRepositionData: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("addRepositionData returns " + con.getResponseCode() + " " + con.getResponseMessage());				
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void setRepositionData(Crystal crystal, int repositionId, int autoindexable, AutoindexResult result) throws Exception {
		
		String urlStr = baseUrl + "/setRepositionData.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&repositionId=" + repositionId
				+ "&autoindexable=" + autoindexable
				+ "&AutoindexDir=" + result.getDir()
				+ "&Score=" + result.getScore()
				+ "&Mosaicity=" + result.getMosaicity()
				+ "&ISigma=" + result.getIsigma()
				+ "&Rmsd=" + result.getRmsd()
				+ "&Resolution=" + result.getResolution()
				+ "&BravaisLattice=" + result.getBravaisLattice()
				+ "&UnitCell=" + URLEncoder.encode(result.getUnitCell().toString(), "UTF-8");
				

		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setRepositionData returns " + con.getResponseCode() + " " + con.getResponseMessage());				
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void autoindex(int silId, int row, long uniqueId, String crystalId, int repositionId, 
						String image1, String image2, String beamline) throws Exception {
		
		String urlStr = caBaseUrl + "/jsp/strategy.jsp"
						+ "?userName=" + userName 
						+ "&SMBSessionID=" + sessionId
						+ "&silId=" + silId
						+ "&row=" + row
						+ "&serialNumber=" + uniqueId
						+ "&uniqueID=" + crystalId
						+ "&image1=" + image1
						+ "&image2=" + image2
						+ "&forBeamLine=" + beamline
						+ "&strategyMethod=mosflm"; // must use mosflm otherwise reautoindex will not work.
		
		if (repositionId > -1)
			urlStr += "&repositionId=" + repositionId;
		
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("autoindex returns " + con.getResponseCode() + " " + con.getResponseMessage());				
		if (con.getResponseCode() != 200)
		throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private void reautoindex(int silId, int row, long uniqueId, String crystalId,
						String image1, String image2, String beamline) throws Exception {
		
		String urlStr = caBaseUrl + "/jsp/reautoindex.jsp"
					+ "?userName=" + userName 
					+ "&SMBSessionID=" + sessionId
					+ "&silId=" + silId
					+ "&row=" + row
					+ "&serialNumber=" + uniqueId
					+ "&uniqueID=" + crystalId
					+ "&image1=" + image1
					+ "&image2=" + image2
					+ "&forBeamLine=" + beamline;
		
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("reautoindex returns " + con.getResponseCode() + " " + con.getResponseMessage());				
		if (con.getResponseCode() != 200)
		throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private String checkJobStatus(String beamline, String dir) throws Exception {
		
		String controlFile = dir + File.separator + "control.txt";

		String urlStr = caBaseUrl + "/secureServlet/checkJobStatus?userName=" + userName 
					+ "&SMBSessionID=" + sessionId 
					+ "&beamline=" + beamline
					+ "&controlFile=" + controlFile;
		
		URL url = new URL(urlStr);	
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		con.setRequestMethod("GET");
		
		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception(String.valueOf(response) + " " + con.getResponseMessage());
	
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));	
		String line = reader.readLine();
		
		reader.close();
		con.disconnect();
		
		return line;
	}
	

	private void waitForJob(String beamline, String dir, int maxWaitInSeconds) throws Exception {
		String status = checkJobStatus(beamline, dir);
		int totalWait = 0;
		int interval = 3000;
		int maxWait = maxWaitInSeconds*1000;
		String curStatus = "";
		while (!status.startsWith("not running")) {
			if (totalWait > maxWait) {
				System.out.println(new Date() + " Job did not finish within " + maxWaitInSeconds + " seconds");
				break;
			}
			if (!curStatus.equals(status)) {
				System.out.println(new Date() + " Job status = " + status);
			}
			curStatus = status;
			
			Thread.sleep(3000);
			totalWait += interval;
			status = checkJobStatus(beamline, dir);
		}
		System.out.println(new Date() + " Job status = " + status);
		
	}
	
	private void setRunDefRepositionData(Crystal crystal, int runIndex, int repositionId) throws Exception {
		
		String urlStr = baseUrl + "/setRunDefinitionProperties.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&runIndex=" + runIndex
				+ "&repositionId=" + repositionId;
		
		System.out.println("setRunDefRepositionData: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("setRunDefinitionProperties returns " + con.getResponseCode() + " " + con.getResponseMessage());			
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		con.disconnect();
	}
	
	private List<String> getRunDefinition(Crystal crystal, int fromIndex) throws Exception {
		
		String urlStr = baseUrl + "/getRunDefinition.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&runIndex=" + fromIndex;
		
		System.out.println("getRunDefinition: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("getRunDefinition returns " + con.getResponseCode() + " " + con.getResponseMessage());	
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + " " + con.getResponseMessage());
		List<String> lines = new ArrayList<String>();
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line;
		while ((line=reader.readLine()) != null) {
			lines.add(line);
			System.out.println("getRunDefinition return: " + line);
		}
		reader.close();
		con.disconnect();
		return lines;	
	}
	
	private int copyRunDefinition(Crystal crystal, int fromIndex) throws Exception {
		
		String urlStr = baseUrl + "/copyRunDefinition.do"
				+ "?userName=" + userName 
				+ "&SMBSessionID=" + sessionId
				+ "&silId=" + silId
				+ "&row=" + crystal.getRow()
				+ "&uniqueId=" + crystal.getUniqueId()
				+ "&runIndex=" + fromIndex;
		
		System.out.println("copyRunDefinition: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		System.out.println("copyRunDefinition returns " + con.getResponseCode() + " " + con.getResponseMessage());	
		if (con.getResponseCode() != 200)
			throw new Exception(con.getResponseCode() + con.getResponseMessage());
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line;
		int repositionId = -1;
		while ((line=reader.readLine()) != null) {
			if (line.startsWith("OK")) {
				repositionId = Integer.parseInt(line.substring(3).trim());
			}
		}
		reader.close();
		con.disconnect();
		return repositionId;	
	}
	
	private String getBaseQueryString() {
		return "userName=" + userName + "&SMBSessionID=" + sessionId;
	}
	
	public Crystal getCrystalBeanFromRow(int row) throws Exception {
		
		String urlStr = baseUrl + "/getCrystalBean.do"
						+ "?userName=" + userName 
						+ "&SMBSessionID=" + sessionId
						+ "&silId=" + silId
						+ "&row=" + row;
		System.out.println("getCrystalBeanFromRow: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		
		ByteArrayOutputStream bout = new ByteArrayOutputStream();
		InputStream in = con.getInputStream();
		byte[] buf = new byte[1024];
		int numRead;
		while ((numRead=in.read(buf)) > -1) {
			bout.write(buf, 0, numRead);
//			System.out.write(buf, 0, numRead);
		}
		System.out.println("");
		ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
		XMLDecoder decoder = new XMLDecoder(bin);
		Crystal crystal = (Crystal)decoder.readObject();
		decoder.close();
		return crystal;
	}
	
}
