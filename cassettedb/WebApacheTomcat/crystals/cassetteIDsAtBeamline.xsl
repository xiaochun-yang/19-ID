<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" indent="yes"/>

<!--
tranform CassettesAtBeamline XML -> cassette ID list TCL
-->

<!--
<xsl:template match="/">{<xsl:apply-templates select="*"/>}</xsl:template>
-->

<xsl:template match="Row">
	<xsl:value-of select="CassetteID"/>
</xsl:template>

</xsl:stylesheet>
