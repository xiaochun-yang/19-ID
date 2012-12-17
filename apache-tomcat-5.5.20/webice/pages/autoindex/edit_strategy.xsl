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
<xsl:param name="param9"/>
<xsl:param name="param10"/>
<xsl:param name="param11"/>
<xsl:param name="param12"/>
<xsl:param name="param13"/>
<xsl:param name="param14"/>
<xsl:param name="param15"/>
<xsl:param name="param16"/>
<xsl:param name="param17"/>
<xsl:param name="param18"/>
<xsl:variable name="selectedSp" select="$param1"/>
<xsl:variable name="expType" select="$param2"/>
<xsl:variable name="action" select="$param3"/>
<xsl:variable name="err" select="$param4"/>
<xsl:variable name="startAngle" select="$param5"/>
<xsl:variable name="endAngle" select="$param6"/>
<xsl:variable name="delta" select="$param7"/>
<xsl:variable name="exposureTime" select="$param8"/>
<xsl:variable name="distance" select="$param9"/>
<xsl:variable name="beamstop" select="$param10"/>
<xsl:variable name="energy" select="$param11"/>
<xsl:variable name="solution" select="$param12"/>
<xsl:variable name="phiStrategyType" select="$param13"/>
<xsl:variable name="doseMode" select="$param14"/>
<xsl:variable name="helpUrl" select="$param15"/>
<xsl:variable name="runIndex" select="$param16"/>
<xsl:variable name="runLabel" select="$param17"/>
<xsl:variable name="queueEnabled" select="$param18"/>

<xsl:template match="*">

<html>
<head>
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" content="no-cache"/>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>
<xsl:apply-templates select="spaceGroup[@name=$selectedSp]"/>

</body>
</html>
</xsl:template>

<xsl:template match="spaceGroup">
<xsl:apply-templates select="dcStrategy[expType/@value=$phiStrategyType]"/>
</xsl:template>

<xsl:template match="dcStrategy">
<form action="Autoindex_ExportRunDefinition.do" target="_self">
<p><span class="warning">Please verify data collection strategy before proceeding.</span>
<xsl:element name="input">
  <xsl:attribute name="type">submit</xsl:attribute>
  <xsl:attribute name="name">action</xsl:attribute>
  <xsl:attribute name="class">actionbutton1</xsl:attribute>
    <xsl:attribute name="value"><xsl:value-of select="$action"/></xsl:attribute>
</xsl:element>
<xsl:if test="$action = 'Send to Queue'">
<xsl:if test="$runIndex &gt; -1">
<input type="radio" name="addOrReplace" value="add" checked="true"/>Add new run
<input type="radio" name="addOrReplace" value="replace"/>Replace run <xsl:value-of select="$runLabel"/>
</xsl:if>
</xsl:if>
</p>
<xsl:if test="$err!=''">
<p><span class="error"><xsl:value-of select="$err"/></span></p>
</xsl:if>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">solution</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$solution"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">sp</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$selectedSp"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">expType</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="expType/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">axis</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="axis/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">numEnergy</xsl:attribute>
<xsl:choose>
  <xsl:when test="$expType='MAD'">
  <xsl:attribute name="value">3</xsl:attribute>
  </xsl:when>
  <xsl:otherwise>
  <xsl:attribute name="value">1</xsl:attribute>
  </xsl:otherwise>
</xsl:choose>
</xsl:element>
<xsl:if test="$expType='MAD'">
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy1</xsl:attribute>
  <xsl:choose>
  <xsl:when test="contains(energyWarning/@value1, 'will not be used')"><xsl:attribute name="value">0.0</xsl:attribute></xsl:when>
  <xsl:otherwise><xsl:attribute name="value"><xsl:value-of select="energy/@value1"/></xsl:attribute></xsl:otherwise>
  </xsl:choose>
</xsl:element>
</xsl:if>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy2</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="energy/@value2"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy3</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="energy/@value3"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy4</xsl:attribute>
  <xsl:attribute name="value">0.0</xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy5</xsl:attribute>
  <xsl:attribute name="value">0.0</xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">inverse</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="inverseBeam/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">wedge</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="wedge/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">detectorMode</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="detector/@number"/></xsl:attribute>
</xsl:element>

