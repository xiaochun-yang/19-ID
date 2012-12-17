<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text"/>
<xsl:template match="Sil">
<xsl:value-of select="@lock"/>
</xsl:template>
</xsl:stylesheet>