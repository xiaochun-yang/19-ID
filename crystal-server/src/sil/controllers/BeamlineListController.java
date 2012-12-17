package sil.controllers;

import sil.app.SilAppSession;
import sil.beans.BeamlineInfo;
import sil.managers.SilStorageManager;
import ssrl.authClient.spring.AppSessionManager;
import velocity.tools.generic.NullTool;

import java.util.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

public class BeamlineListController extends MultiActionController implements InitializingBean
{
	private AppSessionManager appSessionManager;
	private SilStorageManager storageManager;
	
	// Default view
	public ModelAndView view(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{
		SilAppSession appSession = getSilAppSession(request);
		appSession.setView(SilAppSession.BEAMLINELIST_VIEW);
		Map model = new HashMap();
		fillModel(appSession, model);
		
		return new ModelAndView("/silPages/beamlineList", model);		
	}
	
	/*
	 * Save this session states and data retrieved from DB in model.
	 */
	protected ModelAndView fillModel(SilAppSession appSession, Map model)
	{
		model.put("nullTool", new NullTool());
		
		// List beamlines that are accessible by this user.
		List beamlineList = storageManager.getBeamlineList();
		List userBeamlineList = filterBeamlineList(appSession, beamlineList);
		model.put("beamlineList", userBeamlineList);
			
		return new ModelAndView("/silPages/beamlineList", model);
	}
	
	private List filterBeamlineList(SilAppSession appSession, List beamlineList)
	{
		List ret = new ArrayList();
		Iterator it = beamlineList.iterator();
		while (it.hasNext()) {
			BeamlineInfo bl = (BeamlineInfo)it.next();
			if (appSession.hasAccessToBeamline(bl.getName())) {
				ret.add(bl);
			}
		}
		
		return ret;
	}

	protected SilAppSession getSilAppSession(HttpServletRequest request) {
		return (SilAppSession)appSessionManager.getAppSession(request);
	}
	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public void afterPropertiesSet() throws Exception {
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' property for CassetteListController bean");
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for CassetteListController bean");
		
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

}
