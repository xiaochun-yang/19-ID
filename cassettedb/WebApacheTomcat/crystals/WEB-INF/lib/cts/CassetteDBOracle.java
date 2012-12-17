/* CassetteDB.java
* JavaBean for the Cassette Tracking System
* calls stored procedures in the Oracle database
*
* works with Oracle jdbc driver using OCI net8 or with "thin" Oracle jdbcs driver (without net8)
* requires in classpath the Oracle 8i file C:\oracle\ora81\jdbc\lib\classes111.zip
*
* setenv CLASSPATH=${CLASSPATH};C:\oracle\ora81\jdbc\lib\classes111.zip
* or on win2000
* set CLASSPATH=%CLASSPATH%;C:\oracle\ora81\jdbc\lib\classes111.zip
* Windows 2000 needs restart!
*
* in forte filesystem | mount jar | "C:\oracle\ora81\jdbc\lib\classes111.zip"
*
*
To use this class as a COM server (see "regi.bat"):
cd T:\prog\db1\ctsdb
copy ctsdb.class C:\WINNT\java\trustlib\
cd C:\WINNT\java\trustlib\
"C:\Program Files\Microsoft Visual Studio\VIntDev98\bin\JAVAREG.EXE" /unregister /class:CassetteDB /progid:CassetteDB
"C:\Program Files\Microsoft Visual Studio\VIntDev98\bin\JAVAREG.EXE" /register /class:CassetteDB /progid:CassetteDB
restart IIS !!!
*
*
*/

package cts;

import java.util.*;
import java.sql.*;
import oracle.jdbc.driver.*;
import java.text.*;
import java.io.*;
import java.util.regex.*;
//
// Here are the dbcp-specific classes.
// Note that they are only used in the setupDataSource
// method. In normal use, your classes interact
// only with the standard JDBC API
//
import org.apache.commons.dbcp.BasicDataSource;
import org.apache.commons.dbcp.DelegatingStatement;

/**************************************************
 *
 * CassetteDB
 *
 **************************************************/
public class CassetteDBOracle implements Serializable, CassetteDB
{
	private static String m_strDSN="";
	private static String m_userName="";
	private static String m_password="";

	private static String m_testDataHome="";

	private BasicDataSource datasource = null;
	
	private static CassetteDB singleton = null;


public static CassetteDB getCassetteDB(Properties prop)
	throws Exception
{
	if (singleton == null)
		singleton = new CassetteDBOracle(prop);
		
	return singleton;
}

public CassetteDBOracle(Properties prop)
	throws Exception
{
		
	String dsn = (String)prop.get("dbDsn");
	String u = (String)prop.get("dbUserName");
	String p = (String)prop.get("dbPassword");
	
	setDSN(dsn);
	setUserName(u);
	setPassword(p);
	
	datasource = null;
	datasource = new BasicDataSource();
	datasource.setDriverClassName("oracle.jdbc.driver.OracleDriver");
	datasource.setUsername(m_userName);
	datasource.setPassword(m_password);
	datasource.setUrl(m_strDSN);
	
}

private void setDSN( String x)
{
	m_strDSN= x;
}

private String getDSN()
{
	return m_strDSN;
}

private void setUserName( String x)
{
	m_userName= x;
}

private String getUserName()
{
	return m_userName;
}

private void setPassword( String x)
{
	m_password= x;
}

private String getPassword()
{
	return m_password;
}

private void setDataHome( String x)
{
	m_testDataHome= x;
}

private String getDataHome()
{
	return m_testDataHome;
}

/**
 * Get or create a DB connection
 */
private Connection getConnection()
	throws java.sql.SQLException
{
	return datasource.getConnection();
}

/**
 * Convenient method to close the DB connection
 */
private void closeConnectionNoThrow(Connection connection, String method)
{
	try {
		connection.close(); // close DB connection
	} catch (SQLException e) {
		System.out.println("Error in " + method + ": failed to close DB connection: " + e.toString());
//		e.printStackTrace();
	}
}


/**
 * Convenient method to create an xml error string
 */
private String getErrorString(String method, String message)
{
	return "<Error>" + method + ": " + message + "</Error>";
}


//---------------------------------

public String removeCassette( int cassetteID)
{

	// returns unique file name "STOREFILENAME"
	String data= "";
	String strSQL = "{CALL CTS_REMOVECASSETTE(?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, cassetteID);
	  cstmt.execute();
	  data+= "OK";
	  connection.close();

   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("removeCassette", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "removeCassette");
   }


   return data;

}


//---------------------------------

