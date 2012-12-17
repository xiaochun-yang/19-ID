<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                   version="1.0"
                   xmlns:xalan="http://xml.apache.org/xalan"
                   exclude-result-prefixes="xalan">

<xsl:output method="html" indent="yes"/>

<xsl:template match="labelit">

<xsl:choose>
<xsl:when test="count(error) >= 1">
<p style="color:red"><xsl:value-of select="error"/></p>
</xsl:when>
<xsl:otherwise>


<form action="Autoindex_IntegrateAdditionalSolutions.do" target="_self" method="post">
<table cellspacing="1" border="1" width="100%" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00"><th colspan="3" align="left">3.Integrate Other Solutions</th></tr>
<tr bgcolor="#FFEE77"><th>Solution</th><th colspan="2">Crystal System</th></tr>

<xsl:apply-templates select="indexing"/>

<xsl:choose>
<xsl:when test="count(integration/solution[@integrated = 'true']) = count(indexing/solution)">
<tr><td colspan="3" align="center"><input class="actionbutton1" type="submit" value="Integrate" disabled="true"/></td></tr>
</xsl:when>
<xsl:otherwise>
<tr><td colspan="3" align="center"><input class="actionbutton1" type="submit" value="Integrate" /></td></tr>
</xsl:otherwise>
</xsl:choose>
</table>
</form>

</xsl:otherwise>
</xsl:choose>


</xsl:template>

<xsl:template match="indexing">
<xsl:apply-templates select="solution">
<xsl:sort select="@number" order="descending" data-type="number" />
</xsl:apply-templates>
</xsl:template>

<xsl:template match="solution">
<xsl:variable name="solNum" select="@number"/>
<tr>
<td align="center">
<xsl:choose>
<xsl:when test="count(/labelit/integration/solution[@number=$solNum and @integrated = 'true']) = 1">
<input type="checkbox" name="{@number}" disabled="true" />
</xsl:when>
<xsl:otherwise>
<input type="checkbox" name="{$solNum}" />
</xsl:otherwise>
</xsl:choose>
 <xsl:value-of select="@number"/></td>
<td align="center"><xsl:value-of select="@crystalSystem"/></td>
<td align="center"><xsl:value-of select="@lattice"/></td>
</tr>
</xsl:template>

</xsl:stylesheet>
