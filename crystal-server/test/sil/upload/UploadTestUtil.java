package sil.upload;

import sil.beans.*;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;

import java.beans.XMLEncoder;
import java.io.*;

import junit.framework.TestCase;

public class UploadTestUtil extends TestCase {
	
	static public String baseDir = "test/SilUploadTests";
		
	static public RawData createRawData(UploadData uploadData)
		throws Exception
	{					
		UploadParser parser = new Excel2003Parser();
		return parser.parse(uploadData);
			
	}
	
	static public void saveRawData(RawData rawData, String outputFile)
		throws Exception
	{
		FileOutputStream out = new FileOutputStream(outputFile);
		XMLEncoder encoder = new XMLEncoder(out);
		encoder.writeObject(rawData);
		encoder.flush();
		out.close();		
	}
	static public void debugRawData(RawData rawData)
		throws Exception
	{
		XMLEncoder encoder = new XMLEncoder(System.out);
		encoder.writeObject(rawData);
		encoder.flush();
	}
		
	static public Sil createSil1() throws Exception
	{
		Sil sil = new Sil();
		sil.setId(1);
		sil.getInfo().setEventId(0);
		sil.getInfo().setKey("");

		Crystal crystal1 = new Crystal();
		crystal1.setRow(0);
		crystal1.setUniqueId(100);
		crystal1.setCrystalId("myo1");
		crystal1.setPort("A1");
		crystal1.setContainerId("SSRL001");
		crystal1.getData().setProtein("Myoglobin 1");
		crystal1.getData().setDirectory("/data/penjitk/myo1");
		crystal1.getResult().getAutoindexResult().setMosaicity(0.045);
		crystal1.getResult().getAutoindexResult().setIsigma(0.88);
	
		Image image = new Image();
		image.setName("A1_001.img");
		image.setDir("/data/penjitk/myo1");
		image.setGroup("1");
		image.getResult().getSpotfinderResult().setNumIceRings(2);
		image.getData().setJpeg("A1_001.jpg");
		image.getResult().getSpotfinderResult().setScore(0.7882);
		CrystalUtil.addImage(crystal1, image);
		
		image = new Image();
		image.setName("A1_002.img");
		image.setDir("/data/penjitk/myo1");
		image.setGroup("2");
		image.getResult().getSpotfinderResult().setNumIceRings(2);
		image.getData().setJpeg("A1_002.jpg");
		image.getResult().getSpotfinderResult().setScore(0.975);			
		CrystalUtil.addImage(crystal1, image);
		
		SilUtil.addCrystal(sil, crystal1);
		
		// Crystal 2
		Crystal crystal2 = new Crystal();
		crystal2.setRow(1);
		crystal1.setUniqueId(101);
		crystal2.setCrystalId("myo2");
		crystal2.setPort("A2");
		crystal2.setContainerId("SSRL001");
		crystal2.getData().setProtein("Myoglobin 2");
		crystal2.getData().setDirectory("/data/penjitk/myo2");
		crystal2.getResult().getAutoindexResult().setMosaicity(0.002);
		crystal2.getResult().getAutoindexResult().setIsigma(0.96);
		
		image = new Image();
		image.setName("A2_001.img");
		image.setDir("/data/penjitk/myo2");
		image.setGroup("1");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A2_001.jpg");
		image.getResult().getSpotfinderResult().setScore(0.978);
		CrystalUtil.addImage(crystal2, image);
		
		image = new Image();
		image.setName("A2_002.img");
		image.setDir("/data/penjitk/myo2");
		image.setGroup("2");
		image.getResult().getSpotfinderResult().setNumIceRings(0);
		image.getData().setJpeg("A2_002.jpg");
		image.getResult().getSpotfinderResult().setScore(0.916);			
		CrystalUtil.addImage(crystal2, image);
		
		SilUtil.addCrystal(sil, crystal2);

		return sil;
	
	}
	