<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">oscStartOrg</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="osc/@start"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">oscEndOrg</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="osc/@end"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">deltaOrg</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="osc/@delta"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">wedgeOrg</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="wedge/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">exposureTimeOrg</xsl:attribute>
  <xsl:choose>
  <xsl:when test="exposureTime/@perImageUsed">
    <xsl:attribute name="value"><xsl:value-of select="exposureTime/@perImageUsed"/></xsl:attribute>
  </xsl:when>
  <xsl:when test="best/@exposureTimePerImg*10.0 &lt; exposureTime/@perImage">
    <xsl:attribute name="value"><xsl:value-of select="exposureTime/@perImage"/></xsl:attribute>
  </xsl:when>
  <xsl:otherwise>
    <xsl:attribute name="value"><xsl:value-of select="best/@exposureTimePerImg"/></xsl:attribute>
  </xsl:otherwise>
  </xsl:choose>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">attenuationOrg</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="attenuation/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">distanceOrg</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="detectorZCorr/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">beamStopOrg</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="beamStopZ/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy1Org</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="energy/@value1"/></xsl:attribute>
</xsl:element>

<xsl:if test="(count(attenuation) > 0) and (attenuation/@value > 0.0) and ($doseMode = 'true')">
<div style="color:red">Dose mode is currently enabled. To collect data with attenuated beam, dose mode must be disabled in BluIce. Otherwise attenuation should be set to 0%.</div>
</xsl:if>

<!--<table cellborder="1" border="1" cellspacing="1" width="100%" bgcolor="#FFFF99">-->
<table class="autoindex">
<tr style="background-color:#FFCC00;"><td colspan="2" style="text-align:left"><b>Data Collection
Strategy</b>&#160;&#160;<a id="help" target="new" href="{$helpUrl}/Autoindex_strategy_calculat.html#explanation">i</a></td></tr>
<tr><td width="15%">Experiment Type</td><td><b><xsl:value-of select="expType/@value"/></b></td></tr>
<xsl:choose>
<xsl:when test="../../autoindex/@status != 'ok'">
<tr><td>Mosaicity and Score</td><td><div class="error"><xsl:value-of select="../../autoindex/@result"/></div></td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td>Mosaicity and Score</td><td><xsl:value-of select="../../autoindex/@result"/></td></tr>
</xsl:otherwise>
</xsl:choose>
<!--<tr><td>Rotation Axis</td><td><xsl:value-of select="axis/@value"/></td></tr>-->
<xsl:choose>
<xsl:when test="$action='Recollect Test Images'">
<input type="hidden" name="oscStart" value="0.0"/>
<input type="hidden" name="oscEnd" value="1.0"/>
<tr><td>Oscillation Angle</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">delta</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="osc/@delta"/></xsl:attribute>
</xsl:element>
</td></tr></xsl:when>
<xsl:otherwise>
<tr><td>Oscillation Start</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">oscStart</xsl:attribute>
<xsl:choose>
<xsl:when test="$startAngle=''">
  <xsl:attribute name="value"><xsl:value-of select="osc/@start"/></xsl:attribute>
</xsl:when>
<xsl:otherwise>
  <xsl:attribute name="value"><xsl:value-of select="$startAngle"/></xsl:attribute>
</xsl:otherwise>
</xsl:choose>
</xsl:element>
</td></tr>
<tr><td>Oscillation End</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">oscEnd</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="osc/@end"/></xsl:attribute>
</xsl:element>
</td></tr>
<tr><td>Oscillation Angle</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">delta</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="osc/@delta"/></xsl:attribute>
</xsl:element>
</td></tr>
<tr><td>Oscillation Wedge</td><td><xsl:value-of select="wedge/@value"/></td></tr>
</xsl:otherwise>
</xsl:choose>
<xsl:choose>
<xsl:when test="resolution/@predicted &lt; resolution/@detector">
<tr><td>Resolution</td><td><xsl:value-of select="resolution/@detector"/> &#197;
<div style="color:red">The predicted resolution from 
the diffraction images is <xsl:value-of select="resolution/@predicted"/> &#197;</div>
</td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td>Resolution</td><td><xsl:value-of select="resolution/@predicted"/> &#197;</td></tr>
</xsl:otherwise>
</xsl:choose>
<tr><td>Exposure Time</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">exposureTime</xsl:attribute>
  <xsl:choose>
  <xsl:when test="$exposureTime!=''">
    <xsl:attribute name="value"><xsl:value-of select="$exposureTime"/></xsl:attribute>
  </xsl:when>
  <xsl:when test="exposureTime/@perImageUsed">
    <xsl:attribute name="value"><xsl:value-of select="exposureTime/@perImageUsed"/></xsl:attribute>
  </xsl:when>
  <xsl:when test="best/@exposureTimePerImg*10.0 &lt; exposureTime/@perImage">
    <xsl:attribute name="value"><xsl:value-of select="exposureTime/@perImage"/></xsl:attribute>
  </xsl:when>
  <xsl:otherwise>
    <xsl:attribute name="value"><xsl:value-of select="best/@exposureTimePerImg"/></xsl:attribute>
  </xsl:otherwise>
  </xsl:choose>
