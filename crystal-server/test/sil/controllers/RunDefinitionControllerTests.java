package sil.controllers;

import org.springframework.beans.MutablePropertyValues;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.AutoindexResult;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.UnitCell;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;

public class RunDefinitionControllerTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}
	
	public void testAddRunDefinition() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	        
        initRepositionData(silManager, uniqueId);
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "10.0");
    	request.addParameter("end_angle", "240.0");
    	request.addParameter("attenuation", "99.0");
    	
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        assertEquals("OK 0", content);
        
        cacheManager.removeSil(silId, false);
        silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(1, silManager.getNumRunDefinitions(uniqueId));
        RunDefinition run = silManager.getRunDefinition(uniqueId, 0);
        assertNotNull(run);
        assertEquals(1, run.getRunLabel());
        assertEquals(10.0, run.getStartAngle());
        assertEquals(240.0, run.getEndAngle());
        assertEquals(99.0, run.getAttenuation());
	}
	
	public void testDeleteRunDefinition() throws Exception {
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
               
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
/*    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos0");
    	request.addParameter("beam_width", String.valueOf(0.5));
    	request.addParameter("beam_height", String.valueOf(0.5));
    	request.addParameter("autoindexDir", "/data/annikas/webice/autoindex/test1");
    	controller.addDefaultRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	String content = response.getContentAsString().trim();
    	assertEquals("OK 0", content);
                
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	*/
        
        initRepositionData(silManager, uniqueId);
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "10.0");
    	request.addParameter("end_angle", "240.0");
    	request.addParameter("attenuation", "99.0");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	String content = response.getContentAsString().trim();
    	assertEquals("OK 0", content);
    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "20.0");
    	request.addParameter("end_angle", "300.0");
    	request.addParameter("attenuation", "60.0");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	assertEquals("OK 1", content);
    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "5.0");
    	request.addParameter("end_angle", "100.0");
    	request.addParameter("attenuation", "70.0");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	assertEquals("OK 2", content);

        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "1");
    	controller.deleteRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        assertEquals("OK", content);
        
        cacheManager.removeSil(silId, false);
        silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(2, silManager.getNumRunDefinitions(uniqueId));
        RunDefinition run = silManager.getRunDefinition(uniqueId, 0);
        assertNotNull(run);
        assertEquals(1, run.getRunLabel());
        assertEquals(10.0, run.getStartAngle());
        assertEquals(240.0, run.getEndAngle());
        assertEquals(99.0, run.getAttenuation());
        
        run = silManager.getRunDefinition(uniqueId, 1);
        assertNotNull(run);
        assertEquals(3, run.getRunLabel());
        assertEquals(5.0, run.getStartAngle());
        assertEquals(100.0, run.getEndAngle());
        assertEquals(70.0, run.getAttenuation());
	}
	
	public void testGetNumRunDefitions() throws Exception {
	}
	
	public void testGetRunDefition() throws Exception {

		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        int row = silManager.getCrystalRowFromUniqueId(uniqueId);
        
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        initRepositionData(silManager, uniqueId);
               
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "10.0");
    	request.addParameter("end_angle", "240.0");
    	request.addParameter("attenuation", "99.0");
    	request.addParameter("runStatus", "Inactive");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	String content = response.getContentAsString().trim();
    	assertEquals("OK 0", content);
    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "1");
    	request.addParameter("start_angle", "20.0");
    	request.addParameter("end_angle", "300.0");
    	request.addParameter("attenuation", "60.0");
    	request.addParameter("runStatus", "Aborted");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	content = response.getContentAsString().trim();
    	assertEquals("OK 1", content);
    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "5.0");
    	request.addParameter("end_angle", "100.0");
    	request.addParameter("attenuation", "70.0");
    	request.addParameter("runStatus", "Active");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	content = response.getContentAsString().trim();
    	assertEquals("OK 2", content);
        
        // Set crystal so that sil's eventId will be 1.
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
		CommandController commandController = (CommandController)ctx.getBean("commandController");
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("Comment", "Good Crystal");
    	commandController.setCrystal(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	assertEquals("OK 1", content); // sil eventId

        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "1");
    	controller.getRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	
        content = response.getContentAsString().trim();
        
        System.out.println(content);
        
        StringBuffer expected = new StringBuffer();
        expected.append("3 1 2000194 5\n"); // silId row crystalEventId
        expected.append("{1 2 3 }\n"); // run labels
        expected.append("{Inactive Aborted Active }\n"); // run status
        // silId row runIndex ...
        expected.append("{3 1 2000194 {1} {2} {Aborted} {0} {2} {} {} {0} {} {20.0} {300.0} {0.0} {0.0} {0} {60.0} {0.0} {0} {0} {0.0} {200.0} {60.0} {0} {0.0} {0.0} {0.0} {0.0} {0.0} {0} {0} {0.8} {0.9} {0.0} {0.0} {0.0}}\n");
        expected.append(getDefaultRepositionData2Tcl(silId, row, uniqueId));
	}
	
	public void testGetRunDefitionIndexOutOfRange() throws Exception {

		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        int row = silManager.getCrystalRowFromUniqueId(uniqueId);
               
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
                
        initRepositionData(silManager, uniqueId);
               
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "10.0");
    	request.addParameter("end_angle", "240.0");
    	request.addParameter("attenuation", "99.0");
    	request.addParameter("runStatus", "Inactive");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	String content = response.getContentAsString().trim();
    	assertEquals("OK 0", content);
    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "20.0");
    	request.addParameter("end_angle", "300.0");
    	request.addParameter("attenuation", "60.0");
    	request.addParameter("runStatus", "Aborted");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	assertEquals("OK 1", content);
    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "2");
    	request.addParameter("start_angle", "5.0");
    	request.addParameter("end_angle", "100.0");
    	request.addParameter("attenuation", "70.0");
    	request.addParameter("runStatus", "Active");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	assertEquals("OK 2", content);

        
        // Set crystal so that sil's eventId will be 1.
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
		CommandController commandController = (CommandController)ctx.getBean("commandController");
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("Comment", "Good Crystal");
    	commandController.setCrystal(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	assertEquals("OK 1", content);

        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
        // Run index 4 does not exist
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "4");
    	
    	// Return run index 0
    	controller.getRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
        System.out.println(content);
    	
        // Run index 0 is returned instead of run index 4 which does not exist.
        StringBuffer expected = new StringBuffer();
        expected.append("3 1 2000194 9\n"); // silId row crystalEventId
        expected.append("{1 2 3 }\n"); // run labels
        expected.append("{Inactive Aborted Active }\n"); // run status
        // silId row runIndex ...
        expected.append("{3 1 2000194 {0} {0} {Inactive} {0} {1} {} {} {0} {} {10.0} {240.0} {0.0} {0.0} {0} {99.0} {0.0} {0} {0} {0.0} {0.0} {0.0} {0} {0.0} {0.0} {0.0} {0.0} {0.0} {0} {0} {0.0} {0.0} {0.0} {0.0} {0.0}}\n");
        expected.append(getDefaultRepositionData0Tcl(silId, row, uniqueId));

        assertEquals(expected.toString(), content);
	}
	
	public void testGetRunDefitionNoRuns() throws Exception {

		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        int row = silManager.getCrystalRowFromUniqueId(uniqueId);
               
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        initRepositionData(silManager, uniqueId);

        // Run index 4 does not exist
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "4");
    	
    	// Return run index 0
    	controller.getRunDefinition(request, response);
    	
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        System.out.println("response content: " + content);
    	
        // Run index 0 is returned instead of run index 4 which does not exist.
        StringBuffer expected = new StringBuffer();
        expected.append("3 1 2000194 6\n"); // silId row crystalEventId
        expected.append("{}\n"); // run labels
        expected.append("{}\n"); // run status
        // silId row runIndex ...
        expected.append("{}\n");
        expected.append(getDefaultRepositionData0Tcl(silId, row, uniqueId));
        assertEquals(expected.toString(), content);
	} 
	
	public void testGetRunDefitionNoRunsNoRepositions() throws Exception {

		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
               
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();

        // Run index 4 does not exist
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "4");
    	
    	// Return run index 0
    	controller.getRunDefinition(request, response);
    	
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        System.out.println("response content: " + content);
    	
        // Run index 0 is returned instead of run index 4 which does not exist.
        StringBuffer expected = new StringBuffer();
        expected.append("3 1 2000194 0\n"); // silId row crystalEventId
        expected.append("{}\n"); // run labels
        expected.append("{}\n"); // run status
        // silId row runIndex ...
        expected.append("{}\n");
        expected.append("{}\n");
        expected.append("{}\n");
        expected.append("{}\n");
        expected.append("{}");
        assertEquals(expected.toString(), content);
	}

	
	public void testMoveRunDefinition() throws Exception {
		
	}
	
	public void testSetRunDefinitionPropertyValue() throws Exception {
		
	}
	
	public void testSetRunDefinitionProperties() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        int row = silManager.getCrystalRowFromUniqueId(uniqueId);
               
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        initRepositionData(silManager, uniqueId);
          	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "10.0");
    	request.addParameter("end_angle", "240.0");
    	request.addParameter("attenuation", "99.0");
    	request.addParameter("runStatus", "Inactive");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	String content = response.getContentAsString().trim();
    	assertEquals("OK 0", content);
    	    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "0");
    	request.addParameter("start_angle", "20.0");
    	request.addParameter("end_angle", "300.0");
    	request.addParameter("attenuation", "60.0");
    	request.addParameter("runStatus", "Aborted");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
    	content = response.getContentAsString().trim();
    	assertEquals("OK 1", content);
    	
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "2");
    	request.addParameter("start_angle", "5.0");
    	request.addParameter("end_angle", "100.0");
    	request.addParameter("attenuation", "70.0");
    	request.addParameter("runStatus", "Active");
    	controller.addRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        assertEquals("OK 2", content);
        
        // Set run definition properties
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "1");
    	request.addParameter("start_angle", "80.0");
    	request.addParameter("end_angle", "360.0.0");
    	request.addParameter("attenuation", "20.0");
    	request.addParameter("runStatus", "Active");
    	controller.setRunDefinitionProperties(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        assertEquals("OK", content);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("runIndex", "1");
    	controller.getRunDefinition(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());

        content = response.getContentAsString().trim();
        
        System.out.println(content);
        
        StringBuffer expected = new StringBuffer();
        expected.append("3 1 2000194 10\n"); // silId row crystalEventId
        expected.append("{1 2 3 }\n"); // run labels
        expected.append("{Inactive Active Active }\n"); // run status
        // silId row runIndex ...        
        expected.append("{3 1 2000194 {1} {0} {Active} {0} {2} {} {} {0} {} {80.0} {300.0} {0.0} {0.0} {0} {20.0} {0.0} {0} {0} {0.0} {0.0} {0.0} {0} {0.0} {0.0} {0.0} {0.0} {0.0} {0} {0} {0.0} {0.0} {0.0} {0.0} {0.0}}\n");
        expected.append(getDefaultRepositionData0Tcl(silId, row, uniqueId));
        assertEquals(expected.toString(), content);
		
	}

	public void testAddRepositionData() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos0");
    	request.addParameter("beam_width", "0.5");
    	request.addParameter("beam_height", "0.6");
    	request.addParameter("reposition_x", "10.0");
    	request.addParameter("reposition_y", "20.0");
    	request.addParameter("reposition_z", "30.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test_001.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test_002.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex");
    	
    	controller.addDefaultRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        assertEquals("OK 0", content);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos1");
    	request.addParameter("autoindexable", "1");
    	request.addParameter("beam_width", "0.1");
    	request.addParameter("beam_height", "0.2");
    	request.addParameter("reposition_x", "50.0");
    	request.addParameter("reposition_y", "60.0");
    	request.addParameter("reposition_z", "70.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test2_jpeg1.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test2_jpeg2.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/test2_box1.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/test2_box2.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test2_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test2_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex/reposition1");
    	
    	controller.addRepositionData(request, response);
        if (response.getStatus() != 200)
        	fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        assertEquals("OK 1", content);
        
        cacheManager.removeSil(silId, false);
        silManager = cacheManager.getOrCreateSilManager(silId);
        RepositionData actual = silManager.getRepositionData(uniqueId, 1);
		assertEquals("repos1", actual.getLabel());
		assertEquals(1, actual.getAutoindexable());
		assertEquals(0.1, actual.getBeamSizeX());
		assertEquals(0.2, actual.getBeamSizeY());
		assertEquals(50.0, actual.getOffsetX());
		assertEquals(60.0, actual.getOffsetY());
		assertEquals(70.0, actual.getOffsetZ());
		assertEquals("/data/annikas/collect1/test2_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/annikas/collect1/test2_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/annikas/collect1/test2_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/annikas/collect1/test2_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/annikas/collect1/test2_001.mccd", actual.getImage1());
		assertEquals("/data/annikas/collect1/test2_002.mccd", actual.getImage2());
		assertEquals("/data/annikas/webice/screening/3/A2/autoindex/reposition1", actual.getAutoindexResult().getDir());

	}
	
	public void testSetRepositionData() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos0");
    	request.addParameter("beam_width", "0.5");
    	request.addParameter("beam_height", "0.6");
    	request.addParameter("reposition_x", "10.0");
    	request.addParameter("reposition_y", "20.0");
    	request.addParameter("reposition_z", "30.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test_001.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test_002.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex");
    	
    	controller.addDefaultRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        assertEquals("OK 0", content);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos1");
    	request.addParameter("beam_width", "0.1");
    	request.addParameter("beam_height", "0.2");
    	request.addParameter("reposition_x", "50.0");
    	request.addParameter("reposition_y", "60.0");
    	request.addParameter("reposition_z", "70.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test2_jpeg1.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test2_jpeg2.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/test2_box1.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/test2_box2.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test2_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test2_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex/reposition1");
    	
    	controller.addRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        assertEquals("OK 1", content);
        
        cacheManager.removeSil(silId, false);
        silManager = cacheManager.getOrCreateSilManager(silId);
        RepositionData actual = silManager.getRepositionData(uniqueId, 1);
		assertEquals(0.1, actual.getBeamSizeX());
		assertEquals(0.2, actual.getBeamSizeY());
		assertEquals(50.0, actual.getOffsetX());
		assertEquals(60.0, actual.getOffsetY());
		assertEquals(70.0, actual.getOffsetZ());
		assertEquals("/data/annikas/collect1/test2_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/annikas/collect1/test2_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/annikas/collect1/test2_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/annikas/collect1/test2_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/annikas/collect1/test2_001.mccd", actual.getImage1());
		assertEquals("/data/annikas/collect1/test2_002.mccd", actual.getImage2());
		assertEquals("/data/annikas/webice/screening/3/A2/autoindex/reposition1", actual.getAutoindexResult().getDir());
		
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "1");
    	request.addParameter("beam_width", "0.8");
    	request.addParameter("beam_height", "0.9");
    	request.addParameter("reposition_x", "80.0");
    	request.addParameter("reposition_y", "90.0");
    	request.addParameter("reposition_z", "100.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect3/test2_jpeg1.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect3/test2_jpeg2.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect3/test2_box1.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect3/test2_box2.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect3/test2_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect3/test2_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex/reposition3");
    	
    	controller.setRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        assertEquals("OK", content);
        
        cacheManager.removeSil(silId, false);
        silManager = cacheManager.getOrCreateSilManager(silId);
        actual = silManager.getRepositionData(uniqueId, 1);
        assertEquals("repos1", actual.getLabel());
		assertEquals(0.8, actual.getBeamSizeX());
		assertEquals(0.9, actual.getBeamSizeY());
		assertEquals(80.0, actual.getOffsetX());
		assertEquals(90.0, actual.getOffsetY());
		assertEquals(100.0, actual.getOffsetZ());
		assertEquals("/data/annikas/collect3/test2_jpeg1.jpg", actual.getJpeg1());
		assertEquals("/data/annikas/collect3/test2_jpeg2.jpg", actual.getJpeg2());
		assertEquals("/data/annikas/collect3/test2_box1.jpg", actual.getJpegBox1());
		assertEquals("/data/annikas/collect3/test2_box2.jpg", actual.getJpegBox2());
		assertEquals("/data/annikas/collect3/test2_001.mccd", actual.getImage1());
		assertEquals("/data/annikas/collect3/test2_002.mccd", actual.getImage2());
		assertEquals("/data/annikas/webice/screening/3/A2/autoindex/reposition3", actual.getAutoindexResult().getDir());
	}
	
	public void testSetRepositionDataInvalidRepositionId() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos0");
    	request.addParameter("beam_width", "0.5");
    	request.addParameter("beam_height", "0.6");
    	request.addParameter("reposition_x", "10.0");
    	request.addParameter("reposition_y", "20.0");
    	request.addParameter("reposition_z", "30.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test_001.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test_002.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/box_002.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex");
    	
    	controller.addDefaultRepositionData(request, response);
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        assertEquals("OK 0", content);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "1");
    	request.addParameter("label", "repos1");
    	request.addParameter("beam_width", "0.1");
    	request.addParameter("beam_height", "0.2");
    	request.addParameter("reposition_x", "50.0");
    	request.addParameter("reposition_y", "60.0");
    	request.addParameter("reposition_z", "70.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test2_jpeg1.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test2_jpeg2.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/test2_box1.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/test2_box2.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test2_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test2_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex/reposition1");
    	
    	controller.setRepositionData(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Reposition data id 1 does not exist.", response.getErrorMessage());
        
        // Make sure reposition data has not been altered.
        cacheManager.removeSil(silId, false);
        silManager = cacheManager.getOrCreateSilManager(silId);
        RepositionData actual = silManager.getRepositionData(uniqueId, 0);
		assertEquals(0.5, actual.getBeamSizeX());
		assertEquals(0.6, actual.getBeamSizeY());
		assertEquals(10.0, actual.getOffsetX());
		assertEquals(20.0, actual.getOffsetY());
		assertEquals(30.0, actual.getOffsetZ());
		assertEquals("/data/annikas/collect1/test_001.jpg", actual.getJpeg1());
		assertEquals("/data/annikas/collect1/test_002.jpg", actual.getJpeg2());
		assertEquals("/data/annikas/collect1/box_001.jpg", actual.getJpegBox1());
		assertEquals("/data/annikas/collect1/box_002.jpg", actual.getJpegBox2());
		assertEquals("/data/annikas/collect1/test_001.mccd", actual.getImage1());
		assertEquals("/data/annikas/collect1/test_002.mccd", actual.getImage2());
		assertEquals("/data/annikas/webice/screening/3/A2/autoindex", actual.getAutoindexResult().getDir());
	}
	
	public void testAddDefaultRepositionData() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos0");
    	request.addParameter("beam_width", "0.5");
    	request.addParameter("beam_height", "0.6");
    	request.addParameter("reposition_x", "10.0");
    	request.addParameter("reposition_y", "20.0");
    	request.addParameter("reposition_z", "30.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test_001.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test_002.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/box_002.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex");
    	
    	controller.addDefaultRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        assertEquals("OK 0", content);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos1");
    	request.addParameter("beam_width", "0.1");
    	request.addParameter("beam_height", "0.2");
    	request.addParameter("reposition_x", "50.0");
    	request.addParameter("reposition_y", "60.0");
    	request.addParameter("reposition_z", "70.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test2_jpeg1.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test2_jpeg2.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/test2_box1.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/test2_box2.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test2_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test2_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex/reposition1");
    	
    	// Cannot be called twice on the same crystal
    	controller.addDefaultRepositionData(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Default reposition data already exists.", response.getErrorMessage());
        
        // Make sure reposition data has not been altered.
        cacheManager.removeSil(silId, false);
        silManager = cacheManager.getOrCreateSilManager(silId);
        RepositionData actual = silManager.getRepositionData(uniqueId, 0);
		assertEquals(0.5, actual.getBeamSizeX());
		assertEquals(0.6, actual.getBeamSizeY());
		assertEquals(10.0, actual.getOffsetX());
		assertEquals(20.0, actual.getOffsetY());
		assertEquals(30.0, actual.getOffsetZ());
		assertEquals("/data/annikas/collect1/test_001.jpg", actual.getJpeg1());
		assertEquals("/data/annikas/collect1/test_002.jpg", actual.getJpeg2());
		assertEquals("/data/annikas/collect1/box_001.jpg", actual.getJpegBox1());
		assertEquals("/data/annikas/collect1/box_002.jpg", actual.getJpegBox2());
		assertEquals("/data/annikas/collect1/test_001.mccd", actual.getImage1());
		assertEquals("/data/annikas/collect1/test_002.mccd", actual.getImage2());
		assertEquals("/data/annikas/webice/screening/3/A2/autoindex", actual.getAutoindexResult().getDir());
	}
	
	public void testMissingDefaultRepositionData() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos1");
    	request.addParameter("beam_width", "0.5");
    	request.addParameter("beam_height", "0.6");
    	request.addParameter("reposition_x", "10.0");
    	request.addParameter("reposition_y", "20.0");
    	request.addParameter("reposition_z", "30.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test_001.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test_002.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/box_002.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex");
    	
    	// Will throw an exception since default reposition data does not exist.
    	controller.addRepositionData(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("No default reposition data for this crystal.", response.getErrorMessage());        
	}
	
	public void testGetRepositionData() throws Exception {
		
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        int row = silManager.getCrystalRowFromUniqueId(uniqueId);

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        initRepositionData(silManager, uniqueId);
    	    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "2");
    	
    	controller.getRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        
