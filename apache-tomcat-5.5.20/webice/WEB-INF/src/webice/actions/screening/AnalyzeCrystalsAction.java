/**
 * Javabean for SMB resources
 */
package webice.actions.screening;

import java.net.*;
import java.io.*;
import java.util.*;
import java.text.*;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

import org.apache.xerces.dom.DocumentImpl;
import org.apache.xerces.dom.DOMImplementationImpl;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.*;
import org.xml.sax.InputSource;
import org.xml.sax.EntityResolver;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;


import webice.beans.*;
import webice.beans.screening.*;


public class AnalyzeCrystalsAction extends Action
{
	FileWriter logWriter = null;

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{
		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		ScreeningViewer viewer = client.getScreeningViewer();

		if (viewer == null)
			throw new ServletException("ScreeningViewer is null");
			
			
		// Get a list of rows to analyze
		Enumeration keys = request.getParameterNames();
		Vector rows = new Vector();
		while (keys.hasMoreElements()) {
			String key = (String)keys.nextElement();
			if (!key.startsWith("row_"))
				continue;
			String rowStr = request.getParameter(key);
			int row = -1;
			try {
				row = Integer.parseInt(rowStr);
				viewer.analyzeCrystal(row);
			} catch (NumberFormatException e) {
				WebiceLogger.getLogger().warn("AnalyzeCrystals failed for row " + key);
				continue;
			} catch (Exception e) {
				WebiceLogger.getLogger().warn("AnalyzeCrystals failed for row " 
							+ row + " because " + e.getMessage());
				// Should we stop or keep going?
				continue;
			}
		}
		
		// Go back to simgle selection mode
		viewer.setSelectionMode(ScreeningViewer.ONE_CRYSTAL);
		
		return mapping.findForward("success");


	}

}

