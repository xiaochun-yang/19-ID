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
<xsl:variable name="runName" select="$param1"/>
<xsl:variable name="userName" select="$param2"/>
<xsl:variable name="sessionId" select="$param3"/>
<xsl:variable name="workDir" select="$param4"/>
<xsl:variable name="selectedSpaceGroup" select="$param5"/>
<xsl:variable name="junk" select="$param6"/>
<xsl:variable name="phiStrategyType" select="$param7"/>
<xsl:variable name="impUrl" select="$param8"/>
<xsl:variable name="strategyType" select="$param10"/>
<xsl:variable name="expType" select="$param11"/>
<xsl:variable name="helpUrl" select="$param12"/>
<xsl:variable name="queueEnabled" select="$param13"/>
<xsl:variable name="solNum">
  <xsl:choose>
    <xsl:when test="$param9=''">
      <xsl:value-of select="labelit/integration/solution[@integrated='true']/@number"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$param9"/>
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

<xsl:variable name="selectedSp">
<xsl:choose>
  <xsl:when test="$selectedSpaceGroup=''">
	<xsl:value-of select="labelit/integration/solution[@number=$solNum]/spaceGroup/@name"/>
  </xsl:when>
  <xsl:otherwise>
  	<!-- if the selected sp does not exist for this solution then select the first sp of this solution -->
	<xsl:choose>
  	  <xsl:when test="count(labelit/integration/solution[@number=$solNum]/spaceGroup[@name=$selectedSpaceGroup])=0">
	  	<xsl:value-of select="labelit/integration/solution[@number=$solNum]/spaceGroup/@name"/>
  	  </xsl:when>
	  <xsl:otherwise>
		<xsl:value-of select="$selectedSpaceGroup"/>
	  </xsl:otherwise>
	</xsl:choose>
  </xsl:otherwise>
</xsl:choose>
</xsl:variable>

<!--<xsl:variable name="expType" select="Native"/>-->

<xsl:template match="labelit">
<html>
<head>
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" CONTENT="no-cache"/>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
function sol_onchange() {
    eval("i = document.solForm.solution.selectedIndex");
    eval("x= document.solForm.solution.options[i].value");
    var submit_url = "Autoindex_SelectSolAndSp.do?solution=" + x;

    location.replace(submit_url);
}
</script>

<style>
.url_link {text-decoration: none}
.selected {font-weight:bold;border-width:1;border-color:black;border-style:solid;padding-left:0.5em;padding-right:0.5em;background-color:gray;color:white}
.unselected {border-width:1;border-color:black;border-style:solid;padding-left:0.5em;padding-right:0.5em;background-color:white;color:black}
</style>

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

<table>
<tr>
<td>
<!-- Drop down menu for solution selection -->
<form name="solForm" action="Autoindex_SelectSolAndSp.do" target="_self">
<select name="solution" onchange="sol_onchange()">
  <xsl:for-each select="solution[@integrated='true']">
    <xsl:choose>
      <xsl:when test="@number=$solNum">
        <option value="{@number}" selected="selected">Solution<xsl:value-of select="@number"/></option>
      </xsl:when>
      <xsl:otherwise>
        <option value="{@number}">Solution<xsl:value-of select="@number"/></option>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</select>
</form>
</td>
<td>
<!-- Strategy summary table for the selected solution from /runNN/solutionNN/strategy_summary.xml -->
<xsl:variable name="sf">
    <xsl:value-of select="$impUrl"/><xsl:text>/readFile?impUser=</xsl:text><xsl:value-of select="$userName"/><xsl:text>&amp;impSessionID=</xsl:text><xsl:value-of select="$sessionId"/><xsl:text>&amp;impFilePath=</xsl:text><xsl:value-of select="$workDir"/><xsl:text>/solution</xsl:text><xsl:value-of select="$solStr"/><xsl:text>/strategy_summary.xml</xsl:text>
