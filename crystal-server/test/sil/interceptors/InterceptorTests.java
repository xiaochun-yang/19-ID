package sil.interceptors;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.servlet.HandlerInterceptor;

import sil.ControllerTestBase;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

public class InterceptorTests extends ControllerTestBase {
	
    private HandlerInterceptor userAuthenticationInterceptor;
    private HandlerInterceptor silOwnerOnlyInterceptor;
    private HandlerInterceptor silLockInterceptor;
    private HandlerInterceptor silOwnerOrBeamlineUserOnlyInterceptor;
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
		
		userAuthenticationInterceptor = (HandlerInterceptor)ctx.getBean("userAuthenticationInterceptor");
		assertNotNull(userAuthenticationInterceptor);
		silOwnerOnlyInterceptor = (HandlerInterceptor)ctx.getBean("silOwnerOnlyInterceptor");
		assertNotNull(silOwnerOnlyInterceptor);
		silLockInterceptor = (HandlerInterceptor)ctx.getBean("silLockInterceptor");
		assertNotNull(silLockInterceptor);
		silOwnerOrBeamlineUserOnlyInterceptor = (HandlerInterceptor)ctx.getBean("silOwnerOrBeamlineUserOnlyInterceptor");
		assertNotNull(silOwnerOrBeamlineUserOnlyInterceptor);
		
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}
	
	public void testUserAuthenticationInterceptorValidSMBSessionID() throws Exception {
		
		AppSessionManager appSessionManager = (AppSessionManager)ctx.getBean("appSessionManager");
    	AppSession session = appSessionManager.createAppSession(tigerw.getLoginName(), tigerw.getPassword());
    	AuthSession authSession = session.getAuthSession();
    	assertTrue(authSession.isSessionValid());

        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("userName", authSession.getUserName());
        request.addParameter("SMBSessionID", authSession.getSessionId());
        
        assertTrue(userAuthenticationInterceptor.preHandle(request, response, null));
        			
	}
	
	public void testUserAuthenticationInterceptorValidAccessID() throws Exception {
		
		AppSessionManager appSessionManager = (AppSessionManager)ctx.getBean("appSessionManager");
    	AppSession session = appSessionManager.createAppSession(tigerw.getLoginName(), tigerw.getPassword());
    	AuthSession authSession = session.getAuthSession();
    	assertTrue(authSession.isSessionValid());

        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("userName", authSession.getUserName());
        request.addParameter("accessID", authSession.getSessionId());
        
        assertTrue(userAuthenticationInterceptor.preHandle(request, response, null));
        			
	}
	
	public void testUserAuthenticationInterceptorMissingUserName() throws Exception {

        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("SMBSessionID", "XXXXXXX");
        
        assertFalse(userAuthenticationInterceptor.preHandle(request, response, null));
        
        assertEquals(500, response.getStatus());
        assertEquals("Missing userName parameter", response.getErrorMessage());
        			
	}
	
	public void testUserAuthenticationInterceptorMissingSessionId() throws Exception {

        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("userName", tigerw.getLoginName());
        
        assertFalse(userAuthenticationInterceptor.preHandle(request, response, null));
        
        assertEquals(500, response.getStatus());
        assertEquals("Missing SMBSessionID parameter", response.getErrorMessage());
        			
	}
	
	public void testUserAuthenticationInterceptorInvalidSessionId() throws Exception {

        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("userName", tigerw.getLoginName());
        request.addParameter("SMBSessionID", "XXXXXXX"); // invalid sessionId
        
        assertFalse(userAuthenticationInterceptor.preHandle(request, response, null));
        
        assertEquals(500, response.getStatus());
        assertEquals("Invalid session id", response.getErrorMessage());
        			
	}

	public void testSilOwnerOnlyInterceptor() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "4");
        
        assertTrue(silOwnerOnlyInterceptor.preHandle(request, response, null));
        			
	}
	
	public void testSilOwnerOnlyInterceptorNotOwner() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog); // wrong user
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "4");
        
        assertFalse(silOwnerOnlyInterceptor.preHandle(request, response, null));
		       
        assertEquals(500, response.getStatus());
        assertEquals("User is not the sil owner", response.getErrorMessage());
        			
	}
	
	public void testSilLockInterceptorCorrectKey() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "1"); // sil is locked with key ABCDEF
        request.addParameter("key", "ABCDEF"); // correct key
        
        assertTrue(silLockInterceptor.preHandle(request, response, null));
        			
	}
	
	public void testSilLockInterceptorSilUnlocked() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "3"); // sil is unlocked   
        assertTrue(silLockInterceptor.preHandle(request, response, null));
        			
	}
	
	public void testSilLockInterceptorSilLockedWithoutKey() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "2"); // sil is locked without key    
        assertTrue(silLockInterceptor.preHandle(request, response, null));
        			
	}
	
	public void testSilLockInterceptorWrongKey() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "1"); // sil is locked with key ABCDEF
        request.addParameter("key", "AAAAA"); // wrong key
        
        assertFalse(silLockInterceptor.preHandle(request, response, null));
		       
        assertEquals(500, response.getStatus());
        assertEquals("Wrong key", response.getErrorMessage());
        			
	}
	
	// Owner is allowed
	public void testSilOwnerOrBeamlineUserOnlyInterceptorUserIsSilOwner() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "4"); // owned by tigerw, assigned to BL7-1
        
        assertTrue(silOwnerOrBeamlineUserOnlyInterceptor.preHandle(request, response, null));
       			
	}
	
	// Beamline BL7-1 user is allowed
	public void testSilOwnerOrBeamlineUserOnlyInterceptorUserIsBeamlineUser() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog); // not owner of sil 4 but has permission to access BL7-1
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "4"); // owned by tigerw, assigned to BL7-1
        
        assertTrue(silOwnerOrBeamlineUserOnlyInterceptor.preHandle(request, response, null));
        			
	}
	
	// Owner is allowed
	public void testSilOwnerOrBeamlineUserOnlyInterceptorNotSilOwnerAndNotBeamlineUser() throws Exception {

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw); // not owner of sil 11 and does NOT have permission to access BL12-2
        MockHttpServletResponse response = new MockHttpServletResponse();	
    	
        request.addParameter("silId", "11"); // owned by sergiog, assigned to BL12-2
        request.addParameter("forBeamLine", "BL12-2"); 
        request.addParameter("forCassetteIndex", "1"); 
        
        assertFalse(silOwnerOrBeamlineUserOnlyInterceptor.preHandle(request, response, null));
        
        assertEquals(500, response.getStatus());
        assertEquals("User is not sil owner and not beamline BL12-2 user", response.getErrorMessage());
       			
	}
		
}
