package ssrl.interceptor;

import java.io.File;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;
    
	
public class BlockFileFilter extends HandlerInterceptorAdapter implements InitializingBean {

	protected final Log logger = LogFactory.getLog(getClass());
	protected String baseUrl = "";
	protected String blockFile = "";
	protected String blockUri = "";
	
	public boolean preHandle(HttpServletRequest request,
			HttpServletResponse response, Object handler) throws Exception {

		File file = new File(getBlockFile());

		if (!file.exists()) return true;
		
		logger.info("request rejected because of block file:" + request.getRequestURL().toString());
		
		response.sendRedirect(getBaseUrl()+blockUri);

		return false;
	}

	public void afterPropertiesSet() throws Exception {
		if ( baseUrl==null ) throw new BeanCreationException("must set baseUrl ");
		if ( blockFile==null ) throw new BeanCreationException("must set blockFile");
		if ( blockUri==null ) throw new BeanCreationException("must set blockUri property");
	}

	public String getBaseUrl() {
		return baseUrl;
	}

	public void setBaseUrl(String baseUrl) {
		this.baseUrl = baseUrl;
	}

	public String getBlockFile() {
		return blockFile;
	}

	public void setBlockFile(String blockFile) {
		this.blockFile = blockFile;
	}

	public String getBlockUri() {
		return blockUri;
	}

	public void setBlockUri(String blockUri) {
		this.blockUri = blockUri;
	}
	

	
	
	
}
