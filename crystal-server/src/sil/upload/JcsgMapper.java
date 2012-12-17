package sil.upload;

import java.util.List;


public class JcsgMapper implements UploadDataMapper
{	
	//@override
	public RawData applyTemplate(RawData rawData, String templateName, List<String> warnings) 
		throws Exception
	{			
		RawData newRawData = new RawData();
		
		if (!rawData.hasColumnName("CurrentPosition"))
			throw new Exception("Missing column CurrentPosition");
		if (!rawData.hasColumnName("XtalID"))
			throw new Exception("Missing column XtalID");
		if (!rawData.hasColumnName("CurrentCasette"))
			throw new Exception("Missing column CurrentCasette");
		
		// Only map these columns and ignore the rest
		newRawData.copyColumn(rawData, "CurrentPosition", "port");
		newRawData.copyColumn(rawData, "XtalID", "crystalId");
		newRawData.copyColumn(rawData, "AccessionID", "data.protein");
		newRawData.copyColumn(rawData, "CCRemarks", "data.comment");
		newRawData.copyColumn(rawData, "Cryo", "data.freezingCond");
		newRawData.copyColumn(rawData, "CrystalConditions", "data.crystalCond");
		newRawData.copyColumn(rawData, "SelMetOrNative", "data.metal");
		if (rawData.hasColumnName("PRIScore")) {	
			newRawData.copyColumn(rawData, "PRIScore", "data.priority");
		} else {
			newRawData.addColumn("data.priority", null);
		}
//		int newCol = newRawData.addColumn("containerType", "cassette");

		newRawData.copyColumn(rawData, "CurrentCasette", "containerId");
		if (rawData.hasColumnName("CrystalURL")) {
			newRawData.copyColumn(rawData, "CrystalURL", "data.crystalUrl");
		} else {
			newRawData.addColumn("data.crystalUrl", null);
		}
		// Add new column
		if (rawData.hasColumnName("ProteinURL")) {
			newRawData.copyColumn(rawData, "ProteinURL", "data.proteinUrl");
		} else {
			int col = newRawData.addColumn("data.proteinUrl", null);
			// Add new row if it does not exist.
			while (newRawData.getRowCount() < rawData.getRowCount()) { newRawData.newRow(); }
			for (int row = 0; row < rawData.getRowCount(); ++row) {
				String accessID = rawData.getData(row, "AccessionID");
				newRawData.setData(row, col, "http://www1.jcsg.org/cgi-bin/psat/analyzer.cgi?acc=" + accessID);
			}
		}
		
		if (rawData.hasColumnName("Directory")) {
			newRawData.copyColumn(rawData, "Directory", "data.directory");
		} else {
			int col = newRawData.addColumn("data.directory", null);
			// Add new row if it does not exist.
			while (newRawData.getRowCount() < rawData.getRowCount()) { newRawData.newRow(); }
			for (int row = 0; row < rawData.getRowCount(); ++row) {
				String accessID = rawData.getData(row, "AccessionID");
				String xtalID = rawData.getData(row, "XtalID");
				newRawData.setData(row, col, accessID + "/" + xtalID);
			}
		}
		
		return newRawData;
	}
	
	public boolean supports(String templateName) throws Exception
	{
		return templateName.equals("jcsg");			
	}
}
