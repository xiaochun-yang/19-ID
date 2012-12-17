package sil.beans;

public class RepositionData {

	private int repositionId;
	private String label;
	private String jpeg1;
	private String jpeg2;
	private String jpegBox1;
	private String jpegBox2;
	private String image1;
	private String image2;
	private double beamSizeX;
	private double beamSizeY;
	private double offsetX;
	private double offsetY;
	private double offsetZ;
	
	private double energy;
	private double distance;
	private double beamStop;
	private double delta;
	private double attenuation;
	private double exposureTime;
	private double flux;
	private double i2;
	private double cameraZoom;
	private double scalingFactor;
	private int detectorMode;
	private String beamline;
	
	private String reorientInfo;
	private int autoindexable = -1; // -1: not yet autoindex, 0: autoindex fails, 1: autoindex succeeds
	private AutoindexResult autoindexResult = new AutoindexResult();

	public RepositionData() {
		super();
	}
	public String getJpeg1() {
		return jpeg1;
	}
	public void setJpeg1(String jpeg1) {
		this.jpeg1 = jpeg1;
	}
	public String getJpeg2() {
		return jpeg2;
	}
	public void setJpeg2(String jpeg2) {
		this.jpeg2 = jpeg2;
	}
	public String getImage1() {
		return image1;
	}
	public void setImage1(String image1) {
		this.image1 = image1;
	}
	public String getImage2() {
		return image2;
	}
	public void setImage2(String image2) {
		this.image2 = image2;
	}
	public double getBeamSizeX() {
		return beamSizeX;
	}
	public void setBeamSizeX(double beamSizeX) {
		this.beamSizeX = beamSizeX;
	}
	public double getBeamSizeY() {
		return beamSizeY;
	}
	public void setBeamSizeY(double beamSizeY) {
		this.beamSizeY = beamSizeY;
	}
	public double getOffsetX() {
		return offsetX;
	}
	public void setOffsetX(double offsetX) {
		this.offsetX = offsetX;
	}
	public double getOffsetY() {
		return offsetY;
	}
	public void setOffsetY(double offsetY) {
		this.offsetY = offsetY;
	}
	public double getOffsetZ() {
		return offsetZ;
	}
	public void setOffsetZ(double offsetZ) {
		this.offsetZ = offsetZ;
	}
	public String getJpegBox1() {
		return jpegBox1;
	}
	public void setJpegBox1(String jpegBox1) {
		this.jpegBox1 = jpegBox1;
	}
	public String getJpegBox2() {
		return jpegBox2;
	}
	public void setJpegBox2(String jpegBox2) {
		this.jpegBox2 = jpegBox2;
	}
	public double getEnergy() {
		return energy;
	}
	public void setEnergy(double energy) {
		this.energy = energy;
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
	public double getDelta() {
		return delta;
	}
	public void setDelta(double delta) {
		this.delta = delta;
	}
	public double getAttenuation() {
		return attenuation;
	}
	public void setAttenuation(double attenuation) {
		this.attenuation = attenuation;
	}
	public double getExposureTime() {
		return exposureTime;
	}
	public void setExposureTime(double exposureTime) {
		this.exposureTime = exposureTime;
	}
	public double getFlux() {
		return flux;
	}
	public void setFlux(double flux) {
		this.flux = flux;
	}
	public double getI2() {
		return i2;
	}
	public void setI2(double i2) {
		this.i2 = i2;
	}
	public double getCameraZoom() {
		return cameraZoom;
	}
	public void setCameraZoom(double cameraZoom) {
		this.cameraZoom = cameraZoom;
	}
	public double getScalingFactor() {
		return scalingFactor;
	}
	public void setScalingFactor(double scalingFactor) {
		this.scalingFactor = scalingFactor;
	}
	public int getDetectorMode() {
		return detectorMode;
	}
	public void setDetectorMode(int detectorMode) {
		this.detectorMode = detectorMode;
	}
	public int getAutoindexable() {
		return autoindexable;
	}
	public void setAutoindexable(int autoindexable) {
		this.autoindexable = autoindexable;
	}
	public String getReorientInfo() {
		return reorientInfo;
	}
	public void setReorientInfo(String reorientInfo) {
		this.reorientInfo = reorientInfo;
	}
	public String getBeamline() {
		return beamline;
	}
	public void setBeamline(String beamline) {
		this.beamline = beamline;
	}
	public int getRepositionId() {
		return repositionId;
	}
	public void setRepositionId(int repositionId) {
		this.repositionId = repositionId;
	}
	public String getLabel() {
		return label;
	}
	public void setLabel(String label) {
		this.label = label;
	}
	public AutoindexResult getAutoindexResult() {
		return autoindexResult;
	}
	public void setAutoindexResult(AutoindexResult autoindexResult) {
		this.autoindexResult = autoindexResult;
	}

}