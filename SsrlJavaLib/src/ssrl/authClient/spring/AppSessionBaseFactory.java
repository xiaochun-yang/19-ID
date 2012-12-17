package ssrl.authClient.spring;

import ssrl.beans.AppSession;
import ssrl.beans.AppSessionBase;

public class AppSessionBaseFactory implements AppSessionFactory {

	public AppSession createAppSession() {
		return new AppSessionBase();
	}

}
