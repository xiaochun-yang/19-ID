package sil.beans;

public class SilDataFactory
{
	public static int SIMPLE_SILDATA = 1;
	public static int DOM_SILDATA = 2;

	private static SilDataFactory simpleFactory = new SilDataFactory("simple");
	private static SilDataFactory domFactory = new SilDataFactory("dom");

	private String type = "simple";

	public static SilDataFactory getFactory(int type)
	{
		if (type == DOM_SILDATA)
			return domFactory;

		return simpleFactory;
	}

	SilDataFactory(String type)
	{
		this.type = type;
	}

	public SilData getSilData()
		throws Exception
	{
		if (type.equals("dom"))
			return new SilDataDomImp();

		return new SilDataSimpleImp();

	}
	
	/**
	 */
	public Crystal newCrystal()
	{
		return new CrystalSimpleImp();
	}

	/**
	 */
	public Crystal newCrystal(int row)
	{
		return new CrystalSimpleImp(row, row, false);
	}

	/**
	 */
	public Crystal newCrystal(int row, int excelRow)
	{
		return new CrystalSimpleImp(row, excelRow, false);
	}

}
