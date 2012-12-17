package sil.controllers;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.web.servlet.ModelAndView;

public class DeleteSilController extends UnlockableSilController
{
	// Sil Must be unlocked, unless it is forced.
	public ModelAndView view(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		String silIdStr = request.getParameter("silId");
		String targetUrl = "redirect:/cassetteList.html";
		try {
			int silId = Integer.parseInt(silIdStr);
			if (silId > 0) {
				checkSilLocked(silId, targetUrl);
				storageManager.deleteSil(silId);
			}
		} catch (NumberFormatException e) {
			// Ignore
			logger.warn("deleteSil: invalid silId parameter " + silIdStr);
		}
		
		return new ModelAndView(targetUrl);
	}

}
