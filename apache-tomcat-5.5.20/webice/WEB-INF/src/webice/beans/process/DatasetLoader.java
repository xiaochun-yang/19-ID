/**
 * Javabean for SMB resources
 */
package webice.beans.process;

import webice.beans.*;
import java.io.*;
import java.net.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;


public class DatasetLoader extends Object
{

	/**
	 * Read xml string in a local file.
	 * @param xml The xml string to be saved
	 */
	public static Dataset load(String fname)
		throws Exception
	{
		if (fname == null)
			throw new Exception("Definition xml file name is null");


		FileInputStream input = new FileInputStream(fname);

		return parseXmlDocument(input);

	}

	/**
	 * Read xml string from a remote file via the impersonation server.
	 * @param xml The xml string to be saved
	 */
	public static Dataset load(
								String host,
								int port,
								String userName,
								String sessionId,
								String fname)
		throws Exception
	{
		if (fname == null)
			throw new Exception("Definition xml file name is null");

		String urlString = "http://" + host + ":" + String.valueOf(port)
							+ "/readFile?"
							+ "impUser=" + userName
							+ "&impSessionID=" + sessionId
							+ "&impFilePath=" + fname;

		URL url = new URL(urlString);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");


		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to read xml file: impserver returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlString + ")");


		return parseXmlDocument(con.getInputStream());


	}

	public static Dataset parseXmlDocument(InputStream stream)
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

		stream.close();

		if (doc == null)
			throw new Exception("XML Document is null: parse failed");


		// Create a new dataset
		Dataset ret = new Dataset();

		// Get top node
		Node parent = doc.getDocumentElement();

		if (parent == null)
			throw new Exception("Failed to get document node in xml file");

		// Recursive
		DatasetLoader.parseNode(parent, ret);

		return ret;


	}

	private static void parseNode(Node parent, Dataset ret)
		throws Exception
	{
		Target target = ret.getTargetObj();

		Node node = parent.getFirstChild();

		int atomCount = 0;

		while (node != null) {

			if (node.getNodeType() == Node.ELEMENT_NODE) {

				String name = node.getNodeName();
				if (name.equals("collectedData")) {
					parseNode(node, ret);
				} else if (name.equals("target")) {
					parseNode(node, ret);
				} else {

					Node child = node.getFirstChild();

					if (parent.getNodeName().equals("dataset")) {

						if (child != null) {
							if (name.equals("name")) {
								ret.setName(child.getNodeValue());
							}
						}

					} else if (parent.getNodeName().equals("collectedData")) {

						if (child != null) {
							String value = child.getNodeValue();
							if (name.equals("date")) {
								ret.setDate(value);
							} else if (name.equals("target")) {
								ret.setTarget(value);
							} else if (name.equals("crystalId")) {
								ret.setCrystalId(value);
							} else if (name.equals("beamline")) {
								ret.setBeamline(value);
							} else if (name.equals("experiment")) {
								ret.setExperiment(value);
							} else if (name.equals("resolution")) {
								ret.setResolution(Double.parseDouble(value));
							} else if (name.equals("collectedBy")) {
								ret.setCollectedBy(value);
							} else if (name.equals("directory")) {
								ret.setDirectory(value);
							} else if (name.equals("xFileDirectory")) {
								ret.setXFileDirectory(value);
							} else if (name.equals("beamX")) {
								ret.setBeamX(Double.parseDouble(value));
							} else if (name.equals("beamY")) {
								ret.setBeamY(Double.parseDouble(value));
							} else if (name.equals("autoindexIdent")) {
								ret.setAutoindexIdent(value);
							} else if (name.equals("autoindex1")) {
								ret.setAutoindex1(Integer.parseInt(value));
							} else if (name.equals("autoindex2")) {
								ret.setAutoindex2(Integer.parseInt(value));
							} else if (name.equals("fprimv1")) {
								ret.setFprimv1(Double.parseDouble(value));
							} else if (name.equals("fprprv1")) {
								ret.setFprprv1(Double.parseDouble(value));
							} else if (name.equals("img1")) {
								ret.setImg1(value);
							} else if (name.equals("fprimv2")) {
								ret.setFprimv2(Double.parseDouble(value));
							} else if (name.equals("fprprv2")) {
								ret.setFprprv2(Double.parseDouble(value));
							} else if (name.equals("img2")) {
								ret.setImg2(value);
							} else if (name.equals("fprimv3")) {
								ret.setFprimv3(Double.parseDouble(value));
							} else if (name.equals("fprprv3")) {
								ret.setFprprv3(Double.parseDouble(value));
							} else if (name.equals("img3")) {
								ret.setImg3(value);
							} else if (name.equals("fprimv4")) {
								ret.setFprimv4(Double.parseDouble(value));
							} else if (name.equals("fprprv4")) {
								ret.setFprprv4(Double.parseDouble(value));
							} else if (name.equals("img4")) {
								ret.setImg4(value);
							} else if (name.equals("spacegroup")) {
								ret.setSpacegroup(value);
							} else if (name.equals("nmol")) {
								ret.setNmol(Integer.parseInt(value));
							} else if (name.equals("myComment")) {
								ret.setMyComment(value);
							}
						} // if child != null

					} else if (parent.getNodeName().equals("target")) {

						if (child != null) {
							String value = child.getNodeValue();
							if (name.equals("name")) {
								target.setName(value);
							} else if (name.equals("residues")) {
								target.setResidues(Integer.parseInt(value));
							} else if (name.equals("molecular_weight")) {
								target.setMolecularWeight(Double.parseDouble(value));
							} else if (name.equals("oligomerization")) {
								target.setOligomerization(Integer.parseInt(value));
							} else if (name.equals("has_semet")) {
								target.setHasSemet(Integer.parseInt(value));
							} else if (name.equals("heavy_atoms")) {
								parseNode(node, ret);
							} else if (name.equals("sequence_header")) {
								target.setSequenceHeader(value);
							} else if (name.equals("sequence_prefix")) {
								target.setSequencePrefix(value);
							} else if (name.equals("sequence")) {
								target.setSequence(value);
							}
						} // if child != null


					} else if (parent.getNodeName().equals("heavy_atoms")) {

						if (name.equals("atom")) {

							++atomCount;
							NamedNodeMap map = node.getAttributes();
							String atom = "";
							int num = 0;
							if (map != null) {
								atom = map.getNamedItem("type").getNodeValue();
								num = Integer.parseInt(map.getNamedItem("number").getNodeValue());
							}
							if (atomCount == 1) {
								target.setHeavyAtom1(atom);
								target.setHeavyAtom1Count(num);
							} else if (atomCount == 2) {
								target.setHeavyAtom2(atom);
								target.setHeavyAtom2Count(num);
							} else if (atomCount == 3) {
								target.setHeavyAtom3(atom);
								target.setHeavyAtom3Count(num);
							} else if (atomCount == 4) {
								target.setHeavyAtom4(atom);
								target.setHeavyAtom4Count(num);
							}

						} // name == atom

					} // parent == heavy_atoms


				} // node name != collectedData && node name != target

			} // node type == ELEMENT_NODE

			node = node.getNextSibling();

		} // while node != null


	}

}