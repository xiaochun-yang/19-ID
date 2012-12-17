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
import webice.beans.dcs.*;
import webice.beans.autoindex.*;


public class ChooseStrategyOptionAction extends Action
{
	/**
	 */
	private double getParameterDouble(String param, double d)
		throws NumberFormatException
	{
		
		if ((param != null) && (param.length() > 0)) {
			return Double.parseDouble(param);
		} else {
			return d;
		}
		
	}

	/**
	 */
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
		
		String tmp = "";
		
		try {
										
		AutoindexSetupData setupData = controller.getSetupData();
		data.setIntegrate(request.getParameter("integrate"));
		String generateStrategy = request.getParameter("generateStrategy");
		String beamline = "default";
		DcsConnector dcs = client.getDcsConnector();
		if (client.isConnectedToBeamline() && (dcs != null))
			beamline = dcs.getBeamline();
			
		if (generateStrategy == null)
			throw new Exception("Please select one of the strategy options");
						
		if (generateStrategy.equals("no")) {
			setupData.setGenerateStrategy(false);
		} else {
			data.setGenerateStrategy(true);
			data.setBeamline("default");
			if (generateStrategy.equals("yes")) {
				if ((beamline == null) || (beamline.length() == 0) || beamline.equals("default"))
					throw new Exception("A beamline must be selected in order to generate data collection strategy");
				data.setBeamline(beamline);
				
				if (!data.isCollectImages()) {
					if ((beamline != null) && (beamline.length() > 0) 
						&& !beamline.equals("default")) {
						data.setBeamline(beamline);
						String imgDetectorType = setupData.getDetector();
						String dcsDetectorName = Detector.getDcsDetectorType(imgDetectorType); 
						String bDetectorType = client.getDcsConnector().getDetectorType();
				  		if ((bDetectorType == null) || !bDetectorType.equalsIgnoreCase(dcsDetectorName))
							throw new Exception("The images were collected from " + imgDetectorType
								+ " detector but the selected beamline (" + beamline + ") has " 
								+ bDetectorType + " detector. Please select a new beamline "
								+ " or use the \"Generate strategy offline\" option.");
					}
				}
			}
		}	
					
		String nextStep = request.getParameter("goto");
//		WebiceLogger.info("in ChooseStrategyOption: goto = " + nextStep);
		if (nextStep != null) {
			if (nextStep.equals("Next")) {
				if (data.isGenerateStrategy()) {
					controller.setSetupStep(RunController.SETUP_CHOOSE_EXP);
				} else {
					controller.setSetupStep(RunController.SETUP_CHOOSE_OPTIONS);
				}
			} else if (nextStep.equals("Prev")) {
				controller.setSetupStep(RunController.SETUP_CHOOSE_DIR);
			} else if (nextStep.equals("Finish")) {
				controller.setSetupStep(RunController.SETUP_CHOOSE_STRATEGY_OPTION);
			}
		} else {
			controller.setSetupStep(RunController.SETUP_CHOOSE_STRATEGY_OPTION);
		}

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseStrategyOption: " + e.getMessage(), e);
			request.setAttribute("error", e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

