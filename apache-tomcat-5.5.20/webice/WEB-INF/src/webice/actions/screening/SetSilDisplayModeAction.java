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


public class SetSilDisplayModeAction extends Action
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


		String displayMode = request.getParameter("mode");
		if ((displayMode != null) && (displayMode.length() > 0))
			viewer.setDisplayMode(displayMode);

		if (displayMode.equals(ScreeningViewer.DISPLAY_ALLSILS)) {
			String type = request.getParameter("type");
			if ((type != null) && (type.length() > 0))
				viewer.setCurSilListDisplay(type);
				
			// Sorting
			String sortColumn = request.getParameter("sortColumn");
			String sortDirection = request.getParameter("sortDirection");
			String sortType = request.getParameter("sortType");
			if ((sortColumn != null) && (sortColumn.length() > 0))
				viewer.setSilListSortColumn(sortColumn);
			// toggle
			if (sortDirection != null) {
				if (sortDirection.equals("ascending"))
					viewer.setSilListSortAscending(false);
				else if (sortDirection.equals("descending"))
					viewer.setSilListSortAscending(true);
			}
						
			if ((sortType != null) && (sortType.length() > 0))
				viewer.setSilListSortType(sortType);
				
		} else if (displayMode.equals(ScreeningViewer.DISPLAY_OVERVIEW) ||
			   displayMode.equals(ScreeningViewer.DISPLAY_DETAILS)) {
			String silId = request.getParameter("silId");				
			if ((silId != null) && (silId.length() > 0) && !silId.equals(viewer.getSilId())) {
				String owner = request.getParameter("owner");
				try {
				viewer.loadSil(silId, false, owner);
				} catch (Exception e) {
					if (e.getMessage().contains("no data found")) {
						request.getSession().setAttribute("error.screening", 
							"Cassette ID " + silId + " does not exist or may have been deleted.");
					} else {
						request.getSession().setAttribute("error.screening", e.getMessage());
					}
					return mapping.findForward("error");
				}
				
				String rowStr = request.getParameter("row");
				if ((rowStr != null) && (rowStr.length() > 0)) {
					try {
						int rowInt = Integer.parseInt(rowStr);
						viewer.selectCrystal(rowInt);
					} catch (NumberFormatException e) {
						// Ignore
					}
				}
			}
		}
		
		return mapping.findForward("success");

	}



}

