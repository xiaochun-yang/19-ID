package ssrl.authClient.spring;

import ssrl.beans.AppSession;

public interface AppSessionFactory {
	public AppSession createAppSession();
}
