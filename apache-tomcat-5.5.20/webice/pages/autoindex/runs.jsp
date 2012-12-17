<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="org.xml.sax.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%!


// member function
// Read run summary file (xml file), parse it and writes out data
// as a row in a html table.
// If there is an error node, do not try to extract results and only print out 
// image file names.
String readRunSummaryFile(String f, Imperson imperson, DocumentBuilder builder)
{
	
	String ret = "<td>&#160;</td><td>&#160;</td><td>&#160;</td><td>&#160;</td><td>&#160;</td><td>&#160;</td><td>&#160;</td>";

	try {

	String uri = "http://" + imperson.getHost() + ":" + imperson.getPort()
			+ "/readFile?impFilePath=" + f
			+ "&impUser=" + imperson.getUser() + "&impSessionID=" + imperson.getSessionId();
	Document doc = builder.parse(uri);
	
	Element root = doc.getDocumentElement();
	
	String image1 = "";
	String image2 = "";
	String braggSpots = "";
	String iceRings = "";
	String spots = "";
	
	String score = "";
	String resolution = "";
	String spaceGroup = "";
	
	boolean err = false;
	NodeList nlist = root.getElementsByTagName("error");
	if ((nlist != null) && (nlist.getLength() > 0)) {
		err = true;
	}
	
	
	nlist = root.getElementsByTagName("image");
	if ((nlist != null) && (nlist.getLength() >= 2)) {
		// image 1
		Element el = (Element)nlist.item(0);
		image1 = el.getAttribute("file");
		spots = el.getAttribute("spots");
		braggSpots = el.getAttribute("braggSpots");
		iceRings = el.getAttribute("iceRings");
		
		// image2
		el = (Element)nlist.item(1);
		image2 = el.getAttribute("file"); 
	}
	
	nlist = root.getElementsByTagName("bestSolution");
	if ((nlist != null) && (nlist.getLength() > 0)) {
		Element el = (Element)nlist.item(0);
		score = el.getAttribute("score");
		resolution = el.getAttribute("resolution");
		spaceGroup = el.getAttribute("spaceGroup");
		
	}
	
	StringBuffer buf = new StringBuffer();
	buf.append("<td align=\"center\">" + image1 + ", " + image2 + "</td>");
	if (err) {
		buf.append("<td>&#160;</td><td>&#160;</td><td>&#160;</td><td>&#160;</td><td>&#160;</td><td>&#160;</td>");
	} else {
		buf.append("<td align=\"center\">" + score + "</td>");
		buf.append("<td align=\"center\">" + spots + "</td>");
		buf.append("<td align=\"center\">" + braggSpots + "</td>");
		buf.append("<td align=\"center\">" + iceRings + "</td>");
		buf.append("<td align=\"center\">" + resolution + "</td>");
		buf.append("<td align=\"center\">" + spaceGroup + "</td>");
	}
	
	
	return buf.toString();
	
	} catch (Exception e) {
//		WebiceLogger.warn("Failed to read or parse run summary file " + f + ": " + e.getMessage());
	}
	
	return ret;
	
}

%>


<html>

<head>
<meta http-equiv="Expires" content="0">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
function submitForm() {
    document.sortForm.submit();
}

function loadRuns()
{
	document.location.replace("Autoindex_LoadRuns.do");
}

</script></head>