/*        String expected = "{repos0 repos1 }\n";
        expected += "{1 0 }\n";
        expected += "{" + silId + " " + uniqueId  + "0 {repos1} {0} {/data/annikas/collect1/test2_jpeg1.jpg} {/data/annikas/collect1/test2_jpeg2.jpg} {/data/annikas/collect1/test2_box1.jpg} {/data/annikas/collect1/test2_box2.jpg} {/data/annikas/collect1/test2_001.mccd} {/data/annikas/collect1/test2_002.mccd} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0} {}}";
        System.out.println(content);*/
        
        String expected = this.getDefaultRepositionData2Tcl(silId, row, uniqueId);
        assertEquals(expected, content);
	}
	
	public void testGetAllRepositionData() throws Exception {
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        int row = silManager.getCrystalRowFromUniqueId(uniqueId);

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos0");
    	request.addParameter("autoindexable", "1");
    	request.addParameter("beam_width", "0.5");
    	request.addParameter("beam_height", "0.6");
    	request.addParameter("reposition_x", "10.0");
    	request.addParameter("reposition_y", "20.0");
    	request.addParameter("reposition_z", "30.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test_001.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test_002.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/box_001.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex");
    	
    	controller.addDefaultRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        assertEquals("OK 0", content);
        
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("label", "repos1");
    	request.addParameter("beam_width", "0.1");
    	request.addParameter("beam_height", "0.2");
    	request.addParameter("reposition_x", "50.0");
    	request.addParameter("reposition_y", "60.0");
    	request.addParameter("reposition_z", "70.0");
    	request.addParameter("fileVSnapshot1", "/data/annikas/collect1/test2_jpeg1.jpg");
    	request.addParameter("fileVSnapshot2", "/data/annikas/collect1/test2_jpeg2.jpg");
    	request.addParameter("fileVSnapshotBox1", "/data/annikas/collect1/test2_box1.jpg");
    	request.addParameter("fileVSnapshotBox2", "/data/annikas/collect1/test2_box2.jpg");
    	request.addParameter("fileDiffImage1", "/data/annikas/collect1/test2_001.mccd");
    	request.addParameter("fileDiffImage2", "/data/annikas/collect1/test2_002.mccd");
    	request.addParameter("autoindexDir", "/data/annikas/webice/screening/3/A2/autoindex/reposition1");
    	
    	controller.addRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        assertEquals("OK 1", content);
		
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	
    	controller.getAllRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        content = response.getContentAsString().trim();
        
        String expected = "{3 1 2000194 0 {repos0} {1} {/data/annikas/collect1/test_001.jpg} {/data/annikas/collect1/test_002.jpg} {/data/annikas/collect1/box_001.jpg} {/data/annikas/collect1/box_001.jpg} {/data/annikas/collect1/test_001.mccd} {/data/annikas/collect1/test_002.mccd} {0.5} {0.6} {10.0} {20.0} {30.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0} {} {} {} {0.0} {0.0 0.0 0.0 0.0 0.0 0.0} {0.0} {0.0} {} {0.0} {0.0} {/data/annikas/webice/screening/3/A2/autoindex} {-1} {}}\n";
        expected += "{3 1 2000194 1 {repos1} {0} {/data/annikas/collect1/test2_jpeg1.jpg} {/data/annikas/collect1/test2_jpeg2.jpg} {/data/annikas/collect1/test2_box1.jpg} {/data/annikas/collect1/test2_box2.jpg} {/data/annikas/collect1/test2_001.mccd} {/data/annikas/collect1/test2_002.mccd} {0.1} {0.2} {50.0} {60.0} {70.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0} {} {} {} {0.0} {0.0 0.0 0.0 0.0 0.0 0.0} {0.0} {0.0} {} {0.0} {0.0} {/data/annikas/webice/screening/3/A2/autoindex/reposition1} {-1} {}}";

        System.out.println(content);
        assertEquals(expected, content);		
	}
	
	public void testGetRepositionDataIndexOutOfRange() throws Exception {
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));
        int row = silManager.getCrystalRowFromUniqueId(uniqueId);
                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        initRepositionData(silManager, uniqueId);
    	    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "10");
    	
    	controller.getRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        
        String expected = getDefaultRepositionDataDoesNotExistTcl(silId, row, uniqueId);
        assertEquals(expected, content);		
	}
	
	public void testGetRepositionDataEmpty() throws Exception {
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "2");
    	
    	controller.getRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        
        String expected = "{}\n";
        expected += "{}\n";
        expected += "{}\n";
        expected += "{}";
        System.out.println(content);
        assertEquals(expected, content);		
		
	}
	
	public void testGetAllRepositionDataEmpty() throws Exception {
		RunDefinitionController controller = (RunDefinitionController)ctx.getBean("runDefinitionController");
    	
        int silId = 3; 
        long uniqueId = 2000194;
        
        SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
        cacheManager.removeSil(silId, false);
        SilManager silManager = cacheManager.getOrCreateSilManager(silId);
        assertEquals(0, silManager.getNumRunDefinitions(uniqueId));

                
        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
    	request.addParameter("silId", String.valueOf(silId));
    	request.addParameter("uniqueId", String.valueOf(uniqueId));
    	request.addParameter("repositionId", "2");
    	
    	controller.getAllRepositionData(request, response);
    	if (response.getStatus() != 200)
    		fail(response.getStatus() + " " + response.getErrorMessage());
        String content = response.getContentAsString().trim();
        
        String expected = "";
        System.out.println(content);
        assertEquals(expected, content);			
	}
	
	private void initRepositionData(SilManager manager, long uniqueId) throws Exception {
		
		// repos0
		MutablePropertyValues props = new MutablePropertyValues(); 
		props.addPropertyValue("label", "repos0");
		manager.addDefaultRepositionData(uniqueId, props);
		
		UnitCell c = new UnitCell(); c.setA(80.0); c.setB(81.0); c.setC(82.0); c.setAlpha(83.0); c.setBeta(84.0); c.setGamma(85.0);
		RepositionData item = new RepositionData();
		item.setRepositionId(0);
		item.setLabel("repos0"); item.setAutoindexable(1); 
		item.getAutoindexResult().setScore(14.0); item.getAutoindexResult().setUnitCell(c); item.getAutoindexResult().setMosaicity(0.08); item.getAutoindexResult().setRmsd(0.66);
		item.getAutoindexResult().setBravaisLattice("C2"); item.getAutoindexResult().setResolution(1.65); item.getAutoindexResult().setIsigma(0.99);
		manager.setRepositionData(uniqueId, 0, item);

		// repos1
		props = new MutablePropertyValues(); 
		props.addPropertyValue("label", "repos1");
		manager.addRepositionData(uniqueId, props);
		
		c = new UnitCell(); c.setA(60.0); c.setB(61.0); c.setC(62.0); c.setAlpha(63.0); c.setBeta(64.0); c.setGamma(65.0);
		item = new RepositionData(); 
		item.setRepositionId(1);
		item.setLabel("repos1"); item.setAutoindexable(1); 
		item.getAutoindexResult().setScore(8.0); item.getAutoindexResult().setUnitCell(c); item.getAutoindexResult().setMosaicity(0.05); item.getAutoindexResult().setRmsd(0.77);
		item.getAutoindexResult().setBravaisLattice("C222"); item.getAutoindexResult().setResolution(1.89); item.getAutoindexResult().setIsigma(0.87);
		manager.setRepositionData(uniqueId, 1, item);	
		
		// repos2
		props = new MutablePropertyValues(); 
		props.addPropertyValue("label", "repos2");
		manager.addRepositionData(uniqueId, props);
		
		RepositionData repos = new RepositionData();
		repos.setRepositionId(2);
		repos.setLabel("repos2");
		repos.setJpeg1("test1_0deg_001.img");
		repos.setJpeg2("test1_90deg_002.img");
		repos.setJpegBox1("test1_0deg_box_001.img");
		repos.setJpegBox2("test1_90deg_box_002.img");
		repos.setImage1("test1_001.img");
		repos.setImage2("test1_002.img");
		repos.setBeamSizeX(0.5);
		repos.setBeamSizeY(0.6);
		repos.setOffsetX(2.0);
		repos.setOffsetY(3.0);
		repos.setOffsetZ(4.0);
		repos.setEnergy(12001.0);
		repos.setDistance(300.0);
		repos.setBeamStop(50.0);
		repos.setDelta(1.0);
		repos.setAttenuation(20.0);
		repos.setExposureTime(2.0);
		repos.setFlux(10.0);
		repos.setI2(80.0);
		repos.setCameraZoom(2.0);
		repos.setScalingFactor(7.0);
		repos.setDetectorMode(2);
		repos.setBeamline("BL9-1");
		repos.setReorientInfo("/data/annikas/collect/reorient_info");
		repos.setAutoindexable(1);
		AutoindexResult result = repos.getAutoindexResult();
		result.setImages("test1_001.img test1_002.img");
		result.setScore(9.0);
		UnitCell cell = result.getUnitCell();
		cell.setA(70.0);
		cell.setB(71.0);
		cell.setC(72.0);
		cell.setAlpha(73.0);
		cell.setBeta(74.0);
		cell.setGamma(75.0);
		result.setMosaicity(0.09);
		result.setRmsd(0.88);
		result.setBravaisLattice("P4");
		result.setResolution(1.57);
		result.setIsigma(0.98);
		result.setDir("/data/annikas/webice/autoindex/A2");
		result.setBestSolution(9);
		result.setWarning("Too much ice");
		
		manager.setRepositionData(uniqueId, 2, repos);
		
	}
	
	private String getDefaultRepositionData2Tcl(int silId, int row, long uniqueId) {
		String expected = "{repos0 repos1 repos2 }\n";
		expected += "{1 1 1 }\n";
		expected += "{{{14.0} {80.0 81.0 82.0 83.0 84.0 85.0} {0.08} {0.66} {C2} {1.65} {0.99}}";
		expected += " {{8.0} {60.0 61.0 62.0 63.0 64.0 65.0} {0.05} {0.77} {C222} {1.89} {0.87}}";
		expected += " {{9.0} {70.0 71.0 72.0 73.0 74.0 75.0} {0.09} {0.88} {P4} {1.57} {0.98}} }\n";
		expected += "{" + silId + " " + row + " " + uniqueId + " 2 {repos2} {1} {test1_0deg_001.img} {test1_90deg_002.img} {test1_0deg_box_001.img} {test1_90deg_box_002.img} {test1_001.img} {test1_002.img}";
		expected += " {0.5} {0.6} {2.0} {3.0} {4.0}";
		expected += " {12001.0} {300.0} {50.0} {1.0} {20.0} {2.0} {10.0} {80.0}";
		expected += " {2.0} {7.0} {2} {BL9-1} {/data/annikas/collect/reorient_info}";
		expected += " {test1_001.img test1_002.img} {9.0} {70.0 71.0 72.0 73.0 74.0 75.0} {0.09} {0.88} {P4}";
		expected += " {1.57} {0.98} {/data/annikas/webice/autoindex/A2} {9} {Too much ice}}";
		
		return expected;
	}

	private String getDefaultRepositionData0Tcl(int silId, int row, long uniqueId) {
		String expected = "{repos0 repos1 repos2 }\n";
		expected += "{1 1 1 }\n";
		expected += "{{{14.0} {80.0 81.0 82.0 83.0 84.0 85.0} {0.08} {0.66} {C2} {1.65} {0.99}}";
		expected += " {{8.0} {60.0 61.0 62.0 63.0 64.0 65.0} {0.05} {0.77} {C222} {1.89} {0.87}}";
		expected += " {{9.0} {70.0 71.0 72.0 73.0 74.0 75.0} {0.09} {0.88} {P4} {1.57} {0.98}} }\n";
		expected += "{" + silId + " " + row + " " + uniqueId + " 0 {repos0} {1} {} {} {} {} {} {}";
		expected += " {0.0} {0.0} {0.0} {0.0} {0.0}";
		expected += " {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0} {0.0}";
		expected += " {0.0} {0.0} {0} {} {}";
		expected += " {} {14.0} {80.0 81.0 82.0 83.0 84.0 85.0} {0.08} {0.66} {C2}";
		expected += " {1.65} {0.99} {} {-1} {}}";
		
		return expected;
	}
	
	private String getDefaultRepositionDataDoesNotExistTcl(int silId, int row, long uniqueId) {
		String expected = "{repos0 repos1 repos2 }\n";
		expected += "{1 1 1 }\n";
		expected += "{{{14.0} {80.0 81.0 82.0 83.0 84.0 85.0} {0.08} {0.66} {C2} {1.65} {0.99}}";
		expected += " {{8.0} {60.0 61.0 62.0 63.0 64.0 65.0} {0.05} {0.77} {C222} {1.89} {0.87}}";
		expected += " {{9.0} {70.0 71.0 72.0 73.0 74.0 75.0} {0.09} {0.88} {P4} {1.57} {0.98}} }\n";
		expected += "{}";
		
		return expected;
	}
}
