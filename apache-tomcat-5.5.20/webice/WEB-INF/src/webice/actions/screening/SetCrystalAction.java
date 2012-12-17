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


public class SetCrystalAction extends Action
{
	private int maxWaitTime = 60000; // 1 minute
	private int sleepTime = 3000; // 3 seconds

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

		Enumeration en = request.getParameterNames();
		if (en == null)
			return mapping.findForward("success");
		String param = "";
		String value = "";
		StringBuffer buf = new StringBuffer();
		buf.append("userName=" + client.getUser());
		buf.append("&accessID=" + client.getSessionId());
		buf.append("&silId=" + viewer.getSilId());
		buf.append("&row=" + viewer.getSelectedRow());
		while (en.hasMoreElements()) {

         	param = (String)en.nextElement();
         	if (param.equals("command") ||
         		param.equals("userName") ||
         		param.equals("accessID") ||
         		param.equals("silId") ||
         		param.equals("row"))
         		continue;
         	value = request.getParameter(param);
			buf.append("&" + param + "=" + value);
		}

		String query = buf.toString();

		WebiceLogger.info("Setting crystal form = " + query);

		String url = ServerConfig.getSilSetCrystalUrl();

		// Send HTTP request to crystal-analysis server
		// to analyze the image
		String eventId = submitJob(url, query);

		// Wait for the event to complete
		url = ServerConfig.getSilIsEventCompletedUrl() + "?"
				+ "userName=" + client.getUser()
				+ "&accessID=" + client.getSessionId()
				+ "&silId=" + viewer.getSilId()
				+ "&eventId=" + eventId;
		waitForCompletion(url);

		// force reload sil
		viewer.reloadSil();

		return mapping.findForward("success");

		} catch (Exception e) {
			WebiceLogger.error(e.getMessage(), e);
			request.setAttribute("error", e.getMessage());
			return mapping.findForward("failed");
		}


	}

	/**
	 */
	private void waitForCompletion(String urlStr)
		throws Exception
	{
		int waitTime = 0;

		while (waitTime < maxWaitTime) {

			URL url = new URL(urlStr);

			HttpURLConnection con = (HttpURLConnection)url.openConnection();

			con.setRequestMethod("GET");

			int response = con.getResponseCode();
			if (response != 200)
				throw new Exception("isEventCompleted failed: "
							+ String.valueOf(response) + " " + con.getResponseMessage()
							+ " (for " + urlStr + ")");

			BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

			String line = null;
			StringBuffer buf = new StringBuffer();
			while ((line=reader.readLine()) != null) {
				if (line.length() > 0)
					buf.append(line);
			}

			reader.close();
			con.disconnect();

			// server returns "completed" or "not completed"
			String res = buf.toString().trim();

			if (res.equals("completed"))
				return;

			// sleep for 3 seconds
			Thread.sleep(sleepTime);
			waitTime += sleepTime;

		}

		throw new Exception("Wait timeout for result of setCrystal");

	}

	/**
	 */
	private String submitJob(String urlStr, String body)
		throws Exception
	{
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setDoOutput(true);
		con.setRequestMethod("POST");
		con.setRequestProperty("Content-Length", String.valueOf(body.length()));
		con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

		OutputStreamWriter writer = new OutputStreamWriter(con.getOutputStream());
		writer.write(body, 0, body.length());
		writer.flush();
		writer.close();

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("SetCrystal failed: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

		String line = null;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			if (line.length() > 0)
				buf.append(line);
		}

		// Set silList xml
		String res = buf.toString();

		reader.close();
		con.disconnect();

		int pos = res.indexOf("OK ");
		if (pos < 0)
			throw new Exception("SetCrystal failed: " + res);

		String eventId = res.substring(pos+3).trim();

		WebiceLogger.info("SetCrystal (" + eventId + "): " + url);

		return eventId;

	}


}

