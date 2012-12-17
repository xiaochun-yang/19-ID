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
import webice.beans.screening.*;


public class HandleSilCommandAction extends Action
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

		ScreeningViewer viewer = client.getScreeningViewer();

		if (viewer == null)
			throw new ServletException("ScreeningViewer is null");

		String command = request.getParameter("command");
		
		if (command == null)
			command = "";
			
		WebiceLogger.info("in HandleSilCommand: command = " + command);

		if (command.equals("All Cassettes")) {
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_ALLSILS);
		} else if (command.equals("All")) {
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_ALLSILS);
		} else if (command.equals("Cassette Summary")) {
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_OVERVIEW);
		} else if (command.equals("Summary")) {
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_OVERVIEW);
		} else if (command.equals("Cassette Details")) {
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_DETAILS);
		} else if (command.equals("Details")) {
			viewer.setDisplayMode(ScreeningViewer.DISPLAY_DETAILS);
		} else if (command.equals("Edit Crystal")) {
			return mapping.findForward("edit");
		} else if (command.equals("Edit")) {
			return mapping.findForward("edit");
		} else if (command.equals("Analyze Crystal")) {
			return mapping.findForward("analyze");
		} else if (command.equals("Analyze")) {
			return mapping.findForward("analyze");
		} else if (command.equals("Analyze Crystals")) {
			return mapping.findForward("analyzeCrystals");
		} else if (command.equals("Set Crystal")) {
			return mapping.findForward("setCrystal");
		} else if (command.equals("Submit")) {
			return mapping.findForward("setCrystal");
		} else if (command.equals("Update")) {
			return mapping.findForward("reload");
		} else if (command.equals("Refresh")) {
			return mapping.findForward("reload");
		} else if (command.equals("Reload")) {
			return mapping.findForward("reload");
		} else if (command.equals("View Strategy")) {
			return mapping.findForward("viewStrategy");
		} else if (command.equals("CustomizeDisplay")) {
			return mapping.findForward("customizeDisplay");
		} else if (command.equals("setSelectionMode")) {
			String mode = request.getParameter("mode");
			if (mode == null)
				mode = ScreeningViewer.ONE_CRYSTAL;
			viewer.setSelectionMode(mode);
			return mapping.findForward("setSelectionMode");
		} else if (command.equals("Single Crystal Selection")) {
			viewer.setSelectionMode(ScreeningViewer.ONE_CRYSTAL);
			return mapping.findForward("setSelectionMode");
		} else if (command.equals("Multiple Crystal Selection")) {
			viewer.setSelectionMode(ScreeningViewer.MULTI_CRYSTAL);
			return mapping.findForward("setSelectionMode");
		} else {
			WebiceLogger.info("HandleSilCommand: unrecognized command " + command);
		}

		return mapping.findForward("view");

	}



}

