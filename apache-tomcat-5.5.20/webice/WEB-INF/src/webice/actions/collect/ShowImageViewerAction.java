/**
 * Javabean for SMB resources
 */
package webice.actions.collect;

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
import webice.beans.collect.*;
import webice.beans.image.*;


public class ShowImageViewerAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm form,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{
		try {

		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		CollectViewer viewer = client.getCollectViewer();
		
		if (viewer == null)
			throw new Exception("CollectViewer is null");
			
		String file = viewer.getLastImageCollected();
		
		ImageViewer imgViewer = client.getImageViewer();
				
		imgViewer.setImageFile(file);
		
		client.setTab("image");

		if (imgViewer == null)
			throw new Exception("ImageViewer is null");
			
		} catch (Exception e) {
			WebiceLogger.warn("Error in ShowImageViewerAction: " + e.getMessage());
		}

		return mapping.findForward("success");
		

	}



}

