package sil.app;

import java.beans.XMLDecoder;
import java.beans.XMLEncoder;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import ssrl.authClient.spring.AppSessionFactory;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

public class FakeAppSessionManager implements AppSessionManager, InitializingBean {
	
	static final String sessionIdChars = "1234567890ABCDEF";

	private Map<String, FakeUser> users = new HashMap<String, FakeUser>(); // List of user and sessionId
	private String sessionTag = "APP_SESSION";
	private int maxIdleTime = 1800000; // 30 seconds
	private AppSessionFactory appSessionFactory;
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());	
	private Map<String, FakeAuthSession> sessions = new HashMap<String, FakeAuthSession>(); // Active sessions: map of sessionId and AuthSession
	private String authSessionFile;
	
	public Map<String, FakeAuthSession> getSessions() {
		return sessions;
	}

	public void setSessions(Map<String, FakeAuthSession> sessions) {
		this.sessions = sessions;
	}

	public AppSession createAppSessionFromSessionId(String userName, String sessionId) throws Exception {
		
		if ((sessionId == null) || (sessionId.length() == 0))
			throw new Exception("null or zero length session id");
			
		if ((userName == null) || (userName.length() == 0))
			throw new Exception("null or zero length userName");
		
		if ((sessionTag == null) || (sessionTag.length() == 0))
			throw new Exception("Must set 'sessionTag' property for AppSessionManagerAuthServer bean");
		
		if (!users.containsKey(userName))
			throw new Exception("Invalid credential");
		
		FakeAuthSession authSession = getFakeAuthSession(sessionId);
		if (authSession == null) {
			throw new Exception("Invalid session id");
		}
		
		if (!authSession.getUserName().equals(userName))
			throw new Exception("Wrong userName");

		AppSession appSession = appSessionFactory.createAppSession();
		appSession.setAuthSession(authSession);
		return appSession;
	}
	
	public AppSession createAppSession(String userName, String password) throws Exception {
		
		FakeUser user = users.get(userName);
		
		if (user == null)
			throw new Exception("Invalid username or password");
		
		if (!user.getPassword().equals(password))
			throw new Exception("Invalid username or password");
		
		String sessionId = generateSessionId();
		
		FakeAuthSession authSession = new FakeAuthSession();
		authSession.setUserName(user.getLoginName());
		authSession.setBeamlines(user.getBeamlines());
		authSession.setStaff(user.isStaff());
		authSession.setSessionValid(true);
		authSession.setLastUpdateTime(System.currentTimeMillis());	
		authSession.setSessionId(sessionId);
		
		saveFakeAuthSession(authSession);
		
		AppSession appSession = appSessionFactory.createAppSession();
		appSession.setAuthSession(authSession);
		return appSession;
	}

	public AppSession updateAppSession(AppSession appSession) throws Exception {
		String sessionId = appSession.getAuthSession().getSessionId();
		FakeAuthSession session = getFakeAuthSession(sessionId);
		if (session == null)
			throw new Exception("Invalid session id");
		long now = new Date().getTime();
		if (now - session.getLastUpdateTime() > maxIdleTime) {
			invalidateAuthSession(session);
			removeFakeAuthSession(sessionId);
			throw new Exception("Invalid session id");
		}
		
		AuthSession authSession = appSession.getAuthSession();
		authSession.setUserName(session.getUserName());
		authSession.setSessionValid(session.isSessionValid());
		authSession.setBeamlines(session.getBeamlines());
		authSession.setStaff(session.getStaff());
		return null;
	}
	
	public void endSession(AppSession appSession) throws Exception {
		AuthSession session = appSession.getAuthSession();
		invalidateAuthSession(session);
		removeFakeAuthSession(session.getSessionId());
	}
	
	private void invalidateAuthSession(AuthSession authSession) {
		authSession.setSessionValid(false);
		authSession.setUserName(null);
		authSession.setBeamlines(null);
		authSession.setStaff(false);
	}
		
	// Generate sessionId like tomcat sessionId
	private String generateSessionId() {
		StringBuffer sessionId = new StringBuffer();
		Random ran = new Random();
		for (int i = 0; i < 32; ++i) {
			int index = ran.nextInt(16);
			sessionId.append(sessionIdChars.charAt(index));
		}
		return sessionId.toString();
	}

	public void afterPropertiesSet() throws Exception {
		if (users == null) 
			throw new BeanCreationException("Must set users property");
		if (appSessionFactory == null) 
			throw new BeanCreationException("Must set appSessionFactory property");
		if (authSessionFile == null)
			throw new BeanCreationException("Must set authSessionFile property");
		
		// Clear old sessions
		File file = new File(authSessionFile);
		if (file.exists()) {
			file.delete();
		}
	}

	public Map<String, FakeUser> getUsers() {
		return users;
	}

	public void setUsers(Map<String, FakeUser> users) {
		this.users = users;
	}

	public AppSessionFactory getAppSessionFactory() {
		return appSessionFactory;
	}

	public void setAppSessionFactory(AppSessionFactory appSessionFactory) {
		this.appSessionFactory = appSessionFactory;
	}

	public AppSession getAppSession(HttpServletRequest request) {
		return (AppSession)request.getSession().getAttribute(sessionTag);
	}

	public void setAppSession(HttpServletRequest request, AppSession appSession) {
		request.getSession().setAttribute(sessionTag, appSession);	
	}

	public String getSessionTag() {
		return sessionTag;
	}

	public void setSessionTag(String sessionTag) {
		this.sessionTag = sessionTag;
	}

	public int getMaxIdleTime() {
		return maxIdleTime;
	}

	public void setMaxIdleTime(int maxIdleTime) {
		this.maxIdleTime = maxIdleTime;
	}

	synchronized private FakeAuthSession getFakeAuthSession(String sessionId) throws Exception {
		loadFakeAuthSessionFile();
		FakeAuthSession authSession = sessions.get(sessionId);
		return authSession;
	}
	
	synchronized private void saveFakeAuthSession(FakeAuthSession authSession) throws Exception {
		loadFakeAuthSessionFile();
		sessions.put(authSession.getSessionId(), authSession);
		saveFakeAuthSessionFile();
	}
	
	synchronized private void removeFakeAuthSession(String sessionId) throws Exception {
		loadFakeAuthSessionFile();
		sessions.remove(sessionId);
		saveFakeAuthSessionFile();
	}
	
	private void loadFakeAuthSessionFile() throws Exception {
		File file = new File(authSessionFile);
		if (file.exists()) {
			XMLDecoder decoder = new XMLDecoder(new BufferedInputStream(new FileInputStream(authSessionFile)));
			sessions = (Map<String, FakeAuthSession>)decoder.readObject();
			decoder.close();			
		}
	}
	
	private void saveFakeAuthSessionFile() throws Exception {
		XMLEncoder encoder = new XMLEncoder(new FileOutputStream(authSessionFile));
		encoder.writeObject(sessions);
		encoder.close();	
	}

	public String getAuthSessionFile() {
		return authSessionFile;
	}

	public void setAuthSessionFile(String authSessionFile) {
		this.authSessionFile = authSessionFile;
	}
	
	public void clearSessionCache() {
		sessions.clear();
	}
}
