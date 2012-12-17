package sil.httpunit;

import java.util.StringTokenizer;

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

// Check that URLs and interceptors in applicationContext is setup correctly for CommandUtil.
// Do not check if the command controller works or not (that's done by the controller tests).
public class CommandControllerTests extends TestCase  {
	
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
	
	public void testCreateDefaultSil() throws Exception {
		createDefaultSil(annikas);
	}
	
	private int createDefaultSil(AuthSession session) throws Exception {
		
		String url = baseUrl + "createDefaultSil.do" + "?" + getBaseQueryString(session) + "&templateName=ssrl";
		
		WebConversation con = new WebConversation();
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		assertEquals(200, res.getResponseCode());
		String msg = res.getText();
		String firstLine = "";
		StringTokenizer tok = new StringTokenizer(msg, "\n\r");
		if (tok.countTokens() > 0)
			firstLine = tok.nextToken();
		return Integer.parseInt(firstLine.substring(3).trim());
	}
	
	private String lockSil(AuthSession session, int silId) throws Exception {
		return lockSil(session, silId, "partial");
	}
	private String lockSil(AuthSession session, int silId, String lockType) throws Exception {
		
		String url = baseUrl + "setSilLock.do" + "?" + getBaseQueryString(session) 
					+ "&silId=" + String.valueOf(silId) + "&lock=true";
		if (lockType.equals("full"))
			url += "&lockType=" + lockType;
		
		WebConversation con = new WebConversation();
		con.setExceptionsThrownOnErrorStatus(false);
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		if (res.getResponseCode() != 200)
			fail(res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		assertTrue(res.getText().startsWith("OK"));
		if (lockType.equals("full")) {
			String msg = res.getText();
			return msg.substring(3).trim();
		}
		return null;
	}
	
	private void unlockSil(AuthSession session, int silId, String key) throws Exception {
		
		String url = baseUrl + "setSilLock.do" + "?" + getBaseQueryString(session) 
					+ "&silId=" + String.valueOf(silId) + "&lock=false";
		if (key != null)
			url += "&key=" + key;
		
		WebConversation con = new WebConversation();
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		assertEquals(200, res.getResponseCode());
		assertTrue(res.getResponseMessage().startsWith("OK"));
	}
	
	// User must be sil owner and sil must be unlocked or locked without key.
	public void testAddCrystalImage() throws Exception {
		
		int silId = createDefaultSil(annikas);
		String imageDir = "/data/annikas/screening";
		int row = 5;
		String group = "1";
		String imageName = "A6_001.img";
		String small = "A6_001_small.img";
		String medium = "A6_001_medium.img";
		String large = "A6_001_large.img";
		String jpeg = "A6_001.jpg";
		
		String url = baseUrl + "addCrystalImage.do" + "?" + getBaseQueryString(annikas);
		url += "&silId=" + String.valueOf(silId);
		url += "&row=" + String.valueOf(row);
		url += "&group=" + group;
		url += "&group=" + group;
		url += "&dir=" + imageDir;
		url += "&name=" + imageName;
		url += "&small=" + small;
		url += "&medium=" + medium;
		url += "&large=" + large;
		url += "&jpeg=" + jpeg;
		
		// Add image to group 1 in A6.
		System.out.println("URL = " + url);
		WebConversation con = new WebConversation();
		con.setExceptionsThrownOnErrorStatus(false);
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		if (res.getResponseCode() != 200)
			fail(res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		assertTrue(res.getText().startsWith("OK "));
		
	}
	
	// User must be sil owner
	public void testAddCrystalImageNotSilOwner() throws Exception {
		
		int silId = createDefaultSil(annikas);
		String imageDir = "/data/annikas/screening";
		int row = 5;
		String group = "1";
		String imageName = "A6_001.img";
		String small = "A6_001_small.img";
		String medium = "A6_001_medium.img";
		String large = "A6_001_large.img";
		String jpeg = "A6_001.jpg";
		
		String url = baseUrl + "addCrystalImage.do" + "?" + getBaseQueryString(sergiog); // sergiog is not owner of sil 3
		url += "&silId=" + String.valueOf(silId);
		url += "&row=" + String.valueOf(row);
		url += "&group=" + group;
		url += "&group=" + group;
		url += "&dir=" + imageDir;
		url += "&name=" + imageName;
		url += "&small=" + small;
		url += "&medium=" + medium;
		url += "&large=" + large;
		url += "&jpeg=" + jpeg;
		
		// Add image to group 1 in A6.
		System.out.println("URL = " + url);
		WebConversation con = new WebConversation();
		con.setExceptionsThrownOnErrorStatus(false);
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		System.out.println(res.getResponseCode() + " " + res.getResponseMessage());
		assertEquals(500, res.getResponseCode());
		assertTrue(res.getResponseMessage().startsWith("Not the sil owner"));
		
	}
	
	// User must be sil owner and sil must be unlocked or locked without key.
	public void testAddCrystalImageSilIsLockedWithoutKey() throws Exception {
		
		int silId = createDefaultSil(annikas);
		lockSil(annikas, silId); // lock without key
		
		String imageDir = "/data/annikas/screening";
		int row = 5;
		String group = "1";
		String imageName = "A6_001.img";
		String small = "A6_001_small.img";
		String medium = "A6_001_medium.img";
		String large = "A6_001_large.img";
		String jpeg = "A6_001.jpg";
		
		String url = baseUrl + "addCrystalImage.do" + "?" + getBaseQueryString(annikas);
		url += "&silId=" + String.valueOf(silId);
		url += "&row=" + String.valueOf(row);
		url += "&group=" + group;
		url += "&group=" + group;
		url += "&dir=" + imageDir;
		url += "&name=" + imageName;
		url += "&small=" + small;
		url += "&medium=" + medium;
		url += "&large=" + large;
		url += "&jpeg=" + jpeg;
		
		// Add image to group 1 in A6.
		System.out.println("URL = " + url);
		WebConversation con = new WebConversation();
		con.setExceptionsThrownOnErrorStatus(false);
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		if (res.getResponseCode() != 200)
			fail(res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		assertTrue(res.getText().startsWith("OK "));
		
	}
	
	// addCrystalImage fails if sil is locked with a key and we don't have the key.
	public void testAddCrystalImageSilIsLockedWithKey() throws Exception {
		
		int silId = createDefaultSil(sergiog);
		String key = lockSil(sergiog, silId, "full"); // lock with key

		String imageDir = "/data/annikas/screening";
		int row = 5;
		String group = "1";
		String imageName = "A6_001.img";
		String small = "A6_001_small.img";
		String medium = "A6_001_medium.img";
		String large = "A6_001_large.img";
		String jpeg = "A6_001.jpg";
		
		String url = baseUrl + "addCrystalImage.do" + "?" + getBaseQueryString(sergiog);
		url += "&silId=" + String.valueOf(silId);
		url += "&row=" + String.valueOf(row);
		url += "&group=" + group;
		url += "&group=" + group;
		url += "&dir=" + imageDir;
		url += "&name=" + imageName;
		url += "&small=" + small;
		url += "&medium=" + medium;
		url += "&large=" + large;
		url += "&jpeg=" + jpeg;
		
		// Add image to group 1 in A6.
		System.out.println("URL = " + url);
		WebConversation con = new WebConversation();
		con.setExceptionsThrownOnErrorStatus(false);
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		System.out.println(res.getResponseCode() + " " + res.getResponseMessage());
		assertEquals(500, res.getResponseCode());
		assertTrue(res.getResponseMessage().startsWith("Key required"));
		
	}
	
	// addCrystalImage fails if sil is locked with a key and we we supply the key in the URL.
	public void testAddCrystalImageSilHasKey() throws Exception {
		
		int silId = createDefaultSil(sergiog);
		String key = lockSil(sergiog, silId, "full"); // lock with key
		
		String imageDir = "/data/annikas/screening";
		int row = 5;
		String group = "1";
		String imageName = "A6_001.img";
		String small = "A6_001_small.img";
		String medium = "A6_001_medium.img";
		String large = "A6_001_large.img";
		String jpeg = "A6_001.jpg";
		
		String url = baseUrl + "addCrystalImage.do" + "?" + getBaseQueryString(sergiog);
		url += "&silId=" + String.valueOf(silId);
		url += "&row=" + String.valueOf(row);
		url += "&group=" + group;
		url += "&group=" + group;
		url += "&dir=" + imageDir;
		url += "&name=" + imageName;
		url += "&small=" + small;
		url += "&medium=" + medium;
		url += "&large=" + large;
		url += "&jpeg=" + jpeg;
		url += "&key=" + key;
		
		// Add image to group 1 in A6.
		System.out.println("URL = " + url);
		WebConversation con = new WebConversation();
		con.setExceptionsThrownOnErrorStatus(false);
		WebRequest req = new GetMethodWebRequest(url);
		WebResponse res = con.getResponse(req);
		if (res.getResponseCode() != 200)
			fail(res.getResponseMessage());
		assertEquals(200, res.getResponseCode());
		assertTrue(res.getText().startsWith("OK "));
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
		return "userName=" + authSession.getUserName() + "&SMBSessionID=" + authSession.getSessionId();
	}
	
}
