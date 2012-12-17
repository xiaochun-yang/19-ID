package sil.io;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.InputStream;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.BeanWrapper;
import org.springframework.beans.TypeMismatchException;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.xml.sax.*;

import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.ImageWrapper;
import sil.beans.util.SilUtil;
import sil.factory.SilFactory;

// Load sil from xml file using old schema.
public class SsrlXmlLoader implements SilLoader, InitializingBean
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private SilFactory silFactory = null;

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}
	
	public void afterPropertiesSet() throws Exception {
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for SsrlXmlLoader bean");
	}

	public Sil load(String path) throws Exception
	{
		File xmlFile = new File(path);
		if (!xmlFile.exists()) {
			logger.error("File " + path + " does not exist.");
			throw new FileNotFoundException();
		}

		SAXParserFactory saxFactory = SAXParserFactory.newInstance();
		saxFactory.setValidating(false);
		SAXParser parser = saxFactory.newSAXParser();

		logger.debug("Parsing xml file " + path);
		Sil data = new Sil();
		parser.parse(xmlFile, new SilHandler(data));

		saxFactory = null;
		parser = null;
		
		return data;

	}
	
	public Sil load(InputStream in) throws Exception {

		SAXParserFactory saxFactory = SAXParserFactory.newInstance();
		saxFactory.setValidating(false);
		SAXParser parser = saxFactory.newSAXParser();

		Sil data = new Sil();
		parser.parse(in, new SilHandler(data));

		saxFactory = null;
		parser = null;
		
		return data;
	}

	
	private class SilHandler extends org.xml.sax.helpers.DefaultHandler 
	{
		Sil sil = null;
		
		// Use by SAX parser
		private CrystalWrapper curCrystal = null;
		private String curCrystalField = null;
		private String curGroup = null;
		private StringBuffer curFieldValue = new StringBuffer();
		
		public SilHandler(Sil sil)
		{
			this.sil = sil;
		}

		public void startElement(String uri, String localName,
					String qName, Attributes attributes)
			throws SAXException
		{
			// clear buffer
			curFieldValue.delete(0, curFieldValue.length());
			
			String tmp = "";
			if (qName.equals("Sil")) {
				tmp = attributes.getValue("name");
				if (tmp != null) {
					sil.setId(Integer.parseInt(tmp));
				}
/*				tmp = attributes.getValue("eventId");
				if (tmp != null) {
					try {
						sil.setEventId(Integer.parseInt(tmp));
					} catch (NumberFormatException e) {
						throw new SAXException("Invalid eventId '" + tmp + "'");
					}
				}*/
				tmp = attributes.getValue("version");
				if (tmp != null)
					sil.setVersion(tmp);
/*				tmp = attributes.getValue("key");
				if (tmp != null)
					sil.setKey(tmp);
				tmp = attributes.getValue("lock");
				if (tmp != null) {
					if (tmp.equals("true") || tmp.equals("yes") || tmp.equals("1"))
						sil.setLocked(true);
					else
						sil.setLocked(false);
				}*/

			} else if (qName.equals("Crystal")) {

				int row = -1;
				int excelRow = -1;
				boolean selected = false;

				tmp = attributes.getValue("row");
				if (tmp != null) {
					try {
						row = Integer.parseInt(tmp);
					} catch (NumberFormatException e) {
						throw new SAXException("Invalid row '" + tmp + "'");
					}
				}

				tmp = attributes.getValue("excelRow");
				if (tmp != null) {
					try {
						excelRow = Integer.parseInt(tmp);
					} catch (NumberFormatException e) {
						throw new SAXException("Invalid excelRow '" + tmp + "'");
					}
				}


				tmp = attributes.getValue("selected");
				if (tmp != null) {
					if (tmp.equals("1"))
						selected = true;
					else
						selected = false;
				}
				
//				System.out.println("SAX parser got crystal row  = " + row + " excelRow = " + excelRow + " selected = " + selected);

				Crystal newCrystal = new Crystal();
				newCrystal.setRow(row);
				newCrystal.setUniqueId(row); // tmp uniqueId in case uniqueId property does not exist
				newCrystal.setExcelRow(excelRow);
				newCrystal.setSelected(selected);

				curCrystal = silFactory.createCrystalWrapper(newCrystal);

			} else if (qName.equals("Group")) {

				if (curCrystal == null)
					return;

				curGroup = attributes.getValue("name");

			} else if (qName.equals("Images")) {
				curCrystalField = null;
			} else if (qName.equals("Image")) {

				if (curGroup == null)
					return;

				tmp = attributes.getValue("name");

				Image image = new Image();
				ImageWrapper wrapper = silFactory.createImageWrapper(image);
				wrapper.setImage(image);
				image.setName(tmp);
				image.setGroup(curGroup);
				for (int i = 0; i < attributes.getLength(); ++i) {
					String fieldName = attributes.getQName(i);
					try {
						wrapper.setPropertyValue(fieldName, attributes.getValue(i));
//						logger.debug("Set bean property name = " + fieldName + " value = " + attributes.getValue(i));
					} catch (TypeMismatchException e) {
						logger.debug("Cannot set image property name = " + fieldName 
								+ " value = '" + attributes.getValue(i) + "'"
								+ " because " + e.getMessage());
					}
				}
				try {
					if ((image.getName() != null) && (image.getName().length() > 0))
						CrystalUtil.addImage(curCrystal.getCrystal(), image);
				} catch (Exception e) {
					throw new SAXException(e.getMessage());
				}

			} else if (qName.equals("Repositions")) {
				// do nothing
			} else if (qName.equals("Reposition")) {
				RepositionData data = new RepositionData();
				BeanWrapper wrapper = silFactory.createRepositionDataWrapper(data);
				for (int i = 0; i < attributes.getLength(); ++i) {
					String fieldName = attributes.getQName(i);
					try {
						wrapper.setPropertyValue(fieldName, attributes.getValue(i));
					} catch (TypeMismatchException e) {
						logger.debug("Cannot set RepositionData property name = " + fieldName 
								+ " value = '" + attributes.getValue(i) + "'"
								+ " because " + e.getMessage());
					}
				}	
				try {
				if (CrystalUtil.getNumRepositionData(curCrystal.getCrystal()) == 0)
					CrystalUtil.addDefaultRepositionData(curCrystal.getCrystal(), data);
				else
					CrystalUtil.addRepositionData(curCrystal.getCrystal(), data);
				} catch (Exception e) {
					throw new SAXException("Cannot add repostion data. Root cause: " + e.getMessage());
				}
			} else if (qName.equals("RunDefs")) {
				// do nothing
			} else if (qName.equals("RunDef")) {
				RunDefinition run = new RunDefinition();
				BeanWrapper wrapper = silFactory.createRunDefinitionWrapper(run);
				for (int i = 0; i < attributes.getLength(); ++i) {
					String fieldName = attributes.getQName(i);
					try {
						wrapper.setPropertyValue(fieldName, attributes.getValue(i));
					} catch (TypeMismatchException e) {
						logger.debug("Cannot set RunDefinition property name = " + fieldName 
								+ " value = '" + attributes.getValue(i) + "'"
								+ " because " + e.getMessage());
					}
				}	
				try {
				if (CrystalUtil.getNumRunDefinitions(curCrystal.getCrystal()) == 0)
					CrystalUtil.addRunDefinition(curCrystal.getCrystal(), run);
				else
					CrystalUtil.addRunDefinition(curCrystal.getCrystal(), run);
				} catch (Exception e) {
					throw new SAXException("Cannot add repostion data. Root cause: " + e.getMessage());
				}
			} else {

				if (curCrystal  != null) {
					curCrystalField = qName;
				}
			}
		}

		public void characters(char[] ch,
	                       int start,
	                       int length)
	                throws SAXException
		{
			if (curGroup != null) {
				// We are inside a Group node
			} else if (curCrystal != null) {
				// We are inside Crystal node
				if (curCrystalField != null) {
					curFieldValue.append(new String(ch, start, length));
				}
			}
		}

		public void endElement(String uri, String localName, String qName)
			throws SAXException
		{
			if (qName.equals("Sil")) {
			} else if (qName.equals("Crystal")) {
				try {
					SilUtil.addCrystal(sil, curCrystal.getCrystal());
				} catch (Exception e) {
					throw new SAXException(e.getMessage());
				}
				curCrystal = null;
			} else if (qName.equals("Group")) {
				curGroup = null;
			} else if (qName.equals("Images")) {
				// end all images
			} else {
				if (curCrystal != null) {
					if (curCrystalField != null) {
						// Map old column name to bean property name
						try {
							String val = curFieldValue.toString();
							logger.debug("Setting bean property name = " + curCrystalField + " value = " + curFieldValue.toString());
							if (val.length() > 0)
								curCrystal.setPropertyValue(curCrystalField, val);
						} catch (TypeMismatchException e) {
							logger.debug("Cannot set crystal property name = " + curCrystalField 
									+ " value = '" + curFieldValue + "'"
									+ " because " + e.getMessage());
						}
					}
					curCrystalField = null;
				}
			}
		}

		public void startDocument()
			throws SAXException
		{
		}

		public void endDocument()
			throws SAXException
		{
		}

	} // end private class

	
}
