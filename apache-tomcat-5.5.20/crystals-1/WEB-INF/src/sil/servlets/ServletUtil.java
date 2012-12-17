package sil.servlets;

import javax.servlet.*;
import javax.servlet.http.*;
import java.util.Hashtable;
import java.io.IOException;

import sil.beans.*;
import cts.CassetteDB;
import cts.CassetteIO;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

public class ServletUtil
{
	public static int RC_401 = 401;
	public static int RC_421 = 421;
	public static int RC_430 = 430;
	public static int RC_431 = 431;
	public static int RC_432 = 432;
	public static int RC_433 = 433;
	public static int RC_434 = 434;
	public static int RC_435 = 435;
	public static int RC_436 = 436;
	public static int RC_437 = 437;
	public static int RC_438 = 438;
	public static int RC_439 = 439;
	public static int RC_440 = 440;
	public static int RC_441 = 441;
	public static int RC_442 = 442;
	public static int RC_443 = 443;
	public static int RC_444 = 444;
	public static int RC_445 = 445;
	public static int RC_446 = 446;
	public static int RC_447 = 447;
	public static int RC_448 = 448;
	public static int RC_449 = 449;
	public static int RC_450 = 450;
	public static int RC_451 = 451;
	public static int RC_452 = 452;
	public static int RC_453 = 453;
	public static int RC_454 = 454;
	public static int RC_455 = 455;
	public static int RC_456 = 456;
	public static int RC_457 = 457;
	public static int RC_458 = 458;
	public static int RC_459 = 459;
	public static int RC_460 = 460;
	public static int RC_461 = 461;
	public static int RC_462 = 462;
	public static int RC_463 = 463;
	public static int RC_464 = 464;
	public static int RC_465 = 465;

	private static String loginSessionName= "SMBSessionID";
	
	private static Hashtable errorCode = new Hashtable();

	static {
		errorCode.put(new Integer(RC_401), "Authentication failed");
		errorCode.put(new Integer(RC_421), "Authentication failed");
		errorCode.put(new Integer(RC_430), "Missing userName parameter");
		errorCode.put(new Integer(RC_431), "Invalid username parameter");
		errorCode.put(new Integer(RC_432), "Missing silId parameter");
		errorCode.put(new Integer(RC_433), "Invalid silId parameter");
		errorCode.put(new Integer(RC_434), "Missing row parameter");
		errorCode.put(new Integer(RC_435), "Invalid row parameter");
		errorCode.put(new Integer(RC_436), "Missing fileName parameter");
		errorCode.put(new Integer(RC_437), "Invalid fileName parameter");
		errorCode.put(new Integer(RC_438), "Missing group parameter");
		errorCode.put(new Integer(RC_439), "Invalid group parameter");
		errorCode.put(new Integer(RC_440), "Missing beamLine or forBeamLine parameter");
		errorCode.put(new Integer(RC_441), "Invalid beamLine or forBeamLine parameter");
		errorCode.put(new Integer(RC_442), "Missing cassettePosition or forCassetteIndex parameter");
		errorCode.put(new Integer(RC_443), "Invalid cassettePosition or forCassetteIndex parameter");
		errorCode.put(new Integer(RC_444), "Missing eventId parameter");
		errorCode.put(new Integer(RC_445), "Invalid eventId parameter");
		errorCode.put(new Integer(RC_446), "User has no permission to access beamline");
		errorCode.put(new Integer(RC_447), "Invalid forBeamlineID parameter");
		errorCode.put(new Integer(RC_448), "Missing attrName parameter");
		errorCode.put(new Integer(RC_449), "Invalid attrName parameter");
		errorCode.put(new Integer(RC_450), "Missing attrValues parameter");
		errorCode.put(new Integer(RC_451), "Invalid attrvalues parameter");
		errorCode.put(new Integer(RC_452), "Missing CrystalID parameter");
		errorCode.put(new Integer(RC_453), "Invalid CrystalID parameter");
		errorCode.put(new Integer(RC_454), "Missing Port parameter");
		errorCode.put(new Integer(RC_455), "Invalid Port parameter");
		errorCode.put(new Integer(RC_456), "Missing silList parameter");
		errorCode.put(new Integer(RC_457), "Invalid silList parameter");
		errorCode.put(new Integer(RC_458), "Missing key parameter");
		errorCode.put(new Integer(RC_459), "Invalid key parameter");
		errorCode.put(new Integer(RC_460), "Missing srcSil parameter");
		errorCode.put(new Integer(RC_461), "Invalid srcSil parameter");
		errorCode.put(new Integer(RC_462), "Missing srcPort parameter");
		errorCode.put(new Integer(RC_463), "Invalid srcPort parameter");
		errorCode.put(new Integer(RC_464), "Missing destPort parameter");
		errorCode.put(new Integer(RC_465), "Invalid destPort parameter");
	}



	/**
	 */
	public static String getError(int code)
	{
		String str = (String)errorCode.get(new Integer(code));

		if (str == null)
			str = "unknown error";

		return str;
	}

