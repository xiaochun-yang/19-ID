/**
 * Javabean for SMB resources
 */
package webice.actions;

import java.io.IOException;
import java.util.*;
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


public class SaveConfigAction extends Action
{

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

		Enumeration names = request.getParameterNames();
		Properties newProp = new Properties();
		while (names.hasMoreElements()) {
			String tmp = (String)names.nextElement();
			String v = request.getParameter(tmp);
			String n = tmp.replace('_', '.');
			
			v = validate(n, v);
			
			newProp.setProperty(n, v);
		}

		try {

			client.saveProperties(newProp);

		} catch (Exception e) {
			throw new ServletException(e);
		}
		

		return mapping.findForward("success");

	}
	
	String validate(String n, String v)
	{

		if (n.equals("image.width")) {
			try {
				int x = Integer.parseInt(v);
				if (x < 1)
					return "1";
				else if (x > 20)
					return "20";
					
			} catch (NumberFormatException e) {
				return "10";
			}
		} if (n.startsWith("video") && n.endsWith(".updateRate")) {
			try {
				int x = Integer.parseInt(v);
				if (x < 1)
					return "1";
			} catch (NumberFormatException e) {
				return "5";
			}
		}
		
		return v;
	}



}

