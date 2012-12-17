<script language="JavaScript" runat="server">
// getCassetteData.asp
//
//

//==============================================================

function main()
{
//data= "{cassette1(gwolf) undefined undefined}"
//Response.Write( data)
//return;
var filePath1
filePath1= Server.MapPath("data/beamlines/");
// this requires a running database server:
// filePath1= obj.getParameterValue( "beamlineDir");

forBeamLine= ""+Request.QueryString("forBeamLine");
forBeamLine= getBeamlineName( forBeamLine);
forUser= ""+Request.QueryString("forUser");

filePath1= filePath1 +"\\"+ forBeamLine +"\\inuse_cassettes.txt";
data= loadText( filePath1);

Response.Write( data)
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

function getParameterValue( paraName)
{
x= ""
try
{
var obj
//obj= Server.CreateObject("ctsdb");
obj= GetObject("java:ctsdb");
//setDBConnection( obj);
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

function loadText( filePath)
{
var text= "";
try
{
	var fso = Server.CreateObject("Scripting.FileSystemObject");
	ForReading= 1
	var a = fso.OpenTextFile( filePath, ForReading);
	text= a.ReadAll();
	a.Close();
}
catch( e)
{
	text= "<Error>"+ e.description +" "+ filePath +"</Error>";
}

return( text);
}

//==============================================================
//==============================================================

function setResponseHeader()
{
Response.ContentType = "application/xml"
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
