/**
 * Javabean for SMB resources
 */
package webice.actions.screening;

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
import webice.beans.screening.*;


public class LoadSilAction extends Action
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

		ScreeningViewer viewer = client.getScreeningViewer();

		if (viewer == null)
			throw new ServletException("ScreeningViewer is null");

		String silId = request.getParameter("silId");
		String mode = request.getParameter("mode");
		
		String tmp = request.getParameter("row");
		int row = 0;
		if (tmp != null) {
			try {
				row = Integer.parseInt(tmp);
			} catch (NumberFormatException e) {
			}
		}

		String owner = request.getParameter("owner");
		

		try {

			// Do not force reload if the sil is already loaded
			if ((silId != null) && (silId.length() > 0) && !silId.equals(viewer.getSilId())) {
				viewer.loadSil(silId, false, owner);
			}
		} catch (Exception e) {
			WebiceLogger.error("Failed to load sil " + silId, e);
			return mapping.findForward("failed");
		}
		
		if (row > 0)
			viewer.selectCrystal(row);

		if ((mode != null) && (mode.length() > 0))
			viewer.setDisplayMode(mode);
			
		return mapping.findForward("success");

	}



}

