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


public class ChooseDirAndImageNameAction extends Action
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
		
		if (!client.isConnectedToBeamline())
			throw new Exception("A beamline must be selected for this run in order to collect images.");
			
		DcsConnector dcs = client.getDcsConnector();
		if (!dcs.getBeamline().equals(data.getBeamline())) {
			throw new Exception("This run is setup for beamline " + data.getBeamline() 
				+ " Please select the correct beamline from the toolbar");
	 	}
		
		
		String dir = request.getParameter("dir");
		
		if ((dir == null) || (dir.length() == 0))
			throw new Exception("Invalid image directory path");
			
		dir = dir.trim();
		String defDir = ServerConfig.getUserImageRootDir(client.getUser());
		if (!dir.startsWith(defDir))
			throw new Exception("Image directory path for user " + client.getUser() 
						+ " must start with " + defDir);
		
		String rootName = request.getParameter("root");
				
		data.setImageDir(dir);
		viewer.setImageDir(dir);

		String nextStep = request.getParameter("goto");


		// Save user's property file because autoindex.dir has changed.
		try {
			client.saveProperties();
		} catch (Exception e) {
			WebiceLogger.warn("Failed to save user's property file because " + e.getMessage());
		}
		
		if ((rootName == null) || (rootName.length() == 0))
			throw new Exception("Invalid image root name");
			
		data.setImageRootName(rootName);
				
		if (nextStep != null) {
			if (nextStep.equals("Browse") || nextStep.equals("CreateDir")) {
				if (nextStep.equals("CreateDir")) {
					Imperson imperson = client.getImperson();
					if (!imperson.dirExists(dir))
						imperson.createDirectory(dir);
				}
				run.setShowFileBrowser(true);
			} else {
				run.setShowFileBrowser(false);
			}
			
			if (nextStep.equals("Next")) {
				controller.setSetupStep(RunController.SETUP_CHOOSE_STRATEGY_OPTION);
			} else if (nextStep.equals("Prev")) {
				if (data.isCollectImages()) {
					controller.setSetupStep(RunController.SETUP_CHOOSE_SAMPLE);
				} else {
					controller.setSetupStep(RunController.SETUP_CHOOSE_DIR);
				}
			}
		}

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseDirAndImageName: " + e.getMessage());
			request.getSession().setAttribute("error.autoindex", e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

