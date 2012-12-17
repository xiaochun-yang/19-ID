<script language="VBScript" runat="server">
'// excel2xml.asp
'// translate Excel to XML
'//
'// uses:
'// Microsoft ADODB version 2.6
'// Microsoft COM server "DSOleFile.PropertyReader" (DSOFile.dll)
'// Microsoft XML version 4.0 ("Msxml2.DOMDocument.4.0")
'//
'// Unfortunately we must write this ASP in VBScript since there are
'// problems with garbage collection of COM objects with JScript
'//
'// We must use the OLE DB driver and not ODBC,
'// since ODBC does not support "Extended Properties=""Excel 8.0; IMEX=1;"""
'// IMEX=1 is needed to avoid "mixed data types" problems.
'// Additionally we have to set the registry variable 
'// HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Jet\4.0\Engines\Excel\TypeGuessRows=0
'// http://support.microsoft.com/default.aspx?scid=kb;EN-US;194124
'//
'// We have to replace special characters that are not supported by XML
'// http://support.microsoft.com/default.aspx?scid=kb;en-us;315580
'//

'//==============================================================

Function main()
doExcel2xml()
End Function

'//==============================================================
'//==============================================================

Function doExcel2xml()

fileXSL1 = "xsltADO2XML.xsl"

forSheetName= Request.QueryString("forSheetName")
If IsEmpty(forSheetName) Or IsNull(forSheetName) Then
	forSheetName= "Sheet1"
End If

fileXSL1= Server.MapPath( fileXSL1)

forBlobSize= Request.TotalBytes
forBlob= Request.BinaryRead( forBlobSize)

'// save the request bytes as local Excel file "uploadX.xls"
Application.Lock()
NumVisits= Application("NumVisits")
If IsEmpty(NumVisits) Or IsNull(NumVisits) Or IsNumeric(NumVisits)=False Then
	NumVisits= 1
End If
Application("NumVisits") = NumVisits + 1 
Application.Unlock()

'// save the uploaded spreadsheet to a temp file
id= NumVisits Mod 10
fname1= "temp" & id & ".xls"
filePath= Server.MapPath( fname1)
If  forBlobSize<=0 Then
	errorMsg("forBlobSize="& forBlobSize)
	Exit Function
End If
If forBlobSize >2100000 Then
	errorMsg("Excel File too big.")
	Exit Function
End If
blobsize= saveBlob( filePath, forBlob, forBlobSize)

'// name for temp xml file (used for debugging)
fname2= "temp" & id & ".xml"
xmlFilePath= Server.MapPath( fname2)

'// check if the excel document has Macros
hasMacro= hasMacroTest( filePath)
'//hasMacro= False
If hasMacro Then
	errorMsg("Excel files with Macro code not accepted.")
	Exit Function
End If

'// ADO Excel -> XML
'//strDSN= "DBQ="& filePath &";DRIVER={Microsoft Excel Driver (*.xls)}"
strDSN=  "Provider=Microsoft.Jet.OLEDB.4.0;" & _
         "Data Source="& filePath &";" & _
         "Extended Properties=""Excel 8.0; IMEX=1;"""
'//strSQL = "SELECT * FROM ["+ forSheetName +"$]"
strSQL = "SELECT * FROM ["+ forSheetName +"$A1:AZ2000]"
Set cn = Server.CreateObject("ADODB.Connection")
Set rs = Server.CreateObject("ADODB.Recordset")
Set xmlDoc1= Server.CreateObject("Msxml2.DOMDocument.4.0")
Err.Clear
On Error Resume Next

cn.Open( strDSN)
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "SQL Open Connection Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

adUseClient = 3
adOpenStatic = 3
adLockOptimistic = 3
adPersistXML = 1
rs.CursorLocation = adUseClient
rs.Open strSQL, cn, adOpenStatic, adLockOptimistic
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "SQL Open Recordset Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

'// open ADO stream
Set objStream = Server.CreateObject("ADODB.Stream")
Const adTypeBinary = 1
objStream.Open
objStream.Type = adTypeBinary
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "Open Stream Error " & CStr(Err.Number) & " " & Err.Description
	Set objStream= Nothing
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

'//rs.save xmlDoc1, adPersistXML '// save the recordset-xml to a XML document object
rs.save objStream, adPersistXML '// save the recordset-xml to an ADO stream object
If IsNumeric(Err.Number) And Err.Number>0 Then
	msg= "SQL save Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	rs.Close
	Exit Function
End If
rs.Close
If IsNumeric(Err.Number) And Err.Number>0 Then
	msg= "SQL Close " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

'// save the recordset-xml to a file (optional, but useful for debugging)
objStream.SaveToFile xmlFilePath, 2
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "SaveToFile Error " & CStr(Err.Number) & " " & Err.Description
	objStream.Close
	Set objStream= Nothing
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

'// replace Low-Order ASCII Characters by '_'
'// rejected by MSXML versions 3.0 and later: 
'// #x0 - #x8 (ASCII 0 - 8)
'// #xB - #xC (ASCII 11 - 12)
'// #xE - #x1F (ASCII 14 - 31)
'// http://support.microsoft.com/default.aspx?scid=kb;en-us;315580
objStream.Position= 0
xmlText= objStream.ReadText(-1)
xmlStr= ReplaceEx( xmlText, "[\x00-\x08]|[\x0B-\x0C]|[\x0E-\x1F]", "_")
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "objStream ReadText Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

'//out( "xmlText="& CStr(xmlText) )
'//out( "xmlStr="& xmlStr)
'//Exit Function

