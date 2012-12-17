package sil.controllers;

import java.util.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.CancellableFormController;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.validation.BindException;

import sil.upload.SilUploadManager;
import sil.upload.UploadData;
import sil.app.SilAppSession;
import sil.beans.UserInfo;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

public class FileUploadController extends CancellableFormController implements InitializingBean
{
	private SilUploadManager uploadManager;
	private AppSessionManager appSessionManager;
	private List<String> containerTypes = new ArrayList<String>();
	private List<String> templateNames = new ArrayList<String>();
	
	public FileUploadController() 
	{
		super();
		setCommandName("command");
		setCommandClass(UploadData.class);
		setSessionForm(false);
		setBindOnNewForm(true);
		setCancelView("redirect:/cassetteList.html");
		setFormView("silPages/uploadFileForm");
	}
	
	@Override
	protected Map referenceData(HttpServletRequest request) throws Exception {
		
		Map model = new HashMap();
		model.put("containerTypes", containerTypes);		
		model.put("templateNames", templateNames);		
		return model;
	}
	
	public ModelAndView onSubmit(HttpServletRequest request,
			HttpServletResponse response, Object command, BindException errors) throws Exception 
	{		
		UploadData uploadData = (UploadData)command;
				        
		List<String> warnings = new ArrayList<String>();
		
		try {
		
        int silId = getUploadManager().uploadFile(uploadData, warnings);
        SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
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

	@Override
	protected void onBindAndValidate(HttpServletRequest request, Object command, BindException errors) 
		throws Exception 
	{	
		UploadData uploadData = (UploadData)command;
				
		AuthSession auth = getAuthSession(request);

		if (!auth.getStaff() && !uploadData.getSilOwner().equals(auth.getUserName())) {
				errors.reject("errors.cannotUploadForOtherUser");
				logger.debug("Cannot upload for other user");
		}
				                	
        if ((uploadData.getFile() == null) || uploadData.getFile().isEmpty()) {
       		errors.rejectValue("file", "errors.fileNotSet");
       	}
        
/*        if (!isXlsFormat(uploadData.getFile().getContentType())) {
        	errors.rejectValue("file", "errors.notXlsFile");
        	logger.error("Not excel format content-type = " + uploadData.getFile().getContentType());
         }*/
        
       	if ((uploadData.getSheetName() == null) || (uploadData.getSheetName().length() == 0)) {
       		errors.rejectValue("sheetName", "errors.sheetNameNotSet");
        }
       	     
	}
	
	private AuthSession getAuthSession(HttpServletRequest request)
	{
		AppSession appSession = appSessionManager.getAppSession(request);
		if (appSession == null)
			return null;
		return appSession.getAuthSession();
	}
	
	private SilAppSession getSilAppSession(HttpServletRequest request) {
		return (SilAppSession)appSessionManager.getAppSession(request);
	}
	
	protected Object formBackingObject(HttpServletRequest request)
		throws Exception 
	{
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		UserInfo silOwnerInfo = uploadManager.getStorageManager().getUserInfo(appSession.getSilOwner());
				
		UploadData uploadData = new UploadData();
		uploadData.setSheetName("Sheet1");
		uploadData.setTemplateName(silOwnerInfo.getUploadTemplate());
		uploadData.setContainerType("cassette");
		uploadData.setSilOwner(getSilAppSession(request).getSilOwner());

		return uploadData;
	}

	public SilUploadManager getUploadManager() {
		return uploadManager;
	}

	public void setUploadManager(SilUploadManager uploadManager) {
		this.uploadManager = uploadManager;
	}

	private boolean isXlsFormat(String contentType)
	{
		if (contentType.equals("application/vnd.ms-excel"))
			return true;
		else if (contentType.equals("application/x-msexcel"))
			return true;
		else if (contentType.equals("application/ms-excel"))
			return true;
		else if (contentType.equals("application/msexcel"))
			return true;
		else if (contentType.equals("application/msexcel"))
			return true;
		else
			System.out.println("Content-Type " + contentType + " is unsupported.");
		
		return false;
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public void afterPropertiesSet() throws Exception {
		if (uploadManager == null)
			throw new BeanCreationException("Must set 'uploadMamager' property for FileUploadController bean");
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' property for FileUploadController bean");
		
	}

	public List<String> getContainerTypes() {
		return containerTypes;
	}

	public void setContainerTypes(List<String> containerTypes) {
		this.containerTypes = containerTypes;
	}

	public List<String> getTemplateNames() {
		return templateNames;
	}

	public void setTemplateNames(List<String> templateNames) {
		this.templateNames = templateNames;
	}

}
