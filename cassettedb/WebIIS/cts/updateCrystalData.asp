<script language="JavaScript" runat="server">
// updateCrystalData.asp
//
// To make sure that the user sees the same info as dcss has currently loaded
// we have 3 file states:
// 1.) uploaded (Excel file upload with Web UI).
// 2.) mounted (defined with a Web UI).
// 3.) loaded by dccs ("in use")
// updateCrystalData.asp is responsible for the transition 2->3
//
// It is called by the screening UI when the user clicks the "Update" button with
// updateCrystalData.asp?forBeamLine=blctl111&forUser=${user}&forCassette=${cassette}
// -->
// copy crystalData.xml -> inuse_blctl111.xml
// xslt inuse_blctl111.xml -> inuse_blctl111.html
// xslt inuse_blctl111.xml -> inuse_blctl111.txt
//
//
//

//==============================================================

function main()
{
doUpdateCrystalData();
}

//==============================================================
//==============================================================

function doUpdateCrystalData()
{
// copy crystalData.xml -> inuse_blctl111.xml
//
forBeamLine= ""+Request.QueryString("forBeamLine");
forBeamLine= getBeamlineName( forBeamLine);
forUser= ""+Request.QueryString("forUser");

x= createBeamlineInfo( forUser, forBeamLine);
//out( "x="+ x);
x= copyFilesToInUse( forUser, forBeamLine);

Response.Write( "ok");

return;
}

//==============================================================

function getBeamlineName( forBeamLine)
{
var beamlineName= forBeamLine.toLowerCase();
switch( beamlineName)
{
	case 'smbdcsdev': beamlineName= 'SMBDCSDEV'; break;

	case 'blctl111': beamlineName= 'BL11-1'; break;
	case 'blctl92': beamlineName= 'BL9-2'; break;
	case 'blctl91': beamlineName= 'BL9-1'; break;

	case 'bl111': beamlineName= 'BL11-1'; break;
	case 'bl92': beamlineName= 'BL9-2'; break;
	case 'bl91': beamlineName= 'BL9-1'; break;

	case 'bl11-1': beamlineName= 'BL11-1'; break;
	case 'bl9-2': beamlineName= 'BL9-2'; break;
	case 'bl9-1': beamlineName= 'BL9-1'; break;

	default: beamlineName= forBeamLine; break;
}
return beamlineName;
}

//==============================================================

function createBeamlineInfo( userName, beamlineName)
{
var result= "";
var xml1= getCassettesAtBeamline(beamlineName);
var fileXSL1= "cassettesAtBeamline.xsl";
//out( "xml1="+xml1);

fileXSL1= Server.MapPath( fileXSL1);

var xmlDoc1= new ActiveXObject("Msxml2.DOMDocument.4.0")
xmlDoc1.async = false;
xmlDoc1.loadXML( xml1);

// Load the XSL
xslDoc= new ActiveXObject("Msxml2.DOMDocument.4.0")
xslDoc.async = false;
xslDoc.load( fileXSL1);
if (xslDoc.parseError.errorCode != 0)
{
	result = reportParseError(xslDoc.parseError);
	return result;
}
// xsl transform into tcl format
try
{
    var tcldata= xmlDoc1.transformNode(xslDoc);
    result= tcldata;
}
catch (e)
{
    result = "<Error>"+ e.description +"</Error>";
	return result;
}

//save beamline info to disk
var beamlineDir= getParameterValue( "beamlineDir")+ beamlineName +"\\";
var fso = new ActiveXObject("Scripting.FileSystemObject");
if (fso.FolderExists(beamlineDir)==false )
{
	fso.CreateFolder( beamlineDir);
}
var filepath;
filepath= beamlineDir+ "cassettes.xml";
xmlDoc1.save( filepath);
filepath= beamlineDir+ "cassettes.txt";
var f= fso.CreateTextFile( filepath, true);
f.Write( tcldata);
f.Close();

//out( "filepath="+ filepath);

return result;
}

//==============================================================

