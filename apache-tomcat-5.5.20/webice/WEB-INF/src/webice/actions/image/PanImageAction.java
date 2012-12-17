/**
 * Javabean for SMB resources
 */
package webice.actions.image;

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
import webice.beans.image.*;


public class PanImageAction extends Action
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

		ImageViewer viewer = client.getImageViewer();

		if (viewer == null)
			throw new ServletException("ImageViewer is null");

/*		String x = request.getParameter("fullImage.x");
		String y = request.getParameter("fullImage.y");
		String str = x + "," + y;
		String xt = request.getParameter("thumbnail.x");
		String yt = request.getParameter("thumbnail.y");
		String strt = xt + "," + yt;

		if ((x != null) && (y != null)) {
			viewer.setCenterStr(str);
		}
		if ((xt != null) && (xt != null)) {
			viewer.setThumbnailCenterStr(strt);
		}*/

		String query = request.getQueryString();

		if (query == null)
			throw new ServletException("Request query is null");

		viewer.setCenterStr(query);


		return mapping.findForward("success");

	}



}

