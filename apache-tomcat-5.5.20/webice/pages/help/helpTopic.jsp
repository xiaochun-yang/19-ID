<%@ include file="/pages/common.jspf" %>


<% 	String topic = client.getHelpTopic();
	if ((topic == null) || (topic.length() == 0)) { %>
		<jsp:include page="/pages/help/introduction.html" />
<%	} else {
		String bookmark = client.getHelpBookmark();
		String fname = "/pages/help/" + topic + ".html";
		if ((bookmark != null) && (bookmark.length() > 0)) {
			fname += "#" + bookmark;
		} %>

		<jsp:include page="<%= fname %>" />
<% 	} %>