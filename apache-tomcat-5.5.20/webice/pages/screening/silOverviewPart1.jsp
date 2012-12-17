<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="org.xml.sax.InputSource" %>
<%@ page import="org.xml.sax.EntityResolver" %>
<html>
<script id="event" language="javascript">

function display_onchange() {
    eval("i = document.silForm.displayType.selectedIndex");
    eval("x= document.silForm.displayType.options[i].value");
    var submit_url = "setSilOverviewOption.do?template=" + x;

    parent.location.replace(submit_url);
}

function option_onchange() {
    eval("i = document.silForm.showImages.selectedIndex");
    eval("x= document.silForm.showImages.options[i].value");
    var submit_url = "setSilOverviewOption.do?option=" + x;

    parent.location.replace(submit_url);
}

function rowOption_onchange() {
    eval("i = document.silForm.rowOptions.selectedIndex");
    eval("x= document.silForm.rowOptions.options[i].value");
    var submit_url = "setSilOverviewOption.do?numRows=" + x;

    parent.location.replace(submit_url);
}

function check_target() {

    if (document.silForm.command.value == "View Strategy") {
    	document.silForm.target = "_top";
    }
    
    return true;
}

function view_strategy() {
 	document.silForm.command.value = "View Strategy";
}

</script>

<body>
<%

	ScreeningViewer viewer = client.getScreeningViewer();

	Document doc = viewer.getSilDocument();
	int row = viewer.getSelectedRow();

	if ((doc == null) || (row < 0)) { %>

<b>Please select a cassette.</b>
<form action="loadSilList.do">
<input type="submit" value="View Cassette List"/>
</form>
<%
	} else {
		
		boolean isAnalyzingCrystal = viewer.isAnalyzingCrystal();
		boolean locked = viewer.isSilLocked();
		String displayOption = viewer.getSilOverviewOption();
		String templateName = viewer.getSilOverviewTemplate();
		String templateDir = session.getServletContext().getRealPath("/") + "/templates";
		String templateFile = templateDir + "/" + templateName + ".xml";
		
		
%>
<form name="silForm" action="handleSilCommand.do" target="_parent" method="GET" onSubmit="return check_target()">
<input type="hidden" name="accessID" value="<%= client.getSessionId() %>" />
<input type="hidden" name="userName" value="<%= viewer.getSilOwner() %>" />
<input type="hidden" name="silId" value="<%= viewer.getSilId() %>" />

<table border="1">
<tr>
<th align="center" bgcolor="#bed4e7">Owner</th>
<th align="center" bgcolor="#bed4e7">Sample Information ID</th>
<th align="center" bgcolor="#bed4e7">Column Display Options</th>
<th align="center" bgcolor="#bed4e7">Image Display Options</th>
</tr>
<tr>
<td align="center" bgcolor="#E9EEF5"><%= viewer.getSilOwner() %></td>
<td align="center" bgcolor="#E9EEF5"><%= viewer.getSilId() %></td>
<td align="center">
<select name="displayType" onchange="display_onchange()">
  <option value="display_src" <%= templateName.equals("display_src") ? "selected" : "" %> >Original</option>
  <option value="display_mini" <%= templateName.equals("display_mini") ? "selected" : "" %> >Minimum</option>
  <option value="display_result" <%= templateName.equals("display_result") ? "selected" : "" %> >Result</option>
  <option value="display_all" <%= templateName.equals("display_all") ? "selected" : "" %> >All</option>
<% if (ServerConfig.getInstallation().equals("ALS")) { %>
  <option value="bcsb_screening_view" <%= templateName.equals("bcsb_screening_view") ? "selected" : "" %> >BCSB Screening View</option>
<% } %>
</select>
</td>
<td align="center">
<select name="showImages" onchange="option_onchange()">
  <option value="hide" <%= displayOption.equals("hide") ? "selected" : "" %> >Hide All Images</option>
  <option value="show" <%= displayOption.equals("show") ? "selected" : "" %> >Selected Sample Only</option>
  <option value="link" <%= displayOption.equals("link") ? "selected" : "" %> >Show Image Links Only</option>
</select>
</td>
</tr>
</table>
<br/>
<TABLE width="100%">
<tr bgcolor="#6699CC"><td colspan="16" align="left">
&nbsp;&nbsp;<input style="background-color:yellow;color:black" type="submit" name="command" value="All Cassettes"/>
&nbsp;&nbsp;<input style="background-color:yellow;color:black" type="submit" name="command" value="Cassette Details"/>
&nbsp;&nbsp;<input type="submit" name="command" value="Update"/>
<% if (row < 0) { %>
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" value="Edit Crystal" disabled="true" />
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" value="Analyze Crystal" disabled="true" />
<% } else { %>
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" name="command" value="Edit Crystal"/>
<% if (isAnalyzingCrystal) { %>
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" name="command" value="Analyze Crystal" disabled="true"/>
<% } else { %>
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" name="command" value="Analyze Crystal" />
<% }} %>
<input type="text" readonly style="border-style:groove;background-color:#6699CC;color:white;font:bold;text-align:center" size="3" value="<%= viewer.getSelectedCrystalPort() %>" />
<% if (!client.connectedToBeamline()) { %>
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" name="command" value="View Strategy" disabled="true"/> <span style="color:red">Please select a beamline</span>
<% } else if (viewer.isSelectedCrystalMounted() || ServerConfig.getImportRunMode().equals("all")) { %>
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" name="command" value="View Strategy" onClick="view_strategy()"/>
<% } else { %>
<xsl:text>&nbsp;&nbsp;</xsl:text><input type="submit" name="command" value="View Strategy" disabled="true"/> <span style="color:red"><%= viewer.getSelectedCrystalPort() %> is not mounted</span>
<% } %>
</form>
</td>
</tr>
</TABLE>

<% } %>

</body>
</html>
