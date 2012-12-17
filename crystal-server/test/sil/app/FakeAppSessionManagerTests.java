package sil.app;

import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;
import sil.AllTests;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

public class FakeAppSessionManagerTests  extends TestCase {
	
	private FakeUser user;
	private ApplicationContext ctx;
	private FakeAppSessionManager manager;
	
	
    @Override
	protected void setUp() throws Exception 
	{
    	ctx = AllTests.getApplicationContext();
    	manager = (FakeAppSessionManager)ctx.getBean("appSessionManager");
    	user = AllTests.getFakeUser("annikas");
	} 
    
	@Override
	protected void tearDown() throws Exception {
		manager.clearSessionCache();
	} 

    
	public void testCreateAppSessionFromUserNameAndPassword() throws Exception
    {
    	AppSession appSession = manager.createAppSession(user.getLoginName(), user.getPassword());
    	AuthSession authSession = appSession.getAuthSession();
    	assertNotNull(appSession);
    	assertNotNull(authSession);
    	assertEquals(user.getLoginName(), authSession.getUserName());
    	assertEquals(user.getBeamlines(), authSession.getBeamlines());
    	assertTrue(authSession.getStaff());
    	assertTrue(authSession.isSessionValid());
    	assertNotNull(authSession.getSessionId());
    	assertEquals(32, authSession.getSessionId().length());
    	
    }

    public void testCreateAppSessionWrongPassword()
    {
    	try {
    		AppSession appSession = manager.createAppSession(user.getLoginName(), "XXXXXXX");
    		fail("createAppSession should have failed");
    	} catch (Exception e) {
    		String errMsg = e.getMessage();
    		assertTrue(errMsg.indexOf("Invalid username or password") > -1);
    	}   	
    	
    }

    // 
    public void testCreateAppSessionFromSessionId() throws Exception
    {    		
       	String sessionId = createSessionId();
    	AppSession appSession = manager.createAppSessionFromSessionId(user.getLoginName(), sessionId);
    	AuthSession authSession = appSession.getAuthSession();
    	assertNotNull(appSession);
    	assertNotNull(authSession);
    	assertEquals(user.getLoginName(), authSession.getUserName());
    	assertEquals(user.getBeamlines(), authSession.getBeamlines());
    	assertTrue(authSession.getStaff());
    	assertTrue(authSession.isSessionValid());
    	assertEquals(sessionId, authSession.getSessionId());
   	
    }
    
    private String createSessionId() throws Exception {
    	AppSession appSession = manager.createAppSession(user.getLoginName(), user.getPassword());
    	assertNotNull(appSession);
    	assertNotNull(appSession.getAuthSession());
    	assertTrue(appSession.getAuthSession().isSessionValid());
       	return appSession.getAuthSession().getSessionId();
    }
    
    public void testCreateAppSessionFromSessionIdInvalidCredential()
    {
    	try {
    		AppSession appSession = manager.createAppSessionFromSessionId("blabla", "XXXXXXXXXXXXXXXXXXXXXXXXXXXX");    	
    	} catch (Exception e) {
    		assertEquals("Invalid credential", e.getMessage());
    	}
    	
    }
    
    public void testCreateAppSessionFromSessionIdInvalidSessionId()
    {
    	try {
    		AppSession appSession = manager.createAppSessionFromSessionId(user.getLoginName(), "XXXXXXXXXXXXXXXXXXXXXXXXXXXX");    	
    	} catch (Exception e) {
    		assertEquals("Invalid session id", e.getMessage());
    	}
    	
    }   
    
    public void testCreateAppSessionFromSessionIdWrongUserNameValidSessionId() throws Exception
    {
    	String sessionId = createSessionId();
    	
    	try {
    		AppSession anotherAppSession = manager.createAppSessionFromSessionId("tigerw", sessionId);    	
    	} catch (Exception e) {
    		assertEquals("Wrong userName", e.getMessage());
    	}
    	
    }
     
    
    public void testUpdateAppSession() throws Exception
    {
    	AppSession appSession = manager.createAppSession(user.getLoginName(), user.getPassword());
    	String sessionId = appSession.getAuthSession().getSessionId();
    	
    	AuthSession authSession = new AuthSession();
    	authSession.setSessionId(sessionId);
    	appSession.setAuthSession(authSession);
    	
    	assertEquals(sessionId, authSession.getSessionId());
    	assertNull(authSession.getUserName());
    	assertNull(authSession.getBeamlines());
    	assertFalse(authSession.getStaff());
    	assertFalse(authSession.isSessionValid());
    	
    	manager.updateAppSession(appSession);
    	
    	authSession = appSession.getAuthSession();
    	assertNotNull(appSession);
    	assertNotNull(authSession);
    	assertEquals(user.getLoginName(), authSession.getUserName());
    	assertEquals(user.getBeamlines(), authSession.getBeamlines());
    	assertTrue(authSession.getStaff());
    	assertTrue(authSession.isSessionValid());
    	assertEquals(sessionId, authSession.getSessionId());
	
    }  
    
    public void testUpdateAppSessionInvalidSessionId() throws Exception
    {
    	AppSession appSession = manager.createAppSession(user.getLoginName(), user.getPassword());
    	
    	String sessionId = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    	AuthSession authSession = new AuthSession();
    	authSession.setSessionId(sessionId);
    	appSession.setAuthSession(authSession);
    	
    	assertEquals(sessionId, authSession.getSessionId());
    	assertNull(authSession.getUserName());
    	assertNull(authSession.getBeamlines());
    	assertFalse(authSession.getStaff());
    	assertFalse(authSession.isSessionValid());
    	
    	try {
    		manager.updateAppSession(appSession);
    	} catch (Exception e) {
    		assertEquals("Invalid session id", e.getMessage());
    	}
	
    }  

    public void testEndSession() throws Exception
    {
    	AppSession appSession = manager.createAppSession(user.getLoginName(), user.getPassword());
    	String sessionId = appSession.getAuthSession().getSessionId();
    	
    	manager.endSession(appSession);
    	
    	AuthSession authSession = appSession.getAuthSession();
    	assertNotNull(appSession);
    	assertNotNull(authSession);
    	assertNull(authSession.getUserName());
    	assertNull(authSession.getBeamlines());
    	assertFalse(authSession.getStaff());
    	assertFalse(authSession.isSessionValid());
    	assertEquals(sessionId, authSession.getSessionId());
    	
	
    }


}
