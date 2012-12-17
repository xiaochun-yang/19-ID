/**
 * Javabean for SMB resources
 */
package webice.actions.autoindex;

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

import webice.beans.*;
import webice.beans.autoindex.*;


public class DeleteRunAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{

		String name = "";
		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		try {

			AutoindexViewer viewer = client.getAutoindexViewer();

			if (viewer == null)
				throw new ServletException("AutoindexViewer is null");

			name = request.getParameter("run");

			if ((name == null) || (name.length() == 0))
				throw new ServletException("Invalid request parameter 'run'");
			
			String checkStatus = request.getParameter("checkStatus");
			
			// Delete without checking run status
			if ((checkStatus != null) && checkStatus.equals("false"))
				viewer.deleteRun(name, false);
			else
				viewer.deleteRun(name);
				
		} catch (Exception e) {
			request.setAttribute("error.deleteRunFailed",
								"Cannot delete run "
								+ name + ": " + e.getMessage());
			request.setAttribute("error.run", name);
			return mapping.findForward("error");
		}


		return mapping.findForward("success");

	}



}

