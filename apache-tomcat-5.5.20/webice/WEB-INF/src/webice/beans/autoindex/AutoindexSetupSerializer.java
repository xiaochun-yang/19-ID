/**
 * Javabean for SMB resources
 */
package webice.beans.autoindex;

import java.util.*;
import java.io.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import java.net.*;
import webice.beans.*;
import webice.beans.dcs.*;

/**
 */
public class AutoindexSetupSerializer
{

	static public void load(String url, AutoindexSetupData data)
		throws Exception
	{

		load(url, data, false);

	}

	static private void load(String url, AutoindexSetupData data, boolean oldFormat)
		throws Exception
	{
		// Construct an xml document object from
		// the stream
		Document doc = readXmlDocument(url);
		
		// Recursive
		data.setVersion(1.0);
		parseNode(doc.getDocumentElement(), data, oldFormat);

	}


	/**
	 * Load up run definition and results if they exist.
	 * Need to set imageDir and list of images
	 */
	static public void load(InputStream stream, AutoindexSetupData data)
		throws Exception
	{

		data.setVersion(1.0);
		load(stream, data, false);

	}


	static private void load(InputStream stream, AutoindexSetupData data, boolean oldFormat)
		throws Exception
	{
		if (stream == null)
			throw new Exception("Null input stream");

		// Construct an xml document object from
		// the stream
		Document doc = readXmlDocument(stream);

		// Recursive
		data.setVersion(1.0);
		data.setStrategyMethod("Unknown");
		parseNode(doc.getDocumentElement(), data, oldFormat);

		stream.close();
		stream = null;
	}


