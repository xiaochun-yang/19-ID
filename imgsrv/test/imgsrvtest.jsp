<html> 

<!-- Tag libraries -->
<%@ taglib uri="http://jakarta.apache.org/taglibs/core" prefix="c" %>


<head> 

<title>Image Server Test</title> 
<meta http-equiv="refresh" content="5" />
<META Http-Equiv="Cache-Control" Content="no-cache">
</head> 

<body> 

<%! private int index = 0; %>
<%! private int count = 0; %>
<%! private String host = "blctlxx"; %>
<%! private String port = "14007"; %>
<%! private String fileName = ""; %>
<%! private String url = ""; %>
<%! private String dir = "/data/penjitk/images/low_2"; %>
<%! private String root = "4c10p3_1_0"; %>
<%
	++count;
	
	++index;
	
	if (index > 20) {
		index = 1;
	}
	

	fileName = dir + "/" + root;
	if (index < 10)
		fileName += "0";
		
	fileName += String.valueOf(index) + ".img";
	
	url =   "http://" + host + ":" + port
			+ "/getImage?fileName=" + fileName 
			+ "&userName=" + request.getParameter("user") 
			+ "&sessionId=" + request.getParameter("sessionId")
			+ "&sizeX=400&sizeY=400&zoom=1.0&gray=400&percentX=0.5&percentY=0.5";
			
%>

File: <% out.println(fileName); %>
<br>
Count: <% out.println(count); %>
<br>
<br>
<img src="<% out.println(url); %>" boder="1"/>
  
</body> 

</html> 
