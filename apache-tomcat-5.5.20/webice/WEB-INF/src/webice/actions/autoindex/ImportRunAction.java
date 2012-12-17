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


public class ImportRunAction extends Action
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

		AutoindexViewer viewer = client.getAutoindexViewer();

		if (viewer == null)
			throw new ServletException("AutoindexViewer is null");

		if (request.getParameter("cancel") != null)
			return mapping.findForward("success");

		String runName = request.getParameter("name");
		if ((runName == null) || (runName.length() == 0)) {
			request.setAttribute("error.any", "Failed to create run: Invalid run name");
			return mapping.findForward("error");
		}

		String runDir = request.getParameter("runDir");
		if ((runDir == null) || (runDir.length() == 0)) {
			request.setAttribute("error.any", "Failed to create run: Invalid import run directory");
			return mapping.findForward("error");
		}

		try {
			viewer.importRun(runName, runDir);
		} catch (Exception e) {
			request.setAttribute("error.any", "Failed to import run: " + e.getMessage());
			return mapping.findForward("error");
		}

		return mapping.findForward("success");

	}



}

