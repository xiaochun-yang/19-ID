package webice.beans;

import java.util.Vector;
import java.util.StringTokenizer;

public class ImageHeader
{
	public double pixelSize = 0.0;
	public double distance = 0.0;
	public double phi = 0.0;
	public double oscRange = 0.0;
	public double wavelength = 0.0;
	public double beamCenterX = 0.0;
	public double beamCenterY = 0.0;
	public double expTime = 0.0;
	public String detector = "";
	public String format = "";
	public double beamCenterXPixel = 0.0;
	public double beamCenterYPixel = 0.0;
	public double detectorWidth = 0.0;
	public double detectorHeight = 0.0;
	public double detectorResolution = 0.0;

	public ImageHeader()
	{
	}

	public void parse(Vector lines)
	{
		String line = "";
		for (int i = 0; i < lines.size(); ++i) {

			line = (String)lines.elementAt(i);

			if (line.startsWith("WAVELENGTH")) {
				wavelength = Double.parseDouble(line.substring(10).trim());
			} else if (line.startsWith("DISTANCE")) {
				distance = Double.parseDouble(line.substring(8).trim());
			} else if (line.startsWith("CENTER")) {
				String val = line.substring(6).trim();
				int pos = 0;
				if (val.startsWith("X") && ((pos=val.indexOf("Y")) > 0)) {
					beamCenterXPixel = Double.parseDouble(val.substring(1, pos).trim());
					beamCenterYPixel = Double.parseDouble(val.substring(pos+1).trim());
				}
			} else if (line.startsWith("BEAM_CENTER_X")) {
				beamCenterX = Double.parseDouble(line.substring(13).trim());
			} else if (line.startsWith("BEAM_CENTER_Y")) {
				beamCenterY = Double.parseDouble(line.substring(13).trim());
			} else if (line.startsWith("PIXEL_SIZE")) {
				pixelSize = Double.parseDouble(line.substring(10).trim());
			} else if (line.startsWith("PIXEL SIZE")) {
				String val = line.substring(10).trim();
				int pos = 0;
				// In case PIXEL SIZE header contains two values
				// separated by a space.
				if ((pos=val.indexOf(' ')) > 0)
					pixelSize = Double.parseDouble(val.substring(0, pos));
				else
					pixelSize = Double.parseDouble(val);
			} else if (line.startsWith("OSCILLATION RANGE")) {
				oscRange = Double.parseDouble(line.substring(17).trim());
			} else if (line.startsWith("OSC_RANGE")) {
				oscRange = Double.parseDouble(line.substring(9).trim());
			} else if (line.startsWith("DETECTOR_")) {
				// Detector serial number
			} else if (line.startsWith("DETECTOR")) {
				detector = line.substring(8).trim();
			} else if (line.startsWith("PHI")) {
				String val = line.substring(3).trim();
				int pos = 0;
				if (val.startsWith("START") && ((pos=val.indexOf("END")) > 0))
					phi = Double.parseDouble(val.substring(5, pos).trim());
				else
					phi = Double.parseDouble(val);
			} else if (line.startsWith("FORMAT")) {
				StringTokenizer tok = new StringTokenizer(line);
				if (tok.countTokens() > 0) {
					tok.nextToken();
					format = tok.nextToken();
				};
			} else if (line.startsWith("EXPOSURE TIME")) {
					expTime = Double.parseDouble(line.substring(13).trim());
			} else if (line.startsWith("TIME")) {
					expTime = Double.parseDouble(line.substring(4).trim());
			}

			if ((beamCenterX == 0.0) && (beamCenterY == 0.0)) {
				beamCenterX = beamCenterXPixel*pixelSize;
				beamCenterY = beamCenterYPixel*pixelSize;
			}

		}

		if (detector.startsWith("PILATUS"))
			detector = "PILATUS6";	
			
		detectorWidth = getDetectorWidth(detector, format);
		detectorHeight = getDetectorHeight(detector, format);
		detectorResolution = getDetectorResolution();

	}
	
	public static double getDetectorHeight(String detector, String format) {
		if (detector.equals("PILATUS6"))
			return 423.636;
		else
			return getDetectorWidth(detector, format);
	}
	
