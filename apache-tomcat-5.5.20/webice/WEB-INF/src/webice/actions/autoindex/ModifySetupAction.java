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


public class ModifySetupAction extends Action
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
		
		int setupStep = controller.getSetupStep();
		
		try {
		
		String nextStep = request.getParameter("goto");
		System.out.println("in ModifySetupAction: nextStep = " + nextStep);
		if (nextStep != null) {
			if (nextStep.equals("Edit") || nextStep.equals("Edit Setup") 
				|| nextStep.equals("Edit+Setup")) {
				if (controller.getStatus() <= RunController.READY) {
					if (data.isCollectImages()) {
						controller.setSetupStep(RunController.SETUP_CHOOSE_SAMPLE);
					} else {
						controller.setSetupStep(RunController.SETUP_CHOOSE_DIR);
					}
				} else {
					return mapping.findForward("warning");
				}
			}
		}

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ModifySetup: " + e.getMessage(), e);
			request.setAttribute("error", e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

