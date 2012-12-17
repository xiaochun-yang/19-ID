package webice.beans.autoindex;

import webice.beans.*;
import webice.beans.dcs.*;

public class AutoindexSetupData
{
	private String dir = "";
	private String host = "";
	private int port = 0;
	private String image1 = "";
	private String image2 = "";
	private String filter = "";
	private String integrate = "best";
	private boolean generateStrategy = true;

	private double distance = 0.0;
	private double centerX = 0.0;
	private double centerY = 0.0;
	private double wavelength = 0.0;
	private String detector = "";
	private String format = "";
	private double detectorWidth = 0.0;
	private double exposureTime = 0.0;
	private double oscRange = 0.0;
	private double attenuation = 0.0;

	private double detectorResolution = 0.0;
	
	private String beamline = "default";
	private String beamlineFile = "";
	private String dcsDumpFile = "";
	
	private String runName = "default";
	
	private boolean collectImages = false;
	private boolean mountSample = false;
	private int cassetteIndex = -1;
	private String silId = "";
	private String crystalPort = "";
	private String crystalId = "";
	private String imageRootName = "";
	private String expType = "Native";
	
	// Input options for collecting 2 test images
	// Run definition for test image collection
	private RunDefinition testDef = new RunDefinition();

	private double targetResolution = 0.0;
	private String laueGroup = "";	
	private double cellA = 0.0;
	private double cellB = 0.0;
	private double cellC = 0.0;
	private double cellAlpha = 0.0;
	private double cellBeta = 0.0;
	private double cellGamma = 0.0;
	
	private boolean doScan = true;
	private String scanFile = "";
	private double inflectionEn = 0.0;
	private double peakEn = 0.0;
	private double remoteEn = 0.0;
		
	private Edge edge = new Edge();
	
	static public double CURRENT_VERSION = 2.0;
	
	private double version = 1.0;
	
	private int numHeavyAtoms = 0;
	private int numResidues = 0;
	
	// Either mosflm or best
	private String strategyMethod = "unknown";
	
	private ImageHeader header1 = null;
	private ImageHeader header2 = null;
	
	private boolean reautoindex = false;
	

	public AutoindexSetupData()
	{
		clearImages();
	}

	public void reset()
	{
		dir = "";
		host = "";
		port = 0;
		image1 = "";
		image2 = "";
		filter = "";
		integrate = "best";
		generateStrategy = true;

		distance = 0.0;
		centerX = 0.0;
		centerY = 0.0;
		wavelength = 0.0;
		detector = "";
		format = "";
		detectorWidth = 0.0;
		detectorResolution = 0.0;
		exposureTime = 0.0;
		oscRange = 0.0;
		attenuation = 0.0;
		
		beamline = "";
		beamlineFile = "";
		dcsDumpFile = "";
		
		runName = "default";
		
		collectImages = false;
		mountSample = false;
		cassetteIndex = -1;
		silId = "";
		crystalPort = "";
		crystalId = "";
		imageRootName = "";
		expType = "Native";
		
		testDef.init();
		
		targetResolution = 0.0;
		laueGroup = "";
		
		cellA = 0.0;
		cellB = 0.0;
		cellC = 0.0;
		cellAlpha = 0.0;
		cellBeta = 0.0;
		cellGamma = 0.0;
		
		doScan = true;
		scanFile = "";
		inflectionEn = 0.0;
		peakEn = 0.0;
		remoteEn = 0.0;
		
		edge.name = "";
		edge.en1 = 0.0;
		edge.en2 = 0.0;
				
		version = 1.0;
		
		numHeavyAtoms = 0;
		numResidues = 0;
		
		strategyMethod = "unknown";
		
	}

