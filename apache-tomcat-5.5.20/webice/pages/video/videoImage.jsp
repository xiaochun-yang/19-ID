<html>
<%			
	String beamline = request.getParameter("beamline");
	String camera = request.getParameter("camera");
	String resolution = request.getParameter("resolution");
	if (resolution == null)
		resolution = "medium";
	String size = request.getParameter("resolution");
	if (size == null)
		size = "medium";
	int updateRate = 5;
	String rr = request.getParameter("rate");
	try {
		if (rr != null)
			updateRate = Integer.parseInt(rr);
	} catch (NumberFormatException e) {
	}
%>	
<head>
<META HTTP-EQUIV="refresh" content="<%= updateRate %>;url=showVideoImage.do?beamline=<%= beamline %>&camera=<%= camera %>&resolution=<%= resolution %>&size=<%= size %>&rate=<%= updateRate %>">
</head>
<body>
<img width="352" height="240" src="servlet/video/getVideoImage?beamline=<%= beamline %>&camera=<%= camera %>&resolution=<%= resolution %>&size=<%= size %>" />
</body>
</html>
