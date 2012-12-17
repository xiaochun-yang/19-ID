<%@ page import="sil.beans.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@include file="../config.jsp" %>
<html>
<script id="event" language="javascript">

function row_onclick(obj) {
    var submit_url = "showSil.jsp";
    submit_url += "?accessID="+ document.silForm.accessID.value;
    submit_url += "&userName="+ document.silForm.userName.value;
    submit_url += "&silId="+ document.silForm.silId.value;
    submit_url+= "&row=" + obj.value;
    submit_url+= "&displayType=" + document.silForm.displayType.value;
    submit_url+= "&showImages=" + document.silForm.showImages.value;

    location.replace(submit_url);
}

function display_onchange() {
    eval("i = document.silForm.displayType.selectedIndex");
    eval("x= document.silForm.displayType.options[i].value");
    eval("y= document.silForm.row.value");
    var submit_url = "showSil.jsp";
    submit_url += "?accessID="+ document.silForm.accessID.value;
    submit_url += "&userName="+ document.silForm.userName.value;
    submit_url += "&silId="+ document.silForm.silId.value;
    submit_url+= "&row=" + document.silForm.selectedRow.value;
    submit_url+= "&displayType=" + x;
    submit_url+= "&showImages=" + document.silForm.showImages.value;

    location.replace(submit_url);
}

function option_onchange() {
    eval("i = document.silForm.showImages.selectedIndex");
    eval("x= document.silForm.showImages.options[i].value");
    var submit_url = "showSil.jsp";
    submit_url += "?accessID="+ document.silForm.accessID.value;
    submit_url += "&userName="+ document.silForm.userName.value;
    submit_url += "&silId="+ document.silForm.silId.value;
    submit_url+= "&row=" + document.silForm.selectedRow.value;
    submit_url+= "&displayType=" + document.silForm.displayType.value;
    submit_url+= "&showImages=" + x;

    location.replace(submit_url);
}

function show_diffimage(url) {
    window.open(url, "diffimage",
    		"height=450,width=420,status=no,toolbar=no,menubar=no,location=no")
}

function show_xtal(url) {
    window.open(url, "xtal",
    		"height=280,width=400,status=no,toolbar=no,menubar=no,location=no")
}

</script>

<body>
<%
	try
	{

	// disable browser cache
	response.setHeader("Expires","-1");

	CassetteDB s_db = ctsdb;
	CassetteIO s_io = ctsio;

	SilConfig silConfig = SilConfig.getInstance();
	
	String userName= ServletUtil.getUserName(request);
	String accessID = ServletUtil.getSessionId(request);
		
	if (!checkAccessID(request, response)) {
		return;
	}
	

	String silId = request.getParameter("silId");
	String showImages = request.getParameter("showImages");
	if ((showImages == null) || (showImages.length() == 0))
		showImages = "hide";

	int id = Integer.parseInt(silId);
	String rowStr = request.getParameter("row");
	if ((rowStr == null) || (rowStr.length() == 0)) {
		rowStr = "null";
	}

	String displayType = request.getParameter("displayType");
	if ((displayType == null) || (displayType.length() == 0))
		displayType = "display_src";

	String silFile = s_db.getCassetteFileName(id);
	if ((silFile == null) || (silFile.length() == 0))
		throw new ServletException("Invalid silFile for silId " + silId);
	String path = silConfig.getCassetteDir() + userName +"/" + silFile + "_sil.xml";
	String xsltSil2Html = silConfig.getTemplateDir() + "xsltSil2Html4.xsl";

	String displayTemplate = silConfig.getTemplateDir() + "/" + displayType + ".xml";

	TransformerFactory tFactory = TransformerFactory.newInstance();
	Transformer transformer = tFactory.newTransformer( new StreamSource( xsltSil2Html));
	transformer.setParameter("param1", accessID);
	transformer.setParameter("param2", userName);
	transformer.setParameter("param3", rowStr);
	transformer.setParameter("param4", showImages);
	transformer.setParameter("param5", displayTemplate);
	transformer.setParameter("param6", gate.getUserID());

	String systemId = SilConfig.getInstance().getSilDtdUrl();

	StreamSource source = new StreamSource( new FileReader(path), systemId);
	StreamResult result = new StreamResult(out);
	transformer.transform( source, result);

	} catch (Exception e) {
		errMsg("ERROR in ShowSil.jsp: " + e.getMessage());
		errMsg(e);
		throw e;
	}

%>
</body>
<html>
