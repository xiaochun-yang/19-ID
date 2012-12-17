package webice.beans.strategy;

import java.util.*;

public class SpacegroupHelper
{
	private static Hashtable spacegroups = new Hashtable();

	/**
	 * Returns all spacegroups in the same cystal system
	 * as the given spacegroup.
	 */
	public static Vector getSpacegroups(String lowestSymmetry)
	{
		return (Vector)spacegroups.get(lowestSymmetry);
	}


	static {

		Vector group = new Vector();
		group.add("P1");
		spacegroups.put("P1", group);

		group = new Vector();
		group.add("P2");
		spacegroups.put("P2", group);

		group = new Vector();
		group.add("C2");
		spacegroups.put("C2", group);

		group = new Vector();
		group.add("P222");
		spacegroups.put("P222", group);

		group = new Vector();
		group.add("I222");
		spacegroups.put("I222", group);

		group = new Vector();
		group.add("C222");
		spacegroups.put("C222", group);

		group = new Vector();
		group.add("F222");
		spacegroups.put("F222", group);

		group = new Vector();
		group.add("P4");
		group.add("P422");
		spacegroups.put("P4", group);

		group = new Vector();
		group.add("I4");
		group.add("I422");
		spacegroups.put("I4", group);

		group = new Vector();
		group.add("P3");
		group.add("P312");
		group.add("P321");
		group.add("P6");
		group.add("P622");
		spacegroups.put("P3", group);

		group = new Vector();
		group.add("H3");
		group.add("H32");
		spacegroups.put("H3", group);

		group = new Vector();
		group.add("P23");
		group.add("P432");
		spacegroups.put("P23", group);

		group = new Vector();
		group.add("I23");
		spacegroups.put("I23", group);

		group = new Vector();
		group.add("F23");
		group.add("F432");
		spacegroups.put("F23", group);

	}
}
