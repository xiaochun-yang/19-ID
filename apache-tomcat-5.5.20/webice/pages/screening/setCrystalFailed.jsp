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

function row_onclick(obj) {
    var submit_url = "selectCrystal.do?row=" + obj.value;

    location.replace(submit_url);
}

function display_onchange() {
    eval("i = document.silForm.displayType.selectedIndex");
    eval("x= document.silForm.displayType.options[i].value");
    var submit_url = "setSilOverviewOption.do?template=" + x;

    location.replace(submit_url);
}

function option_onchange() {
    eval("i = document.silForm.showImages.selectedIndex");
    eval("x= document.silForm.showImages.options[i].value");
    var submit_url = "setSilOverviewOption.do?option=" + x;

    location.replace(submit_url);
}

function show_diffimage(url) {
    window.open(url, "diffimage",
    		"height=400,width=400,status=no,toolbar=no,menubar=no,location=no")
}

function show_xtal(url) {
    window.open(url, "xtal",
    		"height=280,width=400,status=no,toolbar=no,menubar=no,location=no")
}

</script>

<body>

<!-- catch an exception here -->
<html:errors />

<%

		ScreeningViewer viewer = client.getScreeningViewer();

		Document doc = viewer.getSilDocument();

		if (doc == null) { %>

<b>Please select a cassette.</b>
<form action="loadSilList.do">
<input type="submit" value="Cassette List"/>
</form>
<%
		} else {

			String templateDir = session.getServletContext().getRealPath("/") + "/templates";
			String xsltFile = templateDir + "/silEdit.xsl";
			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer(new StreamSource(xsltFile));
			transformer.setParameter("param1", client.getUser());

			String systemId = ServerConfig.getSilDtdUrl();
			DOMSource source = new DOMSource(viewer.getSilDocument().getDocumentElement(), systemId);
			StreamResult result = new StreamResult(out);

			transformer.setParameter("param1", client.getSessionId());
			transformer.setParameter("param2", viewer.getSilOwner());
			transformer.setParameter("param3", String.valueOf(viewer.getSelectedRow()));
			transformer.setParameter("param4", viewer.getSilOverviewOption());
			transformer.setParameter("param5", templateDir + "/display_all.xml");
			transformer.setParameter("param6", client.getUser());
			transformer.transform( source, result);

		}


%>
</body>
</html>