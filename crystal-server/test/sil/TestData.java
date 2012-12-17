package sil;

import java.io.File;
import java.io.FileInputStream;
import java.util.Iterator;

import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.Sil;
import sil.beans.UnitCell;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;
import sil.upload.RawData;
import sil.upload.RowData;
import sil.upload.UploadData;

public class TestData {
	
	static public Crystal createSimpleCrystal() throws Exception
	{
		Crystal crystal = new Crystal();
		crystal.setUniqueId(100000000);
		crystal.setRow(0);
		crystal.setCrystalId("A1");
		crystal.setPort("A1");
		crystal.setContainerId("SSRL001");
		crystal.getData().setProtein("Myoglobin 1");
		crystal.getData().setDirectory("/data/annikas/myo");
		crystal.setContainerType("cassette");
		
		Image image = new Image();
		image.setName("A1_001.img");
		image.setDir("/data/annikas/myo1");
		image.setGroup("1");
		image.getResult().getSpotfinderResult().setNumIceRings(2);
		image.getData().setJpeg("A1_001.jpg");
		image.getResult().getSpotfinderResult().setScore(0.7882);
		CrystalUtil.addImage(crystal, image);
		
		image = new Image();
		image.setName("A1_002.img");
		image.setDir("/data/annikas/myo1");
		image.setGroup("2");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A1_002.jpg");
		image.getResult().getSpotfinderResult().setScore(0.975);			
		CrystalUtil.addImage(crystal, image);
		
		return crystal;
		
	}
	
	static public Crystal createCrystal() throws Exception
	{
		Crystal crystal = new Crystal();
		crystal.setUniqueId(100000000);
		crystal.setRow(0);
		crystal.setExcelRow(1);
		crystal.setCrystalId("myo1");
		crystal.setPort("A1");
		crystal.setContainerId("SSRL001");
		crystal.setContainerType("cassette");
		crystal.getData().setDirectory("/data/annikas/A1/myo1");
		crystal.getData().setProtein("Myoglobin 1");
		crystal.getData().setComment("large crystal");
		crystal.getData().setFreezingCond("-10deg");
		crystal.getData().setCrystalCond("good");
		crystal.getData().setMetal("Se");
		crystal.getData().setPriority("High");
		crystal.getData().setPerson("annikas");
		crystal.getData().setCrystalUrl("http://smb.slac.stanford.edu/crystals/A1/myo1.html");
		crystal.getData().setProteinUrl("http://smb.slac.stanford.edu/protein/A1/myi1.html");
		crystal.getData().setMove("B1");
		crystal.getResult().getAutoindexResult().setWarning("Not perfect");
		crystal.getResult().getAutoindexResult().setMosaicity(0.045);
		crystal.getResult().getAutoindexResult().setIsigma(0.88);
		crystal.getResult().getAutoindexResult().setScore(0.01);
		crystal.getResult().getAutoindexResult().setImages("/data/annikas/A1/myo1/A1_001.img /data/annikas/A1/myo1/A1_002.img");
		UnitCell cell = new UnitCell();
		cell.setA(55.0); cell.setB(56.0); cell.setC(50.0); cell.setAlpha(90.0); cell.setBeta(89.5); cell.setGamma(90.5);
		crystal.getResult().getAutoindexResult().setUnitCell(cell);
		crystal.getResult().getAutoindexResult().setRmsd(0.89);
		crystal.getResult().getAutoindexResult().setBravaisLattice("unknown");
		crystal.getResult().getAutoindexResult().setResolution(60.0);
		crystal.getResult().getAutoindexResult().setDir("/data/annikas/webice/autoindex/1/A1/autoindex");
		crystal.getResult().getAutoindexResult().setBestSolution(9);
	
		Image image = new Image();
		image.setName("A1_001.img");
		image.setDir("/data/annikas/myo1");
		image.setGroup("1");
		image.getData().setJpeg("A1_001.jpg");
		image.getData().setSmall("/data/annikas/A1/A1_001_small.jpg");
		image.getData().setMedium("/data/annikas/A1/A1_001_medium.jpg");
		image.getData().setLarge("/data/annikas/A1/A1_001_large.jpg");
		image.getResult().getSpotfinderResult().setScore(0.7882);
		image.getResult().getSpotfinderResult().setIntegratedIntensity(99.0);
		image.getResult().getSpotfinderResult().setNumOverloadSpots(20);
		image.getResult().getSpotfinderResult().setResolution(62.0);
		image.getResult().getSpotfinderResult().setNumIceRings(3);
		image.getResult().getSpotfinderResult().setNumSpots(678);
		image.getResult().getSpotfinderResult().setSpotShape(0.88);
		image.getResult().getSpotfinderResult().setQuality(0.99);
		image.getResult().getSpotfinderResult().setDiffractionStrength(77.3);
		image.getResult().getSpotfinderResult().setDir("/data/annikas/webice/screening/1/A1/spotfinder");
		CrystalUtil.addImage(crystal, image);	
		
		image = new Image();
		image.setName("A1_002.img");
		image.setDir("/data/annikas/myo1");
		image.setGroup("2");
		image.getData().setJpeg("A1_002.jpg");
		image.getData().setSmall("/data/annikas/A1/A1_002_small.jpg");
		image.getData().setMedium("/data/annikas/A1/A1_002_medium.jpg");
		image.getData().setLarge("/data/annikas/A1/A1_002_large.jpg");
		image.getResult().getSpotfinderResult().setScore(0.4444);
		image.getResult().getSpotfinderResult().setIntegratedIntensity(55.0);
		image.getResult().getSpotfinderResult().setNumOverloadSpots(30);
		image.getResult().getSpotfinderResult().setResolution(66.0);
		image.getResult().getSpotfinderResult().setNumIceRings(3);
		image.getResult().getSpotfinderResult().setNumSpots(566);
		image.getResult().getSpotfinderResult().setSpotShape(0.80);
		image.getResult().getSpotfinderResult().setQuality(0.97);
		image.getResult().getSpotfinderResult().setDiffractionStrength(88.3);
		image.getResult().getSpotfinderResult().setDir("/data/annikas/webice/screening/1/A1/spotfinder");
		CrystalUtil.addImage(crystal, image);	
		
		return crystal;	
	}

