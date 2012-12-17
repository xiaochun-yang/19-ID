package sil.controllers;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.web.servlet.ModelAndView;

public class UnassignSilController extends UnlockableSilController
{
	// Affected sils must belong to this user or this user must have staff privilege.
	public ModelAndView view(HttpServletRequest request, HttpServletResponse response) throws Exception
	{

		String targetUrl = "redirect:/beamlineList.html";
		String silIdStr = request.getParameter("silId");
				
		try {
		int silId = Integer.parseInt(silIdStr);
		if (silId > 0) {
			// Make sure that this sil is unlocked.
			checkSilLocked(silId, targetUrl);
			storageManager.unassignSil(silId, false);
		}
					
		} catch (NumberFormatException e) {
			// Do nothing
			logger.warn("unassignSil: invalid silId (" + silIdStr + ")");
		}
				
		// Return redirect to stop user from resubmitting assignSil by 
		// clicking reload button in the browser.
		return new ModelAndView(targetUrl);
	}
	
}