	public static double getDetectorWidth(String detector, String format)
	{
		double detectorWidth = 0.0;

		if (detector.equals("ADSC QUANTUM4") || detector.equals("ADSC_QUANTUM4")
			|| detector.equals("ADSC+QUANTUM4")) {
			detectorWidth = 188.0;
		} else if (detector.equals("MAR 345") || detector.equals("MAR_345") || detector.equals("MAR345") 
			|| detector.equals("MAR+345") || detector.equals("mar345")) {
			if ( format.startsWith("1200") || format.startsWith("1800") ) {
				detectorWidth = 180.0;
			} else if ( format.startsWith("1600") || format.startsWith("2400") ) {
				detectorWidth = 240.0;
			} else if ( format.startsWith("2000") || format.startsWith("3000") ) {
				detectorWidth = 300.0;
			} else if ( format.startsWith("2300") || format.startsWith("3450") ) {
				detectorWidth = 345.0;
			}
		} else if (detector.equals("MARCCD165")) {
			detectorWidth = 165.0;
		} else if (detector.equals("MARCCD225")) {
			detectorWidth = 225.0;
		} else if (detector.equals("MARCCD300")) {
			detectorWidth = 300.0;
		} else if (detector.equals("MARCCD325")) {
			detectorWidth = 325.0;
		} else if (detector.equals("ADSC QUANTUM315") || detector.equals("ADSC_QUANTUM315")
				|| detector.equals("ADSC+QUANTUM315")) {
			detectorWidth = 315.0;
		} else if (detector.equals("PILATUS6")) {
			detectorWidth = 434.644;
		}

		return detectorWidth;
	}

	/**
	 */
	private double getDetectorResolution()
	{		
		double radius;
		double beamX;
		double beamY;
		if (detector.equals("PILATUS6")) {
			// Use the smaller of the two dimensions as radius.
			radius = getDetectorHeight(detector, format)/2.0;
			beamX = radius*2.0 - beamCenterX;
			beamY = beamCenterY;
		} else {
		 	radius = getDetectorWidth(detector, format)/2.0;
			beamX = radius*2.0 - beamCenterY;
			beamY = beamCenterX;
		}

//		double beamX = radius*2.0 - beamCenterY;
//		double beamY = beamCenterX;

		double dX = radius - beamX;
		double dY = radius - beamY;

		double Rx = radius + StrictMath.sqrt(dX*dX);
		double Ry = radius + StrictMath.sqrt(dY*dX);

		double Rm = StrictMath.sqrt(Rx*Rx + Ry*Ry);

		double resX = wavelength / ( 2.0 * StrictMath.sin(StrictMath.atan(Rx/distance) / 2.0) );
		double resY = wavelength / ( 2.0 * StrictMath.sin(StrictMath.atan(Ry/distance) / 2.0) );
		double resM = wavelength / ( 2.0 * StrictMath.sin(StrictMath.atan(Rm/distance) / 2.0) );

//		return resX;
		return resX < resY ? resX : resY;
	}
	
	/**
	 */
	public String toString()
	{
		StringBuffer buf = new StringBuffer();
		buf.append("pixelSize " + pixelSize + "\n");
		buf.append("distance " + distance + "\n");
		buf.append("phi " + phi + "\n");
		buf.append("oscRange " + oscRange + "\n");
		buf.append("wavelength " + wavelength + "\n");
		buf.append("beamCenterX " + beamCenterX + "\n");
		buf.append("beamCenterY " + beamCenterY + "\n");
		buf.append("expTime " + expTime + "\n");
		buf.append("detector " + detector + "\n");
		buf.append("format " + format + "\n");
		buf.append("beamCenterXPixel " + beamCenterXPixel + "\n");
		buf.append("beamCenterYPixel " + beamCenterYPixel + "\n");
		buf.append("detectorWidth " + detectorWidth + "\n");
		buf.append("detectorResolution " + detectorResolution + "\n");
		buf.append("detectorHeight " + detectorHeight + "\n");
		
		return buf.toString();
		
	}
}

