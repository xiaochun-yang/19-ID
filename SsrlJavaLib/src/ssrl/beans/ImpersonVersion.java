package ssrl.beans;

public class ImpersonVersion {

	private String implementation;
	private int major;
	private int minor;
	
	public String getImplementation() {
		return implementation;
	}
	public void setImplementation(String implementation) {
		this.implementation = implementation;
	}
	public int getMajor() {
		return major;
	}
	public void setMajor(int major) {
		this.major = major;
	}
	public int getMinor() {
		return minor;
	}
	public void setMinor(int minor) {
		this.minor = minor;
	}
	
	@Override
	public String toString() {
		return implementation + " " + getMajor() + "." + getMinor();
	}
	
}
