<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
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
<xsl:variable name="accessID" select="$param1"/>
<xsl:variable name="owner" select="$param2"/>
<xsl:variable name="selectedPort" select="$param3"/>
<xsl:variable name="showImages" select="$param4"/>
<xsl:variable name="displayTemplate" select="$param5"/>
<xsl:variable name="userName" select="$param6"/>
<xsl:variable name="sortColumn" select="$param7"/>
<xsl:variable name="sortOrder" select="$param8"/>
<xsl:variable name="numRows" select="$param9"/>
<xsl:variable name="cassetteIndex" select="$param10"/>
<xsl:variable name="tmp1" select="document($displayTemplate)/SilDisplay/Column[@name=$sortColumn]/@data-type"/>
<xsl:variable name="sortType">
<xsl:choose>
  <xsl:when test="$tmp1!=''">
  	<xsl:value-of select="$tmp1"/>
  </xsl:when>
  <xsl:otherwise>
  	text
  </xsl:otherwise>
</xsl:choose>
</xsl:variable>
<xsl:template match="Sil">


<form name="silForm" action="Autoindex_ChooseSample.do" target="_self" method="GET">
<input type="hidden" name="accessID" value="{$accessID}" />
<input type="hidden" name="userName" value="{$owner}" />
<input type="hidden" name="silId" value="{@name}" />
<input type="hidden" name="sample" value="cassette" />
<input type="hidden" name="cassette" value="{$cassetteIndex}" />

<TABLE width="100%">
<TR BGCOLOR="#E9EEF5">
<xsl:call-template name="headers" />
</TR>
<!-- List crystals sorted by values in a given column. Skip the crystals whose value of the selected column is empty. -->
<xsl:for-each select="Crystal">
  <xsl:sort select="*[name()=$sortColumn]" order="{$sortOrder}" data-type="{$sortType}"/>
  <xsl:if test="*[name()=$sortColumn][text() != '' and text() != 'N/A']">
  <xsl:apply-templates select="."/>
  </xsl:if>
</xsl:for-each>
<!-- List crystals whose value of the selected column is empty. -->
<xsl:for-each select="Crystal">
  <xsl:if test="*[name()=$sortColumn][text() = '' or text() = 'N/A']">
  <xsl:apply-templates select="."/>
  </xsl:if>
</xsl:for-each>

</TABLE>
</form>
</xsl:template>

<xsl:template name="headers">
<xsl:for-each select="document($displayTemplate)/SilDisplay/Column">
<xsl:element name="th">
<xsl:attribute name="align">center</xsl:attribute>
<xsl:attribute name="width"><xsl:value-of select="@width"/></xsl:attribute>
<xsl:choose>
<xsl:when test="@sort = 'true'">
<xsl:element name="a">
	<xsl:attribute name="target">_self</xsl:attribute>
	<xsl:attribute name="href">Autoindex_sortCrystal.do?column=<xsl:value-of select="@name"/></xsl:attribute>
	<xsl:value-of select="@name"/>
	</xsl:element>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@name"/>
</xsl:otherwise>
</xsl:choose>
</xsl:element>
</xsl:for-each>
</xsl:template>

<xsl:template match="Crystal">

<xsl:variable name="thisNode" select="self::node()" />
<xsl:variable name="thisPos" select="position()" />

<xsl:if test="(($numRows = 1) and ($selectedPort = $thisNode/Port)) or ($numRows = 'all')">
<xsl:element name="TR">
<xsl:choose>
	<xsl:when test="(position() mod 2) = 0">
		<xsl:attribute name="BGCOLOR">#E9EEF5</xsl:attribute>
	</xsl:when>
	<xsl:otherwise>
		<xsl:attribute name="BGCOLOR">#bed4e7</xsl:attribute>
	</xsl:otherwise>
</xsl:choose>


<xsl:for-each select="document($displayTemplate)/SilDisplay/Column">

<xsl:variable name="headerName" select="@name" />