	static public RawData createRawData1()
		throws Exception
	{		
		RawData rawData = new RawData();
		rawData.addColumn("port");
		rawData.addColumn("uniqueId");
		rawData.addColumn("crystalId");
		rawData.addColumn("data.directory");
		rawData.addColumn("data.protein");
		rawData.addColumn("containerId");
		rawData.addColumn("result.autoindexResult.mosaicity");
		rawData.addColumn("result.autoindexResult.isigma");
		rawData.addColumn("images[1].path");
		rawData.addColumn("images[1].group");
		rawData.addColumn("images[1].result.spotfinderResult.numIceRings");
		rawData.addColumn("images[1].data.jpeg");
		rawData.addColumn("images[1].result.spotfinderResult.score");
		rawData.addColumn("images[2].path");
		rawData.addColumn("images[2].group");
		rawData.addColumn("images[2].result.spotfinderResult.numIceRings");
		rawData.addColumn("images[2].data.jpeg");
		rawData.addColumn("images[2].result.spotfinderResult.score");

		RowData rowData1 = rawData.newRow();
		int i = 0;
		rowData1.setCell(i, "A1"); ++i;
		rowData1.setCell(i, "100"); ++i;
		rowData1.setCell(i, "myo1"); ++i;
		rowData1.setCell(i, "/data/penjitk/myo1"); ++i;
		rowData1.setCell(i, "Myoglobin 1"); ++i;
		rowData1.setCell(i, "SSRL001"); ++i;
		rowData1.setCell(i, "0.045"); ++i;
		rowData1.setCell(i, "0.88"); ++i;
		rowData1.setCell(i, "/data/penjitk/myo1" + File.separator + "A1_001.img"); ++i;
		rowData1.setCell(i, "1"); ++i;
		rowData1.setCell(i, "2"); ++i;
		rowData1.setCell(i, "A1_001.jpg"); ++i;
		rowData1.setCell(i, "0.7882"); ++i;
		rowData1.setCell(i, "/data/penjitk/myo1" + File.separator + "A1_002.img"); ++i;
		rowData1.setCell(i, "2"); ++i;
		rowData1.setCell(i, "2"); ++i;
		rowData1.setCell(i, "A1_002.jpg"); ++i;
		rowData1.setCell(i, "0.975"); ++i;
		
		// Crystal 2
		RowData rowData2 = rawData.newRow();
		i = 0;
		rowData2.setCell(i, "A2"); ++i;
		rowData2.setCell(i, "101"); ++i;
		rowData2.setCell(i, "myo2"); ++i;
		rowData2.setCell(i, "/data/penjitk/myo2"); ++i;
		rowData2.setCell(i, "Myoglobin 2"); ++i;
		rowData2.setCell(i, "SSRL001"); ++i;
		rowData2.setCell(i, "0.002"); ++i;
		rowData2.setCell(i, "0.96"); ++i;
		rowData2.setCell(i, "/data/penjitk/myo2" + File.separator + "A2_001.img"); ++i;
		rowData2.setCell(i, "1"); ++i;
		rowData2.setCell(i, "0"); ++i;
		rowData2.setCell(i, "A2_001.jpg"); ++i;
		rowData2.setCell(i, "0.978"); ++i;
		rowData2.setCell(i, "/data/penjitk/myo2" + File.separator + "A2_002.img"); ++i;
		rowData2.setCell(i, "2"); ++i;
		rowData2.setCell(i, "0"); ++i;
		rowData2.setCell(i, "A2_002.jpg"); ++i;
		rowData2.setCell(i, "0.916"); ++i;
	
		return rawData;
	}

	static public RawData createSimpleRawData()
		throws Exception
	{		
		RawData rawData = new RawData();
		rawData.addColumn("Port");
		rawData.addColumn("UniqueID");
		rawData.addColumn("CrystalID");
		rawData.addColumn("Directory");
		rawData.addColumn("Protein");
		rawData.addColumn("UserData");
		rawData.addColumn("ContainerID");
		rawData.addColumn("mosaicity");
		rawData.addColumn("iSigma");
		rawData.addColumn("Image1");
		rawData.addColumn("Group1");
		rawData.addColumn("IceRings1");
		rawData.addColumn("Jpeg1");
		rawData.addColumn("Score1");
		rawData.addColumn("Image2");
		rawData.addColumn("Group2");
		rawData.addColumn("IceRings2");
		rawData.addColumn("Jpeg2");
		rawData.addColumn("Score2");
	
		// Crystal 1
		RowData rowData1 = rawData.newRow();
		setRowData1(rowData1);
		
		// Crystal 2
		RowData rowData2 = rawData.newRow();
		setRowData2(rowData2);
	
		return rawData;
	}
	
	static public void setRowData1(RowData rowData1)
	{
		int i = 0;
		rowData1.setCell(i, "A1"); ++i;
		rowData1.setCell(i, "100"); ++i;
		rowData1.setCell(i, "myo1"); ++i;
		rowData1.setCell(i, "/data/penjitk/myo1"); ++i;
		rowData1.setCell(i, "Myoglobin 1"); ++i;
		rowData1.setCell(i, "my data 1"); ++i;
		rowData1.setCell(i, "SSRL001"); ++i;
		rowData1.setCell(i, "0.045"); ++i;
		rowData1.setCell(i, "0.88"); ++i;
		rowData1.setCell(i, "/data/penjitk/myo1" + File.separator + "A1_001.img"); ++i;
		rowData1.setCell(i, "1"); ++i;
		rowData1.setCell(i, "2"); ++i;
		rowData1.setCell(i, "A1_001.jpg"); ++i;
		rowData1.setCell(i, "0.7882"); ++i;
		rowData1.setCell(i, "/data/penjitk/myo1" + File.separator + "A1_002.img"); ++i;
		rowData1.setCell(i, "2"); ++i;
		rowData1.setCell(i, "2"); ++i;
		rowData1.setCell(i, "A1_002.jpg"); ++i;
		rowData1.setCell(i, "0.975"); ++i;
	}
	
	static public void setRowData2(RowData rowData2)
	{
		int i = 0;
		rowData2.setCell(i, "A2"); ++i;
		rowData2.setCell(i, "101"); ++i;
		rowData2.setCell(i, "myo2"); ++i;
		rowData2.setCell(i, "/data/penjitk/myo2"); ++i;
		rowData2.setCell(i, "Myoglobin 2"); ++i;
		rowData2.setCell(i, "my data 2"); ++i;
		rowData2.setCell(i, "SSRL001"); ++i;
		rowData2.setCell(i, "0.002"); ++i;
		rowData2.setCell(i, "0.96"); ++i;
		rowData2.setCell(i, "/data/penjitk/myo2" + File.separator + "A2_001.img"); ++i;
		rowData2.setCell(i, "1"); ++i;
		rowData2.setCell(i, "0"); ++i;
		rowData2.setCell(i, "A2_001.jpg"); ++i;
		rowData2.setCell(i, "0.978"); ++i;
		rowData2.setCell(i, "/data/penjitk/myo2" + File.separator + "A2_002.img"); ++i;
		rowData2.setCell(i, "2"); ++i;
		rowData2.setCell(i, "0"); ++i;
		rowData2.setCell(i, "A2_002.jpg"); ++i;
		rowData2.setCell(i, "0.916"); ++i;
		
	}
	
}