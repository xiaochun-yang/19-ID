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

public class AdjustImageAction extends Action
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

		String action = (String)request.getParameter("action");
		String amountStr = (String)request.getParameter("amount");

		if (action == null)
			throw new ServletException("request parameter, action, is null");
		if (amountStr == null)
			throw new ServletException("request parameter, amount, is null");


		try {

		if (action.equals("darker")) {
			int amount = Integer.parseInt(amountStr);
			viewer.setDarker(amount);
		} else if (action.equals("lighter")) {
			int amount = Integer.parseInt(amountStr);
			viewer.setLighter(amount);
		} else if (action.equals("setGrayScale")) {
			int amount = Integer.parseInt(amountStr);
			viewer.setGray(amount);
		} else if (action.equals("panUp")) {
			double amount = Double.parseDouble(amountStr);
			viewer.setPanUp(amount);
		} else if (action.equals("panDown")) {
			double amount = Double.parseDouble(amountStr);
			viewer.setPanDown(amount);
		} else if (action.equals("panLeft")) {
			double amount = Double.parseDouble(amountStr);
			viewer.setPanLeft(amount);
		} else if (action.equals("panRight")) {
			double amount = Double.parseDouble(amountStr);
			viewer.setPanRight(amount);
		} else if (action.equals("center")) {
			viewer.setCenter();
		} else if (action.equals("zoomOut")) {
			double amount = Double.parseDouble(amountStr);
			viewer.setZoomOut(amount);
		} else if (action.equals("zoomIn")) {
			double amount = Double.parseDouble(amountStr);
			viewer.setZoomIn(amount);
		} else if (action.equals("setZoom")) {
			double amount = Double.parseDouble(amountStr);
			viewer.setZoom(amount);
		} else if (action.equals("resize")) {
			int amount = Integer.parseInt(amountStr);
//			viewer.setWidth(amount);
//			viewer.setHeight(amount);
			viewer.setImageSize(amount, amount);
			return mapping.findForward("resize");
		}


		} catch (NumberFormatException e) {
			throw new ServletException(e);
		}
				
		return mapping.findForward("success");

	}



}

