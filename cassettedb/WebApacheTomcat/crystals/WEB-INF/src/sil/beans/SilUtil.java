package sil.beans;

import java.util.*;
import cts.*;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

public class SilUtil
{
	private static CassetteDB ctsdb = null;
	private static CassetteIO ctsio = null;

	synchronized public static CassetteDB getCassetteDB()
		throws Exception
	{
		SilConfig silConfig = SilConfig.getInstance();
		if (ctsdb == null) {
			ctsdb = CassetteDBFactory.getCassetteDB(silConfig);
		}

		return ctsdb;
	}

	synchronized public static CassetteIO getCassetteIO()
	{
		if (ctsio == null) {
			ctsio = new CassetteIO();
		}

		return ctsio;
	}

	/**
	 * Find out if this session has acces to this beamline
	 */
	public static boolean hasBeamTime(AuthGatewayBean auth, String beamlineName)
	{
		if(beamlineName==null || beamlineName.equalsIgnoreCase("None"))
			return true;


		Hashtable uProp = auth.getProperties();
		String allBls = (String)uProp.get("Auth.AllBeamlines");
		String bls = (String)uProp.get("Auth.Beamlines");
		if (bls.equals("ALL")) {
			bls = allBls;
			return true;
		} else {
			boolean doneOnce = false;
			String bl = "";
			StringTokenizer tok = new StringTokenizer(bls, ";");
			bls = "";
			while (tok.hasMoreTokens()) {
				bl = (String)tok.nextToken();
				if (bl.equals("ALL") && !doneOnce) {
					bls = bls + ";" + allBls;
					doneOnce = true;
				} else {
					if (bls.length() > 0) {
						bls = bls + ";" + bl;
					} else {
						bls = bl;
					}
				}
			}
				

		}

		String enabledBeamlines = bls;

		if (enabledBeamlines == null)
			return false;

		if (enabledBeamlines.equalsIgnoreCase("ALL"))
			return true;

		StringTokenizer st = new  StringTokenizer(enabledBeamlines, " ;,.\t\n\r");
		while (st.hasMoreTokens()) {
			// Name we get from auth server can be
			// an official beamline name (e.g. BL9-1) or
			// an alias name (e.g 9-1)
			String token = st.nextToken();

			// Find official name from alias
			String enabledBeamline = SilConfig.getInstance().getBeamlineName(token);

			// If not found then use the alias
			if ((enabledBeamline == null) || (enabledBeamline.length() == 0))
				enabledBeamline = token;

			if(enabledBeamline.equalsIgnoreCase(beamlineName))
				return true;
		}

		return false;
	}

	/**
	 * Check the xml string
	 */
	public static boolean isError(String x)
	{
		return ( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0);
	}


	/**
	 * parse error from xml string
	 */
	public static String parseError(String xmlError)
	{
		int pos1 = xmlError.indexOf("<Error>");
		int pos2 = xmlError.indexOf("</Error>");
		if ((pos1 >= 0) && (pos2 >= pos1))
			return xmlError.substring(pos1+7, pos2);

		return xmlError;
	}
}
