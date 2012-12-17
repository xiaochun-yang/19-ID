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
import webice.actions.common.StringForm;


public class FinishSetupAction extends Action
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

		controller.resetLog();

		try {
		
		if (request.getParameter("done") != null) {
			AutoindexSetupData setupData = controller.getSetupData();
			String inte = request.getParameter("integrate");
			if ((inte == null) || (inte.length() == 0))
				inte = "best";
			setupData.setIntegrate(inte);
			String generateStrategy = request.getParameter("generateStrategy");
			String beamline = request.getParameter("beamline");
			if ((generateStrategy != null) && !generateStrategy.equals("no")) {
				setupData.setGenerateStrategy(true);
				setupData.setBeamline("default");
				if (generateStrategy.equals("yes")) {
					if ((beamline == null) || (beamline.length() == 0) || beamline.equals("default"))
						throw new Exception("A beamline must be selected in order to generate data collection strategy");
					setupData.setBeamline(beamline);
				}
			} else {
				setupData.setGenerateStrategy(false);
			}	
			
			// Commit the setup data
			controller.finishSetup();
		} else {
			controller.resetSetupData();
		}

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in FinishSetupAction: " + e.getMessage(), e);
			request.setAttribute("error.finishSetup", e.getMessage());
		}



		return mapping.findForward("success");


	}



}

