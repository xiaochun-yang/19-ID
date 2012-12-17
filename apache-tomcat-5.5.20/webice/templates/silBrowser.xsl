<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" indent="yes"/>

<xsl:template match="Sil">
<CrystalList>
<xsl:apply-templates select="Crystal"/>
</CrystalList>
</xsl:template>

<xsl:template match="Crystal">
<xsl:element name="Crystal">
	<xsl:attribute name="port"><xsl:value-of select="Port"/></xsl:attribute>
	<xsl:attribute name="hasImage">
		<xsl:choose>
			<xsl:when test="string-length(Images/Group/Image/@name) &gt; 0">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:attribute>
</xsl:element>
</xsl:template>

</xsl:stylesheet>
