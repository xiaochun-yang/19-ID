<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" indent="yes"/>

<xsl:param name="param1"/>
<xsl:variable name="row" select="$param1"/>

<xsl:template match="Sil">
<xsl:copy-of select="Crystal[@row=$row]"/>
</xsl:template>
</xsl:stylesheet>
