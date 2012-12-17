package sil.beans;

import sil.beans.*;
import cts.CassetteDB;
import cts.CassetteIO;
import java.io.*;
import java.util.Hashtable;
import org.w3c.dom.*;
import org.xml.sax.InputSource;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.apache.xerces.dom.DocumentImpl;
import org.apache.xerces.dom.DOMImplementationImpl;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.xml.sax.*;
import org.xml.sax.helpers.*;

class UpgradeManager
{
	private CassetteDB ctsdb = null;
	private String xsltFile = "";
	private String xsltTclFile  = "";
	private CassetteListReader reader = null;

	private String curOwner = "";


	/**
	 */
	public UpgradeManager()
		throws Exception
	{
		ctsdb = SilUtil.getCassetteDB();

		xsltFile = SilConfig.getInstance().getTemplateDir()
						+ File.separator + "xsltCrystalData2Sil.xsl";

		xsltTclFile = SilConfig.getInstance().getTemplateDir()
						+ File.separator +  "xsltSil2Tcl.xsl";

		XMLReader parser = XMLReaderFactory.createXMLReader("org.apache.xerces.parsers.SAXParser");
		reader = new CassetteListReader(parser);
	}

	/**
	 */
	public void upgrade(String cassettesDir)
		throws Exception
	{
		upgradeToV1_0(cassettesDir);
	}

	/**
	 */
	private void upgradeSil(String silId, String silPrefix)
	{
		try {


		String src = SilConfig.getInstance().getCassetteDir()
							+ File.separator + curOwner
							+ File.separator + silPrefix + ".xml";
		File srcFile = new File(src);

		String dest = SilConfig.getInstance().getCassetteDir()
							+ File.separator + curOwner
							+ File.separator + silPrefix + "_sil.xml";
		File destFile = new File(dest);

		String tclDest = SilConfig.getInstance().getCassetteDir()
							+ File.separator + curOwner
							+ File.separator + silPrefix + "_sil.tcl";
		File tclDestFile = new File(tclDest);


		if (!srcFile.exists()) {
	 		System.out.println("Cannot find: xml file " + src + " for cassetteID " + silId);
			return;
		}

		if (destFile.exists()) {
	 		System.out.println("Sil file: " + dest + " already exists");
		} else {
	 		System.out.println("Transforming " + src + " to " + dest);
			createSilFile(silId, "unknown_pin", src, dest);
		}


		if (tclDestFile.exists()) {
	 		System.out.println("Tcl file: " + tclDest + " already exists");
		} else {
	 		System.out.println("Transforming " + dest + " to " + tclDest);
			createTclFile(dest, tclDest);
		}

		} catch (Exception e) {
			System.out.println("Failed to upgrade " + silId + ": "
								+ e.getMessage());
			e.printStackTrace();
		}
	}

	/**
	 * Tranform CrystalData xml to sil xml (sil.dtd).
	 */
	private void createSilFile(String silId, String cassettePin,
								String srcFile, String destFile)
		throws Exception
	{
		try {


			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer( new StreamSource(xsltFile));
			transformer.setParameter("param1", silId);
			transformer.setParameter("param2", cassettePin);

//			String systemId = SilConfig.getInstance().getSilDtdUrl();
//			StreamSource source = new StreamSource(new FileReader(srcFile), systemId);
			StreamSource source = new StreamSource(new FileReader(srcFile));
			StreamResult out = new StreamResult(new FileWriter(destFile));
			transformer.transform(source, out);

		} catch( Exception ex) {
			String err = "Failed to transform " + srcFile + " to " + destFile
							+ " using " + xsltFile + " xslt tranformation because "
							+ ex.getMessage();
			throw new Exception(err);
		}
	}

	/**
	 * Tranform CrystalData xml to sil xml (sil.dtd).
	 */
	private void createTclFile(String srcFile, String destFile)
		throws Exception
	{
		try {


			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer( new StreamSource(xsltTclFile));

			String systemId = SilConfig.getInstance().getSilDtdUrl();
			StreamSource source = new StreamSource(new FileReader(srcFile), systemId);
			StreamResult out = new StreamResult(new FileWriter(destFile));
			transformer.transform(source, out);

		} catch( Exception ex) {
			String err = "Failed to transform " + srcFile + " to " + destFile
							+ " using " + xsltTclFile + " xslt tranformation because "
							+ ex.getMessage();
			throw new Exception(err);
		}
	}

