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


public class ShowRunDetailsAction extends Action
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

		String tab = viewer.getSelectedRunTab();
		if ((tab == null) || (tab.length() == 0))
			tab = "autoindex";

		AutoindexRun run = viewer.getSelectedRun();

		FileBrowser browser = viewer.getOutputFileBrowser();

		String dir = request.getParameter("dir");
		
		if (request.getParameter("up") != null) {
			browser.changeToParentDirectory();
		} else if ((dir != null) && (dir.length() > 0)) {
			browser.changeDirectory(dir, "", true);
		} else if (dir == null) {
			// Force reload everytime we look at this page.
			browser.reloadDirectory();
		}

		if (run == null)
			mapping.findForward("noRun");


		return mapping.findForward("success");

	}



}