objStream.Close
Set objStream= Nothing
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "objStream close Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

xmlDoc1.async = false
'//xmlDoc1.load xmlFilePath '// use the original ADO recordest xml
xmlDoc1.loadXML xmlStr '// use xml string where the special characters are removed
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "xmlDoc1.load Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Exit Function
End If
If xmlDoc1.parseError.errorCode<>0 Then
	result = reportParseError(xmlDoc1.parseError)
	errorMsg(result)
	Exit Function
End If

'//out( xmlDoc1.xml)
'//out( "================")
'//Exit Function

'// Load the XSL script ado2xml.xsl
Set xslDoc= Server.CreateObject("Msxml2.DOMDocument.4.0")
xslDoc.async = False
xslDoc.load( fileXSL1)
If xslDoc.parseError.errorCode<>0 Then
	result = reportParseError(xslDoc.parseError)
	errorMsg(result)
	Exit Function
End If

'// xsl transform "persist ADO-XML" --> xml (strip Microsoft specfic info)
Set xmlDoc2 = Server.CreateObject("Msxml2.DOMDocument.4.0")
On Error Resume Next

xmlDoc1.transformNodeToObject xslDoc, xmlDoc2
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "XML transform Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Exit Function
End If

'//out( xmlDoc2.xml);
'//out( "================")

xmlDoc2.save( Response)

End Function

'//==============================================================
'//==============================================================

Function hasMacroTest( fname)
'//out("fname="& fname)
Err.Clear
On Error Resume Next
hasMacro = False
Set pr= Server.CreateObject("DSOleFile.PropertyReader")
If pr Is Nothing Then
    msg = "This function requires the file DSOFile.dll to be installed"
	errorMsg( msg)
	hasMacroTest= hasMacro
	Exit Function
End If

Set docProperties = pr.GetDocumentProperties( fname)
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "hasMacroTest() Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	Set docProperties = Nothing
	Set pr = Nothing
	hasMacroTest= hasMacro
	Exit Function
End If
hasMacro = docProperties.HasMacros
Set docProperties = Nothing
Set pr = Nothing
hasMacroTest= hasMacro
End Function

'//==============================================================
'//==============================================================

Function saveBlob( filePath, forBlob, forBlobSize)

Const adTypeBinary = 1
Const adSaveCreateNotExist = 1 
Const adSaveCreateOverWrite = 2 

Err.Clear
On Error Resume Next
Set objStream = Server.CreateObject("ADODB.Stream")

objStream.Open
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "saveBlob() Open Error " & CStr(Err.Number) & " " & Err.Description
	Set objStream= Nothing
	Err.Clear
	errorMsg( msg)
	saveBlob= 0
	Exit Function
End If
objStream.Type = adTypeBinary

objStream.Write forBlob
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "saveBlob() Write Error " & CStr(Err.Number) & " " & Err.Description
	objStream.Close
	Set objStream= Nothing
	Err.Clear
	errorMsg( msg)
	saveBlob= 0
	Exit Function
End If

objStream.SaveToFile filePath, 2
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "saveBlob() SaveToFile Error " & CStr(Err.Number) & " " & Err.Description
	objStream.Close
	Set objStream= Nothing
	Err.Clear
	errorMsg( msg)
	saveBlob= 0
	Exit Function
End If

objStream.Close
Set objStream= Nothing
If IsNumeric(Err.Number) And Err.Number<>0 Then
	msg= "saveBlob() Close Error " & CStr(Err.Number) & " " & Err.Description
	Err.Clear
	errorMsg( msg)
	saveBlob= 0
	Exit Function
End If

saveBlob= forBlobSize
End Function

'//==============================================================

Function loadBlob( filePath)
Const adTypeBinary = 1
Set objStream = Server.CreateObject("ADODB.Stream")
objStream.Open
objStream.Type = adTypeBinary
objStream.LoadFromFile filePath
result= objStream.Read
objStream.Close
Set objStream = Nothing
loadBlob = result 
End Function

'//==============================================================
'//==============================================================
'//str = "The quick brown fox and Fox jumped over the lazy dog."
'//msg= ReplaceEx( str, "fox", "cat")      ' Replace 'fox' with 'cat'.
'//msg= ReplaceEx(str,"(\S+)(\s+)(\S+)", "$3$2$1")   ' Swap first pair of words.
'//out( msg)

Function ReplaceEx( str, patrn, replStr)
  Dim regEx
  Set regEx = New RegExp            ' Create regular expression.
  regEx.Pattern = patrn            ' Set pattern.
  regEx.Global = True
  regEx.IgnoreCase = True            ' Make case insensitive.
  ReplaceEx = regEx.Replace(str, replStr)   ' Make replacement.
End Function

'//==============================================================
'//==============================================================
'// XML Parse error formatting function

Function reportParseError(error)
  s = ""
  r = "XML parse error: " & error.url &" "& error.reason
  If error.line > 0 Then
    r =  r &"at line "& error.line &", char "& error.linepos &" "& error.srcText
  End If
  reportParseError = r
End Function

'//==============================================================

Function errorMsg( errmsg)
txt = ""
txt= txt & "<Error>"
txt= txt &  Server.HTMLEncode( errmsg)
txt= txt &  "</Error>"
Response.Write( txt)
End Function

'//==============================================================
'//-- for debug:
'//==============================================================

Function out( t)
txt = t + "<br>\r\n"
Response.Write( txt)
End Function

'//==============================================================
'//==============================================================
'// call main():

main()

</script>
