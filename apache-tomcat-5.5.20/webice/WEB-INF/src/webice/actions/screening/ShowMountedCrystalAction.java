/**
 * Javabean for SMB resources
 */
package webice.actions.screening;

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
import webice.beans.dcs.*;
import webice.beans.image.ImageViewer;
import webice.beans.screening.*;


public class ShowMountedCrystalAction extends Action
{

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

		String beamline = request.getParameter("beamline");
		if (beamline == null) {
			request.setAttribute("error", "Missing beamline parameter in the request");
			return mapping.findForward("failed");
		}
		
		// Select the autoindex tab
		client.setTab("screening");

		// Connect to a beamline
		client.connectToBeamline(beamline);
		
		if (!client.isConnectedToBeamline()) {
			request.setAttribute("error", "Cannot connect to beamline " + beamline);
			return mapping.findForward("failed");
		}

		// If runs info has not been loaded then load it.
		viewer.loadSilList();
		
		String silId = client.getScreeningSilId();

		if (silId == null) {
			request.setAttribute("error", "Cannot get id of spreadsheet at beamline " + beamline);
			return mapping.findForward("failed");
		}

		ScreeningStatus stat = client.getScreeningStatus();

				
		int id = Integer.parseInt(silId);
		
		
		if ((id <= 0) || !viewer.isCassetteAtBeamlineViewable()) {
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_ALLSILS);
		} else {
			viewer.loadSil(silId);
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_OVERVIEW);
			if (stat.row >= 0) {
				String mode = request.getParameter("mode");
				if ((mode != null) && mode.equals(ScreeningViewer.DISPLAY_DETAILS)) {
					viewer.setDisplayMode(ScreeningViewer.DISPLAY_DETAILS);
					// Set image info tab to autoindex
					ImageViewer imageViewer = viewer.getImageViewer();
					imageViewer.setInfoTab(ScreeningImageViewer.TAB_AUTOINDEX);
				}
				viewer.selectCrystal(stat.row);
			}
		}
				
							
		WebiceLogger.info("screening ShowMountedCrystal (screening): user = " + client.getUser() 
					+ " beamline = " + beamline
					+ " silId = " + id);

		return mapping.findForward("success");
		
		} catch (Exception e) {
			request.setAttribute("error", "Cannot show mounted crystal because " + e.getMessage());
			return mapping.findForward("failed");
		}
		

	}



}