<xsl:if test="$headerName = 'Row'">
<xsl:call-template name="Row">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Selected'">
<xsl:call-template name="Selected">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Port'">
<xsl:call-template name="Port">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'ContainerID'">
<xsl:call-template name="ContainerID">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'CrystalID'">
<xsl:call-template name="CrystalID">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Protein'">
<xsl:call-template name="Protein">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Comment'">
<xsl:call-template name="Comment">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'SystemWarning'">
<xsl:call-template name="SystemWarning">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Directory'">
<xsl:call-template name="Directory">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Images'">
<xsl:call-template name="AllImages">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'BraggSpots'">
<xsl:call-template name="BraggSpots">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'IceRings'">
<xsl:call-template name="IceRings">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'FreezingCond'">
<xsl:call-template name="FreezingCond">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'CrystalCond'">
<xsl:call-template name="CrystalCond">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Metal'">
<xsl:call-template name="Metal">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Priority'">
<xsl:call-template name="Priority">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Person'">
<xsl:call-template name="Person">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'CrystalURL'">
<xsl:call-template name="CrystalURL">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'ProteinURL'">
<xsl:call-template name="ProteinURL">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'AutoindexImages'">
<xsl:call-template name="AutoindexImages">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Score'">
<xsl:call-template name="Score">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'UnitCell'">
<xsl:call-template name="UnitCell">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Mosaicity'">
<xsl:call-template name="Mosaicity">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<!--backward compatibility-->
<xsl:if test="$headerName = 'Rmsr'">
<xsl:call-template name="Rmsd">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Rmsd'">
<xsl:call-template name="Rmsd">
        <xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'BravaisLattice'">
<xsl:call-template name="BravaisLattice">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Resolution'">
<xsl:call-template name="Resolution">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

</xsl:for-each>

</xsl:element>
</xsl:if>

</xsl:template>

<xsl:template name="Row">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="$crystalNode/@row"/></TD>
</xsl:template>

<xsl:template name="Selected">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="$crystalNode/@selected"/></TD>
</xsl:template>

<xsl:template name="Port">
<xsl:param name="crystalNode" select="null"/>
<xsl:choose>
 <xsl:when test="$selectedPort = $crystalNode/Port">
 <TD>
 <xsl:element name="input">
 	<xsl:attribute name="type">radio</xsl:attribute>
 	<xsl:attribute name="name">crystalPort</xsl:attribute>
 	<xsl:attribute name="value"><xsl:value-of select="$crystalNode/Port"/></xsl:attribute>
 	<xsl:attribute name="onclick">row_onclick()</xsl:attribute>
 	<xsl:attribute name="checked">true</xsl:attribute>
 </xsl:element>
 <xsl:value-of select="$crystalNode/Port"/></TD>
 </xsl:when>
 <xsl:otherwise>
 <TD>
 <xsl:element name="input">
 	<xsl:attribute name="type">radio</xsl:attribute>
 	<xsl:attribute name="name">crystalPort</xsl:attribute>
 	<xsl:attribute name="value"><xsl:value-of select="$crystalNode/Port"/></xsl:attribute>
 	<xsl:attribute name="onclick">row_onclick()</xsl:attribute>
 </xsl:element>
 <xsl:value-of select="$crystalNode/Port" /></TD>
 </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<xsl:template name="ContainerID">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:choose>
    <xsl:when test="string-length($crystalNode/ContainerID)=0">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="$crystalNode/ContainerID"/></xsl:otherwise>
  </xsl:choose></TD>
</xsl:template>

<xsl:template name="CrystalID">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:choose>
    <xsl:when test="string-length($crystalNode/CrystalID)=0">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string($crystalNode/CrystalID), '{}()[]/\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxxxxxxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose></TD>
</xsl:template>

<xsl:template name="Protein">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/Protein), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Comment">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/Comment), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="SystemWarning">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/SystemWarning), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Directory">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:choose>
    <xsl:when test="string-length($crystalNode/Directory)=0">null</xsl:when>
    <xsl:when test="string($crystalNode/Directory)='/'">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string($crystalNode/Directory), '{}()[]\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxx/xxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose></TD>
</xsl:template>

<xsl:template name="AllImages">
<xsl:param name="crystalNode" select="null"/>
  <TD><xsl:apply-templates select="$crystalNode/Images"/></TD>
</xsl:template>

