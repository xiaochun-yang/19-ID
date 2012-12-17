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
import org.apache.struts.action.*;

import webice.beans.*;
import webice.beans.autoindex.*;


public class LoadRunsAction extends Action
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

		try {

			viewer.loadRuns();

		} catch (Exception e) {
			request.setAttribute("error.loadFailed", "Failed to load runs: " + e.getMessage());
			WebiceLogger.error("Failed in loadRuns: " + e.getMessage(), e);
			return mapping.findForward("error");
		}

		return mapping.findForward("success");

	}



}

