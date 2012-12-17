<%
// upload.jsp
//
// called by uploadForm.jsp
// receive uploaded file via MultypartRequest
// call ASP on Micrsosoft Web Server to trnslate Excel to XML
// transform XML -> HTML and TCL-list
// store Excel, XML, HTML and TCL files in "cassetteDir"
//
%>

<%@page contentType="text/html"%>
<%@ page language="java" import="cts.MultipartRequest,java.io.*,java.net.*" %>


<%@ page import="java.io.*" %>
<%@include file="config.jsp" %>

<jsp:useBean id="mreq" class="cts.MultipartRequest">
</jsp:useBean>

<%!
//============================================================
// variable declarations

int MAXCONTENTLENGTH;
String s_excel2xmlURL;
String s_fileXSL1;
String s_fileXSL2;
String s_fileXSL3;
String s_filePrefix;
String s_accessID;
String s_userName;
String s_templateDir;
String s_cassetteDir;
String s_fileCrystalData2Sil;
ServletContext s_application;
HttpServletResponse s_response;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;
%>

<%
//============================================================
// vaiable initialisation

MAXCONTENTLENGTH= 800*1024;
//s_excel2xmlURL= "http://gwolfpc/cts/excel2xml.asp";
//s_excel2xmlURL= "http://gwolfpc/excel2xml/excel2xml.asp";
s_excel2xmlURL= getConfigValue( "excel2xmlURL");
s_fileXSL1 = "import_default.xsl";
s_fileXSL2 = "xsltTCL1.xsl";
s_fileXSL3 = "xsltHTML1.xsl";

s_fileCrystalData2Sil = "xsltCrystalData2Sil.xsl";

s_filePrefix= "excelData";
s_accessID= "";
s_templateDir= getConfigValue( "templateDir");
s_cassetteDir= getConfigValue( "cassetteDir");
s_response= response;
s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;
%>

<%!
//============================================================
//============================================================

public String processRequest( MultipartRequest mreq)
     throws IOException
{
String result= "OK";

// the temporary file received from the web browser
//String source= mreq.getFile();
long length= mreq.getFileParameter("fileName").getLength();
if( length>MAXCONTENTLENGTH)
{
    result= "ERROR - file is too big: "+ length;
    errMsg( result);
    s_out.println( result);
    return result;
}
if( length==0)
{
    result= "ERROR - file is empty";
    errMsg( result);
    s_out.println( result);
    return result;
}

MultipartRequest.File reqFile= null;
Object[] values= mreq.getParameterValues("fileName");
if( values!=null && values.length>0)
{
	reqFile= (MultipartRequest.File) values[0];
}
if( reqFile==null)
{
    result= "No file";
    errMsg( result);
    s_out.println( result);
    return result;
}

String accessID= "" + ServletUtil.getSessionId(mreq);
String userName= "" + ServletUtil.getUserName(mreq);
String PIN_Number= ""+mreq.getParameter("PIN_Number");
if ((PIN_Number == null) || (PIN_Number.length() == 0))
	PIN_Number = "unknown";
PIN_Number.trim();


checkAccessID(mreq, s_response);
if((userName.length() == 0) || userName.equals("null") )
{
	userName = gate.getUserID();
}

// Add cassette first
int userID= s_db.getUserID( userName);
int[] retCassetteID = new int[1];
String x= addCassette( userID, PIN_Number, retCassetteID);
if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	result = "Failed to add cassette for userName=";
	result += userName + " ERROR: " + x;
	SilLogger.info(result);
	s_out.println(result);
	return result;
}

// Retrieve the upload file
//String forCassetteID= ""+mreq.getStringParameter("forCassetteID");
//int cassetteID= Integer.valueOf( forCassetteID.trim() ).intValue();
int cassetteID = retCassetteID[0];
String filePath= mreq.getFileParameter("fileName").getName();
String fileType= mreq.getFileParameter("fileName").getType();
long fileLength= mreq.getFileParameter("fileName").getLength();
String forSheetName= ""+mreq.getStringParameter("forSheetName");
forSheetName= forSheetName.trim();
s_accessID= accessID;
s_userName= userName;

