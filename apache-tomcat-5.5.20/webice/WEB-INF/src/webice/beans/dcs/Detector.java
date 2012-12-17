package webice.beans.dcs;

import java.util.Hashtable;

public class Detector
{
	static private Hashtable detectorLookup = new Hashtable();
	
	/**
	 * Returns dcs detector type for the detector type found
	 * in image header
	 */
	static public String getDcsDetectorType(String imageDetectorType)
	{
		if (detectorLookup.size() == 0) {
			detectorLookup.put("QUANTUM4", "Q4CCD");
			detectorLookup.put("ADSC QUANTUM4", "Q4CCD");
			detectorLookup.put("ADSC+QUANTUM4", "Q4CCD");
			detectorLookup.put("ADSC_QUANTUM4", "Q4CCD");
			detectorLookup.put("ADSC QUANTUM315", "Q315CCD");
			detectorLookup.put("ADSC+QUANTUM315", "Q315CCD");
			detectorLookup.put("ADSC_QUANTUM315", "Q315CCD");
			detectorLookup.put("MAR 345", "MAR345");
			detectorLookup.put("MAR+345", "MAR345");
			detectorLookup.put("MAR_345", "MAR345");
			detectorLookup.put("mar345", "MAR345");
			detectorLookup.put("MARCCD345", "MAR345");
			detectorLookup.put("MARCCD165", "MAR165");
			detectorLookup.put("MARCCD325", "MAR325");
			detectorLookup.put("PILATUS 6M", "PILATUS6");
			detectorLookup.put("PILATUS 6", "PILATUS6");
		}
		
		String ret = (String)detectorLookup.get(imageDetectorType);
		if (ret != null)
			return ret;
		return imageDetectorType;
	}
}

