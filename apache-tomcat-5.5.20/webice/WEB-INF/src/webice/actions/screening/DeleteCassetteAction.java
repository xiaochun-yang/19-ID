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


public class DeleteCassetteAction extends Action
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
		if (image_dir != null) {

		// Create a lookup table for the existing directories
		// that already has a cassette.
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
		boolean found = false;
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
			if ((dir != null) && (silId != null) && dir.equals(image_dir)) {
				found = true;
				break;
				
			}
		   }
		}
		
		if (found) {
			viewer.deleteSil(silId);
		} else {		
			request.setAttribute("image_dir", image_dir); 
			throw new Exception("cassette not found");
		}
		
		} else { // dir == null
		
			silId = request.getParameter("silId");
			if (silId == null)
				throw new Exception("Missing silId parameter");
			viewer.deleteSil(silId);
			request.setAttribute("silId", silId);
			request.setAttribute("dir", viewer.getDefaultSilDir(silId));
					
		}
		
		
		} catch (Exception e) {
			WebiceLogger.error(e.getMessage(), e);
			request.setAttribute("error.msg", "Failed to delete cassette for directory "
					+ image_dir + ": " + e.getMessage());
			return mapping.findForward("failure");
		}
		

		return mapping.findForward("success");
		


	}


}



