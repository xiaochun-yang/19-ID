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


public class ChooseOptionsAction extends Action
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
		
		String nextStep = request.getParameter("goto");
		boolean validate = true;
		if (nextStep.equals("Prev"))
			validate = false;
		
		try {
		
		if (data.isCollectImages()) {
		
			DcsConnector dcs = client.getDcsConnector();
			if (dcs == null)
				throw new Exception("A beamline must be selected for this run in order to collect images");
			if  (!dcs.getBeamline().equals(data.getBeamline()))
				throw new Exception("This run is setup for beamline " + data.getBeamline() + 
						". Please select the correct beamline from the tool bar.");
				
			RunDefinition testDef = data.getTestRunDefinition();
		
			testDef.fileRoot = data.getImageRootName();
			testDef.directory = data.getImageDir();
			testDef.startFrame = 1;
			testDef.axisMotorName = "gonio_phi";
			testDef.startAngle = 0.0;

			// Osc range
			testDef.delta = dcs.getOscRange();
			tmp = request.getParameter("osc");
			if ((tmp != null) && (tmp.length() > 0)) {
				double tt = Double.parseDouble(tmp);
				if (tt > 0.0)
					testDef.delta = tt;
			}
			
			testDef.endAngle = testDef.startAngle + testDef.delta;
			testDef.wedgeSize = 180.0;

			// Exposure time
			testDef.exposureTime = dcs.getExposureTime();
			tmp = request.getParameter("exposureTime");
			if ((tmp != null) && (tmp.length() > 0)) {
				double tt = Double.parseDouble(tmp);
				if (tt > 0.0)
					testDef.exposureTime = tt;
			}

			// Attenuation
			testDef.attenuation = dcs.getAttenuation();
			tmp = request.getParameter("attn");
			if ((tmp != null) && (tmp.length() > 0)) {
				double tt = Double.parseDouble(tmp);
				if (tt > 0.0)
					testDef.attenuation = tt;
			}

			// Detector mode
			testDef.detectorMode = dcs.getDetectorMode(testDef.exposureTime);
			
			testDef.beamStop = dcs.getBeamStop();			

			
			// Energy
			double energy_used = 0.0;
			double detector_radius = dcs.getDetectorRadius();
			double detector_distance = dcs.getDetectorDistance();
			if (data.getExpType().equals("MAD") || data.getExpType().equals("SAD")) {
				if (data.isDoScan()) {
					// If we are doing a scan then set 
					// energy for test images to ege energy
					energy_used = data.getEdge().en1;
				} else {
					// If we are not doing a scan then
					// collect test images with peak energy.
					energy_used = data.getPeakEn();
				}
			} else {
				// If we are doing monichromatic exp
				// then use the current energy 
				// to collect test images.
				energy_used = dcs.getEnergy();
			}
			
			if (validate && (energy_used <= 0.0))
				throw new Exception("Invalid energy " + energy_used);

			testDef.numEnergy = 1;
			testDef.energy1 = energy_used;
			testDef.energy2 = 0.0;
			testDef.energy3 = 0.0;
			testDef.energy4 = 0.0;
			testDef.energy5 = 0.0;
			
			testDef.inverse = 0;
						
		
			// Target resolution & detector distance
			double dt = DcsConnector.getDetectorResolution(energy_used, detector_distance, detector_radius);
			long t = Math.round(dt*1000);
			dt = t/1000.0;
			data.setTargetResolution(dt);
			testDef.distance = detector_distance;
			tmp = request.getParameter("resolution");
			if ((tmp != null) && (tmp.length() > 0)) {
				double res = Double.parseDouble(tmp);
				if (res > 0.0) {
					StepperMotorDevice detector_z = dcs.getDetectorDistanceDevice();
					if (detector_z == null)
						throw new Exception("Failed to get detector_z device from dcss");
					double res1 = DcsConnector.getDetectorResolution(energy_used, detector_z.getLowerLimit(), detector_radius);
					double res2 = DcsConnector.getDetectorResolution(energy_used, detector_z.getUpperLimit(), detector_radius);
					if (validate) {
						if ((res < res1) || (res > res2))
							throw new Exception("Resolution " + res
								+ " is outside limits (" + res2 + " to " + res1
								+ " &#197;), constraint by detector distance limits (" + detector_z.getLowerLimit()
								+ " to " + detector_z.getUpperLimit() + " mm)");
					}
					WebiceLogger.info("res1 = " + res1 + " res2 = " + res2);
					data.setTargetResolution(res);
					double dd = AutoindexSetupData.calculateDetectorDistance(res, detector_radius, energy_used);
					testDef.distance = dd;
				}
			}
					
		}
		
		// Integration method is either mosflm or best.
		String strategyMethod = request.getParameter("strategyMethod");
		if (strategyMethod != null)
			data.setStrategyMethod(strategyMethod);
		else
			data.setStrategyMethod("best");
		
		String laueGroup = "";
		double a = 0.0;
		double b = 0.0;
		double c = 0.0;
		double alpha = 0.0;
		double beta = 0.0;
		double gamma = 0.0;
		
		String aStr = request.getParameter("a").trim();
		String bStr = request.getParameter("b").trim();
		String cStr = request.getParameter("c").trim();
		String alphaStr = request.getParameter("alpha").trim();
		String betaStr = request.getParameter("beta").trim();
		String gammaStr = request.getParameter("gamma").trim();
		
		tmp = request.getParameter("sp");
		if ((tmp != null) && (tmp.length() > 0)) {
			laueGroup = tmp;
		}
		data.setLaueGroup(laueGroup);
		// Validate cell parameters using labelit
		data.setUnitCell(0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
		
		String cellErr = "";
		
		// If at least one of them is filled
		// then set the ones which are not filled
		// or invalid to default value.
		// and validate the values using labelit.
		if ((aStr.length() > 0) || (bStr.length() > 0) || (cStr.length() > 0)
			|| (alphaStr.length() > 0) || (betaStr.length() > 0) || (gammaStr.length() > 0)) {
					
			// Unit cell
			// Throw an exception if the value is not a valid double
			// If the parameter is absence, set it to 90 deg.
			try {
				a = getParameterDouble(aStr, 0.0);
			} catch (NumberFormatException e) {
				a = 0.0;
				cellErr += " Cell parameter 'a' is invalid and reset to 0.";
			}
			try {
				b = getParameterDouble(bStr, 0.0);
			} catch (NumberFormatException e) {
				b = 0.0;
				cellErr += " Cell parameter 'b' is invalid and reset to 0.";
			}
			try {
				c = getParameterDouble(cStr, 0.0);
			} catch (NumberFormatException e) {
				c = 0.0;
				cellErr += " Cell parameter 'c' is invalid and reset to 0.";
			}
			try {
				alpha = getParameterDouble(alphaStr, 90.0);
			} catch (NumberFormatException e) {
				alpha = 0.0;
				cellErr += " Cell parameter 'alpha' is invalid and reset to 90.";
			}
			try {
				beta = getParameterDouble(betaStr, 90.0);
			} catch (NumberFormatException e) {
				beta = 0.0;
				cellErr += " Cell parameter 'beta' is invalid and reset to 90.";
			}
			try {
				gamma = getParameterDouble(gammaStr, 90.0);
			} catch (NumberFormatException e) {
				gamma = 0.0;
				cellErr += " Cell parameter 'gamma' is invalid and reset to 90.";
			}
						
			// Validate cell parameters using labelit
			data.setUnitCell(a, b, c, alpha, beta, gamma);
			
			if (validate) {
				if (cellErr.length() > 0)
					throw new Exception(cellErr);
			}
			
		} // if at least one of them is filled
		
				
		
		// Will throw an exception if laue group and unit cell are not compatble.
		if (validate)
			controller.validateUnitCell();
								
		int heavyAtoms = 0;
		try {
			heavyAtoms = Integer.parseInt(request.getParameter("heavyAtoms").trim());
		} catch (Exception e) {
			heavyAtoms = 0;
		}
		data.setNumHeavyAtoms(heavyAtoms);
		if (validate && (heavyAtoms < 0))
			throw new Exception("Invalid number of heavy atoms in monomer.");
			
			
		int residues = 0;
		try {
			residues = Integer.parseInt(request.getParameter("residues").trim());
		} catch (Exception e) {
			residues = 0;
		}
		
		data.setNumResidues(residues);
		if (validate && (residues < 0))
			throw new Exception("Number of residues in monomer.");
			
		
		if (request.getParameter("done") != null) {
			// Commit the setup data
			controller.finishSetup();
		} else {
			controller.resetSetupData();
		}

//		WebiceLogger.info("in ChooseOptions: goto = " + nextStep);
		if (nextStep != null) {
			if (nextStep.equals("Next")) {
				controller.setSetupStep(RunController.SETUP_FINISH);
			} else if (nextStep.equals("Prev")) {
				if (data.isGenerateStrategy()) {
					controller.setSetupStep(RunController.SETUP_CHOOSE_EXP);
				} else {
					controller.setSetupStep(RunController.SETUP_CHOOSE_STRATEGY_OPTION);
				}
			} else if (nextStep.equals("Finish")) {
				controller.setSetupStep(RunController.SETUP_FINISH);
				return mapping.findForward("finish");
			}
		}

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseOptions: " + e.getMessage(), e);
			request.setAttribute("error", e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

