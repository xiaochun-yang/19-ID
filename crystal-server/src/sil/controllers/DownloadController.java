package sil.controllers;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import sil.beans.SilInfo;
import sil.factory.SilFactory;
import sil.io.SilExcelWriter;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import sil.managers.SilStorageManager;

// Handles a command.
public class DownloadController extends MultiActionController implements InitializingBean 
{		
	private SilFactory silFactory;
	private SilCacheManager silCacheManager;
	private SilExcelWriter silExcelWriter;
	private SilStorageManager storageManager;
	
	public ModelAndView downloadTemplate(HttpServletRequest request, HttpServletResponse response) throws Exception
	{	
		String path = request.getRequestURI();
		int i = path.lastIndexOf('/');
		String templateFile = path.substring(i+1);
		File file = silFactory.getTemplateFile(templateFile);
		if (!file.exists())
			throw new Exception("Template file " + path + " does not exist.");
		
		response.setContentType("application/vnd.ms-excel");
		response.setContentLength((int)file.length());
		
		FileInputStream in = new FileInputStream(file);		
		download(in, response.getOutputStream());

		return null;
	}
	
	public ModelAndView downloadOriginalExcel(HttpServletRequest request, HttpServletResponse response) throws Exception
	{	
		String silIdStr = request.getParameter("silId");
		if (silIdStr == null)
			throw new Exception("Invalid silId parameter");
		
		int silId = Integer.parseInt(silIdStr);
		if (silId < 1)
			throw new Exception("Invalid silId parameter");
		
		SilInfo info = storageManager.getSilInfo(silId);
		if (info == null)
			throw new Exception("Sil " + silId + " does not exist in DB.");
		
		String path = storageManager.getOriginalExcelFilePath(info);
		File file = new File(path);
		if (!file.exists())
			throw new Exception("Original sil file " + path + " does not exist.");
		
		String fname = file.getName();
		String ext = (fname.lastIndexOf(".")==-1)?"":fname.substring(fname.lastIndexOf(".")+1,fname.length());
			
		if (ext.equals("xls"))
			response.setContentType("application/vnd.ms-excel");
		else if (ext.equals("xlsx"))
			response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		else
			response.setContentType("application/octet-stream");

		response.setContentLength((int)file.length());
		
		FileInputStream in = new FileInputStream(file);
		download(in, response.getOutputStream());

		return null;
	}

	public ModelAndView downloadResultSil(HttpServletRequest request, HttpServletResponse response) throws Exception
	{	
		String silIdStr = request.getParameter("silId");
		if (silIdStr == null)
			throw new Exception("Invalid silId parameter");
		
		int silId = Integer.parseInt(silIdStr);
		if (silId < 1)
			throw new Exception("Invalid silId parameter");
		
		SilInfo info = storageManager.getSilInfo(silId);
		if (info == null)
			throw new Exception("Sil " + silId + " does not exist in DB.");
		
		// Write sil to a buffer first so that we 
		// can count the size.
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		SilManager silManager = silCacheManager.getOrCreateSilManager(info.getId());
		silExcelWriter.write(out, silManager.getSil());		
		
		response.setContentType("application/vnd.ms-excel");
		response.setContentLength((int)out.size());
		
		// Then stream it to http response.
		out.writeTo(response.getOutputStream());

		return null;
	}
	
	private void download(InputStream in, OutputStream out) throws Exception {
		
		byte buf[] = new byte[5000];
		int n = -1;
		while ((n=in.read(buf)) > -1) {
			if (n < 1)
				continue;
			out.write(buf, 0, n);
		}
		in.close();		
	}

	public void afterPropertiesSet() throws Exception {
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for CommandControllerBean");
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for CommandControllerBean");
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' property for CommandControllerBean");
		if (silExcelWriter == null)
			throw new BeanCreationException("Must set 'silExcelWriter' property for CommandControllerBean");
		
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

	public SilCacheManager getSilCacheManager() {
		return silCacheManager;
	}

	public void setSilCacheManager(SilCacheManager silCacheManager) {
		this.silCacheManager = silCacheManager;
	}

	public SilExcelWriter getSilExcelWriter() {
		return silExcelWriter;
	}

	public void setSilExcelWriter(SilExcelWriter silExcelWriter) {
		this.silExcelWriter = silExcelWriter;
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

}