</xsl:variable>
<xsl:variable name="def" select="document($sf)/strategySummary/spaceGroup[@name=$selectedSp]/dcStrategy[expType/@value=$phiStrategyType]" />
<form action="Autoindex_ShowEditRunDefinitionForm.do" target="_self">
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">solution</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$solNum"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">sp</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$selectedSp"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">expType</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$expType"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">axis</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/axis/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">oscStart</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/osc/@start"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">oscEnd</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/osc/@end"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">delta</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/osc/@delta"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">wedge</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/wedge/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">exposureTime</xsl:attribute>
  <xsl:choose>
  <xsl:when test="$def/exposureTime/@perImageUsed">
    <xsl:attribute name="value"><xsl:value-of select="$def/exposureTime/@perImageUsed"/></xsl:attribute>
  </xsl:when>
  <xsl:when test="$def/best/@exposureTimePerImg*10.0 &lt; $def/exposureTime/@perImage">
    <xsl:attribute name="value"><xsl:value-of select="$def/exposureTime/@perImage"/></xsl:attribute>
  </xsl:when>
  <xsl:otherwise>
    <xsl:attribute name="value"><xsl:value-of select="$def/best/@exposureTimePerImg"/></xsl:attribute>
  </xsl:otherwise>
  </xsl:choose>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">attenuation</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/attenuation/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">distance</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/detectorZCorr/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">beamStop</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/beamStopZ/@value"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">numEnergy</xsl:attribute>
  <xsl:attribute name="value">1</xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy1</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/energy/@value1"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy2</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/energy/@value2"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy3</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/energy/@value3"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy4</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/energy/@value4"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">energy5</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/energy/@value5"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">detectorMode</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/detector/@number"/></xsl:attribute>
</xsl:element>
<xsl:element name="input">
  <xsl:attribute name="type">hidden</xsl:attribute>
  <xsl:attribute name="name">inverse</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="$def/inverseBeam/@value"/></xsl:attribute>
</xsl:element>
<input class="actionbutton1" type="submit" name="action" value="Export to Blu-Ice"/>
&#160;<input class="actionbutton1"  type="submit" name="action" value="Recollect Test Images"/>
&#160;<input class="actionbutton1"  type="submit" name="action"  value="Collect Dataset"/>
<xsl:if test="$queueEnabled='true'">
&#160;<input class="actionbutton1"  type="submit" name="action"  value="Send to Queue"/>
</xsl:if>
</form>
</td>
</tr>
</table>

<table class="autoindex" cols="6">
<tr>
<th rowspan="2">Space Groups</th>
<th colspan="2" style="text-align:center">Phi Range</th>
<th colspan="2" style="text-align:center">Completeness</th>
<th rowspan="2">Max Delta Phi</th>
</tr>

<tr>
<th>Unique</th>
<th>Anomalous</th>
<th>Unique</th>
<th>Anomalous</th>
</tr>

<!-- Strategy summary table for the selected solution from /runNN/solutionNN/strategy_summary.xml -->
<xsl:for-each select="solution[@number=$solNum]">
  <xsl:variable name="summaryFile">
    <xsl:value-of select="$impUrl"/><xsl:text>/readFile?impUser=</xsl:text><xsl:value-of select="$userName"/><xsl:text>&amp;impSessionID=</xsl:text><xsl:value-of select="$sessionId"/><xsl:text>&amp;impFilePath=</xsl:text><xsl:value-of select="$workDir"/><xsl:text>/solution</xsl:text><xsl:value-of select="$solStr"/><xsl:text>/strategy_summary.xml</xsl:text>
  </xsl:variable>
  <xsl:apply-templates select="document($summaryFile)/strategySummary/spaceGroup"/>
</xsl:for-each>

</table>

<!-- Table displaying strategy data of the selected solution and space group 
     from runNN/solutionNN/spacegroupNN/strategy.xml -->
