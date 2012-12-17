/**
 * Javabean for SMB resources
 */
package webice.actions;

import java.util.*;
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
import edu.stanford.slac.ssrl.authentication.utility.*;

import webice.beans.*;


public class LoginAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{


		HttpSession session = request.getSession();

		if (session == null)
			throw new ServletException("HttpSession is null");

		String userName = request.getParameter("userName");
		String password = request.getParameter("password");
		
		if ((userName == null) || (userName.length() == 0)) {
			request.setAttribute("error", "Please enter loggin name");
			return mapping.findForward("missingParam");
		}
		
		if (password == null)
			password = "";
			
		
		WebiceLogger.info("LoginAction: user " + userName);
		Client client = (Client)session.getAttribute("client");

		if (client == null) {
			WebiceLogger.info("LoginAction: creating a new Client for " + userName);
			client = new Client();
			session.setAttribute("client", client);
		}

		try {

		 client.login(userName, password);
		 session.setAttribute("SMBSessionID", client.getSessionId());

	 	} catch (NoPermissionException e) {
			WebiceLogger.error("NoPermissionException in LoginAction:" + e.getMessage());
			return mapping.findForward("noPermissionException");
	 	} catch (Exception e) {
			WebiceLogger.error("Exception in LoginAction:" + e.getMessage());
			session.setAttribute("exception", e.getMessage());
			return mapping.findForward("exception");
		}


		return mapping.findForward("success");

	}



}

