<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" indent="yes"/>

<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:param name="param4"/>
<xsl:param name="param5"/>
<xsl:param name="param6"/>
<xsl:variable name="accessID" select="$param1"/>
<xsl:variable name="owner" select="$param2"/>
<xsl:variable name="selectedRow" select="$param3"/>
<xsl:variable name="showImages" select="$param4"/>
<xsl:variable name="displayTemplate" select="$param5"/>
<xsl:variable name="userName" select="$param6"/>

<!--
tranform screening system crystallist XML -> HTML
-->

<xsl:template match="Sil">

<form name="silForm" action="editSil.jsp" target="_self" method="GET">

<table border="1">
<tr>
<th align="center" bgcolor="#bed4e7">Owner</th>
<th align="center" bgcolor="#bed4e7">Sample Information ID</th>
<th align="center" bgcolor="#bed4e7">Display Type</th>
<th align="center" bgcolor="#bed4e7">Image Display Type</th>
</tr>
<tr>
<td align="center" bgcolor="#E9EEF5"><xsl:value-of select="$owner"/></td>
<td align="center" bgcolor="#E9EEF5"><xsl:value-of select="@name"/></td>

<input type="hidden" name="accessID" value="{$accessID}" />
<input type="hidden" name="userName" value="{$owner}" />
<input type="hidden" name="silId" value="{@name}" />
<input type="hidden" name="selectedRow" value="{$selectedRow}" />

<td align="center">
<select name="displayType" onchange="display_onchange()">
<xsl:if test="contains($displayTemplate,'display_src')">
  <option value="display_src" selected="true">Display Original</option> 
</xsl:if>
<xsl:if test="not(contains($displayTemplate,'display_src'))">
  <option value="display_src">Display Original</option> 
</xsl:if>
<xsl:if test="contains($displayTemplate,'display_mini')">
  <option value="display_mini" selected="true">Display Mini</option>
</xsl:if>
<xsl:if test="not(contains($displayTemplate,'display_mini'))">
  <option value="display_mini">Display Mini</option>
</xsl:if>
<xsl:if test="contains($displayTemplate,'display_result')">
  <option value="display_result" selected="true">Display Results</option>
</xsl:if>
<xsl:if test="not(contains($displayTemplate,'display_result'))">
  <option value="display_result">Display Results</option>
</xsl:if>
<xsl:if test="contains($displayTemplate,'display_all')">
  <option value="display_all" selected="true">Display All</option>
</xsl:if>
<xsl:if test="not(contains($displayTemplate,'display_all'))">
  <option value="display_all">Display All</option>
</xsl:if>
</select>
</td>
<td align="center">
<select name="showImages" onchange="option_onchange()">
<xsl:if test="$showImages = 'hide'">
  <option value="hide" selected="true">Hide Images</option>
  <option value="selected">Show Selected Images</option>
  <option value="alllinks">Show All Crystal Links</option>
</xsl:if>
<xsl:if test="$showImages = 'selected'">
  <option value="hide">Hide Images</option>
  <option value="selected" selected="true">Show Selected Images</option>
  <option value="alllinks">Show All Crystal Links</option>
</xsl:if>
<xsl:if test="$showImages = 'alllinks'">
  <option value="hide">Hide Images</option>
  <option value="selected">Show Selected Images</option>
  <option value="alllinks" selected="true">Show All Crystal Links</option>
</xsl:if>
</select>
</td></tr>
</table>
<br/>

<TABLE>
<tr bgcolor="#6699CC">
<xsl:element name="td">
<xsl:attribute name="colspan"><xsl:value-of select="count(document($displayTemplate)/SilDisplay/*)"/></xsl:attribute>
<xsl:attribute name="align">left</xsl:attribute>
<xsl:text>  </xsl:text><input type="submit" name="command" value="Sample Database" />
<xsl:text>  </xsl:text><input type="submit" name="command" value="Edit Crystal" />
</xsl:element>
</tr>
<TR BGCOLOR="#E9EEF5">
<xsl:call-template name="headers" />
</TR>
<xsl:apply-templates select="Crystal"/>
<xsl:if test="count(Crystal) &gt; 0">
<tr bgcolor="#6699CC"><td colspan="18" align="left">
<xsl:text>  </xsl:text><input type="submit" name="command" value="Sample Database" />
<xsl:text>  </xsl:text><input type="submit" name="command" value="Edit Crystal" />
</td></tr>
</xsl:if>
</TABLE>
</form>