<xsl:for-each select="solution[@number=$solNum]/spaceGroup[@name=$selectedSp]">
  <xsl:variable name="strategyFile">
    <xsl:value-of select="$impUrl"/><xsl:text>/readFile?impUser=</xsl:text><xsl:value-of select="$userName"/><xsl:text>&amp;impSessionID=</xsl:text><xsl:value-of select="$sessionId"/><xsl:text>&amp;impFilePath=</xsl:text><xsl:value-of select="$workDir"/><xsl:text>/solution</xsl:text><xsl:value-of select="$solStr"/><xsl:text>/</xsl:text><xsl:value-of select="$selectedSp"/><xsl:text>/strategy.xml</xsl:text>
  </xsl:variable>
  <br/><b>Space Group <xsl:value-of select="$selectedSp"/>:&#160;</b>
<div width="100%" style="text-align:left;padding-top:2px;padding-left:1px;background-color:#FFcc00">
  <xsl:choose>
    <xsl:when test="$strategyType='dcStrategy'">
      <span class="setupTabSelected"><a class="a_selected" href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=dcStrategy" target="_self">Strategy</a></span>
    </xsl:when>
    <xsl:otherwise>
      <span class="setupTab"><a class="a_unselected" href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=dcStrategy" target="_self">Strategy</a></span>
    </xsl:otherwise>
  </xsl:choose>
 
  <xsl:choose>
    <xsl:when test="$strategyType='testgen'">
      <span class="setupTabSelected"><a class="a_selected"
    href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=testgen"
    target="_self">Overlap Analysis</a></span> 
    </xsl:when>
    <xsl:otherwise>
      <span class="setupTab"><a class="a_unselected"
    href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=testgen"
    target="_self">Overlap Analysis</a></span>
    </xsl:otherwise>
  </xsl:choose>
&#160;  
<span class="warning">Completeness Analysis:</span>
  <xsl:choose>
    <xsl:when test="$strategyType='uniqueData'">
      <span class="setupTabSelected"><a class="a_selected" href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=uniqueData" target="_self">Unique</a></span>
    </xsl:when>
    <xsl:otherwise>
      <span class="setupTab"><a class="a_unselected" href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=uniqueData" target="_self">Unique</a></span>
    </xsl:otherwise>
  </xsl:choose>
  
  <xsl:choose>
    <xsl:when test="$strategyType='anomData'">
      <span class="setupTabSelected"><a class="a_selected" href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=anomData" target="_self">Anomalous</a></span>
    </xsl:when>
    <xsl:otherwise>
      <span class="setupTab"><a class="a_unselected" href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=anomData" target="_self">Anomalous</a></span>
    </xsl:otherwise>
  </xsl:choose>
</div>
  <xsl:choose>
    <xsl:when test="$strategyType='uniqueData'">
      <xsl:apply-templates select="document($strategyFile)/strategy/completenessStrategy"/>
    </xsl:when>
    <xsl:when test="$strategyType='anomData'">
      <xsl:apply-templates select="document($strategyFile)/strategy/anomalousStrategy"/>
    </xsl:when>
    <xsl:when test="$strategyType='testgen'">
      <xsl:apply-templates select="document($strategyFile)/strategy/testgen"/>
    </xsl:when>
    <xsl:otherwise>
	  <xsl:variable name="summaryFile">
		<xsl:value-of select="$impUrl"/><xsl:text>/readFile?impUser=</xsl:text><xsl:value-of select="$userName"/><xsl:text>&amp;impSessionID=</xsl:text><xsl:value-of select="$sessionId"/><xsl:text>&amp;impFilePath=</xsl:text><xsl:value-of select="$workDir"/><xsl:text>/solution</xsl:text><xsl:value-of select="$solStr"/><xsl:text>/strategy_summary.xml</xsl:text>
	  </xsl:variable>
		<xsl:apply-templates select="document($summaryFile)/strategySummary/spaceGroup[@name=$selectedSp]/dcStrategy[expType/@value=$phiStrategyType]"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:for-each>

</xsl:template>

