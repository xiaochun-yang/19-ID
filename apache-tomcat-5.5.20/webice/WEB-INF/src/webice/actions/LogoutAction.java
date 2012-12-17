/**
 * Javabean for SMB resources
 */
package webice.actions;

import java.io.IOException;
import java.util.Date;
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


public class LogoutAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{


		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client != null) {
			WebiceLogger.info("LogoutAction: logging out client " + client.getSessionId());
			client.logout();
		}

		session.removeAttribute("client");
		session.removeAttribute("SMBSessionID");

		// Invalidate the session
		// WebIceSessionAttributeListener will be called
		// when "client" attribute is removed.
		// The handler will log the client out.
//		WebiceLogger.info("LogoutAction: invalidating session " + session.getId()
//							+ " " + new Date().toString());
		session.invalidate();


		return mapping.findForward("success");

	}



}

