
<html>

<%@ include file="/pages/common.jspf" %>
<%@ page import="java.io.*" %>
<%@ page import="webice.beans.dcs.*" %>

<%
	WebIceProperties prop = client.getProperties(); 
	boolean connected = client.isConnectedToBeamline();
	DcsConnector dcs = client.getDcsConnector();
	String cur_log = "";
	String tab = client.getCollectViewer().getViewType();
	String err = (String)request.getAttribute("error");
	boolean autoUpdateLog = prop.getPropertyBoolean("beamline.autoUpdateLog", false);
	int interval = prop.getPropertyInt("beamline.autoUpdateLogRate", 5);
%>

<head>
<% if (autoUpdateLog) { %>
<meta http-equiv="refresh" content="<%= interval %>;URL=showBeamline.do" />
<% } %>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<style>
.url_link {text-decoration: none;color:black;}
.link_button {
background-color:#CCCCCC;
border-style:outset;
border-color:black;
border-width:3;
padding-left:0.3em;
padding-right:0.3em;
text-size:80%;
}
</style>
<script id="event" language="javascript">

function downloadLog(tt)
{
	window.open("servlet/loader/readFile?impUser=<%= client.getUser() %>&impSessionID=<%= client.getSessionId() %>&impFilePath=" + tt, "_blank");	
}

</script>
</head>
<body class="mainBody">

<% if (err != null) { %>
<span style="color:red"><%= err %></span>
<% } else { %>	
<% if (!connected) { %>
<span class="warning">Please select a beamline from the toolbar.</span>
<% } else {

	cur_log = dcs.getCurrentUserLog();
	if ((cur_log == null) || (cur_log.length() == 0)) { %>
current_user_log string is not set. No log file to load.
<%	} else { %>
<span class="actionbutton1"><a class="url_link" href="servlet/loader/readFile?impUser=<%= client.getUser() %>&impSessionID=<%= client.getSessionId() %>&impFilePath=<%= cur_log %>" target="_blank">Download Log</a></span>
&nbsp;<span class="actionbutton1"><a class="url_link" href="Collect_NewBeamlineLog.do">New Log</a></span>
&nbsp;<span class="actionbutton1"><a class="url_link" href="showBeamline.do">Update Log</a></span>


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
   } // connected

   } // if err
%>

</body>

</html>
