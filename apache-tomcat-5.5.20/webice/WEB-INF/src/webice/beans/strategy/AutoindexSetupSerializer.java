/**
 * Javabean for SMB resources
 */
package webice.beans.strategy;

import webice.beans.*;
import java.util.*;
import java.io.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import java.net.*;


/**
 */
public class AutoindexSetupSerializer
{

	/**
	 * Load up run definition and results if they exist.
	 * Need to set imageDir and list of images
	 */
	static public void load(InputStream stream, LabelitSetupData data)
		throws Exception
	{

		load(stream, data, false);

	}

	/**
	 * Load up run definition and results if they exist.
	 * Need to set imageDir and list of images
	 */
	static public void loadOldFormat(InputStream stream, LabelitSetupData data)
		throws Exception
	{

		load(stream, data, true);

	}

	static private void load(InputStream stream, LabelitSetupData data, boolean oldFormat)
		throws Exception
	{
		if (stream == null)
			throw new Exception("Null input stream");

		// Construct an xml document object from
		// the stream
		Document doc = readXmlDocument(stream);

		// Recursive
		parseNode(doc.getDocumentElement(), data, oldFormat);

		stream.close();
		stream = null;
	}


	/**
	 * Extract input parameters for this node
	 * from the xml document
	 */
	static private void parseNode(Node p, LabelitSetupData data, boolean oldFormat)
		throws Exception
	{
		Node node = p.getFirstChild();

		while (node != null) {
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				String name = node.getNodeName();
				if (name.equals("input") && oldFormat) {
					parseNode(node, data, oldFormat);
				} else if (name.equals("task")) {
					String att = ((Element)node).getAttribute("name");
					if (att.equals("run_autoindex.csh")) {
							parseNode(node, data, oldFormat);
					}
				} else if (name.equals("imageDir")) {
					Node child = node.getFirstChild();
					if (child != null)
						data.setImageDir(child.getNodeValue());
				} else if (name.equals("image")) {
					Node child = node.getFirstChild();
					if (child != null)
						data.addImage(child.getNodeValue());
				} else if (name.equals("integrate")) {
					Node child = node.getFirstChild();
					if (child != null) {
						if (child.getNodeValue().equals("all"))
							data.setIntegrate("all");
						else
							data.setIntegrate("best");
					}
				} else if (name.equals("generate_strategy")) {
					Node child = node.getFirstChild();
					if (child != null) {
						if ((child.getNodeValue().equals("yes"))
						|| (child.getNodeValue().equals("true")))
							data.setGenerateStrategy(true);
						else
							data.setGenerateStrategy(false);
					}
				} else if (name.equals("beamCenterX")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setCenterX(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setCenterX(0.0);
						}
					}
				} else if (name.equals("beamCenterY")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setCenterY(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setCenterY(0.0);
						}
					}
				} else if (name.equals("distance")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setDistance(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setCenterY(0.0);
						}
					}
				} else if (name.equals("wavelength")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setWavelength(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setCenterY(0.0);
						}
					}
				} else if (name.equals("detector")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setDetector(child.getNodeValue().trim());
					}
				} else if (name.equals("detectorFormat")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setDetectorFormat(child.getNodeValue().trim());
					}
				}
			}
			node = node.getNextSibling();
		}
	}

	/**
	 * Helper func to read xml document
	 * and construct a document object
	 */
	static private Document readXmlDocument(InputStream stream)
		throws Exception
	{
        boolean ignoreWhitespace= true;
        boolean ignoreComments= true;
        boolean putCDATAIntoText= false;
        boolean createEntityRefs = false;
        // Step 1: create a DocumentBuilderFactory and configure it
        DocumentBuilderFactory dbf =
            DocumentBuilderFactory.newInstance();

        // Set namespaceAware to true to get a DOM Level 2 tree with nodes
        // containing namesapce information.  This is necessary because the
        // default value from JAXP 1.0 was defined to be false.
        dbf.setNamespaceAware(true);

        // Set the validation mode to either: no validation, DTD
        // validation, or XSD validation
        dbf.setValidating(false);

        // Optional: set various configuration options
        dbf.setIgnoringComments(ignoreComments);
        dbf.setIgnoringElementContentWhitespace(ignoreWhitespace);
        dbf.setCoalescing(putCDATAIntoText);
        // The opposite of creating entity ref nodes is expanding them inline
        dbf.setExpandEntityReferences(!createEntityRefs);

		if (dbf == null)
			throw new Exception("XML DocumentBuildFactory is null");

		DocumentBuilder builder = dbf.newDocumentBuilder();
		if (builder == null)
			throw new Exception("XML DocumentBuilder is null");

		Document doc = builder.parse(stream);

		return doc;
	}

	/**
	 * Save run definition to string buffer.
	 */
	static public void save(StringBuffer buf, LabelitSetupData data)
		throws Exception
	{

		buf.append("<input>\n");
		buf.append("  <task name=\"run_autoindex.csh\">\n");
		buf.append("    <imageDir>"); buf.append(data.getImageDir()); buf.append("</imageDir>\n");
		buf.append("    <image>"); buf.append(data.getImage1()); buf.append("</image>\n");
		buf.append("    <image>"); buf.append(data.getImage2()); buf.append("</image>\n");
		buf.append("    <integrate>"); buf.append(data.getIntegrate()); buf.append("</integrate>\n");
		buf.append("    <generate_strategy>"); buf.append(data.isGenerateStrategy()); buf.append("</generate_strategy>\n");
		buf.append("    <beamCenterX>"); buf.append(data.getCenterX()); buf.append("</beamCenterX>\n");
		buf.append("    <beamCenterY>"); buf.append(data.getCenterY()); buf.append("</beamCenterY>\n");
		buf.append("    <distance>"); buf.append(data.getDistance()); buf.append("</distance>\n");
		buf.append("    <wavelength>"); buf.append(data.getWavelength()); buf.append("</wavelength>\n");
		buf.append("    <detector>"); buf.append(data.getDetector()); buf.append("</detector>\n");
		buf.append("    <detectorFormat>"); buf.append(data.getDetectorFormat()); buf.append("</detectorFormat>\n");
		buf.append("  </task>\n");
		buf.append("</input>\n");

	}

}

