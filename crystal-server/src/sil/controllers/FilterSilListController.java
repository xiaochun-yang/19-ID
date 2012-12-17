package sil.controllers;

import sil.app.SilAppSession;
import sil.beans.util.SilListFilter;
import ssrl.authClient.spring.AppSessionManager;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

public class FilterSilListController extends MultiActionController implements InitializingBean
{
	private AppSessionManager appSessionManager;	
			
	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public ModelAndView firstPage(HttpServletRequest request, HttpServletResponse response)
	{
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		appSession.setPageNumber(0);
		return new ModelAndView("redirect:/cassetteList.html");	
	}
	
	public ModelAndView prevPage(HttpServletRequest request, HttpServletResponse response)
	{
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);	
		appSession.setPageNumber(appSession.getPageNumber() - 1);
		return new ModelAndView("redirect:/cassetteList.html");	
	}
	
	public ModelAndView nextPage(HttpServletRequest request, HttpServletResponse response)
	{
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		appSession.setPageNumber(appSession.getPageNumber() + 1);
		return new ModelAndView("redirect:/cassetteList.html");	
	}
	
	public ModelAndView lastPage(HttpServletRequest request, HttpServletResponse response)
	{
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		appSession.setPageNumber(100000); // big number
		return new ModelAndView("redirect:/cassetteList.html");	
	}
	
	public ModelAndView filterSilList(HttpServletRequest request, HttpServletResponse response)
	{
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		String search = request.getParameter("search");
		if (search != null) {
			String type = request.getParameter("filterType");
			String wildcard = request.getParameter("wildcard");
			if (wildcard != null)
				wildcard = wildcard.trim();
			if (type.equals(SilListFilter.FULL_LIST))
				wildcard = null;
			appSession.getSilListFilter().setFilterType(type);
			appSession.getSilListFilter().setWildcard(wildcard);
		}
		return new ModelAndView("redirect:/cassetteList.html");	
	}


	public void afterPropertiesSet() throws Exception {
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' property for CassetteListController bean");
	}
}
