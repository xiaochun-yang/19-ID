package sil.controllers;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.web.servlet.ModelAndView;

public class AssignSilController extends UnlockableSilController
{
	// Affected sils must belong to this user or this user must have staff privilege.
	public ModelAndView view(HttpServletRequest request, HttpServletResponse response) throws Exception
	{

		String silIdStr = request.getParameter("silId");
		String beamlineIdStr = request.getParameter("beamlineId");
		String targetUrl = "redirect:/cassetteList.html";
				
		try {
		int beamlineId = Integer.parseInt(beamlineIdStr);
		int silId = Integer.parseInt(silIdStr);
		if (silId > 0) {
			// Make sure that this sil is unlocked.
			checkSilLocked(silId, targetUrl);
			if (beamlineId == 0)
				storageManager.unassignSil(silId, false/*forced*/);
			else
				storageManager.assignSil(silId, beamlineId, false/*forced*/);
		}
					
		} catch (NumberFormatException e) {
			// Do nothing
			logger.warn("assignSil: invalid silId (" + silIdStr + ") or beamlineId (" + beamlineIdStr + ")");
		}
				
		// Return redirect to stop user from resubmitting assignSil by 
		// clicking reload button in the browser.
		return new ModelAndView(targetUrl);
	}
	
}
