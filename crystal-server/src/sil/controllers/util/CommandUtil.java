package sil.controllers.util;

import java.util.Enumeration;
import java.util.Set;

import javax.servlet.http.HttpServletRequest;

import org.springframework.beans.MutablePropertyValues;
import sil.beans.BeamlineInfo;

// Handles a command.
public class CommandUtil
{			
	static public boolean getBooleanParameter(HttpServletRequest request, String name, boolean def) {
		String str = request.getParameter(name);
		if (str == null)
			return def;
		return Boolean.parseBoolean(str);
	}
	
	static public boolean getBooleanParameter(HttpServletRequest request, String name) throws Exception {
		String str = request.getParameter(name);
		if (str == null)
			throw new Exception("Missing " + name + " parameter");
		return Boolean.parseBoolean(str);
	}	
	
	static public int getIntParameter(HttpServletRequest request, String name) throws Exception {
		
		String str = request.getParameter(name);
		if ((str == null) || (str.length() == 0))
			throw new Exception("Missing " + name + " parameter");
		try {
			return Integer.parseInt(str);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid " + name + " parameter");
		}	
	}
	
	static public int getIntParameter(HttpServletRequest request, String name, int def) throws Exception {

		String str = request.getParameter(name);
		if ((str == null) || (str.length() == 0))
			return def;
		try {
			return Integer.parseInt(str);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid " + name + " parameter");
		}
	}
		
	static public String getTemplateName(HttpServletRequest request) {
		String templateName = request.getParameter("templateName");
		if (templateName == null)
			templateName = request.getParameter("template");
		if (templateName == null)
			templateName = "ssrl";
		return templateName;
	}
	
	static public String getSheetName(HttpServletRequest request) {
		String sheetName = request.getParameter("sheetName");
		if (sheetName == null)
			sheetName = request.getParameter("forSheetName");
		if (sheetName == null)
			sheetName = "Sheet1";
		return sheetName;
	}
	
	static public String getBeamline(HttpServletRequest request, boolean required) throws Exception {
		String beamline = request.getParameter("beamline");
		if (beamline == null)
			beamline = request.getParameter("forBeamLine");
		if (beamline == null)
			beamline = request.getParameter("beamLine");
		if ((beamline == null) && required)
			throw new Exception("Missing beamline parameter");
		return beamline;
	}
	
	static public String getBeamlinePosition(HttpServletRequest request, boolean required) throws Exception {
		
		String forCassetteIndex = request.getParameter("cassettePosition");
		if ((forCassetteIndex == null) || (forCassetteIndex.length() == 0))
			forCassetteIndex= request.getParameter("forCassetteIndex");
		String beamlinePosition = null;
		if (forCassetteIndex != null) {
			switch (forCassetteIndex.charAt(0)) {
				case '0': beamlinePosition = BeamlineInfo.NO_CASSETTE; break;
				case '1': beamlinePosition = BeamlineInfo.LEFT ; break;
				case '2': beamlinePosition = BeamlineInfo.MIDDLE; break;
				case '3': beamlinePosition = BeamlineInfo.RIGHT; break;
				default: 
					throw new Exception("Invalid cassettePosition or forCassetteIndex");
			}
		} else {
			if (required)
				throw new Exception("Missing cassettePosition or forCassetteIndex parameter");
		}
		
		return beamlinePosition;
	}

	static public int getSilId(HttpServletRequest request) throws Exception {
		String silIdStr = request.getParameter("silId");
		if ((silIdStr == null) || (silIdStr.length() == 0))
			throw new Exception("Missing silId parameter");
		int silId = -1;
		try {
			silId = Integer.parseInt(silIdStr);
			if (silId <= 0)
				throw new Exception("Invalid silId parameter");
		} catch (NumberFormatException e) {
			throw new Exception("Invalid silId parameter");
		}
		return silId;
	}
	
	static public int getEventId(HttpServletRequest request) throws Exception {
		String str = request.getParameter("eventId");
		if ((str == null) || (str.length() == 0))
			throw new Exception("Missing eventId parameter");
		int eventId = -1;
		try {
			return Integer.parseInt(str);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid eventId parameter");
		}
	}
	
	static public long getUniqueId(HttpServletRequest request) throws Exception {
		String unqiueIdStr = request.getParameter("uniqueId");
		if ((unqiueIdStr == null) || (unqiueIdStr.length() == 0))
			throw new Exception("Missing uniqueId parameter");
		try {
			return Long.parseLong(unqiueIdStr);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid uniqueId parameter");
		}
	}
	
	static public long getUniqueIdNoThrow(HttpServletRequest request) throws Exception {
		String unqiueIdStr = request.getParameter("uniqueId");
		if ((unqiueIdStr == null) || (unqiueIdStr.length() == 0))
			return 0;
		try {
			return Long.parseLong(unqiueIdStr);
		} catch (NumberFormatException e) {
			return 0;
		}
	}
	
	static public int getRow(HttpServletRequest request) throws Exception {
		String rowStr = request.getParameter("row");
		if ((rowStr == null) || (rowStr.length() == 0))
			throw new Exception("Missing row parameter");
		try {
			return Integer.parseInt(rowStr);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid row parameter");
		}
	}
	
	static public int getRowNoThrow(HttpServletRequest request) throws Exception {
		String rowStr = request.getParameter("row");
		if ((rowStr == null) || (rowStr.length() == 0))
			return -1;
		try {
			return Integer.parseInt(rowStr);
		} catch (NumberFormatException e) {
			return -1;
		}
	}	
	
	static public String getCrystalId(HttpServletRequest request) throws Exception {
		String crystalId = getCrystalIdNoThrow(request);	
		if ((crystalId == null) || (crystalId.length() == 0))
			throw new Exception("Missing crystalId or CrystalID parameter");			
		return crystalId;
	}
	
	static public String getCrystalIdNoThrow(HttpServletRequest request) throws Exception {
		String crystalId = request.getParameter("crystalId");
		if ((crystalId == null) || (crystalId.length() == 0))
			crystalId = request.getParameter("CrystalID");			
		return crystalId;
	}
	
	static public MutablePropertyValues getPropertyValues(HttpServletRequest request) throws Exception
	{
		Enumeration en = request.getParameterNames();
		MutablePropertyValues props = new MutablePropertyValues();
		while (en.hasMoreElements()) {
			String propName = (String)en.nextElement();
			String propValue = (String)request.getParameter(propName);
			props.addPropertyValue(propName, propValue);
		}
		
		return props;
	}
	
	static public MutablePropertyValues getPropertyValues(HttpServletRequest request, Set<String> excludes) throws Exception
	{
		Enumeration en = request.getParameterNames();
		MutablePropertyValues props = new MutablePropertyValues();
		while (en.hasMoreElements()) {
			String propName = (String)en.nextElement();
			if (excludes.contains(propName))
				continue;
			String propValue = (String)request.getParameter(propName);
			props.addPropertyValue(propName, propValue);
		}
		
		return props;
	}
	
	static public int getRunDefinitionIndex(HttpServletRequest request) throws Exception {
		String str1 = request.getParameter("runIndex");
		if (str1 == null)
			throw new Exception("Missing run definition index");
		
		try {
			int index = Integer.parseInt(str1);
			if (index < 0)
				throw new Exception("Invalid run defition index");
			return index;
		} catch (NumberFormatException e) {
			throw new Exception("Invalid run definition index");
		}
	}
	
}
