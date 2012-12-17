/**
 * Javabean for SMB resources
 */
package webice.actions.screening;

import java.net.*;
import java.io.*;
import java.util.*;
import java.text.*;

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
import webice.beans.screening.*;
import webice.beans.autoindex.*;


public class ViewStrategyAction extends Action
{
	FileWriter logWriter = null;

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{
		try {


		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		ScreeningViewer sViewer = client.getScreeningViewer();
		AutoindexViewer aViewer = client.getAutoindexViewer();

		if (sViewer == null)
			throw new ServletException("ScreeningViewer is null");
		if (aViewer == null)
			throw new ServletException("AutoindexViewer is null");
		
		int row = sViewer.getSelectedRow();
		if (row < 0)
			throw new Exception("no crystal is selected");

		String port = sViewer.getSelectedCrystalPort();
		if ((port == null) || (port.length() == 0))
			throw new Exception("The selected row (" + (row+1) + ") has empty Port field");
		
		String crystalId = sViewer.getSelectedCrystalID();
		if ((crystalId == null) || (crystalId.length() == 0))
			throw new Exception("The selected row (" + (row+1) + ") has empty crystalId field");
		
		String image = sViewer.getImageFile();
		if ((image == null) || (image.length() == 0))
			throw new Exception("The selected row (" + (row+1) + ") has no image.");
		String dir = sViewer.getAutoindexDir();
		if ((dir == null) || (dir.length() == 0))
			throw new Exception("The selected row (" + (row+1) 
				+ ") has empty autoindex dir. "
				+ "There is probably no autoindex result for this crystal");
		
		
		// Import the autoindex & strategy result into a run.
		aViewer.importRun(sViewer.getSilId(), port, crystalId, dir);
		// Switch to the Autoindex tab
		client.setTab("autoindex");
		
		AutoindexRun run = aViewer.getSelectedRun();
		RunController controller = run.getRunController();
		if (controller.isRunning()) {
			aViewer.selectRunTab("setup");
		}

		} catch (Exception e) {
			WebiceLogger.error("Exception in ViewStrategyAction: " + e.getMessage());
			request.getSession().setAttribute("error.viewStrategy", e.getMessage());
			return mapping.findForward("error");
		}

		return mapping.findForward("success");

	}


}

