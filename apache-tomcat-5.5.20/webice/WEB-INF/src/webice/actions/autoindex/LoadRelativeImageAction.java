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


public class LoadRelativeImageAction extends Action
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
			throw new ServletException("AutoindexImageViewer is null");

		AutoindexRun run = viewer.getSelectedRun();
		if (run == null)
			throw new ServletException("No run is selected.");

		String which = request.getParameter("file");
		
		if (which == null)
			mapping.findForward("success");
			
		if (which.equals("previous")) {
			run.gotoPrevImage();
		} else if (which.equals("next")) {
			run.gotoNextImage();
		}

		return mapping.findForward("success");

	}



}