function getCassettesAtBeamline( beamlineName)
{
x= ""
try
{
var obj
obj= GetObject("java:ctsdb");
setDBConnection( obj);
x= ""+obj;
x= obj.getCassettesAtBeamline( beamlineName);
}
catch( ex)
{
x="<Error> getCassettesAtBeamline()"+ ex.description +"</Error>";
}
return x;
}

//==============================================================

function copyFilesToInUse( userName, beamlineName)
{
x= ""
try
{
var obj
obj= GetObject("java:ctsdb");
setDBConnection( obj);
x= ""+obj;
var beamlineDir= obj.getParameterValue( "beamlineDir");

beamlineDir= beamlineDir+ beamlineName +"\\";

//out( "beamlineDir="+ beamlineDir);

var fso = new ActiveXObject("Scripting.FileSystemObject");
if (fso.FolderExists(beamlineDir)==false )
{
	fso.CreateFolder( beamlineDir);
	cassetteInfo= "{undefined undefined undefined }";
	saveText( cassetteInfo, beamlineDir+"cassettes.txt");
}

var ext;
var filepath1= beamlineDir;
var filepath2= beamlineDir+ "inuse_";

//out( "filepath1="+ filepath1);
//out( "filepath2="+ filepath2);

ext= "cassettes.xml";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}
ext= "cassettes.txt";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}

ext= "left.xml";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}
ext= "left.txt";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}

ext= "middle.xml";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}
ext= "middle.txt";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}

ext= "right.xml";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}
ext= "right.txt";
if( fso.FileExists( filepath1+ext)==true ) {fso.CopyFile(filepath1+ext,filepath2+ext);}

x= "ok";
}
catch( ex)
{
x="<Error> copyFilesToBeamline()"+ ex.description +"</Error>";
}
return x;
}

//==============================================================

function getParameterValue( paraName)
{
x= ""
try
{
var obj
//obj= Server.CreateObject("ctsdb");
obj= GetObject("java:ctsdb");
setDBConnection( obj);
x= ""+obj;
x= obj.getParameterValue( paraName);
}
catch( ex)
{
x="<Error> getParameterValue()"+ ex.description +"</Error>";
//out(x);
}
return x;
}

//==============================================================

function setDBConnection( obj)
{
obj.DSN="jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(HOST=smbdb)(PROTOCOL=tcp)(PORT=1521))(CONNECT_DATA=(SID=test)))";
obj.userName="jcsg";
obj.password="tmp_jcsg";
}

//==============================================================

function saveText( text, filePath)
{
var fso = Server.CreateObject("Scripting.FileSystemObject");
var a = fso.CreateTextFile( filePath, true);
a.Write( text);
a.Close();
}

//==============================================================

function setResponseHeader()
{
Response.ContentType = "application/xml"
}


//==============================================================

// Parse error formatting function
function reportParseError(error)
{
  var s = "";
  for (var i=1; i<error.linepos; i++) {
    s += " ";
  }
  r = "<Error>";
  r += "<font face=Verdana size=2><font size=4>XML Error loading '" + 
      error.url + "'</font>" +
      "<P><B>" + error.reason + 
      "</B></P></font>";
  if (error.line > 0)
    r += "<font size=3><XMP>" +
    "at line " + error.line + ", character " + error.linepos +
    "\n" + error.srcText +
    "\n" + s + "^" +
    "</XMP></font>";
  r += "</Error>";
  return r;
}

//==============================================================

// Runtime error formatting function.
function reportRuntimeError(exception)
{
r = "<Error>";
r += "<P><B>" + exception.description + "</B></P>";
r += "</Error>";
return r;
}

//==============================================================

function errorMsg( errmsg)
{
var txt = "";
txt+= "<Error>"
txt+= Server.HTMLEncode( errmsg);
txt+= "</Error>"
Response.Write( txt);
//txt = txt + "\n\r"
// outtext.value = txt
return
}

//==============================================================
//-- for debug:
//==============================================================

function out( t)
{
var txt = t + "<br>\r\n";
Response.Write( txt);
//var txt = t + "\n\r"
// outtext.value = txt
return
}

//==============================================================
//==============================================================
// call test():

main();

</script>