<body class="mainBody">
<% 
   try {

   DocumentBuilderFactory fac = DocumentBuilderFactory.newInstance();
   DocumentBuilder builder = fac.newDocumentBuilder();
   AutoindexViewer viewer = client.getAutoindexViewer();
   String runListType = viewer.getRunListType();
   
   AutoindexRun selectedRun = viewer.getSelectedRun();
   String selectedRunName = "";
   String beamline = "";
   if (selectedRun != null) {
   	selectedRunName = selectedRun.getRunName();
   }
   if (client.isConnectedToBeamline()) { 
	beamline = client.getBeamline();
   }
   TreeSet runDirs = viewer.getRunList();
   String rootDir = viewer.getRunRootDir();

   String sortBy = viewer.getSortBy();
   boolean ascending = viewer.isSortAscending();

   // Number of rows to display at a time
   int numRowsPerPage = viewer.getRunsPerPage();
   // Number of rows we have (number of directories)
   int numRows = runDirs.size();
   // First row to be displayed
   int firstRow = 0;
   // Last row to be displayed
   int lastRow = 0;
   int numPages = viewer.getNumPages();      
   int curPage = viewer.getRunPage();
   
   if (curPage < 1)
   	curPage = 1;

   if (curPage > numPages)
   	curPage = numPages;
   
   // In case of invalid range, display last page
  	 firstRow = (curPage-1)*numRowsPerPage + 1;
  	 lastRow = firstRow + numRowsPerPage - 1;
 	  if (lastRow > numRows)
		lastRow = numRows;
    
   if (numRows == 0) {
   	curPage = 0;
   	firstRow = 0;
	lastRow = 0;
   }
   
%>
<table class="autoindex">
<!-- <table cellborder="1" border="1" width="100%" bgcolor="#FFFF99"> -->
<form id="sortForm" name="sortForm" style="font-size:80%" action="Autoindex_SortRunsBy.do" target="_self">
<tr>
<td colspan="10" class="right">
<span style="float:left">
Sort By:<select name="sortBy" onchange="submitForm()">
<option value="name" <%= sortBy.equals("name") ? "selected" : "" %> />Run Name
<option value="ctime" <%= sortBy.equals("ctime") ? "selected" : "" %> />Creation Time
</select>
<input type="radio" name="direction" value="ascending" <%= ascending ? "checked" : "" %> onclick="submitForm()" />Ascending
<input type="radio" name="direction" value="descending" <%= ascending ? "" : "checked" %> onclick="submitForm()" />Descending
</span>
<span style="float:right">
<input class="actionbutton1" type="submit" value="Update" onclick="loadRuns()"/>
&nbsp;&nbsp;&nbsp;&nbsp;
Run <%= firstRow %> - <%= lastRow %> of <%= numRows %>  [ 
<a href="Autoindex_SelectRunListPage.do?page=first">first</a> | 
<a href="Autoindex_SelectRunListPage.do?page=prev">prev</a> | 
<a href="Autoindex_SelectRunListPage.do?page=next">next</a> | 
<a href="Autoindex_SelectRunListPage.do?page=last">last</a>
   	]</span>
</td></tr></form>
<tr>
<th>Run Name</th>
<th>Creation Time</th>
<th>Images</th>
<th>Score&nbsp;<nbr><a id="help" target="WebIceHelp" href="<%= ServerConfig.getHelpUrl() %>/Autoindex_strategy_calculat.html#allruns">i</a>&nbsp;</th>
<th>#Spots</th>
<th>#Bragg Spots</th>
<th>#Ice Rings</th>
<th>Predicted Resolution</th>
<th>Bravais Choice</th>
<th>Commands</th></tr>
<% 
   String bgc = "#FFFF99";
   Iterator it = runDirs.iterator();
   int count = 0;
   SimpleDateFormat df = new SimpleDateFormat("yy/MM/dd HH:mm:ss");
   Date dd = new Date();
   while (it.hasNext()) {
   	++count;
	FileInfo run = (FileInfo)it.next();
	if ((count < firstRow) || (count > lastRow))
		continue;
	String runSummaryFile = rootDir + "/" + run.name + "/run_summary.xml";
	if ((selectedRunName != null) && selectedRunName.equals(run.name)) {
		bgc = "selected";
	} else {
		bgc = "normal";
	}
	dd.setTime(run.ctime*1000);
%>
<tr class="<%= bgc %>">
<td align="center"><a href="Autoindex_SelectRun.do?run=<%= run.name %>" target="_parent"><%= run.name %></a></td>
<td><%= df.format(dd) %></td>
<%= readRunSummaryFile(runSummaryFile, client.getImperson(), builder) %>
<%	if (runListType.equals(AutoindexViewer.USER_RUNS)) {%>
<td align="center"><a target="_self" href="Autoindex_DeleteRun.do?run=<%= run.name %>" >[Delete]</a></td>
<% } else { // if runListType %>
<td align="center">[Delete]</td>
<% } // if runListType %>
</tr>
<% } // while loop %>
</table>

<%	if ((selectedRunName != null) && (selectedRunName.length() > 0)) { 
%>
<p>Go to selected run <a href="Autoindex_SelectRun.do?run=<%= selectedRunName %>" target="_parent"><%= selectedRunName %></a></p>
<% } 

   } catch (Exception e) { %>
<p class="error"> Unable to display run list because <%= e.getMessage() %>. Please try again later.</p>
<% } %>

</body>
</html>