<!-- Content of strategy summary table from /runNN/solutionNN/strategy_summary.xml -->
<xsl:template match="spaceGroup">
    <tr>
    <td align="center" cellborder="0">
    <xsl:choose>
		<xsl:when test="@name=$selectedSp">
		   <img src="images/autoindex/arrow_right.gif" width="20"/>
		   <xsl:value-of select="@name"/>
		</xsl:when>
		<xsl:otherwise>
		   <img src="images/autoindex/empty.gif" width="20"/>
    		   <a href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=dcStrategy&amp;expType=Native" target="_self"><xsl:value-of select="@name"/></a>
		</xsl:otherwise>
	</xsl:choose>
    </td>
    <td align="center">
    <xsl:choose>
    <xsl:when test="$phiStrategyType='Native' and $selectedSp=@name">
       <xsl:value-of select="phiStrategy/uniqueData/@phiStart"/> to <xsl:value-of select="phiStrategy/uniqueData/@phiEnd"/>
    </xsl:when>
    <xsl:otherwise>
       <a href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=dcStrategy&amp;expType=Native" target="_self">
       <xsl:value-of select="phiStrategy/uniqueData/@phiStart"/> to <xsl:value-of select="phiStrategy/uniqueData/@phiEnd"/></a>
    </xsl:otherwise>
    </xsl:choose>
    </td>
    <td align="center">
    <xsl:choose>
    <xsl:when test="$phiStrategyType='Anomalous' and $selectedSp=@name">
       <xsl:value-of select="phiStrategy/anomalousData/@phiStart"/> to <xsl:value-of select="phiStrategy/anomalousData/@phiEnd"/>
    </xsl:when>
    <xsl:otherwise>
       <a href="Autoindex_SelectSolAndSp.do?solution={$solNum}&amp;spaceGroup={@name}&amp;show=dcStrategy&amp;expType=Anomalous" target="_self">
       <xsl:value-of select="phiStrategy/anomalousData/@phiStart"/> to <xsl:value-of select="phiStrategy/anomalousData/@phiEnd"/></a>
    </xsl:otherwise>
    </xsl:choose>
    </td>
    <td align="center"><xsl:value-of select="phiStrategy/uniqueData/@complete"/></td>
    <td align="center"><xsl:value-of select="phiStrategy/anomalousData/@complete"/></td>
    <td align="center"><xsl:value-of select="phiStrategy/maxDeltaPhi/@value"/></td>
    </tr>
</xsl:template>

<!-- Content of strategy table from runNN/solutionNN/spacegroupNN/strategy.xml -->

<xsl:template match="completenessStrategy">
<table class="autoindex">
<tr><td>
<b>Completeness analysis of phi range to maximize unique reflections</b>
<pre>
<xsl:value-of select="summary"/>
</pre>
<pre>
<xsl:value-of select="uniqueData"/>
<xsl:value-of select="anomalousData"/>
</pre>
</td></tr>
</table>
</xsl:template>

<xsl:template match="anomalousStrategy">
<table class="autoindex">
<tr><td>
<b>Completeness analysis of phi range to maximize anomalous pairs</b>
<pre>
<xsl:value-of select="summary"/>
</pre>
<pre>
<xsl:value-of select="uniqueData"/>

<xsl:value-of select="anomalousData"/>
</pre>
</td></tr>
</table>
</xsl:template>

<xsl:template match="testgen">
<table class="autoindex">
<tr><td>
<b>Overlap Analysis</b>
<pre>
<xsl:value-of select="."/>
</pre></td></tr>
</table>

</xsl:template>

<xsl:template match="dcStrategy">
<table class="autoindex">
<tr><td style="text-align:left" colspan="2"><b>Data Collection Strategy</b>&#160;&#160;
<a class="a_selected" id="help" target="new" href="{$helpUrl}/Autoindex_strategy_calculat.html#explanation">i</a></td></tr>
<tr><td width="20%"><b>Experiment Type</b></td><td><xsl:value-of select="$expType"/>
<xsl:if test="$expType='Native' and $phiStrategyType='Anomalous'">
<span class="error"> Maximizing anomalous completeness; selecting phi range to maximize unique completeness is recommended.</span>
</xsl:if>
<xsl:if test="$expType!='Native' and
$phiStrategyType='Native'"><span class="error">  Maximizing
unique completeness; selecting phi range to maximize anomalous completeness is recommended.</span>
</xsl:if></td></tr>