</xsl:template>

<xsl:template match="col">
<TH><xsl:value-of select="@name"/></TH>
</xsl:template>

<xsl:template name="headers">
<xsl:for-each select="document($displayTemplate)/SilDisplay/*">
<TH><xsl:value-of select="name(.)"/></TH>
</xsl:for-each>
</xsl:template>
  
<xsl:template match="Crystal">

<xsl:variable name="thisNode" select="self::node()" />
<xsl:variable name="thisPos" select="position()" />

<xsl:element name="TR">
<xsl:choose>
	<xsl:when test="(position() mod 2) = 0">
		<xsl:attribute name="BGCOLOR">#E9EEF5</xsl:attribute>
	</xsl:when>
	<xsl:otherwise>
		<xsl:attribute name="BGCOLOR">#bed4e7</xsl:attribute>
	</xsl:otherwise>
</xsl:choose>


<xsl:for-each select="document($displayTemplate)/SilDisplay/*">

<xsl:variable name="headerName" select="name(.)" />

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

<xsl:if test="$headerName = 'Rmsr'">
<xsl:call-template name="Rmsr">
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

<xsl:if test="$headerName = 'AutoindexDir'">
<xsl:call-template name="AutoindexDir">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

<xsl:if test="$headerName = 'Move'">
<xsl:call-template name="Move">
	<xsl:with-param name="crystalNode" select="$thisNode"/>
</xsl:call-template>
</xsl:if>

</xsl:for-each>

</xsl:element>

</xsl:template>

<xsl:template name="Row">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="1 + $crystalNode/@row"/></TD>
</xsl:template>

<xsl:template name="Selected">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="$crystalNode/@selected"/></TD>
</xsl:template>

<xsl:template name="Port">
<xsl:param name="crystalNode" select="null"/>
<xsl:choose>
 <xsl:when test="$selectedRow = $crystalNode/@row">
 <TD><nobr><input type="radio" name="row" value="{$crystalNode/@row}" 
 			checked="true" onclick="row_onclick(this)" />
   <xsl:value-of select="$crystalNode/Port"/></nobr></TD>
 </xsl:when>
 <xsl:otherwise>
 <TD><nobr><input type="radio" name="row" value="{$crystalNode/@row}" onclick="row_onclick(this)" />
 		<xsl:value-of select="$crystalNode/Port" /></nobr></TD>
 </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<xsl:template name="ContainerID">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:choose>
    <xsl:when test="string-length($crystalNode/ContainerID)=0"></xsl:when>
    <xsl:otherwise><xsl:value-of select="$crystalNode/ContainerID"/></xsl:otherwise>
  </xsl:choose></TD>
</xsl:template>

<xsl:template name="CrystalID">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:choose>
    <xsl:when test="string-length($crystalNode/CrystalID)=0"></xsl:when>
    <xsl:otherwise><xsl:value-of select="$crystalNode/CrystalID"/></xsl:otherwise>
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
    <xsl:when test="string-length($crystalNode/Directory)=0"></xsl:when>
    <xsl:when test="string($crystalNode/Directory)='/'">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="$crystalNode/Directory"/></xsl:otherwise>
  </xsl:choose></TD>
</xsl:template>

<xsl:template name="AllImages">
<xsl:param name="crystalNode" select="null"/>
  <TD><xsl:apply-templates select="$crystalNode/Images"/></TD>
</xsl:template>

