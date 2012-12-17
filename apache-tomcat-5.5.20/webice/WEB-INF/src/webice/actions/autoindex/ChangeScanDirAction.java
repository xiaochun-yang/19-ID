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


public class ChangeScanDirAction extends Action
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
		
			String scanDir = request.getParameter("dir");
			if ((scanDir != null) && (scanDir.length() != 0)) {
				// Remove /.. in the path
				String cleanedDir = cleanDir(scanDir);
				if (!cleanedDir.equals(scanDir))
					WebiceLogger.info("ChangeScanDir: replace dir " + scanDir + " with " + cleanedDir);
				run.setScanDir(cleanedDir);
			}
		

		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseExperiment: " + e.getMessage(), e);
			request.setAttribute("error", " Cannot change scan directory. Root cause: " + e.getMessage());
		}
		

		return mapping.findForward("success");


	}

	private String cleanDir(String s)
		throws Exception
	{
		int pos = s.indexOf("/..");
		if (pos == 0)
			throw new Exception("Invalid scan directory");
		if (pos < 0)
			return s;
		
		int pos1 = pos-1;			
		while (pos1 > -1) {
			if (s.charAt(pos1) == '/')
				break;
			--pos1;
		}
		return s.substring(0, pos1) + s.substring(pos+3);
	}


}

