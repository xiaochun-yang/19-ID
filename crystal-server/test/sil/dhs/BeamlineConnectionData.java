package sil.dhs;

public class BeamlineConnectionData {

	private String beamline;
	private String dcssHost;
	private int dcssPort;
	
	public String getDcssHost() {
		return dcssHost;
	}
	public void setDcssHost(String dcssHost) {
		this.dcssHost = dcssHost;
	}
	public int getDcssPort() {
		return dcssPort;
	}
	public void setDcssPort(int dcssPort) {
		this.dcssPort = dcssPort;
	}
	public String getBeamline() {
		return beamline;
	}
	public void setBeamline(String beamline) {
		this.beamline = beamline;
	}
}
