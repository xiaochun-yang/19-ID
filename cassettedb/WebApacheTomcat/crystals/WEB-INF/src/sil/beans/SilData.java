package sil.beans;

import java.util.Hashtable;
import java.io.Writer;
import jxl.Workbook;
import jxl.WorkbookSettings;
import jxl.write.*;
import jxl.format.Font;
import jxl.format.Alignment;

public interface SilData
{
	/**
	 * GETTER
	 */
	public String getId();
	public int getEventId();
	public boolean isLocked();
	public String getVersion();
	public String getKey();
	public int getCrystalRow(String fieldName, String fieldValue);
	public Crystal cloneCrystal(int row)
		throws Exception;

	/**
	 */
	public void load(String xmlFileName)
		throws Exception;

	/**
	 * SETTER
	 */
	public void setKey(String s);
	public void setLocked(boolean l);
	public void setEventId(int ev);
	public int addCrystal(Crystal newCrystal)
		throws Exception;
	public int addCrystal(Hashtable params)
		throws Exception;
	public void setCrystalImage(int row, String groupName, String imgName, Hashtable params)
		throws Exception;
	public void addCrystalImage(int row, String groupName, String imgName, Hashtable params)
		throws Exception;
	public boolean hasCrystalImage(int row, String groupName, String imgName)
			throws Exception;
	public void clearCrystalImages(int row, int group)
		throws Exception;
	public void clearCrystalImages(int row)
			throws Exception;
	public void clearSpotfinderResults(int row)
			throws Exception;
	public void clearAutoindexResults(int row)
			throws Exception;
	public void setCrystal(int row, String fieldName, String fieldValue)
			throws Exception;
	public void clearCrystal(int row, String fieldName)
			throws Exception;
	public void setCrystal(int row, Hashtable params)
			throws Exception;
	public void setCrystal(Crystal c)
			throws Exception;
	public void selectCrystals(String values)
			throws Exception;

	/**
	 * OUTPUT
	 */
	public void toTclString(StringBuffer buf)
			throws Exception;
	public void toTclString(StringBuffer buf, Object[] rows)
			throws Exception;
	public void toXmlString(StringBuffer buf, Object[] rows)
			throws Exception;
	public void toXmlString(StringBuffer buf)
			throws Exception;
	public void toXmlString(Writer writer)
			throws Exception;
	public void toExcel(WritableSheet sheet)
			throws Exception;

}