	/**
	 * Calculate detector distance from target resolution, detector radius and energy.
	 */
	static public double calculateDetectorDistance(double res, double detector_radius, double energy)
	{
		// resolution = wavelength / ( 2 * sin(atan(radius/d) / 2 )
		// d = detector_radius / ( tan(2*asin(wavelength/(2*resolution) ) ) )
		double wavelength = 12398.0/energy;
		long t = Math.round(wavelength*1000.0);
		wavelength = t/1000.0;
		double distance = detector_radius / ( Math.tan(2.0*Math.asin(wavelength/(2*res) ) ) );
		t = Math.round(distance*1000);
		distance = t/1000.0;
		return distance;

	}
	
	/**
	 * Calculate resolution from detector distance, detector radius and energy
	 */
	static public double calculateResolution(double d, double radius, double energy)
	{
		double wavelength = 12398.0/energy;
		double resolution = wavelength / ( 2.0 * Math.sin(Math.atan(radius/d) / 2.0) );
		long t = Math.round(resolution*1000);
		resolution = t/1000.0;
		
		return resolution;
	}
	
	/**
	 */
	public void validateResolution(double res)
		throws Exception
	{
		
	}

	public void setImageDir(String s)
	{
		if ((s != null) && !s.equals(dir)) {
			dir = s;
			clearImages();
		}

	}

	public String getImageDir()
	{
		return dir;
	}
	
	public void setHost(String h)
	{
		if (h == null)
			return;
			
		host = h;
	}
	
	public String getHost()
	{
		return host;
	}
	
	public void setPort(int p)
	{
		port = p;
	}
	
	public int getPort()
	{
		return port;
	}

	public void setImages(String im1, String im2)
		throws Exception
	{
		if ((im1 == null) || (im2 == null))
			throw new Exception("Invalid names");

		// Expect both images to have the same root names
		// only differ in number.
		// xx_xx_NNN.xx
		// Only NNN can differ.
		int pos = im1.lastIndexOf('_');
		if (pos < 0)
			throw new Exception(im1 + " is not a valid image filename");

		int pos1 = im2.lastIndexOf('_');
		if (pos1 < 0)
			throw new Exception(im2 + " is not a valid image filename");

		if (!im1.substring(0, pos).equals(im2.substring(0, pos1)))
			throw new Exception(im1 + " and " + im2 + " have different root names");

		image1 = im1;
		image2 = im2;

	}

	public void addImage(String s)
	{
		if ((s == null) || (s.length() == 0))
			return;

		if ((image1 == null) || (image1.length() == 0)) {
			image1 = s;
			return;
		}

		if ((image2 == null) || (image2.length() == 0)) {
			image2 = s;
			return;
		}

	}

	public String getImage(int index)
	{
		if (index > 2)
			return null;

		if (index == 0)
			return image1;

		return image2;
	}

	public String getImage1()
	{
		return image1;
	}

	public String getImage2()
	{
		return image2;
	}


	public void clearImages()
	{
		image1 = "";
		image2 = "";
	}

	public void setCenterX(double x)
	{
		centerX = x;
	}

	public double getCenterX()
	{
		return centerX;
	}

	public void setCenterY(double y)
	{
		centerY = y;
	}

	public double getCenterY()
	{
		return centerY;
	}