	static public Sil createSimpleSil() throws Exception
	{
		Sil sil = new Sil();
		sil.setId(1);
/*		sil.setEventId(56);
		sil.setKey("JHSD9782KS");
		sil.setLocked(true);*/

		Crystal crystal = new Crystal();
		crystal.setUniqueId(100000000);
		crystal.setRow(0);
		crystal.setExcelRow(1);
		crystal.setCrystalId("myo1");
		crystal.setPort("A1");
		crystal.setContainerId("SSRL001");
		crystal.setContainerType("cassette");
		crystal.getData().setDirectory("/data/annikas/A1/myo1");
		crystal.getData().setProtein("Myoglobin 1");
		crystal.getData().setComment("large crystal");
		crystal.getData().setFreezingCond("-10deg");
		crystal.getData().setCrystalCond("good");
		crystal.getData().setMetal("Se");
		crystal.getData().setPriority("High");
		crystal.getData().setPerson("annikas");
		crystal.getData().setCrystalUrl("http://smb.slac.stanford.edu/crystals/A1/myo1.html");
		crystal.getData().setProteinUrl("http://smb.slac.stanford.edu/protein/A1/myi1.html");
		crystal.getData().setMove("B1");
		crystal.getResult().getAutoindexResult().setWarning("Not perfect");
		crystal.getResult().getAutoindexResult().setMosaicity(0.045);
		crystal.getResult().getAutoindexResult().setIsigma(0.88);
		crystal.getResult().getAutoindexResult().setScore(0.01);
		crystal.getResult().getAutoindexResult().setImages("/data/annikas/A1/myo1/A1_001.img /data/annikas/A1/myo1/A1_002.img");
		UnitCell cell = new UnitCell();
		cell.setA(55.0); cell.setB(56.0); cell.setC(50.0); cell.setAlpha(90.0); cell.setBeta(89.5); cell.setGamma(90.5);
		crystal.getResult().getAutoindexResult().setUnitCell(cell);
		crystal.getResult().getAutoindexResult().setRmsd(0.89);
		crystal.getResult().getAutoindexResult().setBravaisLattice("unknown");
		crystal.getResult().getAutoindexResult().setResolution(60.0);
		crystal.getResult().getAutoindexResult().setDir("/data/annikas/webice/autoindex/1/A1/autoindex");
		crystal.getResult().getAutoindexResult().setBestSolution(9);
	
		Image image = new Image();
		image.setName("A1_001.img");
		image.setDir("/data/annikas/myo1");
		image.setGroup("1");
		image.getData().setJpeg("A1_001.jpg");
		image.getData().setSmall("/data/annikas/A1/A1_001_small.jpg");
		image.getData().setMedium("/data/annikas/A1/A1_001_medium.jpg");
		image.getData().setLarge("/data/annikas/A1/A1_001_large.jpg");
		image.getResult().getSpotfinderResult().setScore(0.7882);
		image.getResult().getSpotfinderResult().setIntegratedIntensity(99.0);
		image.getResult().getSpotfinderResult().setNumOverloadSpots(20);
		image.getResult().getSpotfinderResult().setResolution(62.0);
		image.getResult().getSpotfinderResult().setNumIceRings(3);
		image.getResult().getSpotfinderResult().setNumSpots(678);
		image.getResult().getSpotfinderResult().setSpotShape(0.88);
		image.getResult().getSpotfinderResult().setQuality(0.99);
		image.getResult().getSpotfinderResult().setDiffractionStrength(77.3);
		image.getResult().getSpotfinderResult().setDir("/data/annikas/webice/screening/1/A1/spotfinder");
		CrystalUtil.addImage(crystal, image);	
		
		image = new Image();
		image.setName("A1_002.img");
		image.setDir("/data/annikas/myo1");
		image.setGroup("2");
		image.getData().setJpeg("A1_002.jpg");
		image.getData().setSmall("/data/annikas/A1/A1_002_small.jpg");
		image.getData().setMedium("/data/annikas/A1/A1_002_medium.jpg");
		image.getData().setLarge("/data/annikas/A1/A1_002_large.jpg");
		image.getResult().getSpotfinderResult().setScore(0.4444);
		image.getResult().getSpotfinderResult().setIntegratedIntensity(55.0);
		image.getResult().getSpotfinderResult().setNumOverloadSpots(30);
		image.getResult().getSpotfinderResult().setResolution(66.0);
		image.getResult().getSpotfinderResult().setNumIceRings(3);
		image.getResult().getSpotfinderResult().setNumSpots(566);
		image.getResult().getSpotfinderResult().setSpotShape(0.80);
		image.getResult().getSpotfinderResult().setQuality(0.97);
		image.getResult().getSpotfinderResult().setDiffractionStrength(88.3);
		image.getResult().getSpotfinderResult().setDir("/data/annikas/webice/screening/1/A1/spotfinder");
		CrystalUtil.addImage(crystal, image);	
		
		SilUtil.addCrystal(sil, crystal);
		
		// Crystal 2
		crystal = new Crystal();
		crystal.setUniqueId(100000001);
		crystal.setRow(1);
		crystal.setExcelRow(2);
		crystal.setCrystalId("myo2");
		crystal.setPort("A2");
		crystal.setContainerId("SSRL001");
		crystal.setContainerType("cassette");
		crystal.getData().setDirectory("/data/annikas/A2/myo2");
		crystal.getData().setProtein("Myoglobin 2");
		crystal.getData().setComment("medium crystal");
		crystal.getData().setFreezingCond("-22deg");
		crystal.getData().setCrystalCond("very good");
		crystal.getData().setMetal("Fe");
		crystal.getData().setPriority("Very High");
		crystal.getData().setPerson("annikas");
		crystal.getData().setCrystalUrl("http://smb.slac.stanford.edu/crystals/A2/myo2.html");
		crystal.getData().setProteinUrl("http://smb.slac.stanford.edu/protein/A2/myo2.html");
		crystal.getData().setMove("B2");
		crystal.getResult().getAutoindexResult().setWarning("Minor problem");
		crystal.getResult().getAutoindexResult().setMosaicity(0.1);
		crystal.getResult().getAutoindexResult().setIsigma(1.00);
		crystal.getResult().getAutoindexResult().setScore(0.99);
		crystal.getResult().getAutoindexResult().setImages("/data/annikas/A1/myo2/A2_001.img /data/annikas/A2/myo2/A2_002.img");
		cell = new UnitCell();
		cell.setA(80.0); cell.setB(80.0); cell.setC(80.0); cell.setAlpha(90.0); cell.setBeta(77.0); cell.setGamma(88.0);
		crystal.getResult().getAutoindexResult().setUnitCell(cell);
		crystal.getResult().getAutoindexResult().setRmsd(1.0);
		crystal.getResult().getAutoindexResult().setBravaisLattice("C3");
		crystal.getResult().getAutoindexResult().setResolution(1.2);
		crystal.getResult().getAutoindexResult().setDir("/data/annikas/webice/autoindex/1/A2/autoindex");
		crystal.getResult().getAutoindexResult().setBestSolution(5);
		
		image = new Image();
		image.setName("A2_001.img");
		image.setDir("/data/annikas/myo2");
		image.setGroup("1");
		image.getData().setJpeg("A2_001.jpg");
		image.getData().setSmall("/data/annikas/A2/A2_001_small.jpg");
		image.getData().setMedium("/data/annikas/A2/A2_001_medium.jpg");
		image.getData().setLarge("/data/annikas/A2/A2_001_large.jpg");
		image.getResult().getSpotfinderResult().setScore(0.999);
		image.getResult().getSpotfinderResult().setIntegratedIntensity(1000.0);
		image.getResult().getSpotfinderResult().setNumOverloadSpots(10);
		image.getResult().getSpotfinderResult().setResolution(1.3);
		image.getResult().getSpotfinderResult().setNumIceRings(1);
		image.getResult().getSpotfinderResult().setNumSpots(890);
		image.getResult().getSpotfinderResult().setSpotShape(0.99);
		image.getResult().getSpotfinderResult().setQuality(1.0);
		image.getResult().getSpotfinderResult().setDiffractionStrength(999.9);
		image.getResult().getSpotfinderResult().setDir("/data/annikas/webice/screening/1/A2/spotfinder");
		CrystalUtil.addImage(crystal, image);	
		
		image = new Image();
		image.setName("A2_002.img");
		image.setDir("/data/annikas/myo2");
		image.setGroup("2");
		image.getData().setJpeg("A2_002.jpg");
		image.getData().setSmall("/data/annikas/A2/A2_002_small.jpg");
		image.getData().setMedium("/data/annikas/A2/A2_002_medium.jpg");
		image.getData().setLarge("/data/annikas/A2/A2_002_large.jpg");
		image.getResult().getSpotfinderResult().setScore(0.988);
		image.getResult().getSpotfinderResult().setIntegratedIntensity(1200.0);
		image.getResult().getSpotfinderResult().setNumOverloadSpots(12);
		image.getResult().getSpotfinderResult().setResolution(1.1);
		image.getResult().getSpotfinderResult().setNumIceRings(2);
		image.getResult().getSpotfinderResult().setNumSpots(1720);
		image.getResult().getSpotfinderResult().setSpotShape(0.96);
		image.getResult().getSpotfinderResult().setQuality(0.879);
		image.getResult().getSpotfinderResult().setDiffractionStrength(1233.0);
		image.getResult().getSpotfinderResult().setDir("/data/annikas/webice/screening/1/A2/spotfinder");
		CrystalUtil.addImage(crystal, image);	

		image = new Image();
		image.setName("A2_003.img");
		image.setDir("/data/annikas/myo2");
		image.setGroup("2");
		image.getData().setJpeg("A2_003.jpg");
		image.getData().setSmall("/data/annikas/A2/A2_003_small.jpg");
		image.getData().setMedium("/data/annikas/A2/A2_003_medium.jpg");
		image.getData().setLarge("/data/annikas/A2/A2_003_large.jpg");
		image.getResult().getSpotfinderResult().setScore(0.555);
		image.getResult().getSpotfinderResult().setIntegratedIntensity(1100.0);
		image.getResult().getSpotfinderResult().setNumOverloadSpots(9);
		image.getResult().getSpotfinderResult().setResolution(1.0);
		image.getResult().getSpotfinderResult().setNumIceRings(1);
		image.getResult().getSpotfinderResult().setNumSpots(2220);
		image.getResult().getSpotfinderResult().setSpotShape(0.678);
		image.getResult().getSpotfinderResult().setQuality(0.9522);
		image.getResult().getSpotfinderResult().setDiffractionStrength(2345.0);
		image.getResult().getSpotfinderResult().setDir("/data/annikas/webice/screening/1/A2/spotfinder");
		CrystalUtil.addImage(crystal, image);	
				
		SilUtil.addCrystal(sil, crystal);

		return sil;
	
	}

