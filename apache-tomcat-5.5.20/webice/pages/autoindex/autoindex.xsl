<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                   version="1.0"
                   xmlns:xalan="http://xml.apache.org/xalan"
                   exclude-result-prefixes="xalan">

<xsl:output method="html" indent="yes"/>
<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:param name="param4"/>
<xsl:variable name="runName" select="$param1"/>
<xsl:variable name="userName" select="$param2"/>
<xsl:variable name="sessionId" select="$param3"/>
<xsl:variable name="labelitOutFile" select="$param4"/>

<xsl:template match="labelit">

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">

<xsl:choose>
<xsl:when test="count(error) >= 1">
<p class="error"><xsl:value-of select="error"/><div style="color:black">See 
<a target="_blank" href="servlet/loader/readFile?impUser={$userName}&amp;impSessionID={$sessionId}&amp;impFilePath={$labelitOutFile}">labelit.out</a> for more details.</div></p>
</xsl:when>
<xsl:otherwise>

<!--<table cellborder="1" border="1" cellspacing="1" width="100%"
bgcolor="#FFFF99">-->
<table class="autoindex">

<tr><th style="text-align:left" colspan="2">Indexing Results</th></tr>
<tr><td width="20%"><b>Beam x</b></td><td><xsl:value-of select="beamX/@value"/></td></tr>
<tr><td><b>Beam y</b></td><td><xsl:value-of select="beamY/@value"/></td></tr>
<tr><td><b>Distance</b></td><td><xsl:value-of select="distance/@value"/></td></tr>
<tr><td><b>Mosaicity</b></td><td><xsl:value-of select="mosaicity/@value"/><xsl:text> (predicts </xsl:text><xsl:value-of select="mosaicity/@percent"/><xsl:text> of spots in images)</xsl:text></td></tr>
<tr><td><b>Predicted resolution</b></td><td><xsl:value-of select="resolution/@value"/> &#197;</td></tr>

</table>
<br/>
<!--<table cellborder="1" border="1" cellpadding="5" cellspacing="1"
width="100%" bgcolor="#FFFF99">-->
<table class="autoindex">
<tr><th colspan="14" style="text-align:left">Indexing Solutions</th></tr>
<tr>
<th colspan="2">Solution</th>
<th>Metric Fit</th>
<th>rmsd</th>
<th>#spots</th>
<th colspan="2">Crystal System</th>
<th colspan="6">Unit Cell</th>
<th>Volume</th>
</tr>
<xsl:apply-templates select="indexing"/>

</table>

</xsl:otherwise>
</xsl:choose>

</body>
</html>
</xsl:template>

<xsl:template match="indexing">
<xsl:apply-templates select="solution">
<xsl:sort select="@number" order="descending" data-type="number"/>
</xsl:apply-templates>
</xsl:template>

<xsl:template match="solution">
<tr>
<xsl:if test="@status = 'good'">
	<td align="center"><img src="images/autoindex/happy1.gif" /></td>
</xsl:if>
<xsl:if test="@status = 'bad'">
	<td align="center"><img src="images/autoindex/sad.gif" /></td>
</xsl:if>
<td align="center"><xsl:value-of select="@number"/></td>
<td align="right"><xsl:value-of select="@matrixFit"/></td>
<td align="right"><xsl:value-of select="@rmsd"/></td>
<td align="right"><xsl:value-of select="@spots"/></td>
<td align="center"><xsl:value-of select="@crystalSystem"/></td>
<td align="center"><xsl:value-of select="@lattice"/></td>
<td align="right"><xsl:value-of select="@cellA"/></td>
<td align="right"><xsl:value-of select="@cellB"/></td>
<td align="right"><xsl:value-of select="@cellC"/></td>
<td align="right"><xsl:value-of select="@cellAlpha"/></td>
<td align="right"><xsl:value-of select="@cellBeta"/></td>
<td align="right"><xsl:value-of select="@cellGamma"/></td>
<td align="right"><xsl:value-of select="@volume"/></td>
</tr>
</xsl:template>

</xsl:stylesheet>
