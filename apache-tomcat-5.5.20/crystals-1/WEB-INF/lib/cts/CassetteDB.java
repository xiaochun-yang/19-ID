/* CassetteDB.java
 */

package cts;

import java.util.Hashtable;
import java.util.Properties;
import java.util.Vector;

/**************************************************
 *
 * CassetteDB
 *
 **************************************************/
public interface CassetteDB
{

	public String getCassetteOwner(int cassetteID);
	public String removeCassette(int cassetteID);
	public String addCassette( int userID, String PIN);
	public String addCassette(String uname, String PIN);
	public String removeUser(int uid);
	public String addUser(String loginName, String uid, String realName);
	public String getXSLTemplate( String userName);
	public String getUserList();
	public int getUserID( String accessID);
	public String getUserName( int userID);
	public String mountCassette(int cassetteID, int beamlineID);
	public String addCassetteFile( int cassetteID, String filePrefix, String usrFileName);
	public void addBeamline(String name)
		throws Exception;
	public void removeBeamline(String name)
		throws Exception;
	public String getBeamlineList();
	public Vector getBeamlines();
	public String getBeamlineID(String beamlineName, String position)
		throws Exception;
	public String getCassetteIdAtBeamline(String beamlineName, String position)
		throws Exception;
	public Hashtable getAssignedBeamline(int cassetteID)
		throws Exception;
	public Hashtable getBeamlineInfo(int bid)
		throws Exception;
	public Hashtable getCassetteInfoAtBeamline(String beamlineName, String position)
		throws Exception;
	public String getCassettesAtBeamline( String beamlineName);
	public String getBeamlineName( int beamlineID);
	public String getCassetteFileName( int cassetteID);
	public String getCassetteFileList(int userID, String filterBy, String wildcard);
	public String getCassetteFileList(int userID);
	public String getCassetteFileList(String userName);
	public String getCassetteFileList(String userName, String filterBy, String wildcard);
	public Vector getUserCassettes(int userID)
		throws Exception;
	public Vector getUserCassettes(String userName)
		throws Exception;
	public Vector getUserCassettes(String userName, String filterBy, String wildcard)
		throws Exception;
	public String deleteUnusedCassetteFiles( String userName);

}
