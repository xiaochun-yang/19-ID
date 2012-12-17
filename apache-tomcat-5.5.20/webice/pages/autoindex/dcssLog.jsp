
<html>

<%@ include file="/pages/common.jspf" %>
<%@ page import="java.io.*" %>
<%@ page import="webice.beans.dcs.*" %>

<%

	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	boolean connected = client.isConnectedToBeamline();
	DcsConnector dcs = client.getDcsConnector();
	String cur_log = "";
	String logType = run.getLogType();
%>

<head>

<script id="event" language="javascript">

function downloadLog(tt)
{
	window.open("servlet/loader/readFile?impUser=<%= client.getUser() %>&impSessionID=<%= client.getSessionId() %>&impFilePath=" + tt, "_blank");	
}
</script>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

</head>

<body style="background-color:transparent">

<div class="setupInsideIframe">

<%	if (run == null) { %>

<p class="warning">Please select a run first.</p>

<% } else if (!connected) { %>
<p class="warning">Please select a beamline from the toobar.</p>
<% } else {

	cur_log = dcs.getCurrentUserLog();
	if ((cur_log == null) || (cur_log.length() == 0)) { %>
<p class="error">current_user_log string is not set. No log file to load.</p>
<%	} else { %>
<a class="actionbutton1" href="servlet/loader/readFile?impUser=<%= client.getUser() %>&impSessionID=<%= client.getSessionId() %>&impFilePath=<%= cur_log %>" target="_blank">Download Log</a>
&nbsp;<a class="actionbutton1" href="Autoindex_NewBeamlineLog.do" target="_parent">New Log</a></span>

</div>
<pre>
<%	try {
		FileReader reader = new FileReader(cur_log);
		char buf[] = new char[1000];
		int num = -1;
		while ((num=reader.read(buf, 0, 1000)) > -1) {
			if (num > 0) {
				out.write(buf, 0, num); // write to jsp output
			}
		}
	} catch (FileNotFoundException e) { %>
<span style="color:red">Log file <%= cur_log %> not found.</span>
<% 	} catch (Exception e) { %>
<span style="color:red">Failed to read log file <%= cur_log %>: <%= e.getMessage() %>.</span>
<% 	} // try %>
</pre>
<%	} // if cur_log == null
   } // if run == null %>


</body>

</html>
