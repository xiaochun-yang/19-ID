/* ctsdb.java
* oracle
*
* oracle jdbc driver using OCI net8
* requires in classpath C:\oracle\ora81\jdbc\lib\classes111.zip
*
* setenv CLASSPATH=${CLASSPATH};C:\oracle\ora81\jdbc\lib\classes111.zip
* or on win2000
* set CLASSPATH=%CLASSPATH%;C:\oracle\ora81\jdbc\lib\classes111.zip
* Windows 2000 needs restart!
*
*
To use this class as a COM server (see "regi.bat"):
cd T:\prog\db1\ctsdb
copy ctsdb.class C:\WINNT\java\trustlib\
cd C:\WINNT\java\trustlib\
"C:\Program Files\Microsoft Visual Studio\VIntDev98\bin\JAVAREG.EXE" /unregister /class:ctsdb /progid:ctsdb
"C:\Program Files\Microsoft Visual Studio\VIntDev98\bin\JAVAREG.EXE" /register /class:ctsdb /progid:ctsdb
restart IIS !!!
*
*
*/

import java.io.Serializable;
import java.sql.*;
import oracle.jdbc.driver.*;
import java.text.*;
//import java.util.*;

public class ctsdb implements Serializable
{
String m_strDSN= "jdbc:oracle:oci8:@CRYSTALTRACK";
String m_userName="sa";
String m_password="secret";
//String m_strDSN= "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(HOST=smbdb)(PROTOCOL=tcp)(PORT=1521))(CONNECT_DATA=(SID=test)))";
//String m_userName="jcsg";
//String m_password="tmp_jcsg";

//---------------------------------

public static void main (String args[])
{
System.out.println("start");

//String cp= System.getenv("CLASSPATH");
String cp = System.getProperty("java.class.path",".");
System.out.println("cp="+ cp);

String data="";
//data= new ctsdb().oracle1();
//data= new ctsdb().getXSLTemplate( "jcsg");
//data= new ctsdb().getCassetteFileName( 3);
//data= new ctsdb().getUserList();
data= new ctsdb().getCassetteFileList( 2);
//data= new ctsdb().getParameterValue("cassettedir");
//data= new ctsdb().addCassetteFile(22,"excelData","usrFile1");
//data= new ctsdb().mountCassette(2,3);
//data= new ctsdb().getBeamlineList();
//data= new ctsdb().getCassettesAtBeamline("bl9-2");
//data= new ctsdb().getCassettesAtBeamline("smbdcsdev");
//data= ""+new ctsdb().getUserID("gwolf");
//data= new ctsdb().addUser("gwolf2",null,"g w");
//data= new ctsdb().addCassette(2,"PIN123");
//data= new ctsdb().deleteUser(4);
//data= new ctsdb().deleteCassette(3);
System.out.println( "data="+ data);

System.out.println("done");
return;
}

//---------------------------------
//---------------------------------
// get/set properties


public void setDSN( String x)
{
m_strDSN= x;
}

public String getDSN()
{
return m_strDSN;
}

public void setUserName( String x)
{
m_userName= x;
}

public String getUserName()
{
return m_userName;
}

public void setPassword( String x)
{
m_password= x;
}

public String getPassword()
{
return m_password;
}

//---------------------------------

public String removeCassette( int cassetteID)
{
// returns unique file name "STOREFILENAME"
String data= "";
String strSQL = "{CALL CTS_REMOVECASSETTE(?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, cassetteID);
	  cstmt.execute();
	  data+= "OK";
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>removeCassette() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String removeUser( int userID)
{
// returns unique file name "STOREFILENAME"
String data= "";
String strSQL = "{CALL CTS_REMOVEUSER(?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, userID);
	  cstmt.execute();
	  data+= "OK";
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>removeUser() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String addCassette( int userID, String PIN)
{
// returns unique file name "STOREFILENAME"
String data= "";
String strSQL = "{CALL CTS_ADDCASSETTE(?,?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, userID);
	  cstmt.setString(2, PIN);
	  cstmt.registerOutParameter(3, Types.INTEGER);
	  cstmt.execute();
	  data+= ""+ cstmt.getInt(3);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>addCassette() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String addUser( String loginName, String mySQSLUserID, String realName)
{
// returns unique file name "STOREFILENAME"
String data= "";
String strSQL = "{CALL CTS_addUser(?,?,?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setString(1, loginName);
	  cstmt.setString(2, mySQSLUserID);
	  cstmt.setString(3, realName);
	  cstmt.registerOutParameter(4, Types.INTEGER);
	  cstmt.execute();
	  data+= ""+ cstmt.getInt(4);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>addUser() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String getXSLTemplate( String userName)
{
String data= "";
String strSQL = "{CALL CTS_GETUSERINFO(?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setString(2, userName);
	  cstmt.execute();
	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);
	  
	  while (rs.next())
	  {
		  data+= ""+rs.getString("DATA_IMPORT_TEMPLATE");
	  }
	  rs.close();
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>getUserID() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String getUserList()
{
String data= "";
String strSQL = "{CALL CTS_GETUSERINFO(?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.execute();
	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);
	  
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
	   data= "<Error>getUserID() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public int getUserID( String accessID)
{
int userID= 0;
String strSQL = "{CALL CTS_GETUSERID(?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setString(1, accessID);
	  cstmt.registerOutParameter(2, Types.INTEGER);
	  cstmt.execute();
	  userID= cstmt.getInt(2);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   String data= "<Error>getUserID() "+ ex +"</Error>";
	   System.out.println( data);
   }

return userID;
}

//---------------------------------

public String getUserName( int userID)
{
String data= "";
String strSQL = "{CALL CTS_GETUSERNAME(?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, userID);
	  cstmt.registerOutParameter(2, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(2);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>getUserID() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------
//---------------------------------

public String mountCassette( int cassetteID, int beamlineID)
{
//
String data= "";
String strSQL = "{CALL CTS_mountCassette(?,?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, cassetteID);
	  cstmt.setInt(2, beamlineID);
	  cstmt.registerOutParameter(3, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(3);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>mountCassette() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String addCassetteFile( int cassetteID, String filePrefix, String usrFileName)
{
// returns unique file name "STOREFILENAME"
String data= "";
String strSQL = "{CALL CTS_addCassetteFile(?,?,?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, cassetteID);
	  cstmt.setString(2, filePrefix);
	  cstmt.setString(3, usrFileName);
	  cstmt.registerOutParameter(4, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(4);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>addCassetteFile() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String getParameterValue( String name)
{
String data= "";
String strSQL = "{CALL CTS_getParameterValue(?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setString(1, name);
	  cstmt.registerOutParameter(2, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(2);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>getParameterValue() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String getBeamlineList()
{
return getCassettesAtBeamline(null);
}

//---------------------------------

public String getCassettesAtBeamline( String beamlineName)
{
String data= "";
String strSQL = "{CALL CTS_getCassettesAtBeamline(?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setString(2, beamlineName);
	  cstmt.execute();
	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);
	  
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
	   data= "<Error>getCassettesAtBeamline() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String getCassetteFileName( int cassetteID)
{
String data= "";
String strSQL = "{CALL CTS_GETCASSETTEFILENAME(?,?)}";
   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.setInt(1, cassetteID);
	  cstmt.registerOutParameter(2, Types.VARCHAR);
	  cstmt.execute();
	  data+= cstmt.getString(2);
	  connection.close();
   } catch(Exception ex){ //Trap SQL errors
	   data= "<Error>mountCassette() "+ ex +"</Error>";
	   System.out.println( data);
   }

return data;
}

//---------------------------------

public String getCassetteFileList( int userID)
{
String data= "";
String strSQL = "{CALL CTS_GETCASSETTEFILES(?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	  Connection connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
	  CallableStatement cstmt = connection.prepareCall(strSQL);
	  cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	  cstmt.setInt(2, userID);
	  cstmt.execute();
	  ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);
	  
	  data+= "<CassetteFileList>";
	  data+= "\r\n";
	  while (rs.next())
	  {
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
	   data= "<Error>getCassetteFileList() "+ ex +"</Error>";
	   System.out.println( data);
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

Connection m_connection= null;
String strSQL = "{CALL CTS_GETCASSETTEFILES(?,?)}";

   try {
       //Load the Oracle JDBC Driver and register it.
       DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

	   m_connection = DriverManager.getConnection( m_strDSN, m_userName, m_password);
       //Sets the auto-commit property as false. By default it is true.
      // m_connection.setAutoCommit(false);

	   CallableStatement cstmt = m_connection.prepareCall(strSQL);
	   cstmt.registerOutParameter (1, OracleTypes.CURSOR);
	   cstmt.setInt(2, userID);
	   cstmt.execute();
	   ResultSet rs = ((OracleCallableStatement)cstmt).getCursor(1);

	   while (rs.next())
	   {
		   long n = rs.getLong(1);
		   String s1= rs.getString(2);
		   String s2 = rs.getString("UPLOAD_FILENAME");
		   data+=  n +" "+ s1 +" "+ s2 +"<BR>\r\n";
		   System.out.println(n +" "+ s1 +" "+ s2);
	   }
	   rs.close();

   } catch(Exception ex){ //Trap SQL errors
	   System.out.println("error "+ ex);
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

private String formatDateTime1( Date d)
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
