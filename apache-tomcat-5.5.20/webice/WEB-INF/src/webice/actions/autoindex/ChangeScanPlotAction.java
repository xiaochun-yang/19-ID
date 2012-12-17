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


public class ChangeScanPlotAction extends Action
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


		AutoindexViewer viewer = client.getAutoindexViewer();

		if (viewer == null)
			throw new ServletException("AutoindexViewer is null");

		AutoindexRun run = viewer.getSelectedRun();

		if (run == null)
			throw new ServletException("Selected run is null");
		
		String type = request.getParameter("type");
		
		run.setScanPlotType(type);
		

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChangeScanPlotAction: " + e.getMessage(), e);
			request.setAttribute("error", " Cannot change scan plot type because " + e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