<xsl:template match="Images">
  <xsl:choose>
    <xsl:when test="($selectedRow = ../@row) and ($showImages = 'selected')">
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
		<td><xsl:if test="string-length(Group[@name=1]/Image[position()=last()]/@name) > 0">
		<img src="servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@large}" alt="Image unavailable"/>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=2]/Image[position()=last()]/@name) > 0">
		<img src="servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=2]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@large}" alt="Image unavailable"/>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=3]/Image[position()=last()]/@name) > 0">
		<img src="servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=3]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@large}" alt="Image unavailable"/>
		</xsl:if></td></tr>
		<tr><th>Crystal Jpeg</th>
		<td><xsl:if test="string-length(Group[@name=1]/Image[position()=last()]/@jpeg) > 0">
		<img src="servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@jpeg}" alt="{Group[@name=1]/Image[position()=last()]/@jpeg}"/>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=2]/Image[position()=last()]/@jpeg) > 0">
		<img src="servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@jpeg}" alt="{Group[@name=2]/Image[position()=last()]/@jpeg}"/>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=3]/Image[position()=last()]/@jpeg) > 0">
		<img src="servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@jpeg}" alt="{Group[@name=3]/Image[position()=last()]/@jpeg}"/>
		</xsl:if></td>
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
    <xsl:when test="$showImages='alllinks'">
      <table border="1">
    	<tr><th>Group</th>
    	<td>1</td>
    	<td>2</td>
    	<td>3</td>
    	</tr>
    	<tr><th>Image</th>
		<td><xsl:if test="string-length(Group[@name=1]/Image[position()=last()]/@name) > 0">
		<a style="color:blue" onclick='show_diffimage("servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@large}")'>
		<xsl:value-of select="Group[@name=1]/Image[position()=last()]/@name"/></a>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=2]/Image[position()=last()]/@name) > 0">
		<a style="color:blue" onclick='show_diffimage("servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=2]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@large}")'>
		<xsl:value-of select="Group[@name=2]/Image[position()=last()]/@name"/></a>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=3]/Image[position()=last()]/@name) > 0">
		<a style="color:blue" onclick='show_diffimage("servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=3]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@large}")'>
		<xsl:value-of select="Group[@name=3]/Image[position()=last()]/@name"/></a>
		</xsl:if></td></tr>
		<tr><th>Crystal Jpeg</th>
		<td><xsl:if test="string-length(Group[@name=1]/Image[position()=last()]/@jpeg) > 0">
		<a style="color:blue" onclick='show_xtal("servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=1]/Image[position()=last()]/@dir}/{Group[@name=1]/Image[position()=last()]/@jpeg}")'>
		<xsl:value-of select="Group[@name=1]/Image[position()=last()]/@jpeg"/></a>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=2]/Image[position()=last()]/@jpeg) > 0">
		<a style="color:blue" onclick='show_xtal("servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=2]/Image[position()=last()]/@dir}/{Group[@name=2]/Image[position()=last()]/@jpeg}")'>
		<xsl:value-of select="Group[@name=2]/Image[position()=last()]/@jpeg"/></a>
		</xsl:if></td>
		<td><xsl:if test="string-length(Group[@name=3]/Image[position()=last()]/@jpeg) > 0">
		<a style="color:blue" onclick='show_xtal("servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={Group[@name=3]/Image[position()=last()]/@dir}/{Group[@name=3]/Image[position()=last()]/@jpeg}")'>
		<xsl:value-of select="Group[@name=1]/Image[position()=last()]/@jpeg"/></a>
		</xsl:if></td>
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
		<a style="color:blue" onclick='show_diffimage("servlet/readJpegFile?impSessionID={$accessID}&amp;impUser={$userName}&amp;impFilePath={@dir}/{@large}")'><xsl:value-of select="@name"/></a><br/>
	  </xsl:for-each>
	</xsl:otherwise>
  </xsl:choose>
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
     <xsl:value-of select="format-number($crystalNode/Mosaicity, '0.000')"/>
   </xsl:if>
</TD>
</xsl:template>

<xsl:template name="Rmsr">
<xsl:param name="crystalNode" select="null"/>
 <TD>
   <xsl:if test="number($crystalNode/Rmsr)">
     <xsl:value-of select="format-number($crystalNode/Rmsr, '0.000')"/>
   </xsl:if>
</TD>
</xsl:template>

<xsl:template name="BravaisLattice">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/BravaisLattice), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Resolution">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/Resolution), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="AutoindexDir">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/AutoindexDir), '{}','()')"/></TD>
</xsl:template>

<xsl:template name="Move">
<xsl:param name="crystalNode" select="null"/>
 <TD><xsl:value-of select="translate( string($crystalNode/Move), '{}','()')"/></TD>
</xsl:template>


</xsl:stylesheet>
