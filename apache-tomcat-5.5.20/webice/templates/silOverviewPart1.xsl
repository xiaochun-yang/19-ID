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
<xsl:variable name="accessID" select="$param1"/>
<xsl:variable name="owner" select="$param2"/>
<xsl:variable name="showImages" select="$param3"/>
<xsl:variable name="displayTemplate" select="$param4"/>
<xsl:variable name="userName" select="$param5"/>
<xsl:variable name="numRows" select="$param6"/>
<xsl:variable name="selectedRow" select="$param7"/>
<xsl:variable name="isAnalyzing" select="$param8"/>
<xsl:variable name="isCrystalMounted" select="$param9"/>


<xsl:template match="Sil">

<input type="hidden" name="accessID" value="{$accessID}" />
<input type="hidden" name="userName" value="{$owner}" />
<input type="hidden" name="silId" value="{@name}" />

<table border="1">
<tr>
<th align="center" bgcolor="#bed4e7">Owner</th>
<th align="center" bgcolor="#bed4e7">Sample Information ID</th>
<th align="center" bgcolor="#bed4e7">Column Display Options</th>
<th align="center" bgcolor="#bed4e7">Image Display Options</th>
</tr>
<tr>
<td align="center" bgcolor="#E9EEF5"><xsl:value-of select="$owner"/></td>
<td align="center" bgcolor="#E9EEF5"><xsl:value-of select="@name"/></td>
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
</xsl:if><xsl:if test="contains($displayTemplate,'display_result')">
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
</xsl:if><xsl:if test="contains($displayTemplate,'bcsb_screening_view')">
  <option value="bcsb_screening_view" selected="true">BCSB Screening View</option>
</xsl:if>
<xsl:if test="not(contains($displayTemplate,'bcsb_screening_view'))">
  <option value="bcsb_screening_view">BCSB Screening View</option>
</xsl:if>
</select>
</td>
<td align="center">
<select name="showImages" onchange="option_onchange()">
<xsl:if test="$showImages = 'hide'">
  <option value="hide" selected="true">Hide Images</option>
  <option value="show">Show Selected Images</option>
  <option value="link">Show All Crystal Links</option>
</xsl:if>
<xsl:if test="$showImages = 'show'">
  <option value="hide">Hide Images</option>
  <option value="show" selected="true">Show Selected Images</option>
  <option value="link">Show All Crystal Links</option>
</xsl:if>
<xsl:if test="$showImages = 'link'">
  <option value="hide">Hide Images</option>
  <option value="show">Show Selected Images</option>
  <option value="link" selected="true">Show All Crystal Links</option>
</xsl:if>
</select>
</td>
</tr>
</table>
<br/>
<TABLE width="100%">
<tr bgcolor="#6699CC"><td colspan="16" align="left">
<xsl:text>  </xsl:text><input style="background-color:yellow;color:black" type="submit" name="command" value="All Cassettes"/>
<xsl:text>  </xsl:text><input style="background-color:yellow;color:black" type="submit" name="command" value="Cassette Details"/>
<xsl:text>  </xsl:text><input type="submit" name="command" value="Refresh"/>
<xsl:choose>
<xsl:when test="@lock = 'true'">
<xsl:text>  </xsl:text><input type="submit" value="Edit Crystal" disabled="true" />
<xsl:text>  </xsl:text><input type="submit" value="Analyze Crystal" disabled="true" />
</xsl:when>
<xsl:otherwise>
<xsl:text>  </xsl:text><input type="submit" name="command" value="Edit Crystal"/>
<xsl:choose>
<xsl:when test="$isAnalyzing = 'true'">
<xsl:text>  </xsl:text><input type="submit" name="command" value="Analyze Crystal" disabled="true"/>
</xsl:when>
<xsl:otherwise>
<xsl:text>  </xsl:text><input type="submit" name="command" value="Analyze Crystal" />
</xsl:otherwise>
</xsl:choose>
</xsl:otherwise>
</xsl:choose>
<xsl:text>  </xsl:text>
<xsl:element name="input">
  <xsl:attribute name="type">text</xsl:attribute>
  <xsl:attribute name="disable">yes</xsl:attribute>
  <xsl:attribute name="readonly">yes</xsl:attribute>
  <xsl:attribute name="style">color:black;font:bold;text-align:center</xsl:attribute>
  <xsl:attribute name="size">3</xsl:attribute>
  <xsl:attribute name="value"><xsl:value-of select="Crystal[@row=$selectedRow]/Port" />
  </xsl:attribute>
</xsl:element>
</td>
</tr>

</TABLE>

</xsl:template>

  
</xsl:stylesheet>
