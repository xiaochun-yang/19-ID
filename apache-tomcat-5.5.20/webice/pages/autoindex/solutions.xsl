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
<xsl:variable name="runName" select="$param1"/>
<xsl:variable name="userName" select="$param2"/>
<xsl:variable name="sessionId" select="$param3"/>
<xsl:variable name="workDir" select="$param4"/>
<xsl:variable name="baseUrl" select="$param5"/>
<xsl:variable name="impUrl" select="$param6"/>

<xsl:variable name="solNum">
  <xsl:choose>
    <xsl:when test="$param7=''">
      <xsl:value-of select="labelit/integration/solution[@integrated='true']/@number"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$param7"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="solStr">
  <xsl:choose>
    <xsl:when test="$solNum &lt; 10">
      <xsl:text>0</xsl:text><xsl:value-of select="$solNum"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$solNum"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>
<xsl:variable name="selectedFile1">
  <xsl:value-of select="$baseUrl"/><xsl:text>/loader/readFile?userName=</xsl:text><xsl:value-of select="$userName"/><xsl:text>&amp;sessionId=</xsl:text><xsl:value-of select="$sessionId"/><xsl:text>&amp;file=</xsl:text><xsl:value-of select="$workDir"/><xsl:text>/solution</xsl:text><xsl:value-of select="$solStr"/><xsl:text>/index</xsl:text><xsl:value-of select="$solStr"/><xsl:text>.xml</xsl:text>
</xsl:variable>
<xsl:variable name="selectedFile">
  <xsl:value-of select="$impUrl"/><xsl:text>/readFile?impUser=</xsl:text><xsl:value-of select="$userName"/><xsl:text>&amp;impSessionID=</xsl:text><xsl:value-of select="$sessionId"/><xsl:text>&amp;impFilePath=</xsl:text><xsl:value-of select="$workDir"/><xsl:text>/solution</xsl:text><xsl:value-of select="$solStr"/><xsl:text>/index</xsl:text><xsl:value-of select="$solStr"/><xsl:text>.xml</xsl:text>
</xsl:variable>

<xsl:template match="labelit">
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">
<xsl:choose>
<xsl:when test="count(/labelit/error) >= 1">
<p style="color:red">Integration not completed.</p>
</xsl:when>
<xsl:otherwise>
<xsl:apply-templates select="integration"/>
</xsl:otherwise>
</xsl:choose>
</body>
</html>
</xsl:template>

<xsl:template match="integration">
<xsl:choose>
<xsl:when test="count(error) >= 1">
<p style="color:red"><xsl:value-of select="error"/></p>
</xsl:when>
<xsl:otherwise>

<table class="autoindex">

<tr><th style="text-align:left" colspan="2">Integration Results</th></tr>
<tr><td width="20%"><b>Predicted Resolution</b></td><td><xsl:value-of select="solution[@status='good']/@resolution"/></td></tr>
<tr><td><b>Mosaicity</b></td><td><xsl:value-of select="format-number(solution[@status='good']/@mosaicity, '0.000')"/> deg 
(predicts <xsl:value-of select="../mosaicity/@percent"/> of spots in images)</td></tr>

</table>

<br/>

<table class="autoindex">
<tr><th colspan="11" style="text-align:left">Integrated Solutions</th></tr>
<tr>
<th colspan="2">Solution</th>
<th>Point Group</th>
<th colspan="2">Crystal System</th>
<th>Beam X</th>
<th>Beam Y</th>
<th>Distance</th>
<th>Resolution</th>
<th>Mosaicity</th>
<th>RMS</th>
</tr>
<xsl:for-each select="solution">
<xsl:variable name="solNum" select="@number"/>
<tr>
<xsl:choose>
  <xsl:when test="@status='good'">
	<td align="center"><img src="images/strategy/happy1.gif" /></td>
  </xsl:when>
  <xsl:when test="@status='bad'">
	<td align="center"><img src="images/strategy/sad.gif" /></td>
  </xsl:when>
  <xsl:otherwise>
	<td align="center">&#160;</td>
  </xsl:otherwise>
</xsl:choose>
<xsl:choose>
  <xsl:when test="@integrated='true'">
    <td align="center"><a href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={spaceGroup/@name}" target="_self"><xsl:value-of select="$solNum"/></a></td>
    <td align="center">
      <xsl:for-each select="spaceGroup">
        <xsl:value-of select="@name"/><xsl:text>&#160;</xsl:text>
      </xsl:for-each>
    </td>
  </xsl:when>
  <xsl:otherwise>
    <td align="center"><xsl:value-of select="@number"/></td>
    <td align="center">
      <xsl:for-each select="spaceGroup">
        <xsl:value-of select="@name"/><xsl:text>&#160;</xsl:text>
      </xsl:for-each>
    </td>
  </xsl:otherwise>
</xsl:choose>
<td align="center"><xsl:value-of select="../../indexing/solution[@number=$solNum]/@crystalSystem"/></td>
<td align="center"><xsl:value-of select="../../indexing/solution[@number=$solNum]/@lattice"/></td>
<td align="center"><xsl:value-of select="@beamX"/></td>
<td align="center"><xsl:value-of select="@beamY"/></td>
<td align="center"><xsl:value-of select="@distance"/></td>
<td align="center"><xsl:value-of select="@resolution"/></td>
<td align="center"><xsl:value-of select="@mosaicity"/></td>
<td align="center"><xsl:value-of select="@rms"/></td>
</tr>
</xsl:for-each>
</table>

<br/>

<xsl:for-each select="solution[@number=$solNum]">
  <b>Solution&#160;<xsl:value-of select="@number"/></b>
  <xsl:apply-templates select="document($selectedFile)/solution/image">
  </xsl:apply-templates>
</xsl:for-each>

</xsl:otherwise>
</xsl:choose>

</xsl:template>

<xsl:template match="image">
  <table class="autoindex">
  <tr><th>Average spot profile for image <xsl:value-of select="@file"/>
  </th></tr>
  <tr><td>
  <pre>
    <xsl:value-of select="spotProfile"/>
  </pre>
  </td></tr>
  <tr><th>Statistics</th></tr>
  <tr><td>
  <pre>
    <xsl:value-of select="statistics"/>
  </pre>
  </td></tr>
  </table>
  <br/>
</xsl:template>

</xsl:stylesheet>
