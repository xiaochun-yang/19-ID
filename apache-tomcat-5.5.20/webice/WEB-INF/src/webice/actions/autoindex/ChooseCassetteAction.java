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


public class ChooseCassetteAction extends Action
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
		
			String temp = request.getParameter("index");
			if ((temp == null) || (temp.length() == 0))
				throw new Exception("Missing index parameter");
			int index = Integer.parseInt(temp);
			
			if (index != data.getCassetteIndex())
				data.setCrystalPort("");
			
			data.setCassetteIndex(index);
			data.setMountSample(true);
			run.setShowCassetteBrowser(true);
		
			
		} catch (Exception e) {
			WebiceLogger.error("Caught exception in ChooseSample: " + e.getMessage(), e);
			request.setAttribute("error", e.getMessage());
		}
		

		return mapping.findForward("success");


	}



}