public String removeUser(int userID)
{
	// returns unique file name "STOREFILENAME"
	String data= "";
	String strSQL = "{CALL CTS_REMOVEUSER(?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, userID);
	  cstmt.execute();
	  data+= "OK";
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("removeUser", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "removeUser");
   }

	return data;
}


//---------------------------------

public String addCassette(String uname, String PIN)
{
	int userID = getUserID(uname);
	
	if (userID < 0)
		return getErrorString("addCassette", "Cannot find user id for user " + uname);

	// returns unique file name "STOREFILENAME"
	String data= "";
	String strSQL = "{CALL CTS_ADDCASSETTE(?,?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, userID);
	  cstmt.setString(2, PIN);
	  cstmt.registerOutParameter(3, Types.INTEGER);
	  cstmt.execute();
	  data+= ""+ cstmt.getInt(3);
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("addCassette", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "addCassette");
   }

	return data;
}

//---------------------------------

public String addCassette( int userID, String PIN)
{
	// returns unique file name "STOREFILENAME"
	String data= "";
	String strSQL = "{CALL CTS_ADDCASSETTE(?,?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, userID);
	  cstmt.setString(2, PIN);
	  cstmt.registerOutParameter(3, Types.INTEGER);
	  cstmt.execute();
	  data+= ""+ cstmt.getInt(3);
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("addCassette", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "addCassette");
   }

	return data;
}

//---------------------------------

public String addUser( String loginName, String uid, String realName)
{
	// returns unique file name "STOREFILENAME"
	String data= "";
	String strSQL = "{CALL CTS_addUser(?,?,?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setString(1, loginName);
	  cstmt.setString(2, uid);
	  cstmt.setString(3, realName);
	  cstmt.registerOutParameter(4, Types.INTEGER);
	  cstmt.execute();
	  data+= ""+ cstmt.getInt(4);
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("addUser", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "addUser");
   }

	return data;
}

//---------------------------------

public String getXSLTemplate( String userName)
{
String data= "";
String strSQL = "{CALL CTS_GETUSERINFO(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setString(2, userName);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)delegating).getCursor(1);

	  while (rs.next())
	  {
		  data+= ""+rs.getString("DATA_IMPORT_TEMPLATE");
	  }
	  rs.close();
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getXSLTemplate", ex.toString());
		System.out.println(data);
//		ex.printStackTrace();
		this.closeConnectionNoThrow(connection, "getXSLTemplate");
   }

	return data;
}

//---------------------------------

public String getUserList()
{
String data= "";
String strSQL = "{CALL CTS_GETUSERINFO(?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	  data+= "<UserList>";
	  data+= "\r\n";
	  while (rs.next())
	  {
		  data+= "<Row>";
		  data+=  emitElement("UserID", rs.getString("USER_ID"));
		  data+=  emitElement("LoginName", rs.getString("LOGIN_NAME"));
		  data+=  emitElement("MySQLUserID", rs.getString("MYSQL_USERID"));
		  data+=  emitElement("RealName", rs.getString("REAL_NAME"));
		  data+=  emitElement("DataImportTemplate", rs.getString("DATA_IMPORT_TEMPLATE"));
		  data+= "</Row>";
		  data+= "\r\n";
	  }
	  data+= "</UserList>";
	  data+= "\r\n";
	  rs.close();
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getUserList", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getUserList");
//		ex.printStackTrace();
   }

	return data;
}

//---------------------------------

public int getUserID( String accessID)
{
	int userID= -1;
	String strSQL = "{CALL CTS_GETUSERID(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setString(1, accessID);
	  cstmt.registerOutParameter(2, Types.INTEGER);
	  cstmt.execute();
	  userID= cstmt.getInt(2);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
		System.out.println("Error in getUserID: " + ex.toString());
		this.closeConnectionNoThrow(connection, "getUserID");
   }

	return userID;
}

//---------------------------------

public String getUserName( int userID)
{
	String data= "";
	String strSQL = "{CALL CTS_GETUSERNAME(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, userID);
	  cstmt.registerOutParameter(2, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(2);
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getUserName", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getUserName");
   }

	return data;
}

//---------------------------------
//---------------------------------

public String mountCassette(int cassetteID, int beamlineID)
{
	//
	String data= "";
	String strSQL = "{CALL CTS_mountCassette(?,?,?)}";

   Connection connection = null;
   try {
 	  connection = this.getConnection();
 	  CallableStatement cstmt = connection.prepareCall(strSQL);
 	  cstmt.setInt(1, cassetteID);
	  cstmt.setInt(2, beamlineID);
	  cstmt.registerOutParameter(3, Types.VARCHAR);
	  cstmt.execute();
 	  data+= cstmt.getString(3);
	  connection.close();

   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("mountCassette", ex.toString());
		System.out.println(data);
//		ex.printStackTrace();
		this.closeConnectionNoThrow(connection, "mountCassette");
   }

	return data;
}

