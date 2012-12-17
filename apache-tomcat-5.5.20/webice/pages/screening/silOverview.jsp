<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="org.xml.sax.InputSource" %>
<%@ page import="org.xml.sax.EntityResolver" %>
<%
	ScreeningViewer viewer = client.getScreeningViewer();
%>

<html>
<head>
<meta http-equiv="Expires" content="0">
<meta http-equiv="Pragma" content="no-cache">
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

<script id="event" language="javascript">

function setScroll() {
    silFrame.window.scroll(<%= viewer.getScrollX() %>, <%= viewer.getScrollY() %>); 
}

function display_onchange() {
    eval("i = document.silForm.displayType.selectedIndex");
    eval("x= document.silForm.displayType.options[i].value");
    var submit_url = "setSilOverviewOption.do?template=" + x;

    this.location.replace(submit_url);
}

function option_onchange() {
    eval("i = document.silForm.showImages.selectedIndex");
    eval("x= document.silForm.showImages.options[i].value");
    var submit_url = "setSilOverviewOption.do?option=" + x;

    this.location.replace(submit_url);
}

function rowOption_onchange() {
    eval("i = document.silForm.rowOptions.selectedIndex");
    eval("x= document.silForm.rowOptions.options[i].value");
    var submit_url = "setSilOverviewOption.do?numRows=" + x;

    parent.location.replace(submit_url);
}

function view_strategy() {
 	document.silForm.command.value = "View Strategy";
	document.silForm.target = "_top";
	document.silForm.submit();
}

function set_mode() {
	box = eval("document.silForm.multiple");
	if (box.checked == true)
		document.silForm.mode.value = "multi";
	else
		document.silForm.mode.value = "one";
 	document.silForm.command.value = "setSelectionMode";
	document.silForm.submit();
}

function analyze_crystals()
{
	window.frames['silFrame'].document.forms['silForm'].command.value = "Analyze Crystals";
	window.frames['silFrame'].document.forms['silForm'].submit();
}

</script>
</head>
<body>
<%
	String error = (String)request.getSession().getAttribute("error.screening");
	request.getSession().removeAttribute("error.screening");
	String error1 = (String)request.getSession().getAttribute("error.viewStrategy");
	request.getSession().removeAttribute("error.viewStrategy");
	if (error != null) { %>
<span class="error"><%= error %> Please visit the <a href="<%= ServerConfig.getSilUrl() %>" target="_blank">Sample Information
List</a> main website.</span><br/>
<% 	} %>
<%	if (error1 != null) { %>
<span class="error"><%= error1 %></span><br/>
<% 	} %>
<% 	if ((error == null) && (error1 == null)) { %>

<%	String silId = viewer.getSilId();
	Document doc = viewer.getSilDocument();
	int row = viewer.getSelectedRow();
	String beamline = "Beamline";
	if (client.isConnectedToBeamline())
		beamline = client.getBeamline();

	if ((silId == null) || (silId.length() == 0) || (doc == null) || (row < 0)) { %>

<span class="warning">Please select a spreadsheet from <b>User Cassettes</b> or <b><%= beamline %> Cassettes</b> tab.</span>

<% 	} else if (!viewer.isCassetteViewable()) { %>
User <%= client.getUser() %> has no permission to view spreadsheet (ID <%= silId %>). A spreadsheet is viewable if at
least one of the following conditions is met:
<ul>
<li>The user is the owner of the spreadsheet.</li>
<li>The spreadsheet has been assigned to a beamline, and the user has a permission to access the beamline, 
and the user is the current owner of the cassette position.</li>
<li>The spreadsheet has been assigned to a beamline, and the user has a permission to access the beamline, 
and the cassette position has no owner.</li>
</ul>

<%	} else {
		
		boolean isAnalyzingCrystal = viewer.isAnalyzingCrystal();
		boolean locked = viewer.isSilLocked();
		String displayOption = viewer.getSilOverviewOption();
		String templateName = viewer.getSilOverviewTemplate();
		String templateDir = session.getServletContext().getRealPath("/") + "/templates";
		String templateFile = templateDir + "/" + templateName + ".xml";
		String selectedSilId = viewer.getSilId();
		
		String editDisabled = (row < 0) ? "disabled":"";
		String editGrayed= (row < 0) ? "inactionbutton":"actionbutton1";

		String strategyDisabled = (row < 0) ? "disabled":"";
		String strategyGrayed = (row < 0) ? "inactionbutton":"actionbutton1";
		
		String analyzeDisabled = ((row < 0) && isAnalyzingCrystal) ? "disabled":"";
		String analyzeGrayed = ((row < 0) && isAnalyzingCrystal) ? "inactionbutton":"actionbutton1";
%>

<TABLE class="sil-list" width="100%">
<form name="silForm" action="handleSilCommand.do" target="_self" method="GET" >
<input type="hidden" name="accessID" value="<%= client.getSessionId() %>" />
<input type="hidden" name="userName" value="<%= viewer.getSilOwner() %>" />
<input type="hidden" name="silId" value="<%= viewer.getSilId() %>" />
<input type="hidden" name="mode" value="" />
<tr class="selected"><td align="left">
&nbsp;&nbsp;<b>Spreadsheet ID: <%= selectedSilId %></b>
&nbsp;&nbsp;<input class="actionbutton1"  type="submit" name="command" value="Update"/>
<% if (viewer.getSelectionMode().equals("one")) { %>
<input type="text" readonly class="readonly" size="3" value="<%= viewer.getSelectedCrystalPort() %>" />
<xsl:text>&nbsp;</xsl:text><input class="<%= editGrayed %>"  type="submit" name="command" value="Edit Crystal" <%= editDisabled %> />
<xsl:text>&nbsp;</xsl:text><input class="<%= strategyGrayed %>" type="submit" name="command" value="View Strategy" onClick="view_strategy()" <%= strategyDisabled %>/>
<xsl:text>&nbsp;</xsl:text><input class="<%= analyzeGrayed %>" type="submit" name="command" value="Analyze Crystal" <%= analyzeDisabled %> />
<% } else { // selection != one %>
<input type="text" readonly class="readonly" size="3" value=""/>
<xsl:text>&nbsp;<xsl:text><input class="inactivebutton" type="submit" value="Edit Crystal" disabled="true"/>
<xsl:text>&nbsp;</xsl:text><input class="inactivebutton" type="submit" name="command" value="View Strategy" disabled="true"/>
<xsl:text>&nbsp;</xsl:text><input class="actionbutton1" type="button" name="command" value="Analyze Crystals" onclick="analyze_crystals()"/>
<% } %>
<!--
<input type="checkbox" name="multiple" value="" checked onchange="set_mode()"/>Multiple Crystal Selection
-->
</td>
</tr>
</form>
</TABLE>
<iframe scroll="auto" id="silFrame" name="silFrame" width="100%" height="90%" src="showSilOverviewPart2.do" onLoad="setScroll()"></iframe>

<% } %>
<% 	} // if error %>
</body>
</html>
