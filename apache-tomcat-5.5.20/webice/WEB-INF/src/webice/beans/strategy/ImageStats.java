/**
 * Javabean for SMB resources
 */
package webice.beans.strategy;

import webice.beans.*;
import java.util.StringTokenizer;

public class ImageStats
{
	public String file = "";
	public int numSpots = 0;
	public int numBraggSpots = 0;
	public int numIceRings  = 0;
	public double resolution1 = 0.0;
	public double resolution2 = 0.0;


	/**
	 */
	ImageStats()
	{
	}

	/**
	 */
	static void parse(String str, ImageStats[] stats)
		throws Exception
	{

		if ((stats[0] == null) || (stats[1] == null))
			throw new Exception("Null array passed in to ImageStats.parse()");

		StringTokenizer tok = new StringTokenizer(str, "\r\n:");

		for (int i = 0; i < 2; ++i) {

			if (!tok.nextToken().trim().equals("File"))
				throw new Exception("Cannot find File in image_stats.out");
			stats[i].file = tok.nextToken().trim();

			if (!tok.nextToken().trim().equals("Spot Total"))
				throw new Exception("Cannot find Spot Total in image_stats.out");
			stats[i].numSpots = Integer.parseInt(tok.nextToken().trim());

			if (!tok.nextToken().trim().equals("Good Bragg Candidates"))
				throw new Exception("Cannot find Good Bragg Candidates in image_stats.out");
			stats[i].numBraggSpots = Integer.parseInt(tok.nextToken().trim());

			if (!tok.nextToken().trim().equals("Ice Rings"))
				throw new Exception("Cannot find Ice Rings in image_stats.out");
			stats[i].numIceRings = Integer.parseInt(tok.nextToken().trim());

			if (!tok.nextToken().trim().equals("Method 1 Resolution"))
				throw new Exception("Cannot find Method 1 Resolution in image_stats.out");
			stats[i].resolution1 = Double.parseDouble(tok.nextToken().trim());

			if (!tok.nextToken().trim().equals("Method 2 Resolution"))
				throw new Exception("Cannot find Method 3 Resolution in image_stats.out");
			stats[i].resolution2 = Double.parseDouble(tok.nextToken().trim());

		}

	}
}

