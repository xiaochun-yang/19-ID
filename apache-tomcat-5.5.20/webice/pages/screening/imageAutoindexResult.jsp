<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>

<html>
<head>
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" content="no-cache"/>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">

<% 	ScreeningViewer screening = client.getScreeningViewer();
	ImageViewer viewer = client.getImageViewer();

	Hashtable hash = screening.getSelectedCrystal();
	String score = (String)hash.get("Score");
	if (score == null)
		score = "";
	String mosaicity = (String)hash.get("Mosaicity");
	if (mosaicity == null)
		mosaicity = "";
	// Score
	try {
		if (score.length() > 0) {
			Double dd[] = new Double[1];
			dd[0] = new Double(score);
			score = new Formatter().format("%.3f", dd).toString();
		}
	} catch (NumberFormatException e) {
	}
	if (score.length() == 0)
		score = "N/A";
	// Mosaicity
	try {
		if (mosaicity.length() > 0) {
			Double dd[] = new Double[1];
			dd[0] = new Double(mosaicity);
			mosaicity = new Formatter().format("%.2f", dd).toString();
		}
	} catch (NumberFormatException e) {
	}
	if (mosaicity.length() == 0)
		mosaicity = "N/A";
%>

<%@ include file="imageInfoNav.jspf" %>

<div>
<style><!--PRE {line-height: 12pt; color:blue;font-size:10pt}--></style>
Summary
<PRE>
Score			<%= score %>
Resolution		<%= (String)hash.get("Resolution") %> &Aring;
BravaisLattice		<%= (String)hash.get("BravaisLattice") %>
Rmsd			<%= (String)hash.get("Rmsr") %> mm
UnitCell		<%= (String)hash.get("UnitCell") %>
Mosaicity		<%= mosaicity %>&deg;
</PRE>
<hr/>
Details
<PRE>
<%= screening.getAutoindexResult() %>
</PRE>
</div>

</body>
</html>