s_db.deleteUnusedCassetteFiles(userName);

int i= java.lang.Math.max( filePath.lastIndexOf( '\\'), filePath.lastIndexOf( '/'));
String fileName= filePath.substring( i+1, filePath.length());

String x1;
String x2;
String x3;
String x4;
String x5;
String x6;
String x7;
x1= "userName="+ userName;
x2= "cassetteID="+ cassetteID;
x3= "filePath="+ filePath;
x4= "fileName="+ fileName;
x5= "fileType="+ fileType;
x6= "fileLength="+ fileLength;
x7= "forSheetName="+ forSheetName;
logMsg( x4);
logMsg( x5);
logMsg( x6);
logMsg( x7);
/*
x1+= "<BR>";
x2+= "<BR>";
x3+= "<BR>";
x4+= "<BR>";
x5+= "<BR>";
x6+= "<BR>";
x7+= "<BR>";
s_out.println( x1);
s_out.println( x2);
s_out.println( x3);
s_out.println( x4);
s_out.println( x5);
s_out.println( x6);
s_out.println( x7);
*/

// path for the copy of the uploaded file in our directory
int fileCounter= 0;
String fileCounterString= (String) s_application.getAttribute( "uploadFileCounter");
if( fileCounterString!=null)
{
    fileCounter= Integer.valueOf( fileCounterString.trim() ).intValue();
}
fileCounter++;
fileCounter= fileCounter %10;
s_application.setAttribute( "uploadFileCounter", ""+fileCounter);
String uploadFile= s_application.getRealPath("temp/temp"+ fileCounter +".xls");

// path for the result of the transformation done on the second webserver that is called in uploadFile()
String resultFile= uploadFile.substring(0, uploadFile.length()-3)+"xml";

// transform Excel -> XML
String  uploadURL= s_excel2xmlURL;
uploadURL+= "?forUser="+ userName;
uploadURL+= "&forCassetteID="+ cassetteID;
uploadURL+= "&forFileName="+ fileName;
uploadURL+= "&forSheetName="+ forSheetName;
logMsg( "uploadURL="+ uploadURL);

InputStream ins= null;
ins= reqFile.getInputStream();
if( ins!=null)
{
	result= uploadFileStream( ins, uploadURL, resultFile);
	ins.close();
}
s_out.println( "resultFile="+ resultFile +"<BR>");
if( result.startsWith("OK")==false )
{
    errMsg( "ERROR resultFile "+result);
    s_out.println( "ERROR resultFile "+ result);
    return result;
}

// save the uploaded file
ins= reqFile.getInputStream();
if( ins!=null)
{
    result= s_io.copyFileStream( ins, uploadFile);
    ins.close();
}
s_out.println( "uploadFile="+ uploadFile +"<BR>");
if( result.startsWith("OK")==false )
{
    errMsg( "ERROR uploadFile "+result);
    s_out.println( "ERROR uploadFile "+ result);
    return result;
}


// xslt to XNML, HTML and Tcl
String fileCrystalData2Sil = s_fileCrystalData2Sil;

String fileXSL1= s_fileXSL1;
String fileXSL2= s_fileXSL2;
String fileXSL3= s_fileXSL3;
String filePrefix= s_filePrefix;

String archiveFileName= s_db.addCassetteFile( cassetteID, filePrefix, fileName, userName);
result= archiveFileName;
if( result.length()>4 && result.substring(0,4).equalsIgnoreCase("<Err") )
{
    errMsg( result);
    s_out.println( "result="+ result);
    return result;
}

fileXSL1= s_db.getXSLTemplate( userName);

fileCrystalData2Sil= s_templateDir+ fileCrystalData2Sil;

