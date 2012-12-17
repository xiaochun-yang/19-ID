/**
 * Javabean for SMB resources
 */
package webice.actions.process;

import java.io.*;
import java.net.*;
import java.util.Vector;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import javax.xml.parsers.*;
import org.w3c.dom.*;

import webice.beans.*;
import webice.beans.process.*;


public class LoadDatasetsAction extends Action
{

	private String impHost = "smb.slac.stanford.edu";
	private int impPort = 61001;

	private Client client = null;

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{


		HttpSession session = request.getSession();

		client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		try {

		ProcessViewer viewer = client.getProcessViewer();

		LoadDatasetsForm form = (LoadDatasetsForm)f;

		String file = form.getFile();

		Object[] newSets = loadDatasets(file);

		if (newSets != null) {

			for (int i = 0; i < newSets.length; ++i) {
				viewer.addDataset((Dataset)newSets[i]);
			}
		}

		viewer.setDatasetsCommand(ProcessViewer.COMMAND_SHOW);


		} catch (Exception e) {

			String s = e.getMessage() + "\n";
			StackTraceElement[] el = e.getStackTrace();
			for (int i = 0; i < el.length; ++i) {
				s += "	at " + el[i].getClassName() + ":" + el[i].getMethodName()
						+ " (" + el[i].getFileName()
						+ ":" + el[i].getLineNumber() + ")"
						+ " [" + el[i].toString() + "]\n";
			}
			throw e;
		}

		return mapping.findForward("success");




	}


	/**
	 * Read xml string in a remote file via the impersonation server.
	 * @param xml The xml string to be saved
	 */
	private Object[] loadDatasets(String fname)
		throws Exception
	{
		if (fname == null)
			throw new Exception("Datasets definition file name is null");

		String urlString = "http://" + impHost + ":" + String.valueOf(impPort)
							+ "/readFile?"
							+ "impUser=" + client.getUser()
							+ "&impSessionID=" + client.getSessionId()
							+ "&impFilePath=" + fname;

		URL url = new URL(urlString);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");


		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to read xml file: impserver returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlString + ")");

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

		Document doc = builder.parse(con.getInputStream());

		if (doc == null)
			throw new Exception("XML Document is null: parse failed");


		// Get top node
		Node parent = doc.getDocumentElement();

		if (parent == null)
			throw new Exception("Failed to get document node in xml file");

		NodeList nodes = parent.getChildNodes();

		if (nodes == null)
			return null;

		String datasetsName = "";
		Vector ret = new Vector();

		for (int i = 0; i < nodes.getLength(); ++i) {

			Node node = nodes.item(i);
			if (node.getNodeName().equals("name")) {

				Node child = node.getFirstChild();
				if (child != null) {
					datasetsName = child.getNodeName();
				}

			} else if (node.getNodeName().equals("dataset")) {

				Node child = node.getFirstChild();
				while (child != null) {
					if ((child.getNodeType() == Node.ELEMENT_NODE) &&
						child.getNodeName().equals("file")) {
						Node grand = child.getFirstChild();
						if (grand == null)
							continue;
						String file = grand.getNodeValue();
						if (file == null)
							continue;
						Dataset dataset = DatasetLoader.load(
												impHost, impPort,
												client.getUser(), client.getSessionId(),
												file);
						dataset.setFile(file);
						ret.add(dataset);
						break;
					}

					child = child.getNextSibling();
				}

			}
		}

		return ret.toArray();


	}


}