	static public RawData createSimpleRawData()
		throws Exception
	{
		int numColumns = 19;
		
		RawData rawData = new RawData();
		rawData.addColumn("port");
		rawData.addColumn("uniqueId");
		rawData.addColumn("crystalID");
		rawData.addColumn("directory");
		rawData.addColumn("protein");
		rawData.addColumn("userData");
		rawData.addColumn("containerID");
		rawData.addColumn("mosaicity");
		rawData.addColumn("iSigma");
		rawData.addColumn("images[1].path");
		rawData.addColumn("images[1].group");
		rawData.addColumn("images[1].iceRing");
		rawData.addColumn("images[1].jpeg");
		rawData.addColumn("images[1].score");
		rawData.addColumn("images[2].path");
		rawData.addColumn("images[2].group");
		rawData.addColumn("images[2].iceRing");
		rawData.addColumn("images[2].jpeg");
		rawData.addColumn("images[2].score");
	
		// Crystal 1
		RowData rowData1 = rawData.newRow();
		rowData1.addCell("A1");
		rowData1.addCell("100000000");
		rowData1.addCell("myo1");
		rowData1.addCell("/data/annikas/myo1");
		rowData1.addCell("Myoglobin 1");
		rowData1.addCell("my data 1");
		rowData1.addCell("SSRL001");
		rowData1.addCell("0.045");
		rowData1.addCell("0.88");
		rowData1.addCell("/data/annikas/myo1/A1_001.img");
		rowData1.addCell("1");
		rowData1.addCell("2");
		rowData1.addCell("A1_001.jpg");
		rowData1.addCell("0.7882");
		rowData1.addCell("/data/annikas/myo1/A1_002.img");
		rowData1.addCell("2");
		rowData1.addCell("2");
		rowData1.addCell("A1_002.jpg");
		rowData1.addCell("0.975");
		
		// Crystal 2
		RowData rowData2 = rawData.newRow();
		rowData2.addCell("A2");
		rowData2.addCell("100000001");
		rowData2.addCell("myo2");
		rowData2.addCell("/data/annikas/myo2");
		rowData2.addCell("Myoglobin 2");
		rowData2.addCell("my data 2");
		rowData2.addCell("SSRL001");
		rowData2.addCell("0.002");
		rowData2.addCell("0.96");
		rowData2.addCell("/data/annikas/myo2/A2_001.img");
		rowData2.addCell("1");
		rowData2.addCell("0");
		rowData2.addCell("A2_001.jpg");
		rowData2.addCell("0.978");
		rowData2.addCell("/data/annikas/myo2/A2_002.img");
		rowData2.addCell("2");
		rowData2.addCell("0");
		rowData2.addCell("A2_002.jpg");
		rowData2.addCell("0.916");
	
		return rawData;
	}

	
	static public void printWarnings(java.util.List<String> warnings)
	{
		Iterator it = warnings.iterator();
		while (it.hasNext()) {
			System.out.println(it.next());
		}
	}

	static public UploadData createUploadData(String filePath, 
			String templateName, 
			String containerType,
			String sheetName)
		throws Exception
	{
		UploadData uploadData = new UploadData();
		File f = new File(filePath);
		FileInputStream in = new FileInputStream(f);
		MultipartFile file = new MockMultipartFile("file", f.getName(), "application/vnd.ms-excel", in);
		// Do we need to close it?
		in.close();
		
		uploadData.setBeamline("BL1-5");
		uploadData.setCassettePosition("left");
		uploadData.setSheetName(sheetName);
		uploadData.setSilOwner("annikas");
		uploadData.setTemplateName(templateName);
		uploadData.setContainerType(containerType);
		uploadData.setFile(file);
		
		return uploadData;
	}
	
}