</xsl:element>
&#160;sec
<xsl:if test="best/@exposureTimeWarning != ''">
<div class="error"><xsl:value-of select="best/@exposureTimeWarning"/><br/><xsl:value-of select="exposureTime/@warning"/></div>
</xsl:if>
</td></tr>
<tr><td>Attenuation</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">attenuation</xsl:attribute>
<xsl:choose>
<xsl:when test="(count(attenuation) > 0) and (attenuation/@value > 0.0)">
  <xsl:attribute name="value"><xsl:value-of select="attenuation/@value"/></xsl:attribute> %
</xsl:when>
<xsl:otherwise>
  <xsl:attribute name="value">0.0</xsl:attribute> %
</xsl:otherwise>
</xsl:choose>
</xsl:element>
</td></tr>
<tr><td>Optimal Detector Distance</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">distance</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="detectorZCorr/@value"/></xsl:attribute>
</xsl:element>
&#160;mm
<xsl:if test="detectorZCorr/@warning != ''"><div class="error"><xsl:value-of select="detectorZCorr/@warning"/></div>
</xsl:if></td></tr>
<tr><td>Beamstop Distance</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">beamStop</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="beamStopZ/@value"/></xsl:attribute>
</xsl:element>
&#160;mm
<xsl:if test="detectorZCorr/@warning != ''"><div class="error"><xsl:value-of select="beamStopZ/@warning"/></div>
</xsl:if></td></tr>
<xsl:choose>
<xsl:when test="$expType='MAD'">
<tr><td>Energy 1</td><td><xsl:value-of select="energy/@value1"/> eV
<div class="error"><xsl:value-of select="energyWarning/@value1"/></div></td></tr>
<tr><td>Energy 2</td><td><xsl:value-of select="energy/@value2"/>  eV</td></tr>
<tr><td>Energy 3</td><td><xsl:value-of select="energy/@value3"/>  eV</td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td>Energy1</td><td>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="name">energy1</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="energy/@value1"/></xsl:attribute>
</xsl:element>
&#160;eV
<div class="error"><xsl:value-of select="energyWarning/@value1"/></div></td></tr>
</xsl:otherwise>
</xsl:choose>
<tr><td>Detector Type</td><td><xsl:value-of select="detector/@type"/></td></tr>
<tr><td>Detector Mode</td><td><xsl:value-of select="detector/@mode"/></td></tr>
<xsl:choose>
<xsl:when test="inverseBeam/@value=0">
<tr><td>Inverse Beam</td><td>No</td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td>Inverse Beam</td><td>Yes</td></tr>
</xsl:otherwise>
</xsl:choose>
<xsl:if test="$action!='Recollect Test Images'">
<tr><td>Image Number</td><td><xsl:value-of select="imageCount/@value"/><xsl:if test="$expType != 'Native'"> images per energy</xsl:if>
<!-- The warning is about the completeness for unique reflections (not for anomalous) -->
<xsl:if test="imageCount/@warning != ''"><div class="error"><xsl:value-of select="imageCount/@warning"/></div>
</xsl:if></td></tr>
<tr><td>Absorbed Dose</td>
<td>
<xsl:if test="(energy/@value2 != 0.0) and (energy/@value3 != 0.0)">
<xsl:value-of select="radDose/@en1"/> Gy (<xsl:value-of select="radDose/@en1PerImg"/> Gy per image) at <xsl:value-of select="energy/@value1"/> eV.<br/>
<xsl:value-of select="radDose/@en2"/> Gy (<xsl:value-of select="radDose/@en2PerImg"/> Gy per image) at <xsl:value-of select="energy/@value2"/> eV.<br/>
<xsl:value-of select="radDose/@en3"/> Gy (<xsl:value-of select="radDose/@en3PerImg"/> Gy per image) at <xsl:value-of select="energy/@value3"/> eV.<br/>
</xsl:if>
<xsl:value-of select="radDose/@total"/> Gy 
<xsl:if test="$expType != 'MAD'">(<xsl:value-of select="radDose/@perImage"/> Gy per image)</xsl:if> total. Limit is <xsl:value-of select="radDose/@limit"/> Gy.
<xsl:if test="radDose/@warning != ''"><div class="error"><xsl:value-of select="radDose/@warning"/></div>
</xsl:if>
</td></tr>

</xsl:if>
</table>

</form>
</xsl:template>


</xsl:stylesheet>
