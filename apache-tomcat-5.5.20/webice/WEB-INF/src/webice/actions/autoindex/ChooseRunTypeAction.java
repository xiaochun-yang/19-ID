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


public class ChooseRunTypeAction extends Action
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

		AutoindexRun run = viewer.getSelectedRun();

		if (run == null)
			throw new ServletException("Selected run is null");

		RunController controller = run.getRunController();
		AutoindexSetupData data = controller.getSetupData();
		
		try {
		
		String nextStep = request.getParameter("goto");
		if (nextStep != null) {
		
			if (nextStep.equals("Continue")) {

				String type = request.getParameter("type");
				if ((type == null) || (type.length() == 0))
					type = AutoindexViewer.RUN_TYPE_AUTOINDEX;
				
				controller.changeRunType(type);
							
			} else if (nextStep.equals("Cancel")) {			
				controller.setSetupStep(controller.SETUP_FINISH);			
			}
						
		} // nextStep != null

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseExperiment: " + e.getMessage(), e);
			request.setAttribute("error", e.getMessage());
		}
		
		return mapping.findForward("success");


	}



}