	/**
	 */
	public static String getSessionId(HttpServletRequest req)
	{

		// try to get it from a query string parameter
		String sessionId= req.getParameter("accessID");
		if (sessionId != null)
		{
			return sessionId;
		}

		// try to get it from another query string parameter
		sessionId = req.getParameter(loginSessionName);
		if( sessionId!=null)
		{
			return sessionId;
		}
		
		// Get it from session obj
		HttpSession session = req.getSession();
		if (session != null) {
			AuthGatewayBean gate = (AuthGatewayBean)session.getAttribute("gate");
			if (gate != null) {
				sessionId = gate.getSessionID();
				if ((sessionId != null) && (sessionId.length() > 0))
					return sessionId;
			}
		}
/*
		// try to get it from the cookie that was set during the login
		Cookie[] cookies= req.getCookies();
		int lng= 0;
		if( cookies!=null)
		{
		lng= cookies.length;
		}
		for( int i= 0; i<lng; i++)
		{
			if( cookies[i].getName().equalsIgnoreCase(loginSessionName) )
			{
				sessionId= cookies[i].getValue();
			}
		}
		if( sessionId != null )
		{
			return sessionId;
		}

		// try to get it from the cockie that we have set during checkAccessID()
		cookies= req.getCookies();
		lng= 0;
		if( cookies!=null)
		{
			lng= cookies.length;
		}
		for( int i= 0; i<lng; i++)
		{
			if( cookies[i].getName().equalsIgnoreCase("SMBSessionID") )
			{
				sessionId= cookies[i].getValue();
			}
		}
*/
		return sessionId;


	}
	
	static public String getUserName(HttpServletRequest request)
	{
		String n = request.getParameter("userName");
		if (n != null)
			return n;
		
		HttpSession s = request.getSession();
	
		if (s == null)
			return null;
		
		AuthGatewayBean g = (AuthGatewayBean)s.getAttribute("gate");
		if (g == null)
			return null;
		
		return (String)g.getUserID();
	
	}

	static public boolean isTrue(String s)
	{
		if (s == null)
			return false;
			
		String ss = s.toLowerCase();
			
		return (ss.equals("yes") || ss.equals("true") || ss.equals("t") || ss.equals("y"));
			
	}
	
	static public boolean isUserStaff(AuthGatewayBean gate)
	{
		if (gate == null)
			return false;
		Hashtable hash = gate.getProperties();
		return isTrue((String)hash.get("Auth.UserStaff"));
	}
	
	/**
	 * Used by jsp pages
	 */
	static public boolean checkAccessID(HttpServletRequest request,  HttpServletResponse response)
    		throws IOException
	{	
		// Get session id from accessID or SMBSessionID parameter
		// in the request or from gate obj.
		String accessID = getSessionId(request);
						
		SilConfig cf = SilConfig.getInstance();
		
		AuthGatewayBean gate = null;
		HttpSession session = request.getSession();
		if (session != null) {
			gate = (AuthGatewayBean)session.getAttribute("gate");
		}
										
		// If accessID saved in the session is not equal the given accessID
		// then create a new AuthGateWayBean
		if ((accessID != null) && (accessID.length() > 0)) {
			String servletHost = cf.getAuthServletHost();
			if (gate == null) {
				System.out.println("in ServletUtil::chechAccessID gate == null");
				gate = new AuthGatewayBean();
				gate.initialize(accessID, "Crystals", servletHost);
				session.setAttribute("gate", gate);
			} else {
				if (accessID.equals(gate.getSessionID())) {
					gate.updateSessionData(true);
				} else {
					gate.initialize(accessID, "Crystals", servletHost);
				}
			}
		} else {
			// Return false if accessID is not supplied in the request and 
			// gate obj is null in this session.
			if (gate == null)
				return false;
			else 
				gate.updateSessionData(true);
		}
				
		if (!gate.isSessionValid())
			return false;
			
		Hashtable hash = gate.getProperties();
		String userStaff = (String)hash.get("Auth.UserStaff");
		boolean hasStaffPrivilege = isTrue(userStaff);
		
		if (hasStaffPrivilege)
			return true;
		
		// Normal user may only see his own data and not the data of other users
		String userName= request.getParameter("userName");
		if (!hasStaffPrivilege && (userName != null) && userName.equalsIgnoreCase(gate.getUserID())) {
			return true;
		}
		
/*		if (validSession) {
			// save a cookie with the accessID
			Cookie c= new Cookie("SMBSessionID", accessID);
			c.setMaxAge(-1);
			c.setPath("/");
			response.addCookie(c);
		}*/

		return false;
	}

	public static AuthGatewayBean getAuthGatewaySession(HttpServletRequest req)
	{
		String sessionId = getSessionId(req);
		AuthGatewayBean auth = new AuthGatewayBean();
		String servletHost = SilConfig.getInstance().getAuthServletHost();
//		SilLogger.info("ServletUtil::getAuthGetwaySession: session = " + sessionId + " auth servletHost = " + servletHost);
		auth.initialize(sessionId, "Crystals", servletHost);

		return auth;
	}

}
