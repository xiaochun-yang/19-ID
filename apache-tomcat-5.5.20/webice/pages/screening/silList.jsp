<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="webice.beans.dcs.*" %>
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

<script id="event" language="javascript">

function select_sil(val) {
	var submit_url = "loadSil.do?silId=" + val;
	location.replace(submit_url);
}

</script>

</head>
<body class="mainBody">
<%
	ScreeningViewer viewer = client.getScreeningViewer();
	String error = (String)request.getSession().getAttribute("error.screening");
	request.getSession().removeAttribute("error.screening");
	String filterBy = viewer.getFilterBy();
	if (filterBy == null)
		filterBy = "UploadFileName";
	String wildcard = viewer.getWildcard();
	if (wildcard == null)
		wildcard = "";
	if (error != null) { %>
<span class="error"><%= error %></span><br/>
<% 	} %>
<table>
<tr><td align="right">
<form class="small" action="findSil.do" target="_self">
Search By: 
<select name="filterBy">
<option value="CassetteID" <%= filterBy.equals("CassetteID") ? "selected" : ""%>/>SIL ID
<option value="UploadFileName" <%= filterBy.equals("UploadFileName") ? "selected" : ""%>/>Uploaded Spreadsheet
</select>
<input type="text" name="key" value="<%= wildcard %>"/>
<input type="hidden" name="owner" value="<%= client.getUser() %>"/>
<input class="actionbutton1" type="submit" value="Search"/>
</form>
</td></tr>
<tr><td>
<%

	try
	{
		String selectedSilId = viewer.getSilId();
		if (selectedSilId == null)
			selectedSilId = "";

		String silId = "";
		String silOwner = "";
		int row = 0;
		String str = "";
		DcsConnector dcs = client.getDcsConnector();
		if (client.isConnectedToBeamline() && (dcs != null)) {
			String beamline = client.getBeamline();
			silId = client.getScreeningSilId();
			SequenceDeviceState seq = dcs.getSequenceDeviceState();
			ScreeningStatus stat = client.getScreeningStatus();
			if ((stat != null) && (seq != null)) {
				int index = seq.cassetteIndex;
				if (index >= 0) {
					CassetteInfo info = seq.cassette[index];
					str = info.silId + " " + info.xlsFile + " at " + beamline + " " + stat.cassettePosition;
					silOwner = info.owner;
				}
				if (row >= 0)
					row = stat.row;
			}
		}
		
		if (silOwner == null)
			silOwner = "";
			
		String xsltFile = session.getServletContext().getRealPath("/")
							+ "/templates/silList.xsl";
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer(new StreamSource(xsltFile));
    		transformer.setParameter("param1", client.getUser());
    		transformer.setParameter("param2", client.getSessionId());
    		transformer.setParameter("param3", ServerConfig.getSilDownloadSilUrl());
    		String silUrl = ServerConfig.getSilUrl() + "?userName=" + client.getUser()
    					+ "&accessID=" + client.getSessionId();
    		transformer.setParameter("param4", silUrl);
    		transformer.setParameter("param5", silId);
    		transformer.setParameter("param6", str);
    		transformer.setParameter("param7", String.valueOf(row));
    		transformer.setParameter("param8", silOwner);
    		transformer.setParameter("param9", selectedSilId);
    		transformer.setParameter("param10", viewer.getSilListSortColumn());
		String d = viewer.isSilListSortAscending() ? "ascending" : "descending";
    		transformer.setParameter("param11", d);
    		transformer.setParameter("param12", viewer.getSilListSortType());
		

		StringReader reader = new StringReader(viewer.getSilList());
		StreamSource source = new StreamSource(reader);
		StreamResult result = new StreamResult(out);
		transformer.transform( source, result);

	} catch (Exception e) {
		WebiceLogger.error("ERROR in silList.jsp: " + e.getMessage(), e);
		throw e;
	}

%>
</td></tr>
</table>
</body>
</html>
