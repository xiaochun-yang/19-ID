package sil.controllers;

import sil.app.SilAppSession;
import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.beans.util.FileTool;
import sil.exceptions.SilListFilterException;
import sil.factory.SilFactory;
import sil.managers.SilStorageManager;
import sil.upload.SilUploadManager;
import sil.upload.UploadData;
import ssrl.authClient.spring.AppSessionManager;
import velocity.tools.generic.NullTool;

import java.io.File;
import java.io.FileInputStream;
import java.util.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

public class CassetteListController extends MultiActionController implements InitializingBean
{
	private AppSessionManager appSessionManager;
	private SilStorageManager storageManager;
	private SilUploadManager uploadManager;
	private SilFactory silFactory;
	private String helpUrl;
	private String cassetteTemplateFile = "cassette_template.xls";
	private String puckTemplateFile = "puck_template.xls";
	
	// Default view
	public ModelAndView view(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{
		SilAppSession appSession = getSilAppSession(request);
		appSession.setView(SilAppSession.CASSETTELIST_VIEW);

		Map model = new HashMap();
		fillModel(appSession, model);
		
		return new ModelAndView(getView(appSession), model);		
	}
	
	// Used to test that the exception handling works.
	public ModelAndView testExceptionHandling(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		throw new Exception("TEST EXCEPTION in CassetteListController");
	}
	
	public ModelAndView useCassetteTemplate(HttpServletRequest request, HttpServletResponse response)
	{
		return uploadDefaultSpreadsheet(request, response, cassetteTemplateFile, "ssrl", "cassette");
	}
	
	public ModelAndView usePuckTemplate(HttpServletRequest request, HttpServletResponse response)
	{
		return uploadDefaultSpreadsheet(request, response, puckTemplateFile, "ssrl", "puck");
	}
	
	public ModelAndView uploadDefaultSpreadsheet(
				HttpServletRequest request, 
				HttpServletResponse response,
				String templateFile,
				String templateName,
				String containerType)
	{
		SilAppSession appSession = getSilAppSession(request);
		
		String containerId = request.getParameter("containerId");
		List<String> warnings = new ArrayList<String>();
		
		try {
			
			UploadData data = new UploadData();			
			data.setSheetName("Sheet1");
			data.setTemplateName(templateName);
			data.setContainerType(containerType);
			data.setSilOwner(appSession.getSilOwner());
			File tFile = silFactory.getTemplateFile(templateFile);
			FileInputStream in = new FileInputStream(tFile);
			MultipartFile file = new MockMultipartFile("file", 
					tFile.getName(), "application/vnd.ms-excel", in);
			data.setFile(file);
			in.close();
			
	        int silId = getUploadManager().uploadFile(data, warnings);
			appSession.setPageNumber(SilAppSession.LAST_PAGE_NUMBER);
	        Map model = new HashMap();
	        model.put("silId", silId);
	        model.put("warnings", warnings);
			return new ModelAndView("silPages/uploadFileConfirm", model);
	        
		} catch (Exception e) {
			Map model = new HashMap();
			model.put("error", e.getMessage());
			return new ModelAndView("silPages/uploadFailed", model);
		}

	}
		
	/*
	 * Save this session states and data retrieved from DB in model.
	 */
	protected ModelAndView fillModel(SilAppSession appSession, Map model)
	{
		model.put("nullTool", new NullTool());
			
		String deleteSilUrl = "userDeleteSil.html";
		String assignSilUrl = "userAssignSil.html";
		if (appSession.getAuthSession().getStaff()) {
			// List all users
			List users = storageManager.getUserList();
			model.put("userList", users);
			deleteSilUrl = "staffDeleteSil.html";
			assignSilUrl = "staffAssignSil.html";
		}

		// List cassettes that belong to this user.
		List orgSilList = storageManager.getSilList(appSession.getSilOwner());
		
		// Filter sil list
		List silList; 
		try {
			silList = appSession.getSilListFilter().filter(orgSilList);
		} catch (SilListFilterException e) {
			silList = new ArrayList<SilInfo>();
			model.put("filterError", e.getMessage());
		}

		model.put("cassetteList", silList);
		int numSils = silList.size();
		int numSilsPerPage = appSession.getNumSilsPerPage();
		int numPages = numSils/numSilsPerPage;
		if (numPages*numSilsPerPage < numSils)
			++numPages;
		int newPageNumber = appSession.getPageNumber();
		if (newPageNumber < 0)
			appSession.setPageNumber(0);
		else if (newPageNumber >= numPages)
			appSession.setPageNumber(numPages-1);

		int firstIndex = -1;
		int lastIndex = -1;
		int firstSilId = -1;
		int lastSilId = -1;
		if (silList.size() > 0) {
			firstIndex = appSession.getPageNumber()*numSilsPerPage;
			SilInfo firstSilInfo = (SilInfo)silList.get(firstIndex);
			lastIndex = firstIndex + numSilsPerPage - 1;
			if (lastIndex >= numSils)
				lastIndex = numSils - 1;
			SilInfo lastSilInfo = (SilInfo)silList.get(lastIndex);
			firstSilId = firstSilInfo.getId();
			lastSilId = lastSilInfo.getId();
		}
		model.put("firstSilId", firstSilId);
		model.put("firstIndex", firstIndex+1);
		model.put("lastSilId", lastSilId);
		model.put("lastIndex",lastIndex+1);
		model.put("numSils", numSils);
		model.put("numPages", numPages);
		model.put("pageNumber", appSession.getPageNumber());
		model.put("numSilsPerPage", numSilsPerPage);	
		
		// List beamlines that are accessible by this user.
		List beamlineList = storageManager.getBeamlineList();
		List userBeamlineList = filterBeamlineList(appSession, beamlineList);
		model.put("beamlineList", userBeamlineList);
		model.put("deleteSilUrl", deleteSilUrl);
		model.put("assignSilUrl", assignSilUrl);
		model.put("helpUrl", helpUrl);
		model.put("fileTool", new FileTool());
			
		return new ModelAndView(getView(appSession), model);
	}
	
	protected String getView(SilAppSession appSession)
	{
		return "/silPages/" + appSession.getView(); 
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
		if (uploadManager == null)
			throw new BeanCreationException("Must set 'uploadManager' property for CassetteListController bean");
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for CassetteListController bean");
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for CassetteListController bean");
		
	}

	public SilUploadManager getUploadManager() {
		return uploadManager;
	}

	public void setUploadManager(SilUploadManager uploadManager) {
		this.uploadManager = uploadManager;
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

	public String getCassetteTemplateFile() {
		return cassetteTemplateFile;
	}

	public void setCassetteTemplateFile(String cassetteTemplateFile) {
		this.cassetteTemplateFile = cassetteTemplateFile;
	}

	public String getPuckTemplateFile() {
		return puckTemplateFile;
	}

	public void setPuckTemplateFile(String puckTemplateFile) {
		this.puckTemplateFile = puckTemplateFile;
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

	public String getHelpUrl() {
		return helpUrl;
	}

	public void setHelpUrl(String helpUrl) {
		this.helpUrl = helpUrl;
	}
}
