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


public class AnalyzeCrystalAction extends Action
{
	FileWriter logWriter = null;

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{
		try {


		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		ScreeningViewer viewer = client.getScreeningViewer();

		if (viewer == null)
			throw new ServletException("ScreeningViewer is null");

		viewer.analyzeSelectedCrystal();

		} catch (Exception e) {
			WebiceLogger.error("Exception in AnalyzeCrystalAction: " + e.getMessage(), e);
			request.setAttribute("error.analyzeCrystal", e.getMessage());
			return mapping.findForward("error");
		}

		return mapping.findForward("success");

	}


}

