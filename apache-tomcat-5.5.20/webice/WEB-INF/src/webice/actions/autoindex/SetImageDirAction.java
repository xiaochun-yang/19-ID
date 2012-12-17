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


public class SetImageDirAction extends Action
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


		AutoindexViewer top = client.getAutoindexViewer();

		if (top == null)
			throw new ServletException("AutoindexViewer is null");

		AutoindexRun run = top.getSelectedRun();
		RunController controller = run.getRunController();

		if (controller.getStatus() > RunController.SETUP) {
			controller.appendLog("ERROR: setup cannot be modified");
			return mapping.findForward("success");
		}

		String dir = request.getParameter("dir");
		AutoindexSetupData setupData = controller.getSetupData();

		if ((dir == null) || (dir.length() == 0)) {
			controller.setLog("invalid image directory.");
		} else {
			setupData.setImageDir(dir);

		}

		run.setShowFileBrowser(false);

		return mapping.findForward("success");


	}



}