//---------------------------------

public String addCassetteFile( int cassetteID, String filePrefix, String usrFileName)
{
	// returns unique file name "STOREFILENAME"
	String data= "";
	String strSQL = "{CALL CTS_addCassetteFile(?,?,?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, cassetteID);
	  cstmt.setString(2, filePrefix);
	  cstmt.setString(3, usrFileName);
	  cstmt.registerOutParameter(4, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(4);
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("addCassetteFile", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "addCassetteFile");
   }

	return data;
}

//---------------------------------

private String getParameterValue( String name)
{
	String data= "";
	String strSQL = "{CALL CTS_getParameterValue(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setString(1, name);
	  cstmt.registerOutParameter(2, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(2);
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getParameterValue", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getParameterValue");
   }

	if( m_testDataHome.length()>0 && data.startsWith("/home/") )
	{
		// test
		String x= m_testDataHome + data;
		data= x;
	}


	return data;
}

//---------------------------------

public void removeBeamline(String name)
	throws Exception
{
	throw new Exception("Method not implemented");
}

public void addBeamline(String name)
	throws Exception
{

   Connection connection = null;
   try {

	connection = this.getConnection();

	name = name.toUpperCase();

	// Get the last id
	String strSQL = "{CALL CTS_getCassettesAtBeamline(?,?)}";
	CallableStatement cstmt = connection.prepareCall(strSQL);
	cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	cstmt.setString(2, null);
	cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);
	int lastId = 0;
	int thisId = 0;
	while (rs.next())
	{
		String blID= rs.getString("BEAMLINE_ID");
		if( blID==null)
			blID= "0";
		thisId = Integer.parseInt(blID);
		if (lastId < thisId)
			lastId = thisId;
		if (rs.getString("BEAMLINE_NAME").equalsIgnoreCase(name))
			throw new Exception("Beamline " + name + " already exist: id = " + blID);
	}
	rs.close();

	String sql = "insert into cts_beamline(beamline_id,name,position) values (?,?,?)";

	int id = lastId+1;
	String pos[] = new String[4];

	pos[0] = new String("no cassette");
	pos[1] = new String("left");
	pos[2] = new String("middle");
	pos[3] = new String("right");


	for (int i = 0; i < pos.length; ++i) {
		PreparedStatement pstmt = connection.prepareStatement(sql);
		pstmt.setInt(1, id);
		pstmt.setString(2, name);
		pstmt.setString(3, pos[i]);
		pstmt.execute();
		++id;

	}
	connection.close();


	} catch (Exception ex) {
		System.out.println("Error in addBeamline: " + ex.toString());
		try {
	    	connection.close();
			throw ex;
		} catch (Exception e) {
			System.out.println("Error in addBeamline:" + e.toString());
			throw e;
		}
   	}
}


public String getBeamlineList()
{
String data= "";
String strSQL = "{CALL CTS_getCassettesAtBeamline(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setString(2, null);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	  data+= "<Beamlines>";
	  data+= "\r\n";
	  while (rs.next())
	  {
		  //data+=  emitElement("BeamLineID", rs.getString("BEAMLINE_ID"));
		  String blID= rs.getString("BEAMLINE_ID");
		  if( blID==null)
		  {
			  blID= "0";
		  }
		  data+=  "<BeamLine bid=\""+ blID +"\">";
                  if( rs.getString("BEAMLINE_NAME").equalsIgnoreCase("None") ||  rs.getString("BEAMLINE_POSITION")==null)
                  {
                      data+=  "None";
                  }
                  else
                  {
                      data+=  rs.getString("BEAMLINE_NAME") +" "+ rs.getString("BEAMLINE_POSITION");
                  }
		  data+= "</BeamLine>";
		  data+= "\r\n";
	  }
	  data+= "</Beamlines>";
	  data+= "\r\n";
	  rs.close();
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getBeamlineList", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getBeamlineList");
   	}

	return data;
}


public Vector getBeamlines()
{
   String strSQL = "{CALL CTS_getCassettesAtBeamline(?,?)}";

   Vector ret = new Vector();
   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setString(2, null);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
	  String str = "";
	  while (rs.next())
	  {
	  	  int bId = rs.getInt("BEAMLINE_ID");
                  if( rs.getString("BEAMLINE_NAME").equalsIgnoreCase("None") 
		  	||  rs.getString("BEAMLINE_POSITION")==null) {
                      str = "None";
                  }
                  else
                  {
                      str = rs.getString("BEAMLINE_NAME") +" "+ rs.getString("BEAMLINE_POSITION");
                  }
		  ret.add(new BeamlineInfo(bId, str));
	  }
	  rs.close();
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		ex.printStackTrace();
		this.closeConnectionNoThrow(connection, "getBeamlineList");
   	}

	return ret;
}