	/**
	 */
	private void upgradeToV1_0(String cassettesDir)
		throws Exception
	{
		System.out.println("Upgrading sil to V1.0");

		Object[] userDirs = getUserDirs(cassettesDir);
		int userId = -1;
		String xml = "";
		// Loop over user dirs
		for (int i = 0; i < userDirs.length; ++i) {

			curOwner = (String)userDirs[i];
			System.out.println("Finding user " + curOwner + " in DB");
/*			if (!curOwner.equals("blctl") && !curOwner.equals("penjitk")) {
				System.out.println("Skipping user " + curOwner);
				continue;
			}*/
			userId = ctsdb.getUserID(curOwner);
			if (userId < 0) {
				System.out.println("Cannot find user " + curOwner + " in DB");
				continue;
			}
			xml = ctsdb.getCassetteFileList(userId);
			if (SilUtil.isError(xml)) {
				System.out.println("Cannot find cassette list for user " + curOwner
									+ ": " + SilUtil.parseError(xml));
				continue;
			}
			InputSource source = new InputSource(new StringReader(xml));
			System.out.println("Start parsing cassette list for " + curOwner);
			reader.parse(source);
			System.out.println("Finish parsing cassette list for " + curOwner);
		}

		System.out.println("Upgarded sil to V1.0 successfully");
	}

	/**
	 */
	public static void main(String[] args)
	{
		try {

		if (args.length != 2) {
			System.out.println("Usage: UpgradeManager <cassettes dir> <config path>");
			System.exit(0);
		}

		String cassettesDir = args[0];
		SilConfig.createSilConfig(args[1]);

		UpgradeManager manager = new UpgradeManager();

		if (manager == null)
			throw new Exception("Failed to create UpgrageManager");

		manager.upgradeToV1_0(cassettesDir);


		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 */
	private Object[] getUserDirs(String cassettesDir)
		throws Exception
	{
		System.out.println("Listing dir under " + cassettesDir);

		XMLReader parser1 = XMLReaderFactory.createXMLReader("org.apache.xerces.parsers.SAXParser");
		UserListReader reader1 = new UserListReader(parser1, cassettesDir);
		String xml = ctsdb.getUserList();
		InputSource source = new InputSource(new StringReader(xml));
		reader1.parse(source);

		return reader1.getUserList();
	}

	/**
	 * SAX parser for Cassette List of a given user
	 */
	private class CassetteListReader extends XMLReaderAdapter
	{
		private String curElement = "";
		private String cassetteID = "";
		/**
		 */
		public CassetteListReader(XMLReader reader)
			throws Exception
		{
			super(reader);
		}

		/**
		 */
		public void startElement(String uri,
		                         String localName,
		                         String qName,
		                         Attributes atts)
                  throws SAXException
        {
			curElement = qName;
			// Reset cache for each row
			if (curElement.equals("Row")) {
				cassetteID = "";
			}
		}

		/**
		 */
		public void characters(char[] ch,
		                       int start,
		                       int length)
                throws SAXException
        {
			String value = new String(ch, start, length);
			if (curElement.equals("CassetteID")) {
				cassetteID = value;
//				System.out.println("CassetteID = " + value);
			} else if (curElement.equals("FileName")) {
				System.out.println("FileName = " + value);
				upgradeSil(cassetteID, value);
			}
		}

	}

	/**
	 * SAX parser for user list
	 */
	private class UserListReader extends XMLReaderAdapter
	{
		private String curElement = "";
		private Hashtable users = new Hashtable();
		private File rootDir = null;
		/**
		 */
		public UserListReader(XMLReader reader, String dir)
			throws Exception
		{
			super(reader);

			rootDir = new File(dir);

			if (!rootDir.isDirectory())
			throw new Exception(rootDir.getPath() + " is not a directory");
		}

		/**
		 */
		public void startElement(String uri,
		                         String localName,
		                         String qName,
		                         Attributes atts)
                  throws SAXException
        {
			curElement = qName;
		}

		/**
		 */
		public void characters(char[] ch,
		                       int start,
		                       int length)
                throws SAXException
        {
			String value = new String(ch, start, length);
			if (curElement.equals("LoginName")) {
				File userDir = new File(rootDir.getAbsolutePath() + File.separator + value);
				if (userDir.isDirectory())
					users.put(value, value);
			}
		}

		/**
		 */
		public Object[] getUserList()
		{
			return users.values().toArray();
		}

	}

}

