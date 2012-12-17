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
import webice.beans.dcs.*;


public class ShowRunSetupAction extends Action
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

		String nextPage = "finish";		
		try {
		
		AutoindexViewer viewer = client.getAutoindexViewer();

		if (viewer == null)
			throw new ServletException("AutoindexViewer is null");
			
		AutoindexRun run = viewer.getSelectedRun();
		if (run == null)
			throw new Exception("No run has been selected");
		RunController controller = run.getRunController();
		int setupStep = controller.getSetupStep();
		
		if (setupStep == RunController.SETUP_CHOOSE_RUN_TYPE) {
			nextPage = "chooseRunType";
		} else if (setupStep == RunController.SETUP_CHOOSE_SAMPLE) {
			nextPage = "chooseSample";
		} else if (setupStep == RunController.SETUP_CHOOSE_DIR) { 
			AutoindexSetupData setupData = controller.getSetupData();
			if (setupData.isCollectImages()) {
				nextPage = "chooseDirAndImageName";
			} else {
				nextPage = "chooseDirAndImages";
			}
		} else if (setupStep == RunController.SETUP_CHOOSE_STRATEGY_OPTION) {
			nextPage = "chooseStrategyOption";
		} else if (setupStep == RunController.SETUP_CHOOSE_EXP) {
			nextPage = "chooseExperiment";
		} else if (setupStep == RunController.SETUP_CHOOSE_OPTIONS) {
			nextPage = "chooseOptions";
		}
		
		} catch (Exception e) {
			request.setAttribute("error", e.getMessage());
		}
		
		return mapping.findForward(nextPage);
		

	}



}

