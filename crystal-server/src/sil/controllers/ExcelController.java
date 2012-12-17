package sil.controllers;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import sil.managers.SilStorageManager;

public class ExcelController extends MultiActionController implements InitializingBean
{
	private SilStorageManager storageManager = null;
	
	// Default view
	public ModelAndView view(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{		
		int silId = parseSilId(request);
		
		ServletOutputStream out = response.getOutputStream();
		response.setContentType("application/vnd.ms-excel");
		getStorageManager().writeOriginalExcel(out, silId);
		out.close();

		return null;		
	}
	
	private int parseSilId(HttpServletRequest request)
		throws Exception
	{
		String silId = request.getParameter("silId");
		if (silId == null)
				throw new Exception("Missing silId parameter in URL");
		
		if (silId.length() == 0)
				throw new Exception("Zero length silId parameter in URL");
		
		int id = -1;
		try {
			return Integer.parseInt(silId);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid silId parameter in URL");
		}		
	}
	
	public ModelAndView viewExcel(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{
		return view(request, response);
	}
	
	public ModelAndView viewResult(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{
		int silId = parseSilId(request);
		
		ServletOutputStream out = response.getOutputStream();
		response.setContentType("application/vnd.ms-excel");
		storageManager.writeResultExcel(out, silId);
		out.close();
		
		return null;
	}
	
	public void afterPropertiesSet() throws Exception 
	{
		if (getStorageManager() == null) 
			throw new BeanCreationException("must set 'storageManager' property for SilExcelController bean");
	}


	public SilStorageManager getStorageManager() {
		return storageManager;
	}


	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}
		
}