package ssrl.authClient.spring;

import javax.servlet.http.HttpServletRequest;

import ssrl.beans.AppSession;

public interface AppSessionManager {

	public AppSession createAppSession(String username, String password) throws Exception;
	public AppSession createAppSessionFromSessionId(String username, String sessionId) throws Exception;
	public AppSession updateAppSession(AppSession authSession) throws Exception;
	public void endSession(AppSession authSession) throws Exception;
	public void setAppSession(HttpServletRequest request, AppSession appSession);
	public AppSession getAppSession(HttpServletRequest request);
}
