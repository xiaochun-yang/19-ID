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


public class LoadRelativeImageAction extends Action
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


		LoadImageForm form = (LoadImageForm)f;

		if (form == null)
			throw new ServletException("LoadImageForm is null");

		String which = form.getFile();

		String file = viewer.getImageFile();

		// File name is [alphanum]_NNN.[alphanum] where NNN is a number from 1 to 999
		// prefixed with 0s to make up three letters such as 001, 015 and 173.
		// Here we try to extract NNN from the file name.
		String name = "";
		int pos = file.lastIndexOf('_');
		int pos2 = -1;
		if (pos >= 0) {
			pos2 = file.lastIndexOf('.');
			if (pos2 >= 0) {
				name = file.substring(pos+1, pos2);
			}
		}

		String status = "success";

		// File name does not in the expected format
		if (name.length() == 0) {
//			return mapping.findForward(status);
			throw new ServletException("Invalid filename: " + file);
		}

		int num;
		try {
			num = Integer.parseInt(name);
		} catch (NumberFormatException e) {
//			return mapping.findForward(status);
			throw new ServletException("Invalid filename index: " + name);
		}

		if (which.equals("previous")) {
			if (num > 1)
				--num;
		} else if (which.equals("next")) {
			if (num < 998)
				++num;
		} else {
			throw new ServletException("Invalid relative file: " + which);
		}

		// Put the name back together
		String newFile = file.substring(0, pos+1);
		if (num < 10)
			newFile += "00";
		else if (num < 100)
			newFile += "0";

		newFile += String.valueOf(num) + file.substring(pos2);

		viewer.setImageFile(newFile);

		return mapping.findForward(status);

	}



}

