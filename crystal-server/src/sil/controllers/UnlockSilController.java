package sil.controllers;

import java.util.HashMap;
import java.util.Map;

import sil.managers.SilCacheManager;
import sil.managers.SilManager;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

public class UnlockSilController extends MultiActionController implements InitializingBean
{
	private SilCacheManager silCacheManager;

	public ModelAndView unlockSil(HttpServletRequest request, HttpServletResponse response)
	{
		String silId = request.getParameter("silId");
		String targetUrl = request.getParameter("targetUrl");
		Map model = new HashMap();
		model.put("silId", silId);
		model.put("targetUrl", targetUrl);
		return new ModelAndView("/silPages/unlockSilConfirm", model);	
	}

	public ModelAndView unlockSilConfirm(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		String silIdStr = request.getParameter("silId");
		String targetUrl = request.getParameter("targetUrl");
		if ((silIdStr != null) || (silIdStr.length() > 0)) {
			int silId = Integer.parseInt(silIdStr);
			if (silId > 0) {
				SilManager silManager = silCacheManager.getSilManager(silId);
				silManager.unlockSil();
			}
		}
		
		return new ModelAndView("redirect:/" + targetUrl);	
	}

	public void afterPropertiesSet() throws Exception {
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' property for CassetteListController bean");
	}

	public SilCacheManager getSilCacheManager() {
		return silCacheManager;
	}

	public void setSilCacheManager(SilCacheManager silCacheManager) {
		this.silCacheManager = silCacheManager;
	}

}
