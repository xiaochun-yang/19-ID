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


public class ShowAutoindexRunAction extends Action
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
			
		String beamline = request.getParameter("beamline");
		String runName = request.getParameter("runName");
		if (beamline == null) {
			request.setAttribute("error", "Missing beamline parameter in the request");
			return mapping.findForward("failed");
		}
		
		if ((runName == null) || (runName.length() == 0)) {
			request.setAttribute("error", "Missing runName parameter in the request");
			return mapping.findForward("failed");
		}

		// Connect to a beamline
		client.connectToBeamline(beamline);

		// Select the autoindex tab
		client.setTab("autoindex");

		AutoindexViewer viewer = client.getAutoindexViewer();

		if (viewer == null)
			throw new ServletException("AutoindexViewer is null");

		// If runs info has not been loaded then load it.
		if (!viewer.isLoaded())
			viewer.loadRuns();
			
		viewer.selectRun(runName);
					
		return mapping.findForward("success");

	}



}