//---------------------------------
public String getCassetteIdAtBeamline(String beamlineName, String position)
	throws Exception
{
   Connection connection = null;
   try {

	connection = this.getConnection();

	String strSQL = "{CALL CTS_getCassettesAtBeamline(?,?)}";

	CallableStatement cstmt = connection.prepareCall(strSQL);
	cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	cstmt.setString(2, beamlineName);
	cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	String bName = "";
	String bPosition = "";
	String cassetteId = "";
	while (rs.next())
	{
		bName = rs.getString("BEAMLINE_NAME");
		bPosition = rs.getString("BEAMLINE_POSITION");
		cassetteId = rs.getString("CASSETTE_ID");

		if ((bName != null) && bName.equals(beamlineName)
		&& (bPosition != null) && bPosition.equals(position)) {
			break;
		}
	}
	rs.close();
	connection.close();

	return cassetteId;

	} catch (Exception ex) {
		System.out.println("Error in getCassetteIdAtBeamline: " + ex.toString());
		try {
	    	connection.close();
			throw ex;
		} catch (Exception e) {
			System.out.println("Error in getCassetteIdAtBeamline:" + e.toString());
			throw e;
		}
   	}


}


//---------------------------------
public Hashtable getAssignedBeamline(int cassetteID)
	throws Exception
{
	String data= "";
	String strSQL = "SELECT CTS_BEAMLINE.BEAMLINE_ID AS BEAMLINE_ID"
					+ ", CTS_BEAMLINE.NAME AS BEAMLINE_NAME"
					+ ", CTS_BEAMLINE.POSITION AS BEAMLINE_POSITION"
					+ " FROM CTS_BEAMLINE, CTS_CASSETTEFILE"
					+ " WHERE CTS_BEAMLINE.FILE_ID=CTS_CASSETTEFILE.FILE_ID"
					+ " AND CTS_CASSETTEFILE.CASSETTE_ID=" + cassetteID ;
	Hashtable ret = new Hashtable();
   Connection connection = null;
   try {
	  connection = this.getConnection();
	  Statement command = connection.createStatement();
	  command.executeQuery(strSQL);
	  ResultSet res = command.getResultSet();
	  // make sure we have result
	  if (res.next()) {
		  if (res.getString("BEAMLINE_ID") != null)
			ret.put("BEAMLINE_ID", res.getString("BEAMLINE_ID"));
		  if (res.getString("BEAMLINE_NAME") != null)
			ret.put("BEAMLINE_NAME", res.getString("BEAMLINE_NAME"));
		  if (res.getString("BEAMLINE_POSITION") != null)
			ret.put("BEAMLINE_POSITION", res.getString("BEAMLINE_POSITION"));
	  }
	  res.close();
	  connection.close();
	  return ret;

   } catch(Exception ex){ //Trap SQL errors
		System.out.println("Error in getAssignedBeamline: " + ex.toString());
		try {
	    	connection.close();
			throw ex;
		} catch (Exception e) {
			System.out.println("Error in getAssignedBeamline:" + e.toString());
			throw e;
		}

   	}

}


//---------------------------------
public String getBeamlineID(String beamlineName, String position)
	throws Exception
{
	String data= "";
	String strSQL = "SELECT CTS_BEAMLINE.BEAMLINE_ID AS BEAMLINE_ID FROM CTS_BEAMLINE"
					+ " WHERE CTS_BEAMLINE.NAME = '"
					+ beamlineName
					+ "' AND CTS_BEAMLINE.POSITION = '" + position + "'";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  Statement command = connection.createStatement();
	  command.executeQuery(strSQL);
	  ResultSet res = command.getResultSet();
	  if (res.next()) {
	  	data = res.getString("BEAMLINE_ID");
	  }
	  res.close();
	  connection.close();
	  return data;
   } catch(Exception ex){ //Trap SQL errors
		System.out.println("Error in getBeamlineID: " + ex.toString());
		try {
	    	connection.close();
			throw ex;
		} catch (Exception e) {
			System.out.println("Error in getBeamlineID:" + e.toString());
			throw e;
		}
   	}

}

//---------------------------------
public Hashtable getBeamlineInfo(int bid)
	throws Exception
{
	String strSQL = "SELECT CTS_BEAMLINE.NAME AS BEAMLINE_NAME, CTS_BEAMLINE.POSITION AS BEAMLINE_POSITION FROM CTS_BEAMLINE"
					+ " WHERE CTS_BEAMLINE.BEAMLINE_ID = '"
					+ String.valueOf(bid) + "'";

	Hashtable ret = new Hashtable();
   Connection connection = null;
   try {
	  connection = this.getConnection();
	  Statement command = connection.createStatement();
	  command.executeQuery(strSQL);
	  ResultSet res = command.getResultSet();
	  if (res.next()) {
		  if (res.getString("BEAMLINE_NAME") != null)
			ret.put("BEAMLINE_NAME", res.getString("BEAMLINE_NAME"));
		  if (res.getString("BEAMLINE_POSITION") != null)
			ret.put("BEAMLINE_POSITION", res.getString("BEAMLINE_POSITION"));
  	  }
	  res.close();
	  connection.close();
	  return ret;
   } catch(Exception ex){ //Trap SQL errors
		System.out.println("Error in getBeamlineInfo: " + ex.toString());
		try {
	    	connection.close();
			throw ex;
		} catch (Exception e) {
			System.out.println("Error in getBeamlineInfo:" + e.toString());
			throw e;
		}
   	}

}



//---------------------------------
public Hashtable getCassetteInfoAtBeamline(String beamlineName, String position)
	throws Exception
{
	Connection connection = null;
	try {

	String strSQL = "{CALL CTS_getCassettesAtBeamline(?,?)}";

	connection = this.getConnection();
	CallableStatement cstmt = connection.prepareCall(strSQL);
	cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	cstmt.setString(2, beamlineName);
	cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	String bName = "";
	String bPosition = "";
	Hashtable result = new Hashtable();
//	System.out.println("In getCassetteInfoAtBeamline: beamlineName = " + beamlineName
//						+ " position = " + position);
	while (rs.next())
	{
		bName = rs.getString("BEAMLINE_NAME");
		bPosition = rs.getString("BEAMLINE_POSITION");

//		System.out.println("bName = " + bName + " bPosition = " + bPosition);

		if ((bName != null) && bName.equals(beamlineName)
		&& (bPosition != null) && bPosition.equals(position)) {
		  if (rs.getString("BEAMLINE_NAME") != null)
		  	result.put("BeamLineName", rs.getString("BEAMLINE_NAME"));
		  if (rs.getString("BEAMLINE_POSITION") != null)
		  	result.put("BeamLinePosition", rs.getString("BEAMLINE_POSITION"));
		  if (rs.getString("USER_NAME") != null)
		  	result.put("UserName", rs.getString("USER_NAME"));
		  if (rs.getString("CASSETTE_ID") != null)
		 	result.put("CassetteID", rs.getString("CASSETTE_ID"));
		  if (rs.getString("PIN") != null)
		  	result.put("Pin", rs.getString("PIN"));
		  if (rs.getString("FILENAME") != null)
		  	result.put("FileName", rs.getString("FILENAME"));
		  if (rs.getString("UPLOAD_FILENAME") != null)
		  	result.put("UploadFileName", rs.getString("UPLOAD_FILENAME"));

		}
	}
	rs.close();
	connection.close();

	return result;

	} catch (Exception ex) {
		System.out.println("Error in getCassetteInfoAtBeamline: " + ex.toString());
		try {
	    	connection.close();
			throw ex;
		} catch (Exception e) {
			System.out.println("Error in getCassetteInfoAtBeamline:" + e.toString());
			throw e;
		}
   	}

}

//---------------------------------

public String getCassettesAtBeamline( String beamlineName)
{
	String data= "";
	String strSQL = "{CALL CTS_getCassettesAtBeamline(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setString(2, beamlineName);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	  data+= "<CassettesAtBeamline>";
	  data+= "\r\n";
	  while (rs.next())
	  {
		  data+= "<Row>";
		  //data+=  emitElement("BeamLineID", rs.getString("BEAMLINE_ID"));
		  String blID= rs.getString("BEAMLINE_ID");
		  if( blID==null)
		  {
			  blID= "0";
		  }
		  data+=  emitElement("BeamLineID", blID);
		  data+=  emitElement("BeamLineName", rs.getString("BEAMLINE_NAME"));
		  data+=  emitElement("BeamLinePosition", rs.getString("BEAMLINE_POSITION"));
		  data+=  emitElement("UserID", rs.getString("USER_ID"));
		  data+=  emitElement("UserName", rs.getString("USER_NAME"));
		  data+=  emitElement("CassetteID", rs.getString("CASSETTE_ID"));
		  data+=  emitElement("Pin", rs.getString("PIN"));
		  data+=  emitElement("FileID", rs.getString("FILE_ID"));
		  data+=  emitElement("FileName", rs.getString("FILENAME"));
		  data+=  emitElement("UploadFileName", rs.getString("UPLOAD_FILENAME"));
		  String dateTime= formatDateTime( rs.getTimestamp("UPLOAD_TIME"));
		  data+=  emitElement("UploadTime", dateTime);
		  data+= "</Row>";
		  data+= "\r\n";
	  }
	  data+= "</CassettesAtBeamline>";
	  data+= "\r\n";
	  rs.close();
	  connection.close();

   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getCassettesAtBeamline", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getCassettesAtBeamline");
   }

	return data;
}


//---------------------------------

public String getBeamlineName( int beamlineID)
{
	String data= "";
	String strSQL = "{CALL CTS_GETBEAMLINENAME(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
      CallableStatement cstmt = connection.prepareCall(strSQL);
      cstmt.setInt(1, beamlineID);
      cstmt.registerOutParameter(2, Types.VARCHAR);
      cstmt.execute();
      data+= cstmt.getString(2);
      connection.close();
   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getBeamlineName", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getBeamlineName");
   	}

	return data;
}

//---------------------------------

public String getCassetteFileName( int cassetteID)
{
	String data= "";
	String strSQL = "{CALL CTS_GETCASSETTEFILENAME(?,?)}";
   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, cassetteID);
	  cstmt.registerOutParameter(2, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(2);
	  connection.close();
  } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getCassetteFileName", "sil = " + cassetteID + " " + ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getCassetteFileName");
   }

	return data;
}

//---------------------------------

public String getCassetteOwner( int cassetteID)
{
	String data= "";
	String strSQL = "SELECT LOGIN_NAME FROM CTS_USER, CTS_CASSETTEFILE, CTS_CASSETTE"
				+ " WHERE CTS_CASSETTE.CASSETTE_ID="
				+ String.valueOf(cassetteID)
				+ " AND CTS_CASSETTE.USER_ID=CTS_USER.USER_ID";
   Connection connection = null;
   try {
	  connection = this.getConnection();
	  Statement command = connection.createStatement();
	  command.executeQuery(strSQL);
	  ResultSet res = command.getResultSet();
	  if (res.next()) {
	  	data = res.getString("LOGIN_NAME");
	  }
	  res.close();
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getCassetteOwner", "sil = " + cassetteID + " " + ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getCassetteOwner");
   }

	return data;
}


public String getCassetteFileList(String userName)
{
	int userID = getUserID(userName);
	
	return getCassetteFileList(userID, null, null);
}

public String getCassetteFileList(String userName, String filterBy, String wildcard)
{
	int userID = getUserID(userName);
	
	return getCassetteFileList(userID, filterBy, wildcard);
}


//---------------------------------
public String getCassetteFileList( int userID)
{
	return getCassetteFileList(userID, null, null);
}

public String getCassetteFileList(int userID, String filterBy, String wildcard)
{
	String data= "";
	String strSQL = "{CALL CTS_GETCASSETTEFILES(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setInt(2, userID);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	  Pattern pattern = null;
	  if ((wildcard != null) && (wildcard.length() > 0) && !wildcard.equals("*"))
	  	pattern = Pattern.compile(wildcard);
	  data+= "<CassetteFileList>";
	  data+= "\r\n";
	  while (rs.next())
	  {
	  	  // Filter sils with a wildcard.
	  	  if ((filterBy != null) && (wildcard != null) && (pattern != null)) {
		  	if (filterBy.equals("CassetteID"))
				filterBy = "CASSETTE_ID";
			else if (filterBy.equals("Pin"))
				filterBy = "PIN";
			else if (filterBy.equals("FileID"))
				filterBy = "FILE_ID";
			else if (filterBy.equals("FileName"))
				filterBy = "FILENAME";
			else if (filterBy.equals("UploadFileName"))
				filterBy = "UPLOAD_FILENAME";
			else if (filterBy.equals("UploadTime"))
				filterBy = "UPLOAD_TIME";
			else if (filterBy.equals("BeamLineID"))
				filterBy = "BEAMLINE_ID";
			else if (filterBy.equals("BeamLineName"))
				filterBy = "BEAMLINE_NAME";
			else if (filterBy.equals("BeamLinePosition"))
				filterBy = "BEAMLINE_POSITION";
			if (!pattern.matcher(rs.getString(filterBy)).matches())
				continue;
		  }
		  
		  data+= "<Row>";
		  data+=  emitElement("CassetteID", rs.getString("CASSETTE_ID"));
		  data+=  emitElement("Pin", rs.getString("PIN"));
		  data+=  emitElement("FileID", rs.getString("FILE_ID"));
		  data+=  emitElement("FileName", rs.getString("FILENAME"));
		  data+=  emitElement("UploadFileName", rs.getString("UPLOAD_FILENAME"));
  		  String dateTime= formatDateTime( rs.getTimestamp("UPLOAD_TIME"));
		  data+=  emitElement("UploadTime", dateTime);
		  //data+=  emitElement("BeamLineID", rs.getString("BEAMLINE_ID"));
  		  String blID= rs.getString("BEAMLINE_ID");
		  if( blID==null)
		  {
			  blID= "0";
		  }
		  data+=  emitElement("BeamLineID", blID);
		  data+=  emitElement("BeamLineName", rs.getString("BEAMLINE_NAME"));
		  data+=  emitElement("BeamLinePosition", rs.getString("BEAMLINE_POSITION"));
		  data+= "</Row>";
		  data+= "\r\n";
	  }
	  data+= "</CassetteFileList>";
	  data+= "\r\n";
	  rs.close();
	  connection.close();

   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("getCassetteFileList", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "getCassetteFileList");
//		ex.printStackTrace();
   }

	return data;
}

