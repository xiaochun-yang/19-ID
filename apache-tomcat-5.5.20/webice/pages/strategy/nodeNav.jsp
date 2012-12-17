<html>

<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer top = client.getStrategyViewer();
	NavNode node = top.getSelectedNode();
	Object tabs[] = node.getTabs();
	String selectedTab = node.getSelectedTab();
	String desc = node.getDesc();
%>
<head>
</head>


<body bgcolor="#FFFFFF">
<H3><b><%= desc %>: <%= node.getName() %></b></H3>

<% if (tabs == null) {
	 out.write("&nbsp;[Error: this node has no tab]\n");
   } else {
	 for (int i = 0; i < tabs.length; ++i) {
		String name = (String)tabs[i];
		if (i != 0)
			out.write("&nbsp;");
		if (selectedTab.equals(name)) {
			out.write("<a href='Strategy_SelectTab.do?tab="
				+ name + "' target='_parent'><b>["
				+ name + "]</b></a>\n");
		} else {
			out.write("<a href='Strategy_SelectTab.do?tab="
				+ name + "' target='_parent'>["
				+ name + "]</a>\n");
 		}
   	  }
   }
%>


<body>

</html>