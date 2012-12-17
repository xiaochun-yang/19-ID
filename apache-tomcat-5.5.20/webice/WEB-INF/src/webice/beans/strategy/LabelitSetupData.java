/**
 * Javabean for SMB resources
 */
package webice.beans.strategy;

import webice.beans.ImageHeader;

public class LabelitSetupData
{
	private String dir = "";
	private String image1 = "";
	private String image2 = "";
	private String filter = "";
	private String integrate = "best";
	private boolean generateStrategy = true;

	private double phi = 0.0;
	private double distance = 0.0;
	private double centerX = 0.0;
	private double centerY = 0.0;
	private double wavelength = 0.0;
	private String detector = "";
	private String format = "";
	private double detectorWidth = 0.0;



	public LabelitSetupData()
	{
		clearImages();
	}

	public void reset()
	{
		dir = "";
		image1 = "";
		image2 = "";
		filter = "";
		integrate = "best";
		generateStrategy = true;

		phi = 0.0;
		distance = 0.0;
		centerX = 0.0;
		centerY = 0.0;
		wavelength = 0.0;
		detector = "";
		format = "";
		detectorWidth = 0.0;

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

	public void copy(LabelitSetupData other)
	{

		// Save setup data
		dir = other.getImageDir();
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

	public double getDetectorWidth()
	{
		return ImageHeader.getDetectorWidth(detector, format);
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

		if (image1.length() == 0)
			return false;

		if (image2.length() == 0)
			return false;

		if (integrate.length() == 0)
			return false;

		return true;

	}

}