/**
 * Returns a list of cassette info of the given owner.
 */
public Vector getUserCassettes(String userName)
	throws Exception
{
	int userID = getUserID(userName);
	
	return getUserCassettes(userID);
}

/**
 * Returns a list of cassette info of the given owner.
 */
public Vector getUserCassettes( int userID)
	throws Exception
{
	  Vector ret = new Vector();
	String strSQL = "{CALL CTS_GETCASSETTEFILES(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setInt(2, userID);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);

	  String data = "";
	  while (rs.next())
	  {
		  ret.add(new CassetteInfo(rs.getInt("CASSETTE_ID"),
						rs.getString("PIN"),
						rs.getInt("FILE_ID"),
						rs.getString("FILENAME"),
						rs.getString("UPLOAD_FILENAME"),
						formatDateTime(rs.getTimestamp("UPLOAD_TIME")),
						rs.getInt("BEAMLINE_ID"),
						rs.getString("BEAMLINE_NAME"),
						rs.getString("BEAMLINE_POSITION")));
	  }
	  rs.close();
	  connection.close();

   } catch(Exception ex){ //Trap SQL errors
		this.closeConnectionNoThrow(connection, "getCassetteFileList");
		throw ex;
   }

   return ret;
}

/**
 * Returns a list of cassette info of the given owner.
 */
public Vector getUserCassettes(String userName, String filterBy, String wildcard)
	throws Exception
{
	int userID = getUserID(userName);

	  Vector ret = new Vector();
	String strSQL = "{CALL CTS_GETCASSETTEFILES(?,?)}";

   Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setInt(2, userID);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);

	  Pattern pattern = null;
	  if ((wildcard != null) && (wildcard.length() > 0) && !wildcard.equals("*")) {
	  	wildcard = wildcard.replace("*", ".*");
	  	pattern = Pattern.compile(wildcard);
	  }

	  while (rs.next())
	  {

	  	  // Filter sils with a wildcard.
	  	  if ((filterBy != null) && (wildcard != null) && (pattern != null)) {
		  	if (filterBy.equals("CassetteID"))
				filterBy = "CASSETTE_ID";
			else if (filterBy.equals("Pin"))
				filterBy = "PIN";
			else if (filterBy.equals("FileID"))
				filterBy = "FILE_ID";
			else if (filterBy.equals("FileName"))
				filterBy = "FILENAME";
			else if (filterBy.equals("UploadFileName"))
				filterBy = "UPLOAD_FILENAME";
			else if (filterBy.equals("UploadTime"))
				filterBy = "UPLOAD_TIME";
			else if (filterBy.equals("BeamLineID"))
				filterBy = "BEAMLINE_ID";
			else if (filterBy.equals("BeamLineName"))
				filterBy = "BEAMLINE_NAME";
			else if (filterBy.equals("BeamLinePosition"))
				filterBy = "BEAMLINE_POSITION";
			if (!pattern.matcher(rs.getString(filterBy)).matches())
				continue;
		  }


		  ret.add(new CassetteInfo(rs.getInt("CASSETTE_ID"),
						rs.getString("PIN"),
						rs.getInt("FILE_ID"),
						rs.getString("FILENAME"),
						rs.getString("UPLOAD_FILENAME"),
						formatDateTime(rs.getTimestamp("UPLOAD_TIME")),
						rs.getInt("BEAMLINE_ID"),
						rs.getString("BEAMLINE_NAME"),
						rs.getString("BEAMLINE_POSITION")));
	  }
	  rs.close();
	  connection.close();

   } catch(Exception ex){ //Trap SQL errors
		this.closeConnectionNoThrow(connection, "getCassetteFileList");
		throw ex;
   }

   return ret;
}


