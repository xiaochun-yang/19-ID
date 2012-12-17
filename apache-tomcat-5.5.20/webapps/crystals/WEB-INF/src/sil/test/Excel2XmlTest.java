package sil.test;

import sil.beans.*;

public class Excel2XmlTest
{
	public static void main(String args[])
	{
		try {
		
		if (args.length != 3)
			throw new Exception("Usage: Excel2XmlTest <config file> <excel file> <xml file>");
		String configFile = args[0];
		String excelFile = args[1];
		String xmlFile = args[2];
		
		SilConfig.createSilConfig(configFile);
		
		Excel2Xml converter = new Excel2Xml();
		converter.convert(excelFile, xmlFile);
		
		} catch (Exception e) {
			System.out.println(e.getMessage());
			e.printStackTrace();
		}
	}
}

