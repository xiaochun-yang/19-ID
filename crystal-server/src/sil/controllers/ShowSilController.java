package sil.controllers;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import sil.app.SilAppSession;
import sil.beans.ColumnData;
import sil.beans.Crystal;
import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalWrapper;
import sil.io.ColumnLoader;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import ssrl.authClient.spring.AppSessionManager;
import velocity.tools.generic.NullTool;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

public class ShowSilController extends MultiActionController implements InitializingBean
{
	private Log log = LogFactory.getLog(getClass());
	private SilCacheManager silCacheManager;
	private AppSessionManager appSessionManager;

	public void afterPropertiesSet()
		throws Exception 
	{
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' propety for EditSilController bean");
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' propety for EditSilController bean");
	}
	
	// Default view if 'method' is not recognized.
	public ModelAndView view(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{	
		return show(request, response);
	}
	
	// Default view if 'method' is not recognized.
	public ModelAndView show(HttpServletRequest request, HttpServletResponse response)
	{	
		try {
			
		SilAppSession appSession = getSilAppSession(request);
		
		String silIdStr = request.getParameter("silId");
		int silId = -1;
		if ((silIdStr == null) || (silIdStr.length() == 0)) {
			silId = appSession.getSilId();
		} else {
			try {
				silId = Integer.parseInt(silIdStr);
				appSession.setSilId(silId);
//				appSession.setRow(-1);
				appSession.setUniqueId(0);
			} catch (NumberFormatException e) {
				throw new Exception("Invalid silId");
			}
		}

		if (silId <= 0)
			throw new Exception("no sil has been selected");
		
		return makeModelAndView(appSession);
		
		} catch (Exception e) {
			return gotoErrorPage(e);
		}

	}
	
	private ModelAndView gotoErrorPage(Exception e) {
		Map model = new HashMap();
		model.put("error", e.getMessage());
		logger.error("Cannot showSil. Root cause: " + e.getMessage());
		return new ModelAndView("errorViews/showSilError", model);		
	}

	public ModelAndView selectCrystal(HttpServletRequest request, HttpServletResponse response)
	{		
		try {
		SilAppSession appSession = getSilAppSession(request);
		
/*		String rowStr = request.getParameter("row");
		int row = appSession.getRow();
		if ((rowStr != null) && (rowStr.length() > 0)) {
			try {
				row = Integer.parseInt(rowStr);
				appSession.setRow(row);
			} catch (NumberFormatException e) {
				// ignore
			}
		}
		if (appSession.getRow() < 0)
			throw new Exception("no crystal has been selected");*/
		
		String uniqueIdStr = request.getParameter("uniqueId");
		long uniqueId = appSession.getUniqueId();
		if ((uniqueIdStr != null) && (uniqueIdStr.length() > 0)) {
			try {
				uniqueId = Long.parseLong(uniqueIdStr);
				appSession.setUniqueId(uniqueId);
			} catch (NumberFormatException e) {
				// ignore
			}
		}
		if (appSession.getUniqueId() < 1)
			throw new Exception("no crystal has been selected");
		
		return gotoShowSilPage();
		
		} catch (Exception e) {
			return gotoErrorPage(e);
		}
	}
	
	private ModelAndView gotoShowSilPage() {
		return new ModelAndView("redirect:/showSil.html");	
	}

	public ModelAndView setDisplayType(HttpServletRequest request, HttpServletResponse response)
	{	
		try {
			
		SilAppSession appSession = getSilAppSession(request);
		
		String displayType = request.getParameter("displayType");
		if ((displayType == null) || (displayType.length() == 0))
			displayType = appSession.getDisplayType();
		else
			appSession.setDisplayType(displayType);
		if ((displayType == null) || (displayType.length() == 0))
			throw new Exception("no displayType has been selected");
		
		return gotoShowSilPage();
		
		} catch (Exception e) {
			return gotoErrorPage(e);
		}
	}
		
	public ModelAndView setImageDisplayType(HttpServletRequest request, HttpServletResponse response)
	{
		try {
			
		SilAppSession appSession = getSilAppSession(request);

		String imageDisplayType = request.getParameter("imageDisplayType");
		if ((imageDisplayType == null) || (imageDisplayType.length() == 0))
			imageDisplayType = appSession.getDisplayType();
		else
			appSession.setImageDisplayType(imageDisplayType);
		if ((imageDisplayType == null) || (imageDisplayType.length() == 0))
			throw new Exception("no imageDisplayType has been selected.");
		
		return gotoShowSilPage();
		} catch (Exception e) {
			return gotoErrorPage(e);
		}
	}
	
	public ModelAndView sort(HttpServletRequest request, HttpServletResponse response)
	{
		try {
			
		SilAppSession appSession = getSilAppSession(request);
	
		// sortBy
		String sortBy = request.getParameter("sortBy");
		if ((sortBy == null) || (sortBy.length() == 0))
			sortBy = appSession.getSortBy();
		else
			appSession.setSortBy(sortBy);
		if ((sortBy == null) || (sortBy.length() == 0)) {
			sortBy = "row";
			appSession.setSortBy(sortBy);
		}
		
		// sortDirection
		String sortDirection = request.getParameter("sortDirection");
		if ((sortDirection == null) || (sortDirection.length() == 0))
			sortDirection = appSession.getSortDirection();
		else
			appSession.setSortDirection(sortDirection);
		if ((sortDirection == null) || (sortDirection.length() == 0)) {
			sortDirection = SilAppSession.ASCENDING;
			appSession.setSortDirection(sortDirection);
		}	
		
		return gotoShowSilPage();
		
		} catch (Exception e) {
			return gotoErrorPage(e);
		}
	}
	
	private ModelAndView makeModelAndView(SilAppSession appSession) throws Exception {
		if (appSession.getSilId() < 1)
			return new ModelAndView("redirect:/cassetteList.html");
		Map<String, Object> model = makeModel(appSession);
		return new ModelAndView("/silPages/sil", model);

	}
	
	private Map<String, Object> makeModel(SilAppSession appSession)
		throws Exception 
	{		
		
		int silId = appSession.getSilId();
//		int row = appSession.getRow();
		long uniqueId = appSession.getUniqueId();
		String sortBy = appSession.getSortBy();
		String sortDirection = appSession.getSortDirection();
		
		SilManager silManager = getSilCacheManager().getOrCreateSilManager(silId);
		
		String templateFile = getTemplatePath() + "/column_" + appSession.getDisplayType() + ".txt";
		List<ColumnData> columnData = ColumnLoader.load(templateFile);
					
		boolean ascending = true;
		if (sortDirection.equals(SilAppSession.DESCENDING))
			ascending = false;
		
		// Can actually sort more than one fields
		ArrayList<String> sortFields = new ArrayList<String>();
		sortFields.add(sortBy);
		
		logger.debug("sortBy = " + sortBy + " ascending = " + ascending);
		Collection sortedCrystals = silManager.sortCrystalByProperties(sortFields, ascending);
		
		Iterator it = sortedCrystals.iterator();
		ArrayList<CrystalWrapper> crystalWrappers = new ArrayList<CrystalWrapper>();
		while (it.hasNext()) {
			Crystal crystal = (Crystal)it.next();
			CrystalWrapper wrapper = (CrystalWrapper)getApplicationContext().getBean("crystalWrapper");
			wrapper.setCrystal(crystal);
			crystalWrappers.add(wrapper);
		}
												
		Map<String, Object> model = new HashMap<String, Object>();
		model.put("sil", silManager.getSil());
		model.put("columnNames", columnData);
		model.put("displayType", appSession.getDisplayType());
		model.put("imageDisplayType", appSession.getImageDisplayType());
		model.put("crystals", crystalWrappers);
		model.put("formatter", new String());
		model.put("sortBy", sortBy);
		model.put("sortDirection", sortDirection);
//		model.put("row", row);
		model.put("uniqueId", uniqueId);
		model.put("nullTool", new NullTool());
		model.put("crystalUtil", new CrystalUtil());
		model.put("staff", appSession.getAuthSession().getStaff());

		return model;	
	}
	
	private String getTemplatePath()
		throws IOException
	{
		return getApplicationContext().getResource("/WEB-INF/templates").getFile().getPath();
	}


	public SilCacheManager getSilCacheManager() {
		return silCacheManager;
	}

	public void setSilCacheManager(SilCacheManager silCacheManager) {
		this.silCacheManager = silCacheManager;
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}
	
	private SilAppSession getSilAppSession(HttpServletRequest request)
	{
		return (SilAppSession)appSessionManager.getAppSession(request);
	}

}
