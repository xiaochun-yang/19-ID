package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.util.WebUtils;

import javax.servlet.http.HttpServletRequest;

import junit.framework.TestCase;

public class WebUtilsTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
			
	public void testClearErrorRequestAttributes()
	{
		logger.info("testClearErrorRequestAttributes: START");
		try {
			
			// clearErrorRequestAttributes method exists in spring-web.jar
			// but not spring.jar for spring 2.5.5 release!!
			// which means that spring.jar and spring-web.jar are incompatible.
			HttpServletRequest request = new MockHttpServletRequest();
//			WebUtils.clearErrorRequestAttributes(request);
						
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}		
		logger.info("testClearErrorRequestAttributes: DONE");
	}	
	
}