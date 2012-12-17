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


public class ChooseExperimentAction extends Action
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
		
		// Experiment type: Monichromatic, MAD, SAD or Anomalous
		String exp = request.getParameter("exp");
		
		if ((exp != null) && (exp.length() > 0))
			data.setExpType(exp);
			
		// Do we need to do flourescence scan?
		if (exp.equals("MAD") || exp.equals("SAD")) {
			String tmp = request.getParameter("scan");
			boolean scan = false;
			if ((tmp != null) && tmp.equals("true"))
				scan = true;
			data.setDoScan(scan);	
		}
		
		if (data.isDoScan()) {
			String edge = request.getParameter("edge");
			String tmp = request.getParameter("edgeEn1");
			double en1 = 0.0;
			try {
			if ((tmp != null) && (tmp.length() > 0))
				en1 = Double.parseDouble(tmp);
			} catch (NumberFormatException e) {
				throw new Exception("Invalid absorption edge energy " + tmp + " for " + edge);
			}
			tmp = request.getParameter("edgeEn2");
			double en2 = 0.0;
			try {
			if ((tmp != null) && (tmp.length() > 0))
				en2 = Double.parseDouble(tmp);
			} catch (NumberFormatException e) {
				throw new Exception("Invalid associated emission line energy " + tmp + " for " + edge);
			}
						
			data.setEdge(edge, en1, en2);
			
			// Do not scan if the selected edge is inaccessible
			// due to energy limit at the beamline.
			if (exp.equals("SAD") && edge.contains("Inaccessible")) {
				data.setDoScan(false);
				data.setPeakEn(en1);
			}

		} else {
			String element = request.getParameter("element");
			String edgeName = request.getParameter("edge");
			if ((element != null) && (element.length() > 0) && (edgeName != null) && (edgeName.length() > 0)) {
				data.setEdge(element + "-" + edgeName, 0.0, 0.0);
			}
			String tmp = request.getParameter("peak");
			try {
			   if ((tmp != null) && (tmp.length() > 0)) {
				double peak = Double.parseDouble(tmp.trim());
				data.setPeakEn(peak);
			   }
			} catch (NumberFormatException e) {
				throw new Exception("Invalid peak energy " + tmp);
			}
			tmp = request.getParameter("inflection");
			try {
			   if ((tmp != null) && (tmp.length() > 0)) {
				double inflection = Double.parseDouble(tmp.trim());
				data.setInflectionEn(inflection);
			   }
			} catch (NumberFormatException e) {
				throw new Exception("Invalid inflection energy " + tmp);
			}
			tmp = request.getParameter("remote");
			try {
			   if ((tmp != null) && (tmp.length() > 0)) {
				double remote = Double.parseDouble(tmp.trim());
				data.setRemoteEn(remote);
			   }
			} catch (NumberFormatException e) {
				throw new Exception("Invalid remote energy " + tmp);
			}
						
		}
		
									
		String nextStep = request.getParameter("goto");
		WebiceLogger.info("ChooseExperiment: goto = " + nextStep);
		if (nextStep != null) {
			
			// Validate input if the user clicks "Next" button
			// Do not validate if "Prev"
			if (nextStep.equals("Next")) {
				if (data.getExpType().equals("MAD")) {
					if  (data.isDoScan()) {
						if (data.getEdge().name.length() == 0)
							throw new Exception("Edge must be selected");
						if (data.getEdge().en1 <= 0.0)
							throw new Exception("Invalid absorption edge energy");
				
						if (data.getEdge().en2 <= 0.0)
							throw new Exception("Invalid associated emission line energy");
					} else {
						// At this point all energies must be valid
						if ((data.getInflectionEn() <= 0.0) &&
							(data.getPeakEn() <= 0.0) &&
							(data.getRemoteEn() <= 0.0))
							throw new Exception("At least one energy must be set");
					}
				} else if (data.getExpType().equals("SAD")) {
					if  (data.isDoScan()) {
						if (data.getEdge().en1 <= 0.0)
							throw new Exception("Invalid absorption edge energy");
					} else {
						// Peak energy must be valid for SAD experiment
						if (data.getPeakEn() <= 0.0)
							throw new Exception("Peak energy must be set");
					}
				}
			}
				

			if (nextStep.equals("Next")) {
				controller.setSetupStep(RunController.SETUP_CHOOSE_OPTIONS);
			} else if (nextStep.equals("Prev")) {
				controller.setSetupStep(RunController.SETUP_CHOOSE_STRATEGY_OPTION);
			} else {
				// stay on the same page
				controller.setSetupStep(RunController.SETUP_CHOOSE_EXP);
				if (nextStep.equals("Load Scan File")) { // chosen scan file			
					if (!data.isDoScan() && (data.getExpType().equals("MAD") || data.getExpType().equals("SAD"))) {
					String scanDir = run.getScanDir();
					String scanFile = request.getParameter("scanFile");
					   if ((scanFile != null) && (scanFile.length() > 0)) {
					   
						Imperson imperson = client.getImperson();
					   	if (!imperson.fileExists(scanFile))
							throw new Exception("Scan file " + scanFile + " does not exist.");	
							
						int pos = scanFile.lastIndexOf("/");
						if (pos < 0)
							throw new Exception("Invalid scan summary file path " + scanFile);
						if (!scanFile.endsWith("summary"))
							throw new Exception("Invalid format for scan summary file name (must end with 'summary') "
									+ scanFile);

					   	run.setScanFile(scanFile);
						// read the 3 energies from file
						controller.parseScanSummaryFile(scanFile);
						
						// Copy scan files to run dir
						// <rootName>fp_fpp.bip
						// <rootName>raw_exp.bip
						// <rootName>scan
						// <rootName>smooth_exp.bip
						// <rootName>smooth_norm.bip
						// <rootName>summary
						String rootName = scanFile.substring(pos+1, scanFile.length()-7);

						String dir = run.getWorkDir() + "/scan";
						try {
						if (!imperson.dirExists(dir)) {
							imperson.createDirectory(dir);
							WebiceLogger.info("Created scan dir " + dir);
						}
						
						} catch (Exception e) {
							WebiceLogger.warn("Failed to create dir " + dir + " because " + e.getMessage());
							
						}
						
						StringBuffer warning = new StringBuffer();
						copyNoThrow(imperson, scanDir + "/" + rootName + "raw_exp.bip", 
								dir + "/" + run.getRunName() + "raw_exp.bip", warning);

						copyNoThrow(imperson, scanDir + "/" + rootName + "fp_fpp.bip", 
								dir + "/" + run.getRunName() + "fp_fpp.bip", warning);
								
						copyNoThrow(imperson, scanDir + "/" + rootName + "raw_exp.bip",
								dir + "/" + run.getRunName() + "raw_exp.bip", warning);
									
						copyNoThrow(imperson, scanDir + "/" + rootName + "scan", 
								dir + "/" + run.getRunName() + "scan", warning);
								
						copyNoThrow(imperson, scanDir + "/" + rootName + "smooth_exp.bip", 
								dir + "/" + run.getRunName() + "smooth_exp.bip", warning);
								
						copyNoThrow(imperson, scanDir + "/" + rootName + "smooth_norm.bip", 
								dir + "/" + run.getRunName() + "smooth_norm.bip", warning);
								
						copyNoThrow(imperson, scanFile, 
								dir + "/" + run.getRunName() + "summary", warning);
								
						if (warning.length() > 0) {
							warning.append("\nFlourescence Scan Plot and Fp-Fpp Plot may not be displayed correctly.");
							request.setAttribute("warning", warning.toString());
						}
						
					   } // if nextStep == Submit
					} // if !isDoScan
				}
			}
		}

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseExperiment: " + e.getMessage());
			request.setAttribute("error", e.getMessage());
		}
		

		return mapping.findForward("success");


	}
	
	private void copyNoThrow(Imperson imperson, String from, String to, StringBuffer warning)
	{
		try {
			WebiceLogger.info("Copying scan file from " + from + " to " + to + ".");
			imperson.copyFile(from, to);
		} catch (Exception e) {
			WebiceLogger.warn("Failed to copy file from " + from + " to " + to + ". Root cause: " + e.getMessage());
			if (warning.length() > 0)
				warning.append("\n");
			warning.append(e.getMessage());
		}
	}



}