fileXSL1= s_templateDir+ fileXSL1;
fileXSL2= s_templateDir+ fileXSL2;
fileXSL3= s_templateDir+ fileXSL3;


String cassetteDir= s_cassetteDir+ userName +File.separator;

String filePath2;
filePath2= cassetteDir+ archiveFileName +"_src.xls";
result= s_io.copy( uploadFile, filePath2);
if( result.length()>4 && result.substring(0,4).equalsIgnoreCase("<Err") )
{
    errMsg( result);
    s_out.println( "result="+ result);
    return result;
}

filePath2= cassetteDir+ archiveFileName +"_src.xml";
result= s_io.copy( resultFile, filePath2);
if( result.length()>4 && result.substring(0,4).equalsIgnoreCase("<Err") )
{
    errMsg( result);
    s_out.println( "result="+ result);
    return result;
}


// Transforming from src to Guenter's xml
// Do this for backward compatibility
filePath2= cassetteDir+ archiveFileName +".xml";
result= s_io.xslt( resultFile, filePath2, fileXSL1, null);
if( result.startsWith("OK")==false )
{
    errMsg( result);
    s_out.println( "result="+ result);
    return result;
}

String filePath1= filePath2;
filePath2= cassetteDir+ archiveFileName +".txt";
result= s_io.xslt( filePath1, filePath2, fileXSL2, null);
if( result.startsWith("OK")==false )
{
    errMsg( result);
    s_out.println( "result="+ result);
    return result;
}

filePath2= cassetteDir+ archiveFileName +".html";
result= s_io.xslt( filePath1, filePath2, fileXSL3, null);
if( result.startsWith("OK")==false )
{
    errMsg( result);
    s_out.println( "result="+ result);
    return result;
}

// Transforming from src xml to sil xml
String[] paramArray = new String[2];
paramArray[0]= String.valueOf(cassetteID);
paramArray[1]= PIN_Number;
filePath2= cassetteDir+ archiveFileName +"_sil.xml";
result= s_io.xslt( filepath1, filePath2, fileCrystalData2Sil, paramArray);
if( result.startsWith("OK")==false )
{
    errMsg( result);
    s_out.println( "result="+ result);
    return result;
}

result= "OK";

x1= "result="+ result;
logMsg( x1);
x1+= "<BR>";
s_out.println( x1);

return result;
}

//==============================================================

String addCassette( int userID, String PIN_Number, int retCassetteID[])
{
String x= "";
try
{
x= s_db.addCassette( userID, PIN_Number);
if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	return x;
}

int cassetteID= Integer.valueOf( x.trim() ).intValue();
retCassetteID[0] = cassetteID;

String filePrefix= "excelData";
String userFileName= "default.xls";
String filePath1= getConfigValue( "templateDir")+ "cassette_template";
String cassetteDir= getConfigValue( "cassetteDir");
String userName= s_db.getUserName( userID);

cassetteDir= cassetteDir+ userName +"/";
File fso = new File(cassetteDir);
if( fso.exists()==false )
{
    fso.mkdir();
}
//String archiveFileName= s_db.addCassetteFile( cassetteID, filePrefix, userFileName, userName);
//if( archiveFileName.length()>4 && archiveFileName.substring(0,4).compareToIgnoreCase("<Err")==0)
//{
//	x= archiveFileName;
//	return x;
//}

//x= archiveFileName;

x = String.valueOf(cassetteID);
}
catch( Exception ex)
{
    x="<Error> addCassette()"+ ex +"</Error>";
}

return x;
}


//============================================================

public String upload(  String uploadFile, String uploadURL, String resultFile)
{
	//out.println("uploadFile()");
	String response= "";
	try
	{
		FileInputStream is= new FileInputStream( uploadFile);
		if( is==null)
			return "FileInputStream error";
		response= uploadFileStream( is, uploadURL, resultFile);
		//is.cloe();
	}
	catch( Exception e)
	{
		response= "ERROR uploadFile() "+ e;
		//error( response);
	}

	return response;
}

