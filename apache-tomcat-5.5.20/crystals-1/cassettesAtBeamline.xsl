<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" indent="yes"/>

<!--
tranform CassettesAtBeamline XML -> cassette list TCL
-->

<xsl:template match="/">{<xsl:apply-templates select="*"/>}</xsl:template>

<xsl:template match="Row">
<xsl:choose>
	<xsl:when test="string(FileID)='null'">undefined </xsl:when>
    <xsl:otherwise>
		<!--
		<xsl:value-of select="substring(UploadFileName,0,string-length(UploadFileName)-3)"/>
		-->
		<xsl:value-of select="UploadFileName"/>
		<xsl:text>(</xsl:text>
		<xsl:value-of select="translate( string(UserName), '{}','()')"/>
		<xsl:text>|</xsl:text>
		<xsl:value-of select="translate( string(Pin), '{}','()')"/>
		<xsl:text>|</xsl:text>
		<xsl:value-of select="translate( string(CassetteID), '{}','()')"/>
		<xsl:text>) </xsl:text>
	</xsl:otherwise>
</xsl:choose>
</xsl:template>

</xsl:stylesheet>
