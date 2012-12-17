package sil.httpunit;

import sil.AllTests;
import sil.app.FakeAppSessionManager;
import sil.app.FakeUser;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

import junit.framework.TestCase;

import com.meterware.httpunit.GetMethodWebRequest;
import com.meterware.httpunit.WebConversation;
import com.meterware.httpunit.WebRequest;
import com.meterware.httpunit.WebResponse;

// These commands do not require any authentication
public class GetterCommandControllerTests extends TestCase  {
	
	private AuthSession annikas;
	private AuthSession sergiog;
	private String baseUrl;


	@Override
	protected void setUp() throws Exception {
    	AllTests.setupDB();
    	
    	baseUrl = (String)AllTests.getApplicationContext().getBean("unsecuredBaseUrl");
    	annikas = createAuthSession(AllTests.getFakeUser("annikas"));
    	sergiog = createAuthSession(AllTests.getFakeUser("sergiog"));
    	
	}
	
	// get sil assignment for the given beamline
	public void testGetCassetteData() throws Exception {
		
		String beamline = "BL1-5";
		String url = baseUrl + "/getCassetteData.do?forBeamLine=" + beamline;	
		System.out.println("URL = " + url);
		
		WebConversation con = new WebConversation();
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		System.out.println(res.getResponseCode() + " " + res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		
	}
	
	public void testGetSilIdAndEventId() throws Exception {
		
		String beamline = "BL1-5";
		String url = baseUrl + "/getSilIdAndEventId.do?forBeamLine=" + beamline;
		System.out.println("URL = " + url);
		
		WebConversation con = new WebConversation();
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		System.out.println(res.getResponseCode() + " " + res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		
	}
	
	public void testGetLatestEventId() throws Exception {
		
		int silId = 1;
		String url = baseUrl + "/getLatestEventId.do?silId=" + String.valueOf(silId);
		System.out.println("URL = " + url);
		
		WebConversation con = new WebConversation();
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		System.out.println(res.getResponseCode() + " " + res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		
	}
	
	public void testGetCrystalData() throws Exception {
		
		String beamline = "BL1-5";
		String url = baseUrl + "/getCrystalData.do?" + getBaseQueryString(annikas)
							+ "&forBeamLine=" + beamline
							+ "&forCassetteIndex=1";		
		System.out.println("URL = " + url);
		
		WebConversation con = new WebConversation();
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		System.out.println(res.getResponseCode() + " " + res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		
	}
	
	private AuthSession createAuthSession(FakeUser user) throws Exception 
	{
    	FakeAppSessionManager appSessionManager = (FakeAppSessionManager)AllTests.getApplicationContext().getBean("appSessionManager");
    	AppSession session = appSessionManager.createAppSession(user.getLoginName(), user.getPassword());
    	if (session == null)
    		throw new Exception("Cannot create AppSession for " + user.getLoginName() + ".");
    	AuthSession authSession = session.getAuthSession();
    	if (!authSession.isSessionValid())
    		throw new Exception("Cannot create AuthSession for " + user.getLoginName() + ".");
    	
    	return authSession;
	}
	
	private String getBaseQueryString(AuthSession authSession) {
		return "userName=" + annikas.getUserName() + "&SMBSessionID=" + annikas.getSessionId();
	}
	
}
