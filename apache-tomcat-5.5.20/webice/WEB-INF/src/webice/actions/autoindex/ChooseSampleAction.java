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


public class ChooseSampleAction extends Action
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
		
		String sample = request.getParameter("sample");
				
		if (sample != null) {
			if (sample.equals("current")) {
				data.setMountSample(false);
			} else if (sample.equals("cassette")) {
				data.setMountSample(true);
			}
		}
		
		if (data.isMountSample()) {
		
		String tmp = request.getParameter("silId");				
		if (tmp != null)
			data.setSilId(tmp);
			
		tmp = request.getParameter("cassette");
		int t = -1;
		if (tmp == null)
			throw new Exception("Please select a cassette");
		try {
			t = Integer.parseInt(tmp);
		} catch (Exception e) {
			throw new Exception("Please select a cassette");
		}
		
		if ((t < 1) || (t > 3))
			throw new Exception("Please select a cassette");
		data.setCassetteIndex(t);

		tmp = request.getParameter("crystalPort");
		if (tmp == null)
			throw new Exception("Please select a crystal port");
			
		if (tmp.length() == 0)
			throw new Exception("Please select a crystal port");
			
		data.setCrystalPort(tmp);
			
		
		} else {
		
		String currentSilId = request.getParameter("currentSilId");
		String tmp = request.getParameter("currentCassette");
		int currentCassetteIndex = Integer.parseInt(tmp);
		String crystalPort = request.getParameter("currentCrystalPort");
		
		data.setSilId(currentSilId);
		data.setCassetteIndex(currentCassetteIndex);
		data.setCrystalPort(crystalPort);
		
		
		}
		
		
		String nextStep = request.getParameter("goto");
		if (nextStep != null) {
			if (nextStep.equals("Next")) {
				controller.setSetupStep(RunController.SETUP_CHOOSE_DIR);
				run.setShowCassetteBrowser(false);
			} else if (nextStep.equals("Prev")) {
				controller.setSetupStep(RunController.SETUP_CHOOSE_SAMPLE);
				run.setShowCassetteBrowser(false);
			}
		}
		
		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseSample: " + e.getMessage(), e);
			request.setAttribute("error", e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