//============================================================

public String uploadFileStream(  InputStream ins, String uploadURL, String resultFile)
{
	//out.println("uploadFileStream()");
	String result= "";
	try
	{
		byte bytebuf[]= new byte[2048];
		URLConnection urlcon= null;
		OutputStream os= null;
		DataOutputStream dos= null;
		URL u= new URL(uploadURL);
		if( u==null)
			return "URL error";
		urlcon= u.openConnection();
		if( urlcon==null)
			return "Connetction error";
		urlcon.setDoOutput( true);
		urlcon.setDoInput( true);
		urlcon.setUseCaches( false);

		//urlcon.setRequestMethod("POST");
		//urlcon.setRequestProperty("Content-Type", "application/x-www-form-urlencoded" );
		//urlcon.setRequestProperty("Content-Length", ""+lng );
		os = urlcon.getOutputStream();
		dos= new DataOutputStream(os);
		if( dos==null)
			return "POST DataOutputStream error";

		DataInputStream dis = new DataInputStream( new BufferedInputStream( ins));
		int lng= 0;
		for(;;)
		{
			int lng1= dis.read( bytebuf, 0, 2048);
			if( lng1<0)
				break;
			if( lng1==0)
				continue;
			dos.write( bytebuf, 0, lng1);
			lng+= lng1;
		}
		dis.close();
		dos.flush();
		dos.close();
		//s_out.println( ""+ lng +" bytes sent to server");

		// get the post response
		DataInputStream is2 = new DataInputStream(
			                       new BufferedInputStream(
								         urlcon.getInputStream()));
		dos= new  DataOutputStream( new FileOutputStream( resultFile));
		lng= 0;
		for(;;)
		{
			int lng1= is2.read( bytebuf, 0, 2048);
			if( lng1<0)
				break;
			if( lng1==0)
				continue;
			dos.write( bytebuf, 0, lng1);
			if( lng==0)
			{
				// save first part of response
				result= new String( bytebuf, 0, lng1);
			}
			lng+= lng1;
		}
		is2.close();
		dos.flush();
		dos.close();
		//s_out.println( ""+ lng +" bytes received from server");
		//s_out.println( "resultFile= "+ resultFile);

		if( result.startsWith("<Err")==true )
		{
			//error( response);
			result= "ERROR: "+ result;
		}
		else
		{
			result= "OK";
		}
	}
	catch( Exception e)
	{
		result= "ERROR uploadFileStream() "+ e;
	}

	return result;
}

//============================================================
//============================================================
%>

<html>
<head><title>Upload Excel File</title></head>
<body>

<%
logMsg( "Upload Excel File");
s_out.println("Upload Excel File<BR>");

String result= "";

long length= request.getContentLength();
logMsg( "ContentLength="+ length);
if( length>MAXCONTENTLENGTH)
{
    result= "ERROR - file is too big: "+ length;
    errMsg( result);
    s_out.println( result);
    // to work araound a bug we have to call mreq.setRequest( request) even if we are no interested in the request
    // however, we can make sure that nothing gets downloaded by setting the timeout to 0
    mreq.setExpiration(0);
    mreq.setRequest( request);
    // remove temp file in MultipartRequest
    mreq.release();
}
else
{
    mreq.setRequest( request);
    result= processRequest( mreq);
    // remove temp file in MultipartRequest
    mreq.release();
}


logMsg( "Done");
%>

<BR>
<BR>
<%
String url= "CassetteInfo.jsp?accessID="+ s_accessID;
url+= "&userName="+ s_userName;
%>
<A HREF="<%= url %>">
View Cassette Information
</A>
<BR>


</body>
</html>

<%
if( result.startsWith("OK")==true )
{
   response.sendRedirect( url);
}
%>
