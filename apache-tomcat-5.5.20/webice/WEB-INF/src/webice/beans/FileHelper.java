package webice.beans;

import java.util.*;

public class FileHelper
{
	private static Vector scriptTypes = new Vector();
	private static Vector binaryTypes = new Vector();
	private static Vector textTypes = new Vector();

	public static String BINARY = "binary";
	public static String SCRIPT = "script";
	public static String TEXT = "text";
	public static String UNKNOWN = "unknown";

	static {
		scriptTypes.add("lookat");
		scriptTypes.add(".mfm");

		binaryTypes.add(".gen");
		binaryTypes.add(".mtz");
		binaryTypes.add(".spotod");
		binaryTypes.add("COORDS");
		binaryTypes.add("DISTL_pickle");

		textTypes.add(".py");
		textTypes.add(".sum");
		textTypes.add(".mat");
		textTypes.add(".pic");
		textTypes.add(".out");
		textTypes.add(".pic");
		textTypes.add(".mtzdmp");
		textTypes.add("LABELIT_pickle");
	}

	public static boolean isBinaryFile(String s)
	{
		return isType(s, binaryTypes);
	}

	public static boolean isTextFile(String s)
	{
		return isType(s, textTypes);
	}

	public static boolean isScriptFile(String s)
	{
		return isType(s, scriptTypes);
	}

	public static boolean isType(String s, Vector types)
	{
		String type = null;
		for (int i = 0; i < types.size(); ++i) {
			type = (String)types.elementAt(i);
			if (s.indexOf(type) >= 0)
				return true;
		}

		return false;
	}

	public static String getFileType(String s)
	{
		if (isBinaryFile(s))
			return FileHelper.BINARY;
		if (isScriptFile(s))
			return FileHelper.SCRIPT;
		else if (isTextFile(s))
			return FileHelper.TEXT;

		if ((s.indexOf("index") == 0) && (s.indexOf('.') < 0))
			return FileHelper.SCRIPT;

		return FileHelper.UNKNOWN;
	}


}