	public void copy(AutoindexSetupData other)
	{

		// Save setup data
		dir = other.getImageDir();
		host = other.getHost();
		port = other.getPort();
		image1 = other.getImage1();
		image2 = other.getImage2();
		filter = other.getImageFilter();
		integrate = other.getIntegrate();
		generateStrategy = other.isGenerateStrategy();

		centerX = other.centerX;
		centerY = other.centerY;
		distance = other.distance;
		wavelength = other.wavelength;
		detector = other.detector;
		format = other.format;
		detectorWidth = other.detectorWidth;
		detectorResolution = other.detectorResolution;
		exposureTime = other.exposureTime;
		oscRange = other.oscRange;
		attenuation = other.attenuation;
		beamline = other.beamline;
		beamlineFile= other.beamlineFile;
		dcsDumpFile = other.dcsDumpFile;
		runName = other.runName;
		
		collectImages = other.collectImages;
		mountSample = other.mountSample;
		cassetteIndex = other.cassetteIndex;
		silId = other.silId;
		crystalPort = other.crystalPort;
		crystalId = other.crystalId;
		imageRootName = other.imageRootName;
		expType = other.expType;

		targetResolution = other.targetResolution;
		
		testDef.copy(other.testDef);
		
		laueGroup = other.laueGroup;
		cellA = other.cellA;
		cellB = other.cellB;
		cellC = other.cellC;
		cellAlpha = other.cellAlpha;
		cellBeta = other.cellBeta;
		cellGamma = other.cellGamma;
		
		doScan = other.doScan;
		scanFile = other.scanFile;
		inflectionEn = other.inflectionEn;
		peakEn = other.peakEn;
		remoteEn = other.remoteEn;
		
		numHeavyAtoms = other.numHeavyAtoms;
		numResidues = other.numResidues;
		
		edge.name = other.edge.name;
		edge.en1 = other.edge.en1;
		edge.en2 = other.edge.en2;
		
		version = other.version;
		strategyMethod = other.strategyMethod;
	}

	public boolean hasImage(String s)
	{
		if ((s == null) || (s.length() == 0))
			return false;

		if (image1.equals(s) || image2.equals(s))
			return true;

		return false;

	}
	
	public void setImageFilter(String f)
	{
		filter = f;
	}

	public String getImageFilter()
	{
		return filter;
	}

	public int getImage1Index()
	{
		return getImageIndex(1);
	}

	public int getImage2Index()
	{
		return getImageIndex(2);
	}

	private int getImageIndex(int which)
	{
		String im = image1;

		if (which == 1)
			im = image1;
		else
			im = image2;

		int pos1 = im.lastIndexOf('_');

		if (pos1 < 0)
			return -1;

		int pos2 = im.indexOf('.', pos1+1);

		if (pos2 < 0)
			return -1;

		try {
			return Integer.parseInt(im.substring(pos1+1, pos2));
		} catch (NumberFormatException e) {
		}

		return -1;

	}
	
	/**
	 */
	public void setStrategyMethod(String method)
	{
		if (method == null)
			return;
			
		strategyMethod = method;
	}
	
	/**
	 */
	public String getStrategyMethod()
	{
		return strategyMethod;
	}

	public void setIntegrate(String s)
	{
		integrate = s;
	}

	public String getIntegrate()
	{
		return integrate;
	}

	public void setGenerateStrategy(boolean s)
	{
		generateStrategy = s;
	}

	public boolean isGenerateStrategy()
	{
		return generateStrategy;
	}

	public void setWavelength(double w)
	{
		wavelength = w;
	}

	public double getWavelength()
	{
		return wavelength;
	}

	public void setDistance(double w)
	{
		distance = w;
	}

	public double getDistance()
	{
		return distance;
	}

	public void setDetector(String s)
	{
		detector = s;
	}

	public String getDetector()
	{
		return detector;
	}

	public void setDetectorFormat(String s)
	{
		format = s;
	}

	public String getDetectorFormat()
	{
		return format;
	}

	public void setBeamCenterX(double w)
	{
		centerX = w;
	}

	public double getBeamCenterX()
	{
		return centerX;
	}

	public void setBeamCenterY(double w)
	{
		centerY = w;
	}

	public double getBeamCenterY()
	{
		return centerY;
	}



