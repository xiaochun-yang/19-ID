package sil.app;

import ssrl.authClient.spring.AppSessionFactory;
import ssrl.beans.AppSession;

public class SilAppSessionFactory implements AppSessionFactory {

	public AppSession createAppSession() {
		return new SilAppSession();
	}

}
