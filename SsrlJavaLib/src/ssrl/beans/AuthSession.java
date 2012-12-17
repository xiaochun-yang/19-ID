package ssrl.beans;

import java.util.List;

public class AuthSession {
	
	protected boolean sessionValid = false;
	protected String userName;
	protected Boolean staff = new Boolean(false);
	protected String sessionId;
	protected List<String> beamlines;

	
	public boolean isSessionValid() {
		return sessionValid;
	}
	public void setSessionValid(boolean sessionValid) {
		this.sessionValid = sessionValid;
	}
	public String getUserName() {
		return userName;
	}
	public void setUserName(String userName) {
		this.userName = userName;
	}

	public Boolean getStaff() {
		return staff;
	}
	public void setStaff(Boolean staff) {
		this.staff = staff;
	}
	public String getSessionId() {
		return sessionId;
	}
	public void setSessionId(String sessionId) {
		this.sessionId = sessionId;
	}
	public List<String> getBeamlines() {
		return beamlines;
	}
	
	public void setBeamlines(List<String> beamlines) {
		this.beamlines = beamlines;
	}

}
