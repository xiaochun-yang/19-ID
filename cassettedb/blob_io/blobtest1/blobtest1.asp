<script language="JavaScript" runat="server">
// blobtest1.asp
// load/save blob from/to binary file
//
// uses the COM server "BLOB_io.BLOB_io1" with the functions
//	 success= o.saveBinFile( forBlob, forBlobSize, blobFileName);
//   blob= o.loadBinFile( blobFileName);
//   blobSize= o.getBlobSize( blob);
//
// c:\winnt\system32\regsvr32.exe C:\Inetpub\wwwroot\Excel2XML\BLOB_io.dll
//
// ???
// requires "global.asa" with:
// <object RunAt=Server Scope=Application id=g_xmlhttp progid="Microsoft.XMLHTTP"></object>
//
//
// Article ID: Q244758
// 500-100.asp Returns "Type Mismatch" Error After Request.BinaryRead() 
// solution:
// edit  C:\WINNT\Help\iisHelp\common\500-100.asp "On Error Resume Next"
//


//==============================================================

function test()
{
out( "blobtest1.asp START");

forQuery= Request.QueryString("forQuery");
forBlobSize= Request.TotalBytes;
forBlob= Request.BinaryRead( forBlobSize);

out("forQuery="+ forQuery);
out("forBlobSize="+ forBlobSize);

//var blobsize= saveBlob( forQuery, forBlob, forBlobSize);
//var blobsize= loadBlob();
//out("blobsize="+ blobsize);

filePath= Server.MapPath( "AGES.XLS" );
var xmldata= Excel2XML( filePath)
Response.Write( xmldata)

out( "blobtest1.asp OK");
}

//==============================================================

function saveBlob( forQuery, forBlob, forBlobSize)
{
	var blobsrv = Server.CreateObject("BLOB_io.BLOB_io1");
	
	var filepath= Server.MapPath( "blobtest1.txt");
	out("filepath="+ filepath);

	result= blobsrv.saveBinFile( forBlob, forBlobSize, filepath);
	return result; 
}

//==============================================================

function loadBlob()
{
	var blobsrv = Server.CreateObject("BLOB_io.BLOB_io1");
	//var b1 = Server.CreateObject("BinFile.BinFile1");
	
	var filepath= Server.MapPath( "blobtest1.txt");
	out("filepath="+ filepath);

	var blob= blobsrv.loadBinFile( filepath);
	var result= blobsrv.getBlobSize( blob);
	return result; 
}

//==============================================================

function Excel2XML( forExcelFileName)
{
strDSN= "DBQ="+ forExcelFileName +";DRIVER={Microsoft Excel Driver (*.xls)}"
//out( "strDSN="+ strDSN);

strSQL = "SELECT * FROM [Sheet1$]"

//setResponseHeader()
var cn = Server.CreateObject("ADODB.Connection")
var rs = Server.CreateObject("ADODB.Recordset")
cn.Open( strDSN)
//rs.Open( strSQL, cn, 3, 1)
try
{
	rs.Open( strSQL, cn, 3, 1)
}
catch( exception)
{
	Response.Write( "sql exception: "+ exception);
	Response.Write( "exception.description: "+ exception.description); 
	return;
}

/*
ActiveConnection 
'Report field names and values for record.
    For Each fldLoop In rsCustomers.Fields
        Debug.Print fldLoop.Name, fldLoop.Value
    Next fldLoop

*/

var data= ""
data+= '<?xml version="1.0"?>\r\n'
data+= "<ExcelData>\r\n"
var rowIndex= 2
while( rs.EOF==0 )
{
	data+= "<row id='"+ rowIndex +"'>"
	//data+= createElement( "LastName", rs(0))
	//data+= "</row>\r\n"
    var rsFields = rs.Fields
    for( i=0; i<rsFields.Count; i++)
    {
		fieldName= rsFields.Item(i).Name
		fieldValue= rsFields.Item(i).Value
		data+= createElement( fieldName, fieldValue)
		//out("fieldName="+ fieldName);
		//out("fieldValue="+ fieldValue);
    }
    data+= "</row>\r\n"
    
	rowIndex++;
	rs.MoveNext()
}
data+= "</ExcelData>\r\n"
//Response.Write( data)
return data;
}

//==============================================================

function createElement( tagname, value)
{
return "<"+ tagname +">"+ value +"</"+ tagname +">"
}

//==============================================================

function setResponseHeader()
{
Response.ContentType = "application/xml"
}

//==============================================================
//-- for debug:
//==============================================================

function out( t)
{
return

var txt = t + "<br>\r\n";
Response.Write( txt);
//var txt = t + "\n\r"
// outtext.value = txt
return
}

//==============================================================
//==============================================================
// call test():

test();

</script>