	public boolean validate()
	{
	    if (dir.length() == 0)
		return false;

	    if (isCollectImages()) {

		if (imageRootName.length() == 0)
		    return false;
		if (isMountSample()) {
			if ((cassetteIndex < 1) || (cassetteIndex > 3))
		 	   return false;
			if (crystalPort.length() == 0)
				return false;
		}
		if (runName.length() == 0)
			return false;
		if (expType.length() == 0)
			return false;
			
		if (getExposureTime() < 0)
			return false;
			
		if (getOscRange() < 0.0)
			return false;
			
		if (getAttenuation() < 0.0)
			return false;
			
		if (getTargetResolution() < 0.0)
			return false;
					

	    } else {

		if (image1.length() == 0)
			return false;

		if (image2.length() == 0)
			return false;

		if (integrate.length() == 0)
			return false;
			
	    }
	    
	    if (getExpType().equals("MAD") || getExpType().equals("SAD")) {
		if (isDoScan()) {
			if (edge.name.length() == 0)
				return false;
			if (edge.en1 <= 0.0)
				return false;
		} else {
			if (getPeakEn() <= 0.0)
				return false;
/*			if (getExpType().equals("MAD")) {
				if (getInflectionEn() <= 0.0)
					return false;
				if (getRemoteEn() <= 0.0)
					return false;
			}*/
		}
	    }
	    
	    // If unit cell params are given but laue group is not define.
	    if ((getLaueGroup().length() == 0) && hasUnitCell())
	    	return false;
	    
	    if (getNumHeavyAtoms() < 0)
	    	return false;
		
	    if (getNumResidues() < 0)
	    	return false;

	    return true;

	}

	public String getExpType()
	{
		return expType;
	}

	public void setExpType(String s)
	{
		expType = s;
		if ((expType == null) || (expType.length() == 0))
			expType = "Native";
	}


	/**
	 */
	public double getExposureTime()
	{
		return exposureTime;
	}

	/**
	 */
	public void setExposureTime(double x)
	{
		exposureTime = x;
		if (exposureTime < 0.0)
			exposureTime = 0;
	}

	/**
	 */
	public double getDetectorWidth()
	{
		return detectorWidth;
	}

	/**
	 */
	public void setDetectorWidth(double w)
	{
		detectorWidth = w;

		if (detectorWidth < 0.0)
			detectorWidth = 0.0;
	}

	/**
	 */
	public double getDetectorResolution()
	{
		return detectorResolution;
	}

	/**
	 */
	public void setDetectorResolution(double s)
	{
		detectorResolution = s;
		if (detectorResolution < 0.0)
			detectorResolution = 0.0;
	}
	
	public String getBeamline()
	{
		return beamline;
	}
	
	public void setBeamline(String b)
	{
		beamline = b;
	}
	
	public void setOscRange(double value)
	{
		oscRange = value;
	}
	
	public double getOscRange()
	{
		return oscRange;
	}

        public void setAttenuation(double value)
        {
	        attenuation = value;
        }
    
	public double getAttenuation()
	{
		return attenuation;
	}

	public String getBeamlineFile()
	{
		return beamlineFile;
	}
	
	public void setBeamlineFile(String s)
	{
		beamlineFile = s;
	}
	
	public String getDcsDumpFile()
	{
		return dcsDumpFile;
	}
	
	public void setDcsDumpFile(String s)
	{
		dcsDumpFile = s;
	}
	
	public String getRunName()
	{
		return runName;
	}
	
	public void setRunName(String s)
	{
		if ((s != null) && (s.length() > 0))
			runName = s;		
	}
	
	public boolean isCollectImages()
	{
		return collectImages;
	}
	
	public void setCollectImages(boolean s)
	{
		collectImages = s;
	}
	
	public boolean isMountSample()
	{
		return mountSample;
	}
	
	public void setMountSample(boolean s)
	{
		mountSample = s;
	}
	
	public String getCassettePosition()
	{
		if (cassetteIndex == 1)
			return "left";
		else if (cassetteIndex == 2)
			return "middle";
		else if (cassetteIndex == 3)
			return "right";
			
		return "unkown";
	}
	
	public int getCassetteIndex()
	{
		return cassetteIndex;
	}
	
	public void setCassetteIndex(int s)
	{
		cassetteIndex = s;
	}
	
	public String getSilId()
	{
		return silId;
	}
	
	public void setSilId(String s)
	{
		silId = s;
	}
		
	public String getCrystalPort()
	{
		return crystalPort;
	}
	
	public void setCrystalPort(String s)
	{
		crystalPort = s;
	}
	
