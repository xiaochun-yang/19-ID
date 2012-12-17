package sil.beans;

import java.util.Hashtable;
import java.io.Writer;


/**************************************************
 *
 * Crystal Interface
 *
 **************************************************/
public interface Crystal
{
	/**
	 * Row number
	 */
	public int getRow();
	public void setRow(int r);
	public int getExcelRow();
	public void setExcelRow(int r);
	public Crystal clone()
		throws Exception;
	public ImageGroup getImageGroup(String groupName);
	
	 
	/*=================================================
	 * Crystal selection
	 *=================================================*/
	
	/**
	 * Is this crystal selected
	 */ 
	public boolean isSelected();
	
	/**
	 * Select this crystal
	 */
	public void setSelected(boolean l);
	
	 
	/*=================================================
	 * GET/SET images
	 *=================================================*/
	 
	/**
	 * Get field of the last image in the group
	 */
	public String getImageField(String groupName, String fieldName);

	/**
	 * Get field of the image in the group
	 */
	public void setImageField(String groupName, String fieldName, String fieldValue);
	/**
	 * Set image
	 */
	public void setImage(String groupName, String imgName, Hashtable params);

	/**
	 * Add image
	 */
	public void addImage(String groupName, String imgName, Hashtable params);

	/**
	 * Has image or not in the given group?
	 */
	public boolean hasImage(String groupName, String imgName);

	/**
	 * Clear image in the given group
	 */
	public void clearImages(String groupName);

	/**
	 * Clear image in all groups
	 */
	public void clearImages();
	
	/*=================================================
	 * GET/SET fields
	 *=================================================*/
	
	/**
	 * Returns crystal field
	 */
	public String getField(String name);

	/**
	 * Set a field
	 */
	public void setField(String n, String val);

	/**
	 * Set fields
	 */
	public void setFields(Hashtable params);

	/**
	 * Clear all fields
 	 */
	public void clearFields();
	

	public void clearField(String n);
	
	/**
	 * clear spotfinder result fields for all images
 	 */
	public void clearSpotfinderResults();

	/**
	 * Clear autoindex result fields
 	 */
	public void clearAutoindexResults();
	

	/*=================================================
	 * Covert data to string
	 *=================================================*/

	/**
	 * Dump data to tcl string
	 */
	public void toTclString(StringBuffer buf)
		throws Exception;
	
	/**
	 * Dump data to tcl string
	 */
	public void toTclString(StringBuffer buf, boolean update)
		throws Exception;

	/**
	 * Dump data to xml string
	 */
	public void toXmlString(StringBuffer buf)
		throws Exception;

	/**
	 * Dump data to xml string
	 */
	public void toXmlString(Writer writer)
		throws Exception;

}