<xsl:template match="Images">
  <xsl:choose>
    <xsl:when test="($selectedPort = ../Port) and ($showImages = 'show')">
      <table border="1">
    	<tr><th>Group</th>
    	<td>1</td>
    	<td>2</td>
    	<td>3</td>
    	</tr>
    	<tr><th>fileName</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@name"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@name"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@name"/></td></tr>
    	<tr><th>Image</th>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@large) > 0">
		<img src="servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@large}" alt="Image snapshot unavailable"/>
		</xsl:when><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@large) > 0">
		<img src="servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=2]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@large}" alt="Image snapshot unavailable"/>
		</xsl:when><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@large) > 0">
		<img src="servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=3]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@large}" alt="Image snapshot unavailable"/>
		</xsl:when><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td></tr>
		<tr><th>Crystal</th>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@jpeg) > 0">
		<img src="servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@jpeg}" alt="Crystal snapshot unavailable"/>
		</xsl:when><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@jpeg) > 0">
		<img src="servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@jpeg}" alt="Crystal snapshot unavailable"/>
		</xsl:when><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@jpeg) > 0">
		<img src="servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@jpeg}" alt="Crystal snapshot unavailable"/>
		</xsl:when><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
    	</tr>
    	<tr><th>Spot Shape</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@spotShape"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@spotShape"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@spotShape"/></td></tr>
    	<tr><th>DISTL Resolution</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@resolution"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@resolution"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@resolution"/></td></tr>
    	<tr><th>Ice Rings</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@iceRings"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@iceRings"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@iceRings"/></td></tr>
    	<tr><th>Diffraction Strength</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@diffractionStrength"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@diffractionStrength"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@diffractionStrength"/></td></tr>
    	<tr><th>Score</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@score"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@score"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@score"/></td></tr>
      </table>
  	</xsl:when>
    <xsl:when test="$showImages='link'">
      <table border="1">
    	<tr><th>Group</th>
    	<td>1</td>
    	<td>2</td>
    	<td>3</td>
    	</tr>
    	<tr><th>Image</th>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@large) > 0">
		<a style="color:blue" onclick='show_diffimage("servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@large}")'>
		<xsl:value-of select="Group[@name=1]/Image[position()=last()]/@name"/></a>
		</xsl:when><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@large) > 0">
		<a style="color:blue" onclick='show_diffimage("servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=2]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@large}")'>
		<xsl:value-of select="Group[@name=2]/Image[position()=last()]/@name"/></a>
		</xsl:when><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@large) > 0">
		<a style="color:blue" onclick='show_diffimage("servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=3]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@large}")'>
		<xsl:value-of select="Group[@name=3]/Image[position()=last()]/@name"/></a>
		</xsl:when><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		</tr>
		<tr><th>Crystal</th>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@jpeg) > 0">
		<a style="color:blue" onclick='show_xtal("servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@jpeg}")'>
		<xsl:value-of select="Group[@name=1]/Image[position()=last()]/@jpeg"/></a>
		</xsl:when><xsl:when test="string-length(Group[@name=1]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
		<td><xsl:choose><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@jpeg) > 0">
		<a style="color:blue" onclick='show_xtal("servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=2]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@jpeg}")'>
		<xsl:value-of select="Group[@name=2]/Image[position()=last()]/@jpeg"/></a>
		</xsl:when><xsl:when test="string-length(Group[@name=2]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>		
		<td><xsl:choose><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@jpeg) > 0">
		<a style="color:blue" onclick='show_xtal("servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=3]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@jpeg}")'>
		<xsl:value-of select="Group[@name=1]/Image[position()=last()]/@jpeg"/></a>
		</xsl:when><xsl:when test="string-length(Group[@name=3]/Image[position()=last()]/@name) > 0">Snapshot unavailable</xsl:when></xsl:choose></td>
    	</tr>
    	<tr><th>Spot Shape</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@spotShape"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@spotShape"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@spotShape"/></td></tr>
    	<tr><th>DISTL Resolution</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@resolution"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@resolution"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@resolution"/></td></tr>
    	<tr><th>Ice Rings</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@iceRings"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@iceRings"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@iceRings"/></td></tr>
    	<tr><th>Diffraction Strength</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@diffractionStrength"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@diffractionStrength"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@diffractionStrength"/></td></tr>
    	<tr><th>Score</th>
    	<td><xsl:value-of select="Group[@name=1]/Image[position()=last()]/@score"/></td>
    	<td><xsl:value-of select="Group[@name=2]/Image[position()=last()]/@score"/></td>
    	<td><xsl:value-of select="Group[@name=3]/Image[position()=last()]/@score"/></td></tr>
      </table>
  	</xsl:when>
  	<xsl:otherwise>
	  <xsl:for-each select="Group/Image">
	  	<xsl:choose>
	  	<xsl:when test="string-length(@large) > 0">
		<a style="color:blue" onclick='show_diffimage("servlet/loader/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={@dir}/{@large}")'>
		<xsl:value-of select="@name"/></a>
		</xsl:when>
		<xsl:otherwise>
		<xsl:value-of select="@name"/>
		</xsl:otherwise>
		</xsl:choose><br/>
	  </xsl:for-each>
	</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="BraggSpots">
