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


public class SetDisplayModeAction extends Action
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

		String tab = request.getParameter("mode");
		if (tab == null)
			tab = AutoindexViewer.ALL_RUNS;
			
		viewer.setDisplayMode(tab);
		
		String type = request.getParameter("type");
		
		if (type != null) {
			viewer.setRunListType(type);
		}

/*		if (tab.equals(AutoindexViewer.ALL_RUNS) || (viewer.getSelectedRun() == null))
			viewer.setDisplayMode(AutoindexViewer.ALL_RUNS);
		else
			viewer.setDisplayMode(AutoindexViewer.ONE_RUN);*/

		return mapping.findForward("success");

	}



}

