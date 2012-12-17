package sil.beans;

// Run definition used for queuing crystals for data collection.
public class RunDefinition {
	
	private String deviceName;
	private String runStatus = "inactive";
	private int nextFrame;
	private int runLabel;
	private String fileRoot;
	private String directory;
	private int startFrame;
	private String axisMotorName;
	private double startAngle;
	private double endAngle;
	private double delta;
	private double wedgeSize;
	private int doseMode;
	private double attenuation;
	private double exposureTime;
	private int photonCount;
	private int resolutionMode;
	private double resolution;
	private double distance;
	private double beamStop;
	private int numEnergy;
	private double energy1;
	private double energy2;
	private double energy3;
	private double energy4;
	private double energy5;
	private int detectorMode;
	private int inverse;
	
	private int repositionId = -1;
		
	public String getDeviceName() {
		return deviceName;
	}
	public void setDeviceName(String deviceName) {
		this.deviceName = deviceName;
	}
	public String getRunStatus() {
		return runStatus;
	}
	public void setRunStatus(String runStatus) {
		this.runStatus = runStatus;
	}
	public int getNextFrame() {
		return nextFrame;
	}
	public void setNextFrame(int nextFrame) {
		this.nextFrame = nextFrame;
	}
	public int getRunLabel() {
		return runLabel;
	}
	public void setRunLabel(int runLabel) {
		this.runLabel = runLabel;
	}
	public String getFileRoot() {
		return fileRoot;
	}
	public void setFileRoot(String fileRoot) {
		this.fileRoot = fileRoot;
	}
	public String getDirectory() {
		return directory;
	}
	public void setDirectory(String directory) {
		this.directory = directory;
	}
	public int getStartFrame() {
		return startFrame;
	}
	public void setStartFrame(int startFrame) {
		this.startFrame = startFrame;
	}
	public String getAxisMotorName() {
		return axisMotorName;
	}
	public void setAxisMotorName(String axisMotorName) {
		this.axisMotorName = axisMotorName;
	}
	public double getStartAngle() {
		return startAngle;
	}
	public void setStartAngle(double startAngle) {
		this.startAngle = startAngle;
	}
	public double getEndAngle() {
		return endAngle;
	}
	public void setEndAngle(double endAngle) {
		this.endAngle = endAngle;
	}
	public double getDelta() {
		return delta;
	}
	public void setDelta(double delta) {
		this.delta = delta;
	}
	public double getWedgeSize() {
		return wedgeSize;
	}
	public void setWedgeSize(double wedgeSize) {
		this.wedgeSize = wedgeSize;
	}
	public double getExposureTime() {
		return exposureTime;
	}
	public void setExposureTime(double exposureTime) {
		this.exposureTime = exposureTime;
	}
	public double getDistance() {
		return distance;
	}
	public void setDistance(double distance) {
		this.distance = distance;
	}
	public double getBeamStop() {
		return beamStop;
	}
	public void setBeamStop(double beamStop) {
		this.beamStop = beamStop;
	}
	public double getAttenuation() {
		return attenuation;
	}
	public void setAttenuation(double attenuation) {
		this.attenuation = attenuation;
	}
	public int getNumEnergy() {
		return numEnergy;
	}
	public void setNumEnergy(int numEnergy) {
		this.numEnergy = numEnergy;
	}
	public double getEnergy1() {
		return energy1;
	}
	public void setEnergy1(double energy1) {
		this.energy1 = energy1;
	}
	public double getEnergy2() {
		return energy2;
	}
	public void setEnergy2(double energy2) {
		this.energy2 = energy2;
	}
	public double getEnergy3() {
		return energy3;
	}
	public void setEnergy3(double energy3) {
		this.energy3 = energy3;
	}
	public double getEnergy4() {
		return energy4;
	}
	public void setEnergy4(double energy4) {
		this.energy4 = energy4;
	}
	public double getEnergy5() {
		return energy5;
	}
	public void setEnergy5(double energy5) {
		this.energy5 = energy5;
	}
	public int getDetectorMode() {
		return detectorMode;
	}
	public void setDetectorMode(int detectorMode) {
		this.detectorMode = detectorMode;
	}
	public int getInverse() {
		return inverse;
	}
	public void setInverse(int inverse) {
		this.inverse = inverse;
	}
	public int getDoseMode() {
		return doseMode;
	}
	public void setDoseMode(int doseMode) {
		this.doseMode = doseMode;
	}
	public int getPhotonCount() {
		return photonCount;
	}
	public void setPhotonCount(int photonCount) {
		this.photonCount = photonCount;
	}
	public int getResolutionMode() {
		return resolutionMode;
	}
	public void setResolutionMode(int resolutionMode) {
		this.resolutionMode = resolutionMode;
	}
	public double getResolution() {
		return resolution;
	}
	public void setResolution(double resolution) {
		this.resolution = resolution;
	}
	public int getRepositionId() {
		return repositionId;
	}
	public void setRepositionId(int repositionId) {
		this.repositionId = repositionId;
	}
	
	
}
