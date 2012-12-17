/**
 * Javabean for SMB resources
 */
package webice.actions.strategy;

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
import webice.beans.strategy.*;


public class ShowImageAction extends Action
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


		StrategyViewer top = client.getStrategyViewer();

		if (top == null)
			throw new ServletException("StrategyViewer is null");

		LabelitNode node = (LabelitNode)top.getSelectedNode();

		if (node == null)
			throw new ServletException("Selected node is null");

//		String imageFile = request.getParameter("image");

		ImageForm form = (ImageForm)f;

		String imageFile  = form.getFile();
		String type = form.getType();
		int width = form.getWidth();

		if (imageFile == null)
			throw new ServletException("Form parameter file is null");

		if (type == null)
			throw new ServletException("Form parameter type is null");

		node.setImage(imageFile);
		node.setImageType(type);
		node.setImageWidth(width);
		node.setImageHeight(width);

		return mapping.findForward("success");


	}



}