	public String getCrystalId()
	{
		return crystalId;
	}
	
	public void setCrystalId(String s)
	{
		crystalId = s;
	}
	
	public String getImageRootName()
	{
		return imageRootName;
	}
	
	public void setImageRootName(String s)
	{
		imageRootName = s;
	}
		
	public double getTargetResolution()
	{
		return targetResolution;
	}

	public void setTargetResolution(double x)
	{
		targetResolution = x;
		if (targetResolution < 0.0)
			targetResolution = 0;
	}


	public RunDefinition getTestRunDefinition()
	{
		return testDef;
	}
		
	public String getLaueGroup()
	{
		return laueGroup;
	}
	
	public void setLaueGroup(String s)
	{
		laueGroup = s;
	}
	
	public void setUnitCell(double a, double b, double c, double alpha, double beta, double gamma)
	{
		cellA = a;
		cellB = b;
		cellC = c;
		cellAlpha = alpha;
		cellBeta = beta;
		cellGamma = gamma;
	}
		
	public double getUnitCellA()
	{
		return cellA;
	}
	
	public double getUnitCellB()
	{
		return cellB;
	}
	
	public double getUnitCellC()
	{
		return cellC;
	}
	
	public double getUnitCellAlpha()
	{
		return cellAlpha;
	}
	
	public double getUnitCellBeta()
	{
		return cellBeta;
	}
	
	public double getUnitCellGamma()
	{
		return cellGamma;
	}
	
	public boolean hasUnitCell()
	{
		if ((cellA <= 0.0) && (cellB <= 0.0) && (cellC <= 0.0) && 
			(cellAlpha <= 0.0) & (cellBeta <= 0.0) && (cellGamma <= 0.0))
			return false;
			
		return true;
	}
	
	public double getInflectionEn()
	{
		return inflectionEn;
	}
	
	public void setInflectionEn(double s)
	{
		inflectionEn = s;
		if (inflectionEn < 0.0)
			inflectionEn = 0.0;
	}
	
	public double getPeakEn()
	{
		return peakEn;
	}
	
	public void setPeakEn(double s)
	{
		peakEn = s;
		if (peakEn < 0.0)
			peakEn = 0.0;
	}
	
	public double getRemoteEn()
	{
		return remoteEn;
	}
	
	public void setRemoteEn(double s)
	{
		remoteEn = s;
		if (remoteEn < 0.0)
			remoteEn = 0.0;
	}

	public String getScanFile()
	{
		return scanFile;
	}
	
	public Edge getEdge()
	{
		return edge;
	}
	
	public void setEdge(String s, double en1, double en2)
	{
		edge.name = s;
		if (edge.name == null)
			edge.name = "";
		edge.en1 = en1;
		if (edge.en1 < 0.0)
			edge.en1 = 0.0;
		edge.en2 = en2;
		if (edge.en2 < 0.0)
			edge.en2 = 0.0;
	}
	
	public boolean isDoScan()
	{
		return doScan;
	}	
	
	public void setDoScan(boolean s)
	{
		doScan = s;
	}
	
	public void setVersion(double v)
	{
		version = v;
	}
	
	public double getVersion()
	{
		return version;
	}
	
	public int getNumHeavyAtoms()
	{
		return numHeavyAtoms;
	}
	
	public void setNumHeavyAtoms(int n)
	{
		numHeavyAtoms = n;
	}
	
	public int getNumResidues()
	{
		return numResidues;
	}
	
	public void setNumResidues(int n)
	{
		numResidues = n;
	}
	
	public void setImageHeader(ImageHeader h1, ImageHeader h2)
	{
		header1 = h1;
		header2 = h2;
	}
	
	public ImageHeader getImageHeader1()
	{
		return header1;
	}
	
	public ImageHeader getImageHeader2()
	{
		return header2;
	}
	
	public void setReautoindex(boolean b)
	{
		reautoindex = b;
	}
	
	public boolean getReautoindex()
	{
		return reautoindex;
	}
	
	
}

