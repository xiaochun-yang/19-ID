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


public class EditSetupAction extends Action
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
			
			
		try {


		AutoindexViewer top = client.getAutoindexViewer();

		if (top == null)
			throw new ServletException("AutoindexViewer is null");

		AutoindexRun run = top.getSelectedRun();
		

		if (run == null)
			throw new ServletException("Selected node is null");

		RunController controller = run.getRunController();

		controller.resetLog();

		String confirm = request.getParameter("confirm");
		
		if ((confirm == null) || (confirm.length() == 0)) {

			if (controller.getStatus() > RunController.READY)
				return mapping.findForward("warning");
		
			controller.editSetup();

		} else {
			if (confirm.equals("Continue")) {
				controller.editSetup();
			}
		}

		return mapping.findForward("success");
		
		} catch (Exception e) {
			request.getSession().setAttribute("error.setup", e.getMessage());
			return mapping.findForward("error");
		}


	}



}

