<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" indent="yes"/>

<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:variable name="displayTemplate" select="$param1"/>
<xsl:variable name="sortColumn" select="$param2"/>
<xsl:variable name="sortOrder" select="$param3"/>
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
<Sil>
<!-- List crystals sorted by values in a given column. Skip the crystals whose value of the selected column is empty. -->
<xsl:choose>
<xsl:when test="$sortColumn = 'Rmsd'">
<xsl:for-each select="Crystal">
  <xsl:sort select="*[name()='Rmsr']" order="{$sortOrder}" data-type="{$sortType}"/>
  <xsl:if test="*[name()='Rmsr'][string-length(text()) != 0 and text() != 'N/A']">
    <xsl:copy-of select="."/>
  </xsl:if>
</xsl:for-each>
</xsl:when>
<xsl:when test="$sortColumn = 'Port'">
<xsl:for-each select="Crystal">
  <xsl:sort select="@row" order="{$sortOrder}" data-type="number"/>
  <xsl:if test="*[name()=$sortColumn][string-length(text()) != 0 and text() != 'N/A']">
    <xsl:copy-of select="."/>
  </xsl:if>
</xsl:for-each>
</xsl:when>
<xsl:otherwise>
<xsl:for-each select="Crystal">
  <xsl:sort select="*[name()=$sortColumn]" order="{$sortOrder}" data-type="{$sortType}"/>
  <xsl:if test="*[name()=$sortColumn][string-length(text()) != 0 and text() != 'N/A']">
    <xsl:copy-of select="."/>
  </xsl:if>
</xsl:for-each>
</xsl:otherwise>
</xsl:choose>
<!-- List crystals whose value of the selected column is empty. -->
<xsl:choose>
<xsl:when test="$sortColumn = 'Rmsd'">
  <xsl:for-each select="Crystal">
    <xsl:if test="*[name()='Rmsr'][string-length(text()) = 0 or text() = 'N/A']">
      <xsl:copy-of select="."/>
    </xsl:if>
  </xsl:for-each>
</xsl:when>
<xsl:otherwise>
  <xsl:for-each select="Crystal">
    <xsl:if test="*[name()=$sortColumn][string-length(text()) = 0 or text() = 'N/A']">
      <xsl:copy-of select="."/>
    </xsl:if>
  </xsl:for-each>
</xsl:otherwise>
</xsl:choose>
</Sil>
</xsl:template>

</xsl:stylesheet>
