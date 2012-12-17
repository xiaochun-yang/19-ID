package sil.controllers;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import sil.app.SilAppSession;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

// Handles a command.
public class ImageDownloadController extends MultiActionController implements InitializingBean 
{	
	private String imageServerBaseUrl;
	private String impServerBaseUrl;
	private AppSessionManager appSessionManager;
	
	public ModelAndView showDiffImage(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{	
		SilAppSession appSession = getSilAppSession(request);
		AuthSession authSession = appSession.getAuthSession();
		
		Map<String, Object> model = new HashMap<String, Object>();
		String filePath = request.getParameter("filePath");
		if (filePath == null) {
			model.put("error", "No diffraction image filePath is specified.");
		} else {
			try {
				checkFileReadable(filePath, authSession.getUserName(), authSession.getSessionId());
				model.put("filePath", filePath);
			} catch (Exception e) {
				model.put("error", e.getMessage());
			}
		}
		return new ModelAndView("silPages/showDiffImage", model);
	}
	
	public ModelAndView showJpeg(HttpServletRequest request, HttpServletResponse response)
		throws Exception 
	{	
		SilAppSession appSession = getSilAppSession(request);
		AuthSession authSession = appSession.getAuthSession();

		Map<String, Object> model = new HashMap<String, Object>();
		String filePath = request.getParameter("filePath");
		if (filePath == null) {
			model.put("error", "No jpeg filePath is specified.");
		} else {
			try {
				checkFileReadable(filePath, authSession.getUserName(), authSession.getSessionId());
				model.put("filePath", filePath);
			} catch (Exception e) {
				model.put("error", e.getMessage());
			}
		}
		return new ModelAndView("silPages/showJpeg", model);
	}
		
	public ModelAndView downloadDiffImage(HttpServletRequest request, HttpServletResponse response) throws Exception
	{	
		int size = 0;
		byte[] content = null;
		try {
			
		String file = request.getParameter("filePath");
		if (file == null)
			throw new Exception("Missing filePath parameter");
		
		AppSession appSession = getSilAppSession(request);
		if (appSession == null)
			throw new Exception("appSession is null");
		
		AuthSession authSession = appSession.getAuthSession();
			
		int sizeX = getIntParameter(request, "sizeX", 400);
		int sizeY = getIntParameter(request, "sizeY", 400);
		int gray = getIntParameter(request, "gray", 400);
		double percentX = getDoubleParameter(request, "percentX", 0.5);
		double percentY = getDoubleParameter(request, "percentY", 0.5);
		double zoom = getDoubleParameter(request, "zoom", 1.0);
		
		String urlStr = imageServerBaseUrl + "/getImage?userName=" + authSession.getUserName()
						+ "&sessionId=" + authSession.getSessionId()
						+ "&fileName=" + file
						+ "&sizeX=" + String.valueOf(sizeX)
						+ "&sizeY=" + String.valueOf(sizeY)
						+ "&gray=" + String.valueOf(gray)
						+ "&percentX=" + String.valueOf(percentX)
						+ "&percentY=" + String.valueOf(percentY)
						+ "&zoom=" + String.valueOf(zoom);
		
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		con.setRequestMethod("GET");
		int responseCode = con.getResponseCode();
		if (responseCode != 200)
			throw new Exception("image server returns error " + String.valueOf(responseCode) + " " + con.getResponseMessage());
		
		// Save jpeg in memory first 
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		download(con.getInputStream(), out);
		out.close();
		
		size = out.size();
		content = out.toByteArray();
		
		} catch (Exception e) {
			response.sendError(500, e.getMessage());
			return null;
		}
		
		response.setContentType("image/jpeg");
		response.setContentLength((int)size);
		
		// Then stream it to http response.
		if (size > 0)
			response.getOutputStream().write(content);

		return null;
	}
	
	public ModelAndView downloadJpeg(HttpServletRequest request, HttpServletResponse response) throws Exception
	{	
		int size = 0;
		byte[] content = null;
		try {

		String file = request.getParameter("filePath");
		if (file == null)
			throw new Exception("Missing filePath parameter");
		
		AppSession appSession = getSilAppSession(request);
		if (appSession == null)
			throw new Exception("appSession is null");
		
		AuthSession authSession = appSession.getAuthSession();
		
		String urlStr = impServerBaseUrl + "/readFile?impUser=" + authSession.getUserName()
						+ "&impSessionID=" + authSession.getSessionId()
						+ "&impFilePath=" + file;
		
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		con.setRequestMethod("GET");
		int responseCode = con.getResponseCode();
		if (responseCode != 200)
			throw new Exception("imperson server returns error " + String.valueOf(responseCode) + " " + con.getResponseMessage());
		
		// Save jpeg in memory first 
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		download(con.getInputStream(), out);
		out.close();		
		
		size = out.size();
		content = out.toByteArray();
		
		} catch (Exception e) {
			response.sendError(500, e.getMessage());
			return null;
		}
		
		response.setContentType("image/jpeg");
		response.setContentLength((int)size);
		
		// Then stream it to http response.
		if (size > 0)
			response.getOutputStream().write(content);

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
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' property for CommandControllerBean");
		if (imageServerBaseUrl == null)
			throw new BeanCreationException("Must set 'imageServerBaseUrl' property for CommandControllerBean");
		if (impServerBaseUrl == null)
			throw new BeanCreationException("Must set 'impServerBaseUrl' property for CommandControllerBean");
		
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}
	
	public String getImageServerBaseUrl() {
		return imageServerBaseUrl;
	}

	public void setImageServerBaseUrl(String imageServerBaseUrl) {
		this.imageServerBaseUrl = imageServerBaseUrl;
	}

	public String getImpServerBaseUrl() {
		return impServerBaseUrl;
	}

	public void setImpServerBaseUrl(String impServerBaseUrl) {
		this.impServerBaseUrl = impServerBaseUrl;
	}

	private int getIntParameter(HttpServletRequest request, String name, int def) {
		String str = request.getParameter(name);
		if (str == null)
			return def;
		try {
			return Integer.parseInt(str);
		} catch (NumberFormatException e) {
			return def;
		}
	}
	
	private double getDoubleParameter(HttpServletRequest request, String name, double def) {
		String str = request.getParameter(name);
		if (str == null)
			return def;
		try {
			return Double.parseDouble(str);
		} catch (NumberFormatException e) {
			return def;
		}
	}
	
	private SilAppSession getSilAppSession(HttpServletRequest request)
	{
		return (SilAppSession)appSessionManager.getAppSession(request);
	}
	
	
	private void checkFileReadable(String filePath, String userName, String sessionId) throws Exception 
	{
		String urlStr = impServerBaseUrl + "/readFile?impUser=" + userName + "&impSessionID=" + sessionId + "&impFilePath=" + filePath;

		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		con.setRequestMethod("GET");
		int responseCode = con.getResponseCode();
		if (responseCode != 200) {
			logger.warn("Cannot read file " + filePath + ". Root cause: imperson server returns " + con.getResponseCode() + " " + con.getResponseMessage());
			throw new Exception(con.getResponseMessage());
		}
		con.disconnect();
	}

}
