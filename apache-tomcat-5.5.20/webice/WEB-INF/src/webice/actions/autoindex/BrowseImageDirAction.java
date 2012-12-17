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


public class BrowseImageDirAction extends Action
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
			throw new ServletException("No run is selected");

		RunController controller = run.getRunController();

		controller.resetLog();

		run.setShowFileBrowser(true);

		FileBrowser fileBrowser = viewer.getFileBrowser();

		if (fileBrowser == null)
			throw new ServletException("FileBrowser is null");

		AutoindexSetupData setupData = controller.getSetupData();

		String dir = request.getParameter("dir");
		String filter = request.getParameter("wildcard");


		if ((dir != null) && (dir.length() > 0)) {
//			WebiceLogger.debug("before dir = " + dir);
			int pos = dir.indexOf("/..");
			if (pos == dir.length()-3) {
				dir = dir.substring(0, pos);
				pos = dir.lastIndexOf("/");
				if (pos > 0)
					dir = dir.substring(0, pos);
			}
//			WebiceLogger.debug("after dir = " + dir);
			setupData.setImageDir(dir);
		}

		setupData.setImageFilter(filter);


		try {

			// Retrieve subdirectories
			fileBrowser.changeDirectory(setupData.getImageDir(),
										setupData.getImageFilter());

		} catch (Exception e) {
			request.setAttribute("error.imageBrowser",
								"Failed to browse directory "
								+ setupData.getImageDir()
								+ ": " + e.getMessage());
		}

		return  mapping.findForward("success");


	}



}

