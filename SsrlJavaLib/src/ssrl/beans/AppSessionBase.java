package ssrl.beans;

public class AppSessionBase implements AppSession {
	private AuthSession authSession = null;

	public AuthSession getAuthSession() {
		return authSession;
	}

	public void setAuthSession(AuthSession authSession) {
		this.authSession = authSession;
	}
	
}
