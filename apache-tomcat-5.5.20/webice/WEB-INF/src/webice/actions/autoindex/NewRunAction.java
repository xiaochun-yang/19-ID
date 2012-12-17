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


public class NewRunAction extends Action
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
			
		viewer.setDisplayMode(AutoindexViewer.CREATE_RUN);
//		viewer.setShowSample(false);

		if (request.getParameter("cancel") != null) {
			viewer.setShowMountedCrystal(false);
			return mapping.findForward("success");
		}
			
		String runName = request.getParameter("name");
		if ((runName == null) || (runName.length() == 0)) {
			request.getSession().setAttribute("error.newRun", "Failed to create run: Invalid run name");
			return mapping.findForward("error");
		}
		
		String type = request.getParameter("type");
		if ((type == null) || (type.length() == 0))
			type = AutoindexViewer.RUN_TYPE_AUTOINDEX;
		
		String beamline = "default";
		DcsConnector dcs = client.getDcsConnector();
		if (client.isConnectedToBeamline() && (dcs != null))
			beamline = dcs.getBeamline();
		if (type.equals(AutoindexViewer.RUN_TYPE_COLLECT) && beamline.equals("default"))
			throw new Exception("Cannot select 'Collect 2 image and autoindex' run type. Please select a beamline first.");
		
		try {
			viewer.setDisplayMode(AutoindexViewer.CREATE_RUN);
			
			String runDir = request.getParameter("runDir");
			if ((runDir != null) && (runDir.length() > 0))
				viewer.importRun(runName, runDir);
			else
				viewer.createRun(runName, type);
			
			if (type.equals(AutoindexViewer.RUN_TYPE_COLLECT)) {
				AutoindexRun run = viewer.getSelectedRun();
				RunController controller = run.getRunController();
				AutoindexSetupData data = controller.getSetupData();
				data.setBeamline(beamline);
			}
			
			viewer.setDisplayMode(AutoindexViewer.ONE_RUN);	
			
		} catch (Exception e) {
			request.getSession().setAttribute("error.newRun", "Failed to create run: " + e.getMessage());
			return mapping.findForward("error");
		}

		return mapping.findForward("success");

	}



}

