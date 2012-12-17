<%
// pageheader.jsp
// define the header line for web pages of the Crystal Cassette Tracking System
// load different header depending on the installation site.

   String pageHeader = getConfigValue("pageheader");
   
   if ((pageHeader == null) || (pageHeader.length() == 0))
   	pageHeader = "ssrlheader.jsp";
%>

<jsp:include page="<%= pageHeader %>" />

