/**
 * Javabean for SMB resources
 */
package webice.actions.screening;

import java.io.IOException;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

import java.util.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import java.io.*;
import java.util.Vector;
import javax.xml.parsers.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import java.net.*;

import webice.beans.*;
import webice.beans.screening.*;


public class CreateCassetteAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{
		String image_dir = "";
		String silId = "";
		Client client = null;
		try {


		HttpSession session = request.getSession();

		client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		ScreeningViewer viewer = client.getScreeningViewer();

		if (viewer == null)
			throw new ServletException("ScreeningViewer is null");

		image_dir = request.getParameter("dir");
		if (image_dir == null)
			throw new ServletException("Parameter dir is null");


		// Create a lookup table for the existing directories
		// that already has a cassette.
		Hashtable hash = new Hashtable();
		javax.xml.parsers.DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setValidating(false);
		javax.xml.parsers.DocumentBuilder builder = factory.newDocumentBuilder();
		ByteArrayInputStream stream = new ByteArrayInputStream(viewer.getSilList().getBytes());
		Document doc = builder.parse(stream);
		Element root = doc.getDocumentElement();
		NodeList rows = root.getChildNodes();
		NodeList nl = null;
		Node node = null;
		String dir = null;
		silId = null;
		Node row = null;
		for (int i = 0; i < rows.getLength(); ++i) {
			row = rows.item(i);
			nl = row.getChildNodes();
			dir = null; silId = null;
		   for (int j = 0; j < nl.getLength(); ++j) {
			node = nl.item(j);
			if (node.getNodeType() != Node.ELEMENT_NODE)
				continue; 
			if (node.getNodeName().equals("UploadFileName")) {
				dir = (String)node.getFirstChild().getNodeValue();
			} else if (node.getNodeName().equals("CassetteID")) {
				silId = (String)node.getFirstChild().getNodeValue();
			}
			if ((dir != null) && (silId != null) && dir.startsWith("/")) {
				hash.put(dir, silId);
			}
		   }
		}
		
		// Check if a sil has already been created for this dir.
		if ((silId=(String)hash.get(image_dir)) != null) {
			request.setAttribute("silId", silId); 
			request.setAttribute("error.msg", "Failed to create cassette for directory " 
					+ image_dir + ": a cassette already exists for this directory.");
			return mapping.findForward("alreadyExists");
		}
		
		// Create a sil for this dir
		silId = viewer.createDefaultSil(image_dir);
		request.setAttribute("silId", silId);
		request.setAttribute("dir", image_dir);
		
		} catch (Exception e) {
			WebiceLogger.error(e.getMessage(), e);
			request.setAttribute("error.msg", "Failed to create cassette for directory "
					+ image_dir + ": " + e.getMessage());
			return mapping.findForward("createFailed");
		}
		
		try {
		
		
		// Now run a script to searches for images in dir/subdir,
		// add images to SIL (via crystals server) 
		// and analyze the images (via crystal-analysis server).
		WebiceLogger.info("Start screening data from dir " 
				+ image_dir + " for silId = " + silId);
		screenData(client, image_dir, silId);

		} catch (Exception e) {
			request.setAttribute("error.msg", "Failed to analyze crystals for cassette " + silId
						+ ": " + e.getMessage());
			return mapping.findForward("createFailed");
		}

		return mapping.findForward("success");
		


	}


	/**
	 * Run screen.csh script
	 */
	public void screenData(Client client, String dir, String silId)
		throws Exception
	{
		HttpURLConnection con = null;
		try {
		
		String beamline = "default";
		if (client.isConnectedToBeamline())
			beamline = client.getBeamline();

		String command = ServerConfig.getScriptDir() + "/run_screen.csh"
					+ "%20" + client.getScreeningViewer().getDefaultSilDir(silId)
					+ "%20" + ServerConfig.getSilHost()
					+ "%20" + String.valueOf(ServerConfig.getSilPort())
					+ "%20" + ServerConfig.getCaHost()
					+ "%20" + String.valueOf(ServerConfig.getCaPort())
					+ "%20" + client.getUser()
					+ "%20" + client.getSessionId()
					+ "%20" + dir 
					+ "%20" + silId
					+ "%20" + beamline
					+ "%20" + String.valueOf(ServerConfig.getScreeningDirDepth());
					
		String urlStr = "http://" + ServerConfig.getAutoindexHost() + ":" 
					+ String.valueOf(ServerConfig.getAutoindexPort())
					+ "/runScript?"
					+ "impUser=" + client.getUser()
					+ "&impSessionID=" + client.getSessionId()
					+ "&impCommandLine=" + command
					+ "&impShell=/bin/tcsh";
					
		WebiceLogger.info("screenData: url = " + urlStr);
		WebiceLogger.info("screenData: command = " + command);

		URL url = new URL(urlStr);

		con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impEnv2", "USER=" + client.getUser());
		con.setRequestProperty("impEnv3", "BIN_DIR=" + ServerConfig.getBinDir());
		int response = con.getResponseCode();
		if (response != 200) {
			throw new Exception("screenData failed: dir " + dir
						+ " silId = " + silId
						+ ": imperson server returns "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");
		}

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				WebiceLogger.info(line);
		}

		reader.close();
		con.disconnect();
		con = null;

		} catch (Exception e) {
			throw e;
		} finally {
			if (con != null)
				con.disconnect();
			con = null;
		}
	}


}

