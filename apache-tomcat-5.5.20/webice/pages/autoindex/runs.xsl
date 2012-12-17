<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                   version="1.0"
                   xmlns:xalan="http://xml.apache.org/xalan"
                   exclude-result-prefixes="xalan">

<xsl:output method="html" indent="yes"/>
<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:param name="param4"/>
<xsl:param name="param5"/>
<xsl:param name="param6"/>
<xsl:param name="param7"/>
<xsl:param name="param8"/>
<xsl:variable name="userName" select="$param1"/>
<xsl:variable name="sessionId" select="$param2"/>
<xsl:variable name="workDir" select="$param3"/>
<xsl:variable name="baseUrl" select="$param4"/>
<xsl:variable name="impUrl" select="$param5"/>
<xsl:variable name="beamline" select="$param6"/>
<xsl:variable name="selectedRunName" select="$param7"/>
<xsl:variable name="beamlineRunDir" select="$param8"/>

<xsl:template match="runs">
<html>

<head>
</head>
<body bgcolor="#FFFFFF">

<table>
<tr>
<td>
<span align="left" ><form action="Autoindex_LoadRuns.do" method="get">
<input class="actionbutton1" type="submit" value="Update" />
</form>
</span>
<form action="Autoindex_ShowNewRunForm.do" method="get">
<input type="submit" value="New Run" />
<input type="hidden" name="showSample" value="false" />
</form>
</td>
</tr>
</table>

<b>User Runs</b><br/>
<xsl:apply-templates select="userRuns"/>
<br/>
<xsl:if test="$beamline != ''">
<b>Beamline Runs</b><br/>
<xsl:apply-templates select="beamlineRuns"/>
</xsl:if>

</body>
</html>

</xsl:template>


<xsl:template match="userRuns">
<table cellborder="1" border="1" width="100%" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00">
<th>Run Name</th>
<th>Images</th>
<th>Score</th>
<th>#Spots</th>
<th>#Bragg Spots</th>
<th>#Ice Rings</th>
<th>Predicted Resolution</th>
<th>Bravais Choice</th>
<th>Commands</th></tr>
<xsl:apply-templates select="run">
<xsl:with-param name="runType" select="'user'"/> 
<xsl:with-param name="runRootDir" select="$workDir"/> 
</xsl:apply-templates>
</table>
</xsl:template>

<xsl:template match="beamlineRuns">
<table cellborder="1" border="1" width="100%" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00">
<th>Run Name</th>
<th>Images</th>
<th>Score</th>
<th>#Spots</th>
<th>#Bragg Spots</th>
<th>#Ice Rings</th>
<th>Predicted Resolution</th>
<th>Bravais Choice</th>
<th>Commands</th></tr>
<xsl:apply-templates select="run">
<xsl:with-param name="runType" select="'beamline'"/> 
<xsl:with-param name="runRootDir" select="$beamlineRunDir"/> 
</xsl:apply-templates>
</table>
</xsl:template>

<xsl:template match="run">
<xsl:param name="runType"/>
<xsl:param name="runRootDir"/>
<xsl:variable name="runSummaryFile">
  <xsl:value-of select="$impUrl"/>/readFile?impUser=<xsl:value-of select="$userName"/>&amp;impSessionID=<xsl:value-of select="$sessionId"/>&amp;impFilePath=<xsl:value-of select="$runRootDir"/>/<xsl:value-of select="@name"/>/run_summary.xml
</xsl:variable>
<xsl:variable name="bgc">
<xsl:choose>
<xsl:when test="$selectedRunName=@name">#FFEE55</xsl:when>
<xsl:otherwise>#FFFF99</xsl:otherwise>
</xsl:choose>
</xsl:variable>
<xsl:element name="tr">
	<xsl:attribute name="bgcolor"><xsl:value-of select="$bgc"/></xsl:attribute>
<td align="center"><a href="Autoindex_SelectRun.do?run={@name}" target="_self"><xsl:value-of select="@name"/></a></td>
<xsl:choose>
  <xsl:when test="document($runSummaryFile)">
    <xsl:apply-templates select="document($runSummaryFile)/runSummary" />
  </xsl:when>
  <xsl:otherwise>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
  </xsl:otherwise>
</xsl:choose>
<xsl:choose>
<xsl:when test="$runType = 'user'">
<td align="center"><a target="_self" href="Autoindex_DeleteRun.do?run={@name}" >[Delete]</a></td>
</xsl:when>
<xsl:otherwise>
<td align="center">[Delete]</td>
</xsl:otherwise>
</xsl:choose>
</xsl:element>
</xsl:template>

<xsl:template match="runSummary">
<xsl:choose>
<xsl:when test="error">
	<td align="center">&#160;<xsl:value-of select="image[@number=1]/@file"/>, <xsl:value-of select="image[@number=2]/@file"/></td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
	<td>&#160;</td>
</xsl:when>
<xsl:otherwise>
<td align="center">&#160;<xsl:value-of select="image[@number=1]/@file"/>, <xsl:value-of select="image[@number=2]/@file"/></td>
<td align="center">&#160;<xsl:value-of select="bestSolution/@score"/></td>
<xsl:for-each select="image[@number=1]">
<td align="center">&#160;<xsl:value-of select="@spots"/></td>
<td align="center">&#160;<xsl:value-of select="@braggSpots"/></td>
<td align="center">&#160;<xsl:value-of select="@iceRings"/></td>
</xsl:for-each>
<td align="center">&#160;<xsl:value-of select="bestSolution/@resolution"/></td>
<td align="center">&#160;<xsl:value-of select="bestSolution/@spaceGroup"/></td>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

</xsl:stylesheet>
