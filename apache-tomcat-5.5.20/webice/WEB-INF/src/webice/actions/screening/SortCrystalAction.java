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


public class SortCrystalAction extends Action
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

		String column = viewer.getSortColumn();
		String direction = viewer.getSortOrder();
		
		String newColumn = request.getParameter("column");
		if (newColumn == null)
			newColumn = "Port";
			
		String newDirection = direction;
		if (newColumn.equals(column)) {
			// Reverse direction
			if (direction.equals("ascending"))
				newDirection = "descending";
			else if (direction.equals("descending"))
				newDirection = "ascending";
		}
		
		viewer.sortSil(newColumn, newDirection);

		return mapping.findForward("success");

	}



}

