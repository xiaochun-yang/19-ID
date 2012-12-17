package sil.io;

import sil.beans.AutoindexResult;
import sil.beans.Crystal;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.UnitCell;
import sil.beans.util.CrystalCollection;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;
import sil.io.SilVelocityWriter;
import sil.AllTests;
import sil.TestData;

import java.io.ByteArrayOutputStream;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;

public class VelocityWriterTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private ApplicationContext ctx;
	private VelocityEngine engine;
	
	@Override
	protected void setUp() throws Exception {
		ctx = AllTests.getApplicationContext();
		engine = (VelocityEngine)ctx.getBean("velocityEngine");
	}

	@Override
	protected void tearDown() throws Exception {

	}

	public void testSilTclTemplate()
	{
		try {
			logger.debug("START testSilTclTemplate");			
			Sil sil = TestData.createSimpleSil();
					
			Template t = engine.getTemplate("/tcl/sil.vm");
			VelocityContext context = new VelocityContext();
	   		context.put("sil", sil);
	   		OutputStreamWriter writer = new OutputStreamWriter(System.out);
	   		t.merge(context, writer);
	   		writer.close();
			
			logger.debug("FINISH testSilTclTemplate");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}

	public void testCrystalsTclTemplate()
	{
		try {
			logger.debug("START testCrystalsTclTemplate");			
			Sil sil = TestData.createSimpleSil();

			Template t = engine.getTemplate("/tcl/crystals.vm");
			int rows[] = new int[2];
			rows[0] = 0;
			rows[1] = 4; // does not exist
			
			List crystals = SilUtil.getCrystals(sil, rows);
			
			VelocityContext context = new VelocityContext();
	   		context.put("sil", sil);
	   		context.put("crystals", crystals);
	  		
	   		OutputStreamWriter writer = new OutputStreamWriter(System.out);
	   		t.merge(context, writer);
	   		writer.close();
			
			logger.debug("FINISH testCrystalsTclTemplate");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}
	
	public void testCrystalsTclTemplate1()
	{
		try {
			logger.debug("START testCrystalsTclTemplate1");			
			Sil sil = TestData.createSimpleSil();

			Template t = engine.getTemplate("/tcl/crystals.vm");
			CrystalCollection col = new CrystalCollection();
			col.add(100000000);
			col.add(400000000); // does not exist
			
			List<Crystal> crystals = SilUtil.getCrystalsFromCrystalCollection(sil, col);
			
			VelocityContext context = new VelocityContext();
	   		context.put("sil", sil);
	   		context.put("crystals", crystals);
	  		
	   		OutputStreamWriter writer = new OutputStreamWriter(System.out);
	   		t.merge(context, writer);
	   		writer.close();
			
			logger.debug("FINISH testCrystalsTclTemplate1");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}

	public void testSilXmlTemplate()
	{
		try {
			logger.debug("START testSilXmlTemplate");	
			
			Sil sil = TestData.createSimpleSil();			

//			Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
			Crystal crystal = sil.getCrystals().get(100000000L);
			RepositionData pos = new RepositionData();
			pos.setLabel("repos0");
			pos.setBeamSizeX(0.1);
			pos.setBeamSizeY(0.1);
			pos.setImage1("/data/annikas/test1_001.mccd");
			pos.setImage2("/data/annikas/test1_002.mccd");
			pos.setJpeg1("/data/annikas/jpeg1.jpg");
			pos.setJpeg2("/data/annikas/jpeg2.jpg");
			pos.setJpegBox1("/data/annikas/box1.jpg");
			pos.setJpegBox2("/data/annikas/box2.jpg");
			pos.setOffsetX(0.0);
			pos.setOffsetY(0.0);
			pos.setOffsetZ(0.0);
			pos.getAutoindexResult().setDir("/data/annikas/webice/screening/1/A3/autoindex");
			CrystalUtil.addDefaultRepositionData(crystal, pos);
			
			pos = new RepositionData();
			pos.setLabel("repos1");
			pos.setBeamSizeX(0.2);
			pos.setBeamSizeY(0.3);
			pos.setImage1("/data/annikas/test1_003.mccd");
			pos.setImage2("/data/annikas/test1_004.mccd");
			pos.setJpeg1("/data/annikas/jpeg3.jpg");
			pos.setJpeg2("/data/annikas/jpeg4.jpg");
			pos.setJpegBox1("/data/annikas/box3.jpg");
			pos.setJpegBox2("/data/annikas/box4.jpg");
			pos.setOffsetX(20.0);
			pos.setOffsetY(25.0);
			pos.setOffsetZ(15.0);
			pos.getAutoindexResult().setDir("/data/annikas/webice/screening/1/A3/autoindex/run1");
			CrystalUtil.addRepositionData(crystal, pos);
			
			RunDefinition run = new RunDefinition();
			run.setAttenuation(90.0);
			run.setAxisMotorName("phi");
			run.setRepositionId(0);
			run.setBeamStop(40.0);
			run.setDelta(2.0);
			run.setDetectorMode(1);
			run.setDirectory("/data/annikas/collect1");
			run.setDistance(500.0);
			run.setDoseMode(1);
			run.setEndAngle(300.0);
			run.setEnergy1(12699.0);
			run.setEnergy2(0.0);
			run.setEnergy3(0.0);
			run.setEnergy4(0.0);
			run.setEnergy5(0.0);
			run.setExposureTime(2.0);
			run.setFileRoot("myo1");
			run.setNextFrame(1);
			run.setNumEnergy(1);
			run.setPhotonCount(1);
			run.setRepositionId(0);
			run.setResolution(1.5);
			run.setRunLabel(1);
			run.setRunStatus("inactive");
			run.setStartAngle(20.0);
			run.setStartFrame(1);
			run.setWedgeSize(180.0);
			run.setInverse(1);
			CrystalUtil.addRunDefinition(crystal, run);
			
			run = new RunDefinition();
			run.setAttenuation(30.0);
			run.setAxisMotorName("phi");
			run.setRepositionId(1);
			run.setBeamStop(60.0);
			run.setDelta(1.0);
			run.setDetectorMode(1);
			run.setDirectory("/data/annikas/collect2");
			run.setDistance(600.0);
			run.setDoseMode(1);
			run.setEndAngle(200.0);
			run.setEnergy1(12700.0);
			run.setEnergy2(12701.0);
			run.setEnergy3(12500.0);
			run.setEnergy4(0.0);
			run.setEnergy5(0.0);
			run.setExposureTime(5.0);
			run.setFileRoot("myo1");
			run.setNextFrame(1);
			run.setNumEnergy(1);
			run.setPhotonCount(1);
			run.setRepositionId(1);
			run.setResolution(1.9);
			run.setRunLabel(2);
			run.setRunStatus("aborted");
			run.setStartAngle(50.0);
			run.setStartFrame(5);
			run.setWedgeSize(180.0);
			run.setInverse(1);
			CrystalUtil.addRunDefinition(crystal, run);
			
			assertEquals(2, crystal.getResult().getRepositions().size());
			assertEquals(2, crystal.getResult().getRuns().size());
			
			crystal = sil.getCrystals().get(100000000L);
			assertEquals(2, crystal.getResult().getRepositions().size());
			assertEquals(2, crystal.getResult().getRuns().size());
			
			

			Template t= engine.getTemplate("/xml/sil.vm");
			VelocityContext context = new VelocityContext();
	   		context.put("sil", sil);	  		
	   		OutputStreamWriter writer = new OutputStreamWriter(System.out);
	   		t.merge(context, writer); 
	   		writer.close();
			
			logger.debug("FINISH testSilXmlTemplate");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}

	public void testCrystalsXmlTemplate()
	{
		try {
			logger.debug("START testCrystalsXmlTemplate");	
			
			Sil sil = TestData.createSimpleSil();			
			int rows[] = new int[2];
			rows[0] = 1;
			rows[1] = 3; // does not exist
						
			List crystals = SilUtil.getCrystals(sil, rows);

			Template t= engine.getTemplate("/xml/crystals.vm");			
			VelocityContext context = new VelocityContext();
	   		context.put("sil", sil);
	   		context.put("crystals", crystals);
	   		
	   		OutputStreamWriter writer = new OutputStreamWriter(System.out);
	   		t.merge(context, writer); 
	   		writer.close();
			
			logger.debug("FINISH testCrystalsXmlTemplate");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}
	
	
	public void testSilTclWriter()
	{
		try {
			logger.debug("START testSilTclWriter");			
			Sil sil = TestData.createSimpleSil();
						
			SilVelocityWriter writer = (SilVelocityWriter)ctx.getBean("silTclWriter");	
			writer.write(System.out, sil);
			System.out.flush();
			
			logger.debug("FINISH testSilTclWriter");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}
	
	public void testCrystalsTclWriter()
	{
		try {
			logger.debug("START testCrystalsTclWriter");			
			Sil sil = TestData.createSimpleSil();
						
			SilVelocityWriter writer = (SilVelocityWriter)ctx.getBean("silTclWriter");				
			int rows[] = new int[2];
			rows[0] = 0;
			rows[1] = 5;
			
			writer.write(System.out, sil, rows);
			System.out.flush();
			
			logger.debug("FINISH testCrystalsTclWriter");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}
	
	public void testXmlWriter()
	{
		try {
			logger.debug("START testXmlWriter");			
			Sil sil = TestData.createSimpleSil();
			
			SilVelocityWriter writer = (SilVelocityWriter)ctx.getBean("silXmlWriter");	
			writer.write(System.out, sil);
			
			logger.debug("FINISH testXmlWriter");
		} catch (Exception e) {
			logger.error(e.getMessage());
			e.printStackTrace();
			assertNull(e);
		}
		
	}
	
	public void testCrystalsXmlWriter() throws Exception
	{		
			Sil sil = TestData.createSimpleSil();
			assertNotNull(sil);
			SilVelocityWriter writer = (SilVelocityWriter)ctx.getBean("silXmlWriter");	
			assertNotNull(writer);
			int rows[] = new int[2];
			rows[0] = 0;
			rows[1] = 5;
			
			writer.write(System.out, sil, rows);
			System.out.flush();
			
	}
	
	// Make sure that xml characters are escaped: &, ', ", <, >
	public void testCrystalsXmlWriterEscapeXmlChars() throws Exception
	{		
			Sil sil = TestData.createSimpleSil();
			assertNotNull(sil);
			Crystal crystal = SilUtil.getCrystalFromRow(sil, 0);
			crystal.getData().setComment("Good & bad");
			crystal.getData().setCrystalCond("\"Pear shape\"");
			crystal.getData().setCrystalUrl("http://smb.slac.stanford.edu/crystal?userName=annikas&crystalId=lyso");
			crystal.getData().setFreezingCond("< -10 deg & > -30 deg");
			crystal.getData().setMetal("'Se' & 'Fe'");
			SilVelocityWriter writer = (SilVelocityWriter)ctx.getBean("silXmlWriter");	
			assertNotNull(writer);
			int rows[] = new int[2];
			rows[0] = 0;
			
			ByteArrayOutputStream out = new ByteArrayOutputStream();
			writer.write(out, sil, rows);
			String actual = out.toString();	
			
			System.out.println(actual);
			
			assertFalse(actual.indexOf("Good & bad") > -1);
			assertTrue(actual.indexOf("Good &amp; bad") > -1);
			
			assertFalse(actual.indexOf("\"Pear shape\"") > -1);
			assertTrue(actual.indexOf("&quot;Pear shape&quot;") > -1);

			assertFalse(actual.indexOf("http://smb.slac.stanford.edu/crystal?userName=annikas&crystalId=lyso") > -1);
			assertTrue(actual.indexOf("http://smb.slac.stanford.edu/crystal?userName=annikas&amp;crystalId=lyso") > -1);

			assertFalse(actual.indexOf("< -10 deg & > -30 deg") > -1);
			assertTrue(actual.indexOf("&lt; -10 deg &amp; &gt; -30 deg") > -1);

			assertFalse(actual.indexOf("'Se' & 'Fe'") > -1);
			assertTrue(actual.indexOf("&apos;Se&apos; &amp; &apos;Fe&apos;") > -1);
	}
	
	public void testGenericVelocityWriter() throws Exception
	{
		List<Integer> labels = new ArrayList<Integer>();
		labels.add(100);
		labels.add(200);
		labels.add(300);
		labels.add(400);
		RunDefinition run = new RunDefinition();
		run.setAttenuation(99.0);
		run.setAxisMotorName("phi");
		run.setRepositionId(0);
		run.setBeamStop(40.0);
		run.setDelta(1.0);
		run.setDetectorMode(2);
		run.setDeviceName("run0");
		run.setDirectory("/data/annikas");
		run.setDistance(120.0);
		run.setEndAngle(250.0);
		run.setEnergy1(10000.0);
		run.setEnergy2(12899.0);
		run.setEnergy3(13000.0);
		run.setEnergy4(14000.0);
		run.setEnergy5(14500.0);
		run.setExposureTime(4.0);
		run.setFileRoot("test1");
		run.setInverse(0);
		run.setNextFrame(1);
		run.setNumEnergy(5);
		run.setRunLabel(200);
		run.setRunStatus("inactive");
		run.setStartAngle(60.0);
		run.setStartFrame(1);
		run.setWedgeSize(5.0);

		// Test tcl output
		List<String> runLabels = new ArrayList<String>();
		runLabels.add("1"); runLabels.add("2"); runLabels.add("3");
		List<String> statusList = new ArrayList<String>();
		statusList.add("active"); statusList.add("aborted"); statusList.add("inactive");
		
		List<RepositionData> reposList = new ArrayList<RepositionData>();
		UnitCell c = new UnitCell(); c.setA(80.0); c.setB(81.0); c.setC(82.0); c.setAlpha(83.0); c.setBeta(84.0); c.setGamma(85.0);
		RepositionData item = new RepositionData(); item.setLabel("repos0"); item.setAutoindexable(1); 
		item.getAutoindexResult().setScore(14.0); item.getAutoindexResult().setUnitCell(c); item.getAutoindexResult().setMosaicity(0.08); item.getAutoindexResult().setRmsd(0.66);
		item.getAutoindexResult().setBravaisLattice("C2"); item.getAutoindexResult().setResolution(1.65); item.getAutoindexResult().setIsigma(0.99);
		reposList.add(item);

		c = new UnitCell(); c.setA(60.0); c.setB(61.0); c.setC(62.0); c.setAlpha(63.0); c.setBeta(64.0); c.setGamma(65.0);
		item = new RepositionData(); item.setLabel("repos1"); item.setAutoindexable(1); 
		item.getAutoindexResult().setScore(8.0); item.getAutoindexResult().setUnitCell(c); item.getAutoindexResult().setMosaicity(0.05); item.getAutoindexResult().setRmsd(0.77);
		item.getAutoindexResult().setBravaisLattice("C222"); item.getAutoindexResult().setResolution(1.89); item.getAutoindexResult().setIsigma(0.87);
		reposList.add(item);
		
		RepositionData repos = new RepositionData();
		repos.setRepositionId(0);
		repos.setLabel("repos2");
		repos.setJpeg1("test1_0deg_001.img");
		repos.setJpeg2("test1_90deg_002.img");
		repos.setJpegBox1("test1_0deg_box_001.img");
		repos.setJpegBox2("test1_90deg_box_002.img");
		repos.setImage1("test1_001.img");
		repos.setImage2("test1_002.img");
		repos.setBeamSizeX(0.5);
		repos.setBeamSizeY(0.6);
		repos.setOffsetX(2.0);
		repos.setOffsetY(3.0);
		repos.setOffsetZ(4.0);
		repos.setEnergy(12001.0);
		repos.setDistance(300.0);
		repos.setBeamStop(50.0);
		repos.setDelta(1.0);
		repos.setAttenuation(20.0);
		repos.setExposureTime(2.0);
		repos.setFlux(10.0);
		repos.setI2(80.0);
		repos.setCameraZoom(2.0);
		repos.setScalingFactor(7.0);
		repos.setDetectorMode(2);
		repos.setBeamline("BL9-1");
		repos.setReorientInfo("/data/annikas/collect/reorient_info");
		repos.setAutoindexable(1);
		AutoindexResult result = repos.getAutoindexResult();
		result.setImages("test1_001.img test1_002.img");
		result.setScore(9.0);
		UnitCell cell = result.getUnitCell();
		cell.setA(70.0);
		cell.setB(71.0);
		cell.setC(72.0);
		cell.setAlpha(73.0);
		cell.setBeta(74.0);
		cell.setGamma(75.0);
		result.setMosaicity(0.09);
		result.setRmsd(0.88);
		result.setBravaisLattice("P4");
		result.setResolution(1.57);
		result.setIsigma(0.98);
		result.setDir("/data/annikas/webice/autoindex/A2");
		result.setBestSolution(9);
		result.setWarning("Too much ice");
		
		reposList.add(repos);
		
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		SimpleVelocityWriter writer = (SimpleVelocityWriter)ctx.getBean("simpleVelocityWriter");
		VelocityContext context = new VelocityContext();
		context.put("silId", 1);
		context.put("row", 1);
		context.put("uniqueId", 1000);
		context.put("crystalEventId", 5);
		context.put("runIndex", 0);
		context.put("labels", runLabels);
		context.put("statusList", statusList);
		context.put("run", run);
		context.put("reposList", reposList);
		context.put("repos", repos);
		writer.write(out, "/tcl/runDefinition.vm", context);
		
		String actual = out.toString();	
		
		String expected = "1 1 1000 5\n";
		expected += "{1 2 3 }\n";
		expected += "{active aborted inactive }\n";
		expected += "{1 1 1000 {0} {0} {inactive} {1} {200} {test1} {/data/annikas} {1} {phi} {60.0} {250.0} {1.0} {5.0} {0} {99.0} {4.0} {0} {0} {0.0} {120.0} {40.0} {5} {10000.0} {12899.0} {13000.0} {14000.0} {14500.0} {2} {0} {0.5} {0.6} {2.0} {3.0} {4.0}}\n";
		expected += "{repos0 repos1 repos2 }\n";
		expected += "{1 1 1 }\n";
		expected += "{{14.0 {80.0 81.0 82.0 83.0 84.0 85.0} 0.08 0.66 C2 1.65 0.99}";
		expected += " {8.0 {60.0 61.0 62.0 63.0 64.0 65.0} 0.05 0.77 C222 1.89 0.87}";
		expected += " {9.0 {70.0 71.0 72.0 73.0 74.0 75.0} 0.09 0.88 P4 1.57 0.98} }\n";
		expected += "{1 1 1000 0 {repos2} {1} {test1_0deg_001.img} {test1_90deg_002.img} {test1_0deg_box_001.img} {test1_90deg_box_002.img} {test1_001.img} {test1_002.img}";
		expected += " {0.5} {0.6} {2.0} {3.0} {4.0}";
		expected += " {12001.0} {300.0} {50.0} {1.0} {20.0} {2.0} {10.0} {80.0}";
		expected += " {2.0} {7.0} {2} {BL9-1} {/data/annikas/collect/reorient_info}";
		expected += " {test1_001.img test1_002.img} {9.0} {70.0 71.0 72.0 73.0 74.0 75.0} {0.09} {0.88} {P4}";
		expected += " {1.57} {0.98} {/data/annikas/webice/autoindex/A2} {9} {Too much ice}}\n";

		assertEquals(expected, actual);	
		
		// Test old style xml output
		out = new ByteArrayOutputStream();
		writer = (SimpleVelocityWriter)ctx.getBean("simpleVelocityWriter");
		context = new VelocityContext();
		context.put("silId", 1);
		context.put("row", 1);
		context.put("uniqueId", 1000);
		context.put("repos", repos);
//		context.put("reposLabels", reposLabels);
//		context.put("autoindexableList", autoindexableList);
//		context.put("scores", scores);
		context.put("reposList", reposList);
		
		writer.write(out, "/tcl/repositionData.vm", context);
		
		actual = out.toString();
				
		expected = "{repos0 repos1 repos2 }\n";
		expected += "{1 1 1 }\n";
		expected += "{{{14.0} {80.0 81.0 82.0 83.0 84.0 85.0} {0.08} {0.66} {C2} {1.65} {0.99}}";
		expected += " {{8.0} {60.0 61.0 62.0 63.0 64.0 65.0} {0.05} {0.77} {C222} {1.89} {0.87}}";
		expected += " {{9.0} {70.0 71.0 72.0 73.0 74.0 75.0} {0.09} {0.88} {P4} {1.57} {0.98}} }\n";
		expected += "{1 1 1000 0 {repos2} {1} {test1_0deg_001.img} {test1_90deg_002.img} {test1_0deg_box_001.img} {test1_90deg_box_002.img} {test1_001.img} {test1_002.img}";
		expected += " {0.5} {0.6} {2.0} {3.0} {4.0}";
		expected += " {12001.0} {300.0} {50.0} {1.0} {20.0} {2.0} {10.0} {80.0}";
		expected += " {2.0} {7.0} {2} {BL9-1} {/data/annikas/collect/reorient_info}";
		expected += " {test1_001.img test1_002.img} {9.0} {70.0 71.0 72.0 73.0 74.0 75.0} {0.09} {0.88} {P4}";
		expected += " {1.57} {0.98} {/data/annikas/webice/autoindex/A2} {9} {Too much ice}}\n";
		
		assertEquals(expected, actual);
	}
	
}