/**
 * Javabean for SMB resources
 */
package webice.actions.process;

import java.io.*;
import java.net.*;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

import webice.beans.*;
import webice.beans.process.*;


public class SaveDatasetAction extends Action
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

		String target = "success";

		HttpSession session = request.getSession();

		client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		try {

		// Save form parameters
		DatasetForm form = (DatasetForm)f;


		ProcessViewer viewer = client.getProcessViewer();

		Dataset formSet = form.getDataset();


		// Save the datset in the hash table
		viewer.addDataset(formSet);

		viewer.setSelectedDataset(formSet);


		// Also write it to a file
		String xml = formSet.toXML();
/*

		xml += "<dataset>\n";
		xml += "<name>" + form.getName() + "</name>\n";
		xml += "<date>" + formSet.getDateString() + "</date>\n";
		xml += "<target>" + form.getTarget() + "</target>\n";
		xml += "<crystalId>" + form.getCrystalId() + "</crystalId>\n";
		xml += "<beamline>" + form.getBeamline() + "</beamline>\n";
		xml += "<experiment>" + form.getExperiment() + "</experiment>\n";
		xml += "<resolution>" + String.valueOf(form.getResolution()) + "</resolution>\n";
		xml += "<collectedBy>" + form.getCollectedBy() + "</collectedBy>\n";
		xml += "<directory>" + form.getDirectory() + "</directory>\n";
		xml += "<xFileDirectory>" + form.getXFileDirectory() + "</xFileDirectory>\n";
		xml += "<beamX>" + String.valueOf(form.getBeamX()) + "</beamX>\n";
		xml += "<beamY>" + String.valueOf(form.getBeamY()) + "</beamY>\n";
		xml += "<autoindexIdent>" + form.getAutoindexIdent() + "</autoindexIdent>\n";
		xml += "<autoindex1>" + String.valueOf(form.getAutoindex1()) + "</autoindex1>\n";
		xml += "<autoindex2>" + String.valueOf(form.getAutoindex2()) + "</autoindex2>\n";
		xml += "<fprimv1>" + String.valueOf(form.getFprimv1()) + "</fprimv1>\n";
		xml += "<fprprv1>" + String.valueOf(form.getFprprv1()) + "</fprprv1>\n";
		xml += "<img1>" + form.getImg1() + "</img1>\n";
		xml += "<fprimv2>" + String.valueOf(form.getFprimv2()) + "</fprimv2>\n";
		xml += "<fprprv2>" + String.valueOf(form.getFprprv2()) + "</fprprv2>\n";
		xml += "<img2>" + form.getImg2() + "</img2>\n";
		xml += "<fprimv3>" + String.valueOf(form.getFprimv3()) + "</fprimv3>\n";
		xml += "<fprprv3>" + String.valueOf(form.getFprprv3()) + "</fprprv3>\n";
		xml += "<img3>" + form.getImg3() + "</img3>\n";
		xml += "<fprimv4>" + String.valueOf(form.getFprimv4()) + "</fprimv4>\n";
		xml += "<fprprv4>" + String.valueOf(form.getFprprv4()) + "</fprprv4>\n";
		xml += "<img4>" + form.getImg4() + "</img4>\n";
		xml += "<spacegroup>" + form.getSpacegroup() + "</spacegroup>\n";
		xml += "<nmol>" + String.valueOf(form.getNmol()) + "</nmol>\n";
		xml += "<myComment>" + form.getMyComment() + "</myComment>\n";
		xml += "</dataset>\n";
*/
		String fname = form.getFile();

		writeToRemoteFile(fname, xml);

		return mapping.findForward(target);

		} catch (Exception e) {
			throw new ServletException(e);
		}

	}

	/**
	 * Saves the xml string in a local file
	 * @param xml The xml string to be saved
	 */
	private void writeToLocalFile(String fname, String xml)
		throws Exception
	{

		// Write to a file
		Writer xmlWriter= null;

		File dir= new File( new File( fname).getParent());
		if( dir.exists()==false ) {
			dir.mkdirs();
		}
		FileOutputStream xmlFile= new FileOutputStream( fname);
		xmlWriter= new OutputStreamWriter( xmlFile);

		xmlWriter.write(xml);

		xmlWriter.close();

	}

	/**
	 * Saves the xml string in a remote file via the impersonation server.
	 * @param xml The xml string to be saved
	 */
	private void writeToRemoteFile(String fname, String xml)
		throws Exception
	{

		String urlString = "http://" + impHost + ":" + String.valueOf(impPort)
							+ "/writeFile?"
							+ "impUser=" + client.getUser()
							+ "&impSessionID=" + client.getSessionId()
							+ "&impFilePath=" + fname
							+ "&impFileMode=0755";

		URL url = new URL(urlString);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setDoOutput(true);
		con.setRequestMethod("POST");
		con.setRequestProperty("Content-Length", String.valueOf(xml.length()));
		con.setRequestProperty("Content-Type", "text/plain");

		OutputStreamWriter writer = new OutputStreamWriter(con.getOutputStream());
		writer.write(xml, 0, xml.length());
		writer.flush();

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to write xml file: impserver returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlString + ")");

	}



}

