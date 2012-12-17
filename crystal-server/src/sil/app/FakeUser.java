package sil.app;

import java.util.List;

public class FakeUser {
	
	private String loginName;
	private String password;
	private String realName;
	private boolean staff;
	protected List<String> beamlines;
	
	public String getLoginName() {
		return loginName;
	}
	public void setLoginName(String loginName) {
		this.loginName = loginName;
	}
	public String getRealName() {
		return realName;
	}
	public void setRealName(String realName) {
		this.realName = realName;
	}
	public boolean isStaff() {
		return staff;
	}
	public void setStaff(boolean staff) {
		this.staff = staff;
	}
	public List<String> getBeamlines() {
		return beamlines;
	}
	public void setBeamlines(List<String> beamlines) {
		this.beamlines = beamlines;
	}
	public String getPassword() {
		return password;
	}
	public void setPassword(String password) {
		this.password = password;
	}
	
}
