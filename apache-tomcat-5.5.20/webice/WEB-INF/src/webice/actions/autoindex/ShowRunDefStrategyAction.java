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
import webice.beans.screening.*;


public class ShowRunDefStrategyAction extends Action
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
			
		String beamline = request.getParameter("beamline");
		if (beamline == null) {
			request.setAttribute("error", "Missing beamline parameter in the request");
			return mapping.findForward("failed");
		}
			
		String silId = request.getParameter("silId");
		if (silId == null) {
			request.setAttribute("error", "Missing silId parameter in the request");
			return mapping.findForward("failed");
		}
		
		String tmp = request.getParameter("row");
		if (tmp == null) {
			request.setAttribute("error", "Missing unqiueId parameter in the request");
			return mapping.findForward("failed");
		}
		int row = -1;
		try {
			row = Integer.parseInt(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid row paramater");
		}
		
				
		tmp = request.getParameter("runIndex");
		int runIndex =  -1;
		try {
			if (tmp != null)
				runIndex = Integer.parseInt(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid runIndex parameter");
		}
		
		tmp = request.getParameter("repositionId");
		int repositionId =  -1;
		try {
			if (tmp != null)
				repositionId = Integer.parseInt(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid repositionId parameter");
		}
		if ((runIndex < 0) && (repositionId < 0))
			throw new Exception("Missing runIndex or repositionId");
		
		// Connect to a beamline
		client.connectToBeamline(beamline);
		
		// Load sil into the screening viewer so that user
		// can navigate to another crystal on the screening tab.	
		ScreeningViewer screeningViewer = client.getScreeningViewer();
		if (screeningViewer == null)
			throw new ServletException("ScreeningViewer is null");
			
		// Do not force reload if the sil is already loaded
		if ((silId != null) && (silId.length() > 0) && !silId.equals(screeningViewer.getSilId())) {
			screeningViewer.loadSil(silId, false, client.getUser());
		}
		
		// Select this row
		screeningViewer.selectCrystal(row);		
			
		// Select the autoindex tab
		client.setTab("autoindex");

		AutoindexViewer autoindexViewer = client.getAutoindexViewer();
		if (autoindexViewer == null)
			throw new ServletException("AutoindexViewer is null");
			
		// Load crystal data and rundef from crystal-server
		String crystalId = screeningViewer.getSelectedCrystalID();
		if (crystalId == null)
			throw new ServletException("Crystal ID is null");
		String port = screeningViewer.getSelectedCrystalPort();
		if (port == null)
			throw new ServletException("Crystal port is null");
		// Get Reposition id from run def.
//		WebiceLogger.info("in ShowRunDefStrategyAction1: selectedRun silId = " + silId 
//					+ " runIndex + " + runIndex + " repositionId = " + repositionId);
		if (runIndex > -1) {
			repositionId = screeningViewer.getRunDefRepositionId(runIndex);
			if (repositionId < 0)
				throw new ServletException("No reposition data associated with this run definition");
		}
		String autoindexDir = screeningViewer.getRepositionDataAutoindexDir(repositionId);
		if (autoindexDir == null)
			throw new ServletException("No autoindex dir associated with this run definition");
		autoindexViewer.importRun(silId, port, crystalId, repositionId, autoindexDir);
		AutoindexRun selectedRun = autoindexViewer.getSelectedRun();
		WebiceLogger.info("in ShowRunDefStrategyAction: selectedRun = " + selectedRun);
		if (selectedRun != null) {
			selectedRun.setSilId(silId);
			selectedRun.setRow(row);
			selectedRun.setRepositionId(repositionId);
			selectedRun.setRunIndex(runIndex);
			selectedRun.setRunLabel(screeningViewer.getRunDefLabel(runIndex));
		}
					
		return mapping.findForward("success");
		
		} catch (Exception e) {
			WebiceLogger.error("ShowRunDefStrategyAction failed", e);
			request.setAttribute("error", e.getMessage());
			return mapping.findForward("failed");
		}

	}
}