//---------------------------------

public String deleteUnusedCassetteFiles( String userName)
{
int userID= getUserID( userName);
String cassetteDir= getParameterValue( "cassetteDir");
java.util.Vector fileList= new java.util.Vector();
String strSQL = "{CALL CTS_GETUNUSEDCASSETTEFILES(?,?)}";
String data= "";
Connection connection = null;
   try {
	  connection = this.getConnection();
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setInt(2, userID);
	  cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	  while (rs.next())
	  {
		String fileName= rs.getString("FILENAME");
                fileList.addElement(fileName);
                data+= fileName +"\r\n";
	  }
	  data+= "\r\n";
	  rs.close();
	  //connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>deleteUnusedCassetteFiles() "+ ex +"</Error>";
	   System.out.println( data);
	   this.closeConnectionNoThrow(connection, "deleteUnusedCassetteFiles");
       return data;
   }

strSQL = "{CALL CTS_REMOVECASSETTEFILE(?)}";
for( int i=0; i<fileList.size(); i++)
{
    String fname= (String) fileList.elementAt(i);
    File f;
    try
    {
        f= new File( cassetteDir, userName+"/"+fname+".txt");
        String s1= f.getPath();
        if( f.exists() )
        {
            f.delete();
        }
        f= new File( cassetteDir, userName+"/"+fname+".xml");
        if( f.exists() )
        {
            f.delete();
        }
        f= new File( cassetteDir, userName+"/"+fname+".html");
        if( f.exists() )
        {
            f.delete();
        }
        f= new File( cassetteDir, userName+"/"+fname+"_src.xls");
        if( f.exists() )
        {
            f.delete();
        }
        f= new File( cassetteDir, userName+"/"+fname+"_src.xml");
        if( f.exists() )
        {
            f.delete();
        }
          CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setString(1, fname);
	  cstmt.execute();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>deleteUnusedCassetteFiles() "+ ex +"</Error>";
	   System.out.println( data);
   }

}

   try {
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   System.out.println( "deleteUnusedCassetteFiles()"+ ex);
   }

return data;
}

//---------------------------------
//---------------------------------

public String test1()
{
return "hallo";
}

//---------------------------------

public String oracle1()
{
String data= "";

int userID= 2;

Connection connection= null;
String strSQL = "{CALL CTS_GETCASSETTEFILES(?,?)}";

   try {
	  	connection = this.getConnection();

	   CallableStatement cstmt = connection.prepareCall(strSQL);
	   cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	   cstmt.setInt(2, userID);
	   cstmt.execute();
	  DelegatingStatement delegating = (DelegatingStatement)cstmt;
	  ResultSet rs = ((OracleCallableStatement)delegating.getDelegate()).getCursor(1);
//	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	   while (rs.next())
	   {
		   long n = rs.getLong(1);
		   String s1= rs.getString(2);
		   String s2 = rs.getString("UPLOAD_FILENAME");
		   data+=  n +" "+ s1 +" "+ s2 +"<BR>\r\n";
		   System.out.println(n +" "+ s1 +" "+ s2);
	   }
	   rs.close();

	   connection.close();

   } catch(Exception ex){ //Trap SQL errors
		data = getErrorString("oracle1", ex.toString());
		System.out.println(data);
		this.closeConnectionNoThrow(connection, "oracle1");
   }

return data;
}

//---------------------------------

private String emitElement( String name, String val)
{
String elem= "<"+ name +">"+ val +"</"+ name +">";
//elem+= "\r\n";
return elem;
}

//---------------------------------

private String formatDateTime( Timestamp t1)
{
String dt2;
if( t1!=null)
{
	dt2= t1.toString();
	int i= dt2.lastIndexOf('.');
	if( i>5)
	{
		dt2= dt2.substring(0,i);
	}
}
else
{
	dt2= "null";
}
return dt2;
}

//---------------------------------

private String formatDateTime1( java.util.Date d)
{
String dt2;
SimpleDateFormat format= new SimpleDateFormat("yyyy-MMM-dd HH:mm:ss");
if( d!=null)
{
	dt2= format.format(d);
}
else
{
	dt2= "null";
}
return dt2;
}

//---------------------------------

}
