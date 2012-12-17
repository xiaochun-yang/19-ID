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


public class ShowMountedCrystalAction extends Action
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
		if (beamline == null) {
			request.setAttribute("error", "Missing beamline parameter in the request");
			return mapping.findForward("failed");
		}
		String spaceGroup = request.getParameter("spaceGroup");
		
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
			
		String runName = request.getParameter("runName");
		if ((runName == null) || (runName.length() == 0)) {
		
			viewer.setDisplayMode("createRun");
			viewer.setShowMountedCrystal(true);
		
		} else {
			viewer.selectRun(runName);
			viewer.selectRunTab("strategy");
			AutoindexRun selectedRun = viewer.getSelectedRun();
			if ((selectedRun != null) && (spaceGroup != null) && (spaceGroup.length() > 0)) {
				selectedRun.selectSpaceGroup(spaceGroup);
			}
		}
		
		WebiceLogger.info("ShowMountedCrystal (autoindex): user = " + client.getUser() 
					+ " beamline = " + beamline
					+ " run name = " + runName);
					
		return mapping.findForward("success");

	}



}