	/**
	 * Extract input parameters for this node
	 * from the xml document
	 */
	static private void parseNode(Node p, AutoindexSetupData data, boolean oldFormat)
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
					} else if (att.equals("collect")) {
							parseNode(node, data, oldFormat);
					}
				} else if (name.equals("imageDir")) {
					Node child = node.getFirstChild();
					if (child != null)
						data.setImageDir(child.getNodeValue());
				} else if (name.equals("host")) {
					Node child = node.getFirstChild();
					if (child != null)
						data.setHost(child.getNodeValue());
				} else if (name.equals("port")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setPort(Integer.parseInt(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
						}
					}
				} else if (name.equals("version")) {
					Node child = node.getFirstChild();
					if (child != null)
						try {
							data.setVersion(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
						}
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
				} else if (name.equals("strategyMethod")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setStrategyMethod(child.getNodeValue());
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
				} else if (name.equals("exposureTime")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setExposureTime(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setExposureTime(0.0);
						}
					}
				} else if (name.equals("oscRange")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setOscRange(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setOscRange(0.0);
						}
					}
				} else if (name.equals("attenuation")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setAttenuation(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setAttenuation(0.0);
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
				} else if (name.equals("detectorResolution")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setDetectorResolution(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
							// ignore
							data.setDetectorResolution(0.0);
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
				} else if (name.equals("beamline")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setBeamline(child.getNodeValue().trim());
					}
				} else if (name.equals("beamlineFile")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setBeamlineFile(child.getNodeValue().trim());
					}
				} else if (name.equals("dcsDumpFile")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setDcsDumpFile(child.getNodeValue().trim());
					}
				} else if (name.equals("runName")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setRunName(child.getNodeValue().trim());
					}
				} else if (name.equals("collectImages")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setCollectImages(Boolean.parseBoolean(child.getNodeValue().trim()));
						} catch (Exception e) {
						}
					}
				} else if (name.equals("mountSample")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setMountSample(Boolean.parseBoolean(child.getNodeValue().trim()));
						} catch (Exception e) {
						}
					}
				} else if (name.equals("cassetteIndex")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setCassetteIndex(Integer.parseInt(child.getNodeValue().trim()));
						} catch (Exception e) {
						}
					}
				} else if (name.equals("silId")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setSilId(child.getNodeValue().trim());
					}
				} else if (name.equals("crystalPort")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setCrystalPort(child.getNodeValue().trim());
					}
				} else if (name.equals("crystalId")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setCrystalId(child.getNodeValue().trim());
					}
				} else if (name.equals("imageRootName")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setImageRootName(child.getNodeValue().trim());
					}
				} else if (name.equals("expType")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setExpType(child.getNodeValue().trim());
					}
				} else if (name.equals("testRunDef")) {
					parseRunDefNode(node, data.getTestRunDefinition());
				} else if (name.equals("targetResolution")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
							data.setTargetResolution(Double.parseDouble(child.getNodeValue().trim()));
						} catch (Exception e) {
						}
					}
				} else if (name.equals("laueGroup")) {
					Node child = node.getFirstChild();
					if (child != null) {
						data.setLaueGroup(child.getNodeValue().trim());
					}
				} else if (name.equals("unitCell")) {
					double a = parseDoubleNoThrow(((Element)node).getAttribute("a"), 0.0);
					double b = parseDoubleNoThrow(((Element)node).getAttribute("b"), 0.0);
					double c = parseDoubleNoThrow(((Element)node).getAttribute("c"), 0.0);
					double alpha = parseDoubleNoThrow(((Element)node).getAttribute("alpha"), 0.0);
					double beta = parseDoubleNoThrow(((Element)node).getAttribute("beta"), 0.0);
					double gamma = parseDoubleNoThrow(((Element)node).getAttribute("gamma"), 0.0);
					data.setUnitCell(a, b, c, alpha, beta, gamma);
				} else if (name.equals("mad")) {
					String tmp = ((Element)node).getAttribute("scan");
					boolean doScan = false;
					if ((tmp != null) && tmp.equals("true"))
						doScan = true;
					data.setDoScan(doScan);
					double inflection = parseDoubleNoThrow(((Element)node).getAttribute("inflection"), 0.0);
					double peak = parseDoubleNoThrow(((Element)node).getAttribute("peak"), 0.0);
					double remote = parseDoubleNoThrow(((Element)node).getAttribute("remote"), 0.0);
					data.setInflectionEn(inflection);
					data.setPeakEn(peak);
					data.setRemoteEn(remote);
					String edge = ((Element)node).getAttribute("edge");
					double en1 = parseDoubleNoThrow(((Element)node).getAttribute("edgeEn1"), 0.0);
					double en2 = parseDoubleNoThrow(((Element)node).getAttribute("edgeEn2"), 0.0);
					data.setEdge(edge, en1, en2);
				} else if (name.equals("detectorWidth")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
						    data.setDetectorWidth(Double.parseDouble(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
						    // ignore
						}
					}
				} else if (name.equals("numHeavyAtoms")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
						    data.setNumHeavyAtoms(Integer.parseInt(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
						    // ignore
						}
					}
				} else if (name.equals("numResidues")) {
					Node child = node.getFirstChild();
					if (child != null) {
						try {
						    data.setNumResidues(Integer.parseInt(child.getNodeValue().trim()));
						} catch (NumberFormatException e) {
						    // ignore
						}
					}
				}
			}
			node = node.getNextSibling();
		}
	}
	
	/**
	 * Parse runDef
	 */
	static private void parseRunDefNode(Node p, RunDefinition def)
	{
		Node node = p.getFirstChild();

		while (node != null) {
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				String name = node.getNodeName();
				if (name.equals("deviceName")) {
					def.deviceName = parseString(node.getFirstChild(), "");
				} else if (name.equals("runStatus")) {
					def.runStatus = parseString(node.getFirstChild(), "");
				} else if (name.equals("nextFrame")) {
					def.nextFrame = parseInt(node.getFirstChild(), 0);
				} else if (name.equals("runLabel")) {
					def.runLabel = parseInt(node.getFirstChild(), 0);
				} else if (name.equals("fileRoot")) {
					def.fileRoot = parseString(node.getFirstChild(), "");
				} else if (name.equals("directory")) {
					def.directory = parseString(node.getFirstChild(), "");
				} else if (name.equals("startFrame")) {
					def.startFrame = parseInt(node.getFirstChild(), 0);
				} else if (name.equals("axisMotorName")) {
					def.axisMotorName = parseString(node.getFirstChild(), "");
				} else if (name.equals("startAngle")) {
					def.startAngle = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("endAngle")) {
					def.endAngle = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("delta")) {
					def.delta = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("wedgeSize")) {
					def.wedgeSize = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("exposureTime")) {
					def.exposureTime = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("distance")) {
					def.distance = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("beamStop")) {
					def.beamStop = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("attenuation")) {
					def.attenuation = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("numEnergy")) {
					def.numEnergy = parseInt(node.getFirstChild(), 0);
				} else if (name.equals("energy1")) {
					def.energy1 = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("energy2")) {
					def.energy2 = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("energy3")) {
					def.energy3 = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("energy4")) {
					def.energy4 = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("energy5")) {
					def.energy5 = parseDouble(node.getFirstChild(), 0.0);
				} else if (name.equals("detectorMode")) {
					def.detectorMode = parseInt(node.getFirstChild(), 0);
				} else if (name.equals("inverse")) {
					def.inverse = parseInt(node.getFirstChild(), 0);
				}
			}
			node = node.getNextSibling();
		}
	}
	
	static private double parseDouble(Node child, double de)
	{
		if (child != null) {
			try {
				return Double.parseDouble(child.getNodeValue().trim());
			} catch (Exception e) {
			}
		}
		
		return de;
	}
	
	static private int parseInt(Node child, int de)
	{
		if (child != null) {
			try {
				return Integer.parseInt(child.getNodeValue().trim());
			} catch (Exception e) {
			}
		}
		
		return de;
	}
	
	static private String parseString(Node child, String de)
	{
		if (child != null) {
			return child.getNodeValue().trim();
		}
		
		return de;
	}
	
	static private double parseDoubleNoThrow(String s, double d)
		throws Exception
	{
		try {
		
		if ((s != null) && (s.length() > 0)) {
			return Double.parseDouble(s);
		}
		} catch (Exception e) {
			// ignore
		}
		
		return d;
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

	static private Document readXmlDocument(String url)
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

		Document doc = builder.parse(url);

		return doc;
	}

	/**
	 * Save run definition to string buffer.
	 */
	static public void save(StringBuffer buf, AutoindexSetupData data)
		throws Exception
	{

		buf.append("<input>\n");
		buf.append("  <version>"); buf.append(data.getVersion()); buf.append("</version>\n");
		buf.append("  <task name=\"run_autoindex.csh\">\n");
		buf.append("    <runName>"); buf.append(data.getRunName()); buf.append("</runName>\n");
		buf.append("    <imageDir>"); buf.append(data.getImageDir()); buf.append("</imageDir>\n");
		buf.append("    <host>"); buf.append(data.getHost()); buf.append("</host>\n");
		buf.append("    <port>"); buf.append(data.getPort()); buf.append("</port>\n");
		buf.append("    <image>"); buf.append(data.getImage1()); buf.append("</image>\n");
		buf.append("    <image>"); buf.append(data.getImage2()); buf.append("</image>\n");
		buf.append("    <integrate>"); buf.append(data.getIntegrate()); buf.append("</integrate>\n");
		buf.append("    <strategyMethod>"); buf.append(data.getStrategyMethod()); buf.append("</strategyMethod>\n");
		buf.append("    <generate_strategy>"); buf.append(data.isGenerateStrategy()); buf.append("</generate_strategy>\n");
		buf.append("    <beamCenterX>"); buf.append(data.getCenterX()); buf.append("</beamCenterX>\n");
		buf.append("    <beamCenterY>"); buf.append(data.getCenterY()); buf.append("</beamCenterY>\n");
		buf.append("    <distance>"); buf.append(data.getDistance()); buf.append("</distance>\n");
		buf.append("    <wavelength>"); buf.append(data.getWavelength()); buf.append("</wavelength>\n");
		buf.append("    <detector>"); buf.append(data.getDetector()); buf.append("</detector>\n");
		buf.append("    <detectorFormat>"); buf.append(data.getDetectorFormat()); buf.append("</detectorFormat>\n");
		buf.append("    <detectorWidth>"); buf.append(data.getDetectorWidth()); buf.append("</detectorWidth>\n");
		buf.append("    <detectorResolution>"); buf.append(data.getDetectorResolution()); buf.append("</detectorResolution>\n");
		buf.append("    <exposureTime>"); buf.append(data.getExposureTime()); buf.append("</exposureTime>\n");
		buf.append("    <oscRange>"); buf.append(data.getOscRange()); buf.append("</oscRange>\n");
		buf.append("    <beamline>"); buf.append(data.getBeamline()); buf.append("</beamline>\n");
		buf.append("    <beamlineFile>"); buf.append(data.getBeamlineFile()); buf.append("</beamlineFile>\n");
		buf.append("    <dcsDumpFile>"); buf.append(data.getDcsDumpFile()); buf.append("</dcsDumpFile>\n");
		buf.append("    <expType>"); buf.append(data.getExpType()); buf.append("</expType>\n");
		buf.append("    <mad");
		buf.append(" edge=\""); buf.append(data.getEdge().name); buf.append("\"");
		buf.append(" inflection=\""); buf.append(data.getInflectionEn()); buf.append("\"");
		buf.append(" peak=\""); buf.append(data.getPeakEn()); buf.append("\"");
		buf.append(" remote=\""); buf.append(data.getRemoteEn()); buf.append("\"");
		buf.append("/>\n");
		buf.append("    <laueGroup>"); buf.append(data.getLaueGroup()); buf.append("</laueGroup>\n");
		buf.append("    <unitCell");
		buf.append(" a=\""); buf.append(data.getUnitCellA()); buf.append("\"");
		buf.append(" b=\""); buf.append(data.getUnitCellB()); buf.append("\"");
		buf.append(" c=\""); buf.append(data.getUnitCellC()); buf.append("\"");
		buf.append(" alpha=\""); buf.append(data.getUnitCellAlpha()); buf.append("\"");
		buf.append(" beta=\""); buf.append(data.getUnitCellBeta()); buf.append("\"");
		buf.append(" gamma=\""); buf.append(data.getUnitCellGamma()); buf.append("\"");
		buf.append("/>\n");
		buf.append("    <numHeavyAtoms>"); buf.append(data.getNumHeavyAtoms()); buf.append("</numHeavyAtoms>\n");
		buf.append("    <numResidues>"); buf.append(data.getNumResidues()); buf.append("</numResidues>\n");
		buf.append("  </task>\n");
		buf.append("</input>\n");

	}

	/**
	 * Save definition for collecting 2 test image for autoindex.
	 */
	static public void saveCollect(StringBuffer buf, AutoindexSetupData data)
		throws Exception
	{
	
		RunDefinition testDef = data.getTestRunDefinition();

		buf.append("<input>\n");
		buf.append("  <version>"); buf.append(data.getVersion()); buf.append("</version>\n");
		buf.append("  <task name=\"collect\">\n");
		buf.append("    <runName>"); buf.append(data.getRunName()); buf.append("</runName>\n");
		buf.append("    <beamline>"); buf.append(data.getBeamline()); buf.append("</beamline>\n");
		buf.append("    <imageDir>"); buf.append(data.getImageDir()); buf.append("</imageDir>\n");
		buf.append("    <strategyMethod>"); buf.append(data.getStrategyMethod()); buf.append("</strategyMethod>\n");
		buf.append("    <generate_strategy>"); buf.append(data.isGenerateStrategy()); buf.append("</generate_strategy>\n");
		buf.append("    <mountSample>"); buf.append(data.isMountSample()); buf.append("</mountSample>\n");
		buf.append("    <cassetteIndex>"); buf.append(data.getCassetteIndex()); buf.append("</cassetteIndex>\n");
		buf.append("    <silId>"); buf.append(data.getSilId()); buf.append("</silId>\n");
		buf.append("    <crystalPort>"); buf.append(data.getCrystalPort()); buf.append("</crystalPort>\n");
		buf.append("    <crystalId>"); buf.append(data.getCrystalId()); buf.append("</crystalId>\n");
		buf.append("    <imageRootName>"); buf.append(data.getImageRootName()); buf.append("</imageRootName>\n");
		buf.append("    <expType>"); buf.append(data.getExpType()); buf.append("</expType>\n");
		buf.append("    <mad");
		buf.append(" scan=\""); buf.append(data.isDoScan()); buf.append("\"");
		buf.append(" edge=\""); buf.append(data.getEdge().name); buf.append("\"");
		buf.append(" edgeEn1=\""); buf.append(data.getEdge().en1); buf.append("\"");
		buf.append(" edgeEn2=\""); buf.append(data.getEdge().en2); buf.append("\"");
		buf.append(" inflection=\""); buf.append(data.getInflectionEn()); buf.append("\"");
		buf.append(" peak=\""); buf.append(data.getPeakEn()); buf.append("\"");
		buf.append(" remote=\""); buf.append(data.getRemoteEn()); buf.append("\"");
		buf.append("/>\n");
		buf.append("    <testRunDef>\n");
		buf.append("      <deviceName>" + testDef.deviceName + "</deviceName>\n");
		buf.append("      <runStatus>" + testDef.runStatus + "</runStatus>\n");
		buf.append("      <nextFrame>" + testDef.nextFrame + "</nextFrame>\n");
		buf.append("      <runLabel>" + testDef.runLabel + "</runLabel>\n");
		buf.append("      <fileRoot>" + testDef.fileRoot + "</fileRoot>\n");
		buf.append("      <directory>" + testDef.directory + "</directory>\n");
		buf.append("      <startFrame>" + testDef.startFrame + "</startFrame>\n");
		buf.append("      <axisMotorName>" + testDef.axisMotorName + "</axisMotorName>\n");
		buf.append("      <startAngle>" + testDef.startAngle + "</startAngle>\n");
		buf.append("      <endAngle>" + testDef.endAngle + "</endAngle>\n");
		buf.append("      <delta>" + testDef.delta + "</delta>\n");
		buf.append("      <wedgeSize>" + testDef.wedgeSize + "</wedgeSize>\n");
		buf.append("      <exposureTime>" + testDef.exposureTime + "</exposureTime>\n");
		buf.append("      <distance>" + testDef.distance + "</distance>\n");
		buf.append("      <beamStop>" + testDef.beamStop + "</beamStop>\n");
		buf.append("      <attenuation>" + testDef.attenuation + "</attenuation>\n");
		buf.append("      <numEnergy>" + testDef.numEnergy + "</numEnergy>\n");
		buf.append("      <energy1>" + testDef.energy1 + "</energy1>\n");
		buf.append("      <energy2>" + testDef.energy2 + "</energy2>\n");
		buf.append("      <energy3>" + testDef.energy3 + "</energy3>\n");
		buf.append("      <energy4>" + testDef.energy4 + "</energy4>\n");
		buf.append("      <energy5>" + testDef.energy5 + "</energy5>\n");
		buf.append("      <detectorMode>" + testDef.detectorMode + "</detectorMode>\n");
		buf.append("      <inverse>" + testDef.inverse + "</inverse>\n");
		buf.append("    </testRunDef>\n");
		buf.append("    <targetResolution>"); buf.append(data.getTargetResolution()); buf.append("</targetResolution>\n");
		buf.append("    <laueGroup>"); buf.append(data.getLaueGroup()); buf.append("</laueGroup>\n");
		buf.append("    <unitCell");
		buf.append(" a=\""); buf.append(data.getUnitCellA()); buf.append("\"");
		buf.append(" b=\""); buf.append(data.getUnitCellB()); buf.append("\"");
		buf.append(" c=\""); buf.append(data.getUnitCellC()); buf.append("\"");
		buf.append(" alpha=\""); buf.append(data.getUnitCellAlpha()); buf.append("\"");
		buf.append(" beta=\""); buf.append(data.getUnitCellBeta()); buf.append("\"");
		buf.append(" gamma=\""); buf.append(data.getUnitCellGamma()); buf.append("\"");
		buf.append("/>\n");
		buf.append("    <numHeavyAtoms>"); buf.append(data.getNumHeavyAtoms()); buf.append("</numHeavyAtoms>\n");
		buf.append("    <numResidues>"); buf.append(data.getNumResidues()); buf.append("</numResidues>\n");
		buf.append("  </task>\n");
		buf.append("</input>\n");

	}

}

