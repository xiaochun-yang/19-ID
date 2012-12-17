package sil.beans;

import java.util.Hashtable;

public class SilEvent
{
	private static int COMMAND_INDEX_MIN = 1;
	public static int LOAD_SIL = 1;
	public static int SET_CRYSTAL = 2;
	public static int SET_CRYSTAL_IMAGE = 3;
	public static int ADD_CRYSTAL_IMAGE = 4;
	public static int CLEAR_CRYSTAL_IMAGES = 5;
	public static int REMOVE_CRYSTAL = 8;
	public static int SET_CRYSTAL_ATTRIBUTE = 8;
	public static int CLEAR_CRYSTAL = 9;
	public static int CLEAR_ALL_CRYSTALS = 10;
	public static int ADD_CRYSTAL = 11;
	private static int COMMAND_INDEX_MAX = 11;

	private int command = -1;
	private String silId = "";
	private String error = null;
	private String key = "";

	private boolean silent = false;

	private int row = -1;
	private Hashtable fields = new Hashtable();

	// Event id
	private int id = -1;
	
	private Crystal crystal = null;
	
	public static SilEvent createClearCrystalEvent(String silId, int row, String fieldName)
		throws Exception
	{
		return new SilEvent(CLEAR_CRYSTAL, silId, row, fieldName);
	}

	/**
	 */
	public SilEvent(int command, String silId)
		throws Exception
	{

		this.command = command;
		if ((silId == null) || (silId.length() == 0))
			throw new Exception("Invalid silId");

		this.silId = silId;
	}

	/**
	 */
	private SilEvent(int command, String silId, int row, String fieldName)
		throws Exception
	{
		if ((silId == null) || (silId.length() == 0))
			throw new Exception("Invalid silId");

		if (row < 0)
			throw new Exception("Invalid row: " + row);

		if ((fieldName == null) || (fieldName.length() == 0))
			throw new Exception("Invalid field name");

		if (command != CLEAR_CRYSTAL)
			throw new Exception("Expect clearCrystal command");


		this.command = command;
		this.silId = silId;
		this.row = row;

		fields.put("clearField", fieldName);


	}

	/**
	 */
	public SilEvent(int command, String silId,
			int row, String fieldName, String fieldValue)
		throws Exception
	{
		if ((silId == null) || (silId.length() == 0))
			throw new Exception("Invalid silId");

		if (row < 0)
			throw new Exception("Invalid row: " + row);

		if ((fieldName == null) || (fieldName.length() == 0))
			throw new Exception("Invalid field name");

		if ((fieldValue == null) || (fieldValue.length() == 0))
			throw new Exception("Invalid field value");

		if ((command < COMMAND_INDEX_MIN) || (command > COMMAND_INDEX_MAX))
			throw new Exception("Invalid command: " + command);


		this.command = command;
		this.silId = silId;
		this.row = row;

		fields.put(fieldName, fieldValue);


	}
	
	public SilEvent(int command, String silId, Crystal crystal)
		throws Exception
	{

		this.command = command;
		if ((silId == null) || (silId.length() == 0))
			throw new Exception("Invalid silId");
			
		if (crystal == null)
			throw new Exception("Null crystal");
			
		if (crystal.getRow() < 0)
			throw new Exception("Invalid crystal row " + crystal.getRow());

		this.silId = silId;
		this.row = crystal.getRow();
		this.crystal = crystal;
	}
	
	/**
	 */
	public Crystal getCrystal()
	{
		return crystal;
	}

	/**
	 */
	public String getSilKey()
	{
		return key;
	}
	
	/**
	 */
	public void setSilKey(String s)
	{
		if (s == null)
			s = "";
			
		key = s;
	}

	/**
	 */
	public void setSilent(boolean b)
	{
		silent = b;
	}

	/**
	 */
	public boolean isSilent()
	{
		return silent;
	}

	/**
	 */
	public int getCommand()
	{
		return command;
	}

	/**
	 * Used to clear results in all rows
	 */
	public SilEvent(int command,
			String silId,
			Hashtable fields)
		throws Exception
	{
		if ((silId == null) || (silId.length() == 0))
			throw new Exception("Invalid silId");

		this.command = command;
		this.silId = silId;
		this.fields = fields;
		
	}

	/**
	 */
	public SilEvent(int command,
					String silId,
					int row, Hashtable fields)
		throws Exception
	{
		if ((silId == null) || (silId.length() == 0))
			throw new Exception("Invalid silId");

		if (row < 0) {
			String cId = (String)fields.get("CrystalID");
			if ((cId == null) || (cId.length() == 0))
				throw new Exception("Invalid row: " + row);
		}

		this.command = command;
		this.silId = silId;
		this.row = row;
		this.fields = fields;
		
	}

	/**
	 * Package method
	 */
	void setId(int id)
	{
		this.id = id;
	}

	/**
	 * Returns the unique event id
	 */
	public int getId()
	{
		return id;
	}

	/**
	 * Returns id of the sil associated with this event
	 */
	public String getSilId()
	{
		return silId;
	}

	/**
	 */
	public void setError(String s)
	{
		error = s;
	}

	/**
	 */
	public String getError()
	{
		return error;
	}

	/**
	 */
	public boolean hasError()
	{
		return (error != null);
	}

	/**
	 */
	public Hashtable getFields()
	{
		return fields;
	}
	
	/**
	 */
	public String getField(String f)
	{
		return (String)fields.get(f);
	}

	/**
	 */
	public int getRow()
	{
		return row;
	}
	
	public void setRow(int r)
	{
		row = r;
	}

}

