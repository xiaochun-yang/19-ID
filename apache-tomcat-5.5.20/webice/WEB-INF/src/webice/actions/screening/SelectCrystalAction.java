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


public class SelectCrystalAction extends Action
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

		String row = request.getParameter("row");

		int rowInt = -1;

		int scrollX = -1;
		int scrollY = -1;
		
		try {

		rowInt = Integer.parseInt(row);
		
		String x = request.getParameter("scrollX");
		String y = request.getParameter("scrollY");
		if ((x != null) && (x.length() > 0))
			scrollX = Integer.parseInt(x.trim());
		if ((y != null) && (y.length() > 0))
			scrollY = Integer.parseInt(y.trim());
			
		if ((scrollX > -1) && (scrollY > -1))
			viewer.setScroll(scrollX, scrollY);

		} catch (NumberFormatException e) {
			rowInt = -1;
		}
		

		viewer.selectCrystal(rowInt);

		return mapping.findForward("success");

	}



}

