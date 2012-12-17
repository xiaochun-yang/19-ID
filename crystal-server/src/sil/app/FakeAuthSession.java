package sil.app;

import ssrl.beans.AuthSession;

public class FakeAuthSession  extends AuthSession {

	private long lastUpdateTime;

	public long getLastUpdateTime() {
		return lastUpdateTime;
	}

	public void setLastUpdateTime(long lastUpdateTime) {
		this.lastUpdateTime = lastUpdateTime;
	}
}
