/**
 * Javabean for SMB resources
 */
package webice.actions.autoindex;

import java.util.*;
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


public class ChooseDirAndImagesAction extends Action
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

		String dir = request.getParameter("dir");
		
		if ((dir != null) && (dir.length() > 0)) {
		
			if (!client.getImperson().dirExists(dir))
				throw new Exception("Image directory " + dir + " does not exist.");
		
			data.setImageDir(dir);
			viewer.setImageDir(dir);
			
			// Save user's property file because autoindex.dir has changed.
			try {
				client.saveProperties();
			} catch (Exception e) {
				WebiceLogger.warn("Failed to save user's property file because " + e.getMessage());
			}
		}

		String nextStep = request.getParameter("goto");
		if ((nextStep != null) && nextStep.equals("Browse")) {
			run.setShowFileBrowser(true);
			return mapping.findForward("success");
		}
				
		
		String image1 = request.getParameter("image1");
		String image2 = request.getParameter("image2");
					
		if ((image1 == null) || (image1.length() == 0)) {
			request.setAttribute("error", "Please select image1");
			return mapping.findForward("error"); // do not move to next or prev page
		}
		
		if ((image2 == null) || (image2.length() == 0)) {
			request.setAttribute("error", "Please select image2");
			return mapping.findForward("error"); // do not move to next or prev page
		}
			
		controller.setImages(image1, image2);

/*		if (run.getShowFileBrowser()) {
				
			Object files[] = viewer.getFileBrowser().getFileNames();

			controller.clearImages();

			controller.resetLog();

			String file = null;
			Vector selectedFiles = new Vector();
			for (int i = 0; i < files.length; ++i) {
			    file = (String)files[i];
			    if (request.getParameter(file) != null)
				selectedFiles.add(file);
			}

			if (selectedFiles.size() == 2) {
			    controller.setImages((String)selectedFiles.elementAt(0),
						(String)selectedFiles.elementAt(1));
			    // Done with the file selection
			    run.setShowFileBrowser(false);
			} else {
			    request.setAttribute("error", "Please select 2 images");
			    return mapping.findForward("error"); // do not move to next or prev page
			}

	        } else {
			String image1 = request.getParameter("image1");
			String image2 = request.getParameter("image2");
					
			if ((image1 == null) || (image1.length() == 0)) {
			    request.setAttribute("error", "Please select image1");
			    return mapping.findForward("error"); // do not move to next or prev page
			}
		
			if ((image2 == null) || (image2.length() == 0)) {
			    request.setAttribute("error", "Please select image2");
			    return mapping.findForward("error"); // do not move to next or prev page
			}
			
			controller.setImages(image1, image2);
		}
*/

		if (nextStep != null) {
		
			
		
			if (nextStep.equals("Browse")) {
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
			WebiceLogger.error("Caught exception in ChooseDirAndImages: " + e.getMessage());
			request.setAttribute("error", e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

