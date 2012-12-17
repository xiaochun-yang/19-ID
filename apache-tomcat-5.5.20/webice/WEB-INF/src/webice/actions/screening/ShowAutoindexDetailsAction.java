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


public class ShowAutoindexDetailsAction extends Action
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

		FileBrowser browser = viewer.getOutputFileBrowser();
		
		String dir = request.getParameter("dir");
		
		if (request.getParameter("up") != null) {
			browser.changeToParentDirectory();
		} else if ((dir != null) && (dir.length() > 0)) {
			browser.changeDirectory(dir, "", true);
		} else if (dir == null) {
			// Force reload everytime we look at this page.
			browser.changeDirectory(viewer.getAutoindexDir(), "", true);
		}

		
		} catch (Exception e) {
			request.setAttribute("error", e.getMessage());
		}

		return mapping.findForward("success");
	}



}

