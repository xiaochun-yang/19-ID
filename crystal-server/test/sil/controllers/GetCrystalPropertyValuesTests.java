package sil.controllers;

import java.io.ByteArrayOutputStream;
import java.util.List;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.beans.util.SilUtil;
import sil.controllers.util.SimpleTclStringParserCallback;
import sil.controllers.util.TclStringParser;
import sil.controllers.util.TclStringParserCallback;
import sil.dao.SilDao;
import sil.io.SilWriter;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import sil.managers.SilStorageManager;

public class GetCrystalPropertyValuesTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testGetCrystalPropertyValues() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 3; 
        SilCacheManager cache = (SilCacheManager)ctx.getBean("silCacheManager");
        SilManager silManager = cache.getOrCreateSilManager(silId);
        MutablePropertyValues props = new MutablePropertyValues();
        props.addPropertyValue("Score", "1.01");
        silManager.setCrystalProperties(2000193, props); // A1
        props = new MutablePropertyValues();
        props.addPropertyValue("Score", "5.01");
        silManager.setCrystalProperties(2000210, props); // B2
        props = new MutablePropertyValues();
        props.addPropertyValue("Score", "9.01");
        silManager.setCrystalProperties(2000229, props); // C5
           	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("propertyName", "Score");
    	
    	controller.getCrystalPropertyValues(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getErrorMessage());
        
        String content = response.getContentAsString();
        System.out.println(content);
        TclStringParser parser = new TclStringParser();
        SimpleTclStringParserCallback callback = new SimpleTclStringParserCallback();
        parser.setCallback(callback);
        parser.parse(content);
        List<String> values = callback.getValues(); 
        
        assertEquals("1.01", values.get(0)); // A1
        assertEquals("0.0", values.get(1)); // A2
        assertEquals("5.01", values.get(17)); // B2
        assertEquals("0.0", values.get(18)); // B3
        assertEquals("0.0", values.get(35)); // C4
        assertEquals("9.01", values.get(36)); // C5
        assertEquals("0.0", values.get(37)); // C6
        
	}

}
