package webice.beans.dcs;

import java.util.*;

/**
gtos_configure_run $deviceName $runStatus_ $nextFrame_ $runLabel_
	$fileRoot_ $directory_ $startFrame_ $axisMotorName
	$startAngle_ $endAngle_ $delta_ $wedgeSize_ $exposureTime_ $distance_ $beamStop_
	$numEnergy_ $energy1_ $energy2_ $energy3_ $energy4_ $energy5_
	$detectorMode_ $inverse_
*/
public class RunDefinition
{
	public String deviceName = ""; // run0 - run16
	public String runStatus = "inactive"; // active, inactive, paused, complete
	public int nextFrame = 0;
	public int runLabel = 0;
	public String fileRoot = "";
	public String directory = "";
	public int startFrame = 0;
	public String axisMotorName = ""; // gonio_phi
	public double startAngle = 0;
	public double endAngle = 0;
	public double delta = 0;
	public double wedgeSize = 0;
	public double exposureTime = 0.0;
	public double distance = 0.0;
	public double beamStop = 0.0;
	public double attenuation = 0.0;
	public int numEnergy = 0;
	public double energy1 = 0.0;
	public double energy2 = 0.0;
	public double energy3 = 0.0;
	public double energy4 = 0.0;
	public double energy5 = 0.0;
	public int detectorMode = 0;
	public int inverse = 0;
	
	public int repositionId = -1;
	
	public RunDefinition()
	{
	}
	
	/**
	 * Create run definition from string device
	 */
	public RunDefinition(String n, String s)
		throws Exception
	{
		StringTokenizer tok = new StringTokenizer(s, " ");
		if (tok.countTokens() != 23)
			throw new Exception("Cannot create run definition: expecting 23 params but got " + tok.countTokens());
			
		String str = "";
		deviceName =  n;
		runStatus = tok.nextToken(); // collecting, paused or inactive
		nextFrame = Integer.parseInt(tok.nextToken());
		runLabel = Integer.parseInt(tok.nextToken());
		fileRoot = tok.nextToken();
		directory = tok.nextToken();
		startFrame = Integer.parseInt(tok.nextToken());
		axisMotorName = tok.nextToken();
		startAngle = Double.parseDouble(tok.nextToken());
		endAngle = Double.parseDouble(tok.nextToken());
		delta = Double.parseDouble(tok.nextToken());
		wedgeSize = Double.parseDouble(tok.nextToken());
		exposureTime = Double.parseDouble(tok.nextToken());
               	distance = Double.parseDouble(tok.nextToken());
              	beamStop = Double.parseDouble(tok.nextToken());
		attenuation = Double.parseDouble(tok.nextToken());
		numEnergy = Integer.parseInt(tok.nextToken());
              	str = tok.nextToken();
		if (!str.equals("{}"))
			energy1 = Double.parseDouble(str);
              	str = tok.nextToken();
		if (!str.equals("{}"))
              		energy2 = Double.parseDouble(str);
              	str = tok.nextToken();
		if (!str.equals("{}"))
              		energy3 = Double.parseDouble(str);
              	str = tok.nextToken();
		if (!str.equals("{}"))
              		energy4 = Double.parseDouble(str);
              	str = tok.nextToken();
		if (!str.equals("{}"))
              		energy5 = Double.parseDouble(str);
              	str = tok.nextToken();
		if (!str.equals("{}"))
			detectorMode = Integer.parseInt(str);
              	str = tok.nextToken();
		if (!str.equals("{}"))
			inverse = Integer.parseInt(str);
       }
       
       public void init()
       {
		deviceName =  "";
		runStatus = "inactive";
		nextFrame = 0;
		runLabel = 0;
		fileRoot = "";
		directory = "";
		startFrame = 0;
		axisMotorName = "";
		startAngle = 0.0;
		endAngle = 0.0;
		delta = 0.0;
		wedgeSize = 0.0;
		exposureTime = 0.0;
               	distance = 0.0;
              	beamStop = 0.0;
		attenuation = 0.0;
		numEnergy = 0;
              	energy1 = 0.0;
              	energy2 = 0.0;
              	energy3 = 0.0;
              	energy4 = 0.0;
              	energy5 = 0.0;
		detectorMode = 0;
		inverse = 0;
		repositionId = -1;
        }
	
       public void copy(RunDefinition other)
	{
		deviceName =  other.deviceName;
		runStatus = other.runStatus;
		nextFrame = other.nextFrame;
		runLabel = other.runLabel;
		fileRoot = other.fileRoot;
		directory = other.directory;
		startFrame = other.startFrame;
		axisMotorName = other.axisMotorName;
		startAngle = other.startAngle;
		endAngle = other.endAngle;
		delta = other.delta;
		wedgeSize = other.wedgeSize;
		exposureTime = other.exposureTime;
               	distance = other.distance;
              	beamStop = other.beamStop;
		attenuation = other.attenuation;
		numEnergy = other.numEnergy;
              	energy1 = other.energy1;
              	energy2 = other.energy2;
              	energy3 = other.energy3;
              	energy4 = other.energy4;
              	energy5 = other.energy5;
		detectorMode = other.detectorMode;
		inverse = other.inverse;
		repositionId = other.repositionId;
	}
	
	/**
	 * Run definition as in dcs message format
	 */
	public String toString()
	{
		return toString(true);
	}
	
	/**
	 * Run definition as in dcs message format
	 */
	public String toString(boolean flag)
	{
		StringBuffer buf = new StringBuffer();
		if (flag) {
			buf.append(deviceName);
			buf.append(" " + runStatus);
			buf.append(" " + String.valueOf(nextFrame));
			buf.append(" " + String.valueOf(runLabel));
			buf.append(" ");
		}
		buf.append(fileRoot);
		buf.append(" " + directory);
		buf.append(" " + String.valueOf(startFrame));
		buf.append(" " + axisMotorName);
		buf.append(" " + String.valueOf(startAngle));
		buf.append(" " + String.valueOf(endAngle));
		buf.append(" " + String.valueOf(delta));
		buf.append(" " + String.valueOf(wedgeSize));
		buf.append(" " + String.valueOf(exposureTime));
		buf.append(" " + String.valueOf(distance));
		buf.append(" " + String.valueOf(beamStop));
		buf.append(" " + String.valueOf(attenuation));
		buf.append(" " + String.valueOf(numEnergy));
		buf.append(" " + String.valueOf(energy1));
		buf.append(" " + String.valueOf(energy2));
		buf.append(" " + String.valueOf(energy3));
		buf.append(" " + String.valueOf(energy4));
		buf.append(" " + String.valueOf(energy5));
		buf.append(" " + String.valueOf(detectorMode));
		buf.append(" " + String.valueOf(inverse));
		
		return buf.toString();
	}
	
}