<xsl:choose>
<xsl:when test="../../autoindex/@score != ''">


<xsl:choose>
<xsl:when test="../../autoindex/@status != 'ok'">
<tr><td><b>Score</b></td><td><xsl:value-of select="../../autoindex/@score"/>
<xsl:text> </xsl:text><span class="warning">(score = 1.0 - 0.7e<sup>-4&#47;d</sup> - 1.5rmsd - 0.4mosaicity)</span>
</td></tr>
<tr><td><b>Mosaicity</b></td><td><div class="error"><xsl:value-of
select="../../autoindex/@mosaicity"/> Predicts only 60% of spots in images</div></td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td><b>Score</b></td><td><xsl:value-of select="../../autoindex/@score"/>
<xsl:text> </xsl:text><span class="warning">(score = 1.0 - 0.7e<sup>-4&#47;d</sup> - 1.5rmsd - 0.2mosaicity)</span>
</td></tr>
<tr><td><b>Mosaicity</b></td><td><xsl:value-of
select="../../autoindex/@mosaicity"/>&#160;<span class="warning">Predicts 80% of spots in images</span></td></tr>
</xsl:otherwise>
</xsl:choose>

</xsl:when>
<xsl:otherwise>

<xsl:choose>
<xsl:when test="../../autoindex/@status != 'ok'">
<tr><td><b>Mosaicity and Score</b></td><td><div class="error"><xsl:value-of select="../../autoindex/@result"/></div></td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td><b>Mosaicity and Score</b></td><td><xsl:value-of select="../../autoindex/@result"/></td></tr>
</xsl:otherwise>
</xsl:choose>

</xsl:otherwise>
</xsl:choose>
<!--<tr><td><b>Rotation Axis</b></td><td><xsl:value-of select="axis/@value"/></td></tr>-->
<tr><td><b>Oscillation Start</b></td><td><xsl:value-of select="osc/@start"/>&#176;</td></tr>
<tr><td><b>Oscillation End</b></td><td><xsl:value-of select="osc/@end"/>&#176;</td></tr>
<tr><td><b>Oscillation Angle</b></td><td><xsl:value-of select="osc/@delta"/>&#176;</td></tr>
<tr><td><b>Oscillation Wedge</b></td><td><xsl:value-of select="wedge/@value"/>&#176;</td></tr>
<xsl:choose>
<xsl:when test="resolution/@predicted &lt; resolution/@detector">
<tr><td><b>Resolution</b></td><td><xsl:value-of select="resolution/@detector"/> &#197;
<div style="color:red">The predicted resolution from 
the diffraction images is <xsl:value-of select="resolution/@predicted"/> &#197;</div>
</td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td><b>Resolution</b></td><td><xsl:value-of select="resolution/@predicted"/> &#197;</td></tr>
</xsl:otherwise>
</xsl:choose>
<tr><td><b>Exposure Time</b></td><td><xsl:value-of select="exposureTime/@perImageUsed"/> sec
<div class="error"><xsl:if test="best/@exposureTimeWarning != ''"><xsl:value-of select="best/@exposureTimeWarning"/><br/></xsl:if><xsl:value-of select="exposureTime/@warning"/></div>
</td></tr>
<tr><td><b>Attenuation</b></td><td>
<xsl:choose>
<xsl:when test="(count(attenuation) > 0) and (attenuation/@value > 0.0)">
<xsl:value-of select="attenuation/@value"/> %
<xsl:if test="attenuation/@warning != ''"><div class="error"><xsl:value-of select="attenuation/@warning"/></div>
</xsl:if>
</xsl:when>
<xsl:otherwise>
0.0 %
</xsl:otherwise>
</xsl:choose>
</td></tr>
<tr><td><b>Optimal Detector Distance</b></td><td><xsl:value-of select="detectorZCorr/@value"/> mm
<xsl:if test="detectorZCorr/@warning != ''"><div class="error"><xsl:value-of select="detectorZCorr/@warning"/></div>
</xsl:if></td></tr>
<tr><td><b>Beamstop Distance</b></td><td><xsl:value-of select="beamStopZ/@value"/> mm
<xsl:if test="detectorZCorr/@warning != ''"><div class="error"><xsl:value-of select="beamStopZ/@warning"/></div>
</xsl:if></td></tr>
<xsl:choose>
<xsl:when test="$expType='MAD'">
<tr><td><b>Energy 1</b></td><td><xsl:value-of select="energy/@value1"/> eV
<div style="color:red"><xsl:value-of select="energyWarning/@value1"/></div></td></tr>
<tr><td><b>Energy 2</b></td><td><xsl:value-of select="energy/@value2"/> eV</td></tr>
<tr><td><b>Energy 3</b></td><td><xsl:value-of select="energy/@value3"/> eV</td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td><b>Energy</b></td><td><xsl:value-of select="energy/@value1"/> eV
<div style="color:red"><xsl:value-of select="energyWarning/@value1"/></div></td></tr>
</xsl:otherwise>
</xsl:choose>
<tr><td><b>Detector Type</b></td><td><xsl:value-of select="detector/@type"/></td></tr>
<tr><td><b>Detector Mode</b></td><td><xsl:value-of select="detector/@mode"/></td></tr>
<xsl:choose>
<xsl:when test="inverseBeam/@value=0">
<tr><td><b>Inverse Beam</b></td><td>No</td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td><b>Inverse Beam</b></td><td>Yes</td></tr>
</xsl:otherwise>
</xsl:choose>
<tr><td><b>Number of images</b></td><td><xsl:value-of select="imageCount/@value"/><xsl:if test="$expType != 'Native'"> images per energy</xsl:if>
<!-- The warning is about the completeness for unique reflections (not for anomalous) -->
<xsl:if test="imageCount/@warning != ''"><div style="color:red"><xsl:value-of select="imageCount/@warning"/></div>
</xsl:if></td></tr>
<tr><td><b>Estimated Absorbed Dose</b>&#160;<a class="a_selected" id="help" target="new" href="{$helpUrl}/Autoindex_strategy_calculat.html#dose">i</a>&#160;</td>
<td>
<xsl:if test="$expType = 'MAD'">
<xsl:value-of select="radDose/@en1"/> Gy (<xsl:value-of select="radDose/@en1PerImg"/> Gy per image) at <xsl:value-of select="energy/@value1"/> eV.<br/>
<xsl:if test="energy/@value2 != 0.0">
<xsl:value-of select="radDose/@en2"/> Gy (<xsl:value-of select="radDose/@en2PerImg"/> Gy per image) at <xsl:value-of select="energy/@value2"/> eV.<br/>
</xsl:if>
<xsl:if test="energy/@value3 != 0.0">
<xsl:value-of select="radDose/@en3"/> Gy (<xsl:value-of select="radDose/@en3PerImg"/> Gy per image) at <xsl:value-of select="energy/@value3"/> eV.<br/>
</xsl:if>
</xsl:if>
<xsl:value-of select="radDose/@total"/> Gy 
<xsl:if test="$expType != 'MAD'">(<xsl:value-of select="radDose/@perImage"/> Gy per image)</xsl:if> total. &#160;<span class="warning">Limit is <xsl:value-of select="radDose/@limit" /> Gy.</span>
<xsl:if test="radDose/@warning != ''"><div class="error"><xsl:value-of select="radDose/@warning"/></div>
</xsl:if>
</td></tr>
</table>

</xsl:template>

</xsl:stylesheet>
