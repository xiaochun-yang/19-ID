package sil;

import org.jmock.integration.junit3.MockObjectTestCase;
import org.springframework.context.ApplicationContext;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockMultipartHttpServletRequest;

import sil.app.FakeAppSessionManager;
import sil.app.FakeUser;
import sil.beans.BeamlineInfo;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.dao.SilDao;
import sil.managers.SilCacheManager;
import sil.managers.SilStorageManager;

import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

public class ControllerTestBase extends MockObjectTestCase {
	
	protected FakeUser annikas;
	protected FakeUser tigerw;
	protected FakeUser lorenao;
	protected FakeUser sergiog;
	protected ApplicationContext ctx;

	
	@Override
	protected void setUp() throws Exception {
		// Create a new application context for every test.
		ctx = AllTests.getApplicationContext();
    	annikas = AllTests.getFakeUser("annikas");
    	tigerw = AllTests.getFakeUser("tigerw");
    	lorenao = AllTests.getFakeUser("lorenao");
    	sergiog = AllTests.getFakeUser("sergiog");

    	AllTests.setupDB();
    }
	

	@Override
	protected void tearDown() throws Exception {
		SilCacheManager cacheManager = (SilCacheManager)ctx.getBean("silCacheManager");
		cacheManager.clearCache();
		FakeAppSessionManager appSessionManager = (FakeAppSessionManager)ctx.getBean("appSessionManager");
		appSessionManager.clearSessionCache();
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	AllTests.restoreSilFiles(storageManager.getCassetteDir(annikas.getLoginName()));
    	AllTests.restoreSilFiles(storageManager.getCassetteDir(tigerw.getLoginName()));
    	AllTests.restoreSilFiles(storageManager.getCassetteDir(lorenao.getLoginName()));
    	AllTests.restoreSilFiles(storageManager.getCassetteDir(sergiog.getLoginName()));
    }
	
	protected MockHttpServletRequest createMockHttpServletRequest(FakeUser user) throws Exception {
		MockHttpServletRequest request = new MockHttpServletRequest();
		AppSession session = createAppSession(user);
		addAppSession(request, session);
		return request;
	}
	
	protected MockMultipartHttpServletRequest createMockMultipartHttpServletRequest(FakeUser user) throws Exception {
		MockMultipartHttpServletRequest request = new MockMultipartHttpServletRequest();
		AppSession session = createAppSession(user);
		addAppSession(request, session);
		return request;
	}
	
	protected AppSession createAppSession(FakeUser user) throws Exception 
	{
    	AppSessionManager appSessionManager = (AppSessionManager)ctx.getBean("appSessionManager");
    	AppSession session = appSessionManager.createAppSession(user.getLoginName(), user.getPassword());
    	if (session == null)
    		throw new Exception("Cannot create AppSession for " + user.getLoginName() + ".");
    	AuthSession authSession = session.getAuthSession();
    	if (!authSession.isSessionValid())
    		throw new Exception("Cannot create AuthSession for " + user.getLoginName() + ".");
    	
    	return session;
	}
	
	protected void addAppSession(MockHttpServletRequest request, AppSession session) {
		
		AppSessionManager appSessionManager = (AppSessionManager)ctx.getBean("appSessionManager");
		request.setParameter("userName", session.getAuthSession().getUserName());
        request.setParameter("SMBSessionID", session.getAuthSession().getSessionId());
        appSessionManager.setAppSession(request, session);		
	}
		
	// Make sure sil does not exist.
	protected void checkSilDoesNotExist(int silId) throws Exception {
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
    	try {
    		Sil sil = storageManager.loadSil(silId);
    	} catch (Exception e) {
    		assertEquals("silId " + silId + " does not exist.", e.getMessage().trim());
    	}		
	}
	
	// Make sure sil exists.
	protected void checkSilExists(int silId) throws Exception {
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
	}
	
	// Make sure sil exists.
	protected void checkSilExists(int silId, int numCrystals) throws Exception {
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertEquals(numCrystals, sil.getCrystals().size());	
	}	
	
	protected void checkBeamlineHasNoSil(String beamline, String position) throws Exception {
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		BeamlineInfo info = silDao.getBeamlineInfo(beamline, position);
		assertNotNull(info);
		assertEquals(0, info.getSilInfo().getId());
	}
	
	protected void checkBeamlineHasSil(String beamline, String position, int silId) throws Exception {
		SilDao silDao = (SilDao)ctx.getBean("silDao");
		BeamlineInfo info = silDao.getBeamlineInfo(beamline, position);
		assertNotNull(info);
		assertNotNull(info.getSilInfo());
		assertEquals(silId, info.getSilInfo().getId());		
	}
	protected void checkSilExists(SilInfo info) throws Exception {
		
		assertNotNull(info);
		checkSilExists(info.getId());	
	}
	
	protected void checkSilDoesNotExist(SilInfo info) throws Exception {
		
		assertNull(info);
	}	
	
	protected void checkSilAssigned(SilInfo info) {
		
		assertNotNull(info);
		assertNotNull(info.getBeamlineName());
		assertNotNull(info.getBeamlinePosition());
		
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		BeamlineInfo bInfo = storageManager.getBeamlineInfo(info.getBeamlineName(), info.getBeamlinePosition());
		assertNotNull(bInfo);
		assertNotNull(bInfo.getSilInfo());
		assertEquals(info.getId(), bInfo.getSilInfo().getId());
	}
	
	protected void checkSilNotAssigned(SilInfo info) {
		
		assertNotNull(info);
		assertNull(info.getBeamlineName());
		assertNull(info.getBeamlinePosition());
	}	
	
	protected void checkSilLocked(SilInfo info) {
		
		assertNotNull(info);
		assertTrue(info.isLocked());
	}
	
	protected void checkSilNotLocked(SilInfo info) {
		
		assertNotNull(info);
		assertFalse(info.isLocked());
	}
	
}