<xsl:param name="crystalNode" select="null"/>
<td>
  <xsl:choose>
    <xsl:when test="$crystalNode/Images/Group[@name=1]/Image[position()=last()] and $crystalNode/Images/Group[@name=1]/Image[position()=last()]/@numSpots">
      <xsl:value-of select="$crystalNode/Images/Group[@name=1]/Image[position()=last()]/@numSpots"/>
    </xsl:when>
    <xsl:when test="$crystalNode/Images/Group[@name=1]/Image[position()=last()]">0</xsl:when>
  </xsl:choose>
  <xsl:if test="$crystalNode/Images/Group[@name=1]/Image[position()=last()] and $crystalNode/Images/Group[@name=2]/Image[position()=last()]"><br/></xsl:if>
  <xsl:choose>
    <xsl:when test="$crystalNode/Images/Group[@name=2]/Image[position()=last()]/@numSpots">
      <xsl:value-of select="$crystalNode/Images/Group[@name=2]/Image[position()=last()]/@numSpots"/>
    </xsl:when>
    <xsl:when test="$crystalNode/Images/Group[@name=2]/Image[position()=last()]">0</xsl:when>
  </xsl:choose>
</td>
</xsl:template>

<xsl:template name="IceRings">
<xsl:param name="crystalNode" select="null"/>
<td>
<xsl:choose>
<xsl:when test="$crystalNode/Images/Group[@name=1]/Image[position()=last()] and $crystalNode/Images/Group[@name=1]/Image[position()=last()]/@iceRings">
<xsl:value-of select="$crystalNode/Images/Group[@name=1]/Image[position()=last()]/@iceRings"/>
</xsl:when>
<xsl:when test="$crystalNode/Images/Group[@name=1]/Image[position()=last()]">0</xsl:when>
</xsl:choose>
<xsl:if test="$crystalNode/Images/Group[@name=1]/Image[position()=last()] and $crystalNode/Images/Group[@name=2]/Image[position()=last()]"><br/></xsl:if>
<xsl:choose>
<xsl:when test="$crystalNode/Images/Group[@name=2]/Image[position()=last()]/@iceRings">
<xsl:value-of select="$crystalNode/Images/Group[@name=2]/Image[position()=last()]/@iceRings"/>
</xsl:when>
<xsl:when test="$crystalNode/Images/Group[@name=2]/Image[position()=last()]">0</xsl:when>
</xsl:choose>
</td>
</xsl:template>

<xsl:template name="FreezingCond">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/FreezingCond), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="CrystalCond">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/CrystalCond), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Metal">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/Metal), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Priority">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/Priority), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Person">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/Person), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="CrystalURL">
<xsl:param name="crystalNode" select="null"/>
 <TD>
 	<xsl:element name="a">
 	  <xsl:attribute name="href"><xsl:value-of select="translate( string($crystalNode/CrystalURL), '{}','()')"/></xsl:attribute>
 	<xsl:value-of select="translate( string($crystalNode/CrystalURL), '{}','()')"/></xsl:element>
 </TD>
</xsl:template>

<xsl:template name="ProteinURL">
<xsl:param name="crystalNode" select="null"/>
 <TD>
 	<xsl:element name="a">
 	  <xsl:attribute name="href"><xsl:value-of select="translate( string($crystalNode/ProteinURL), '{}','()')"/></xsl:attribute>
 	<xsl:value-of select="translate( string($crystalNode/ProteinURL), '{}','()')"/></xsl:element>
 </TD>
</xsl:template>

<xsl:template name="AutoindexImages">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/AutoindexImages), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Score">
<xsl:param name="crystalNode" select="null"/>
 <TD>
   <xsl:if test="number($crystalNode/Score)">
     <xsl:value-of select="format-number($crystalNode/Score, '0.000')"/>
   </xsl:if>
</TD>
</xsl:template>

<xsl:template name="UnitCell">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/UnitCell), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Mosaicity">
<xsl:param name="crystalNode" select="null"/>
 <TD>
   <xsl:if test="number($crystalNode/Mosaicity)">
     <xsl:value-of select="format-number($crystalNode/Mosaicity, '0.00')"/>&#176;
   </xsl:if>
</TD>
</xsl:template>

<xsl:template name="Rmsd">
<xsl:param name="crystalNode" select="null"/>
 <TD>
   <xsl:if test="number($crystalNode/Rmsr)">
     <xsl:value-of select="format-number($crystalNode/Rmsr, '0.000')"/> mm
   </xsl:if>
</TD>
</xsl:template>

<xsl:template name="BravaisLattice">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/BravaisLattice), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Resolution">
<xsl:param name="crystalNode" select="null"/>
 <TD>
  <xsl:if test="number($crystalNode/Resolution)">
   <xsl:value-of select="translate( string($crystalNode/Resolution), '{}','()')"/>
   <xsl:text> &#197;</xsl:text>
  </xsl:if>
 </TD>
</xsl:template>


</xsl:stylesheet>
