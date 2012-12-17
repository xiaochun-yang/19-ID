<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" indent="yes"/>
<xsl:param name="param1"/>

<!--
tranform screening system crystallist XML -> tcl list
-->
  
<xsl:template match="/">
{
	<xsl:apply-templates select="*"/>
}
</xsl:template>
  
<xsl:template match="Row">
{
 {<xsl:value-of select="Port"/>}
 {<xsl:choose>
    <xsl:when test="string-length(CrystalID)=0">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string(CrystalID), '{}()[]/\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxxxxxxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose>}
 {<xsl:value-of select="translate( string(Protein), '{}','()')"/>}
 {<xsl:value-of select="translate( string(Comment), '{}','()')"/>}
 {<xsl:choose>
    <xsl:when test="string-length(Directory)=0">null</xsl:when>
    <xsl:when test="string(Directory)='/'">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string(Directory), '{}()[]\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxx/xxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose>}
 {<xsl:value-of select="translate( string(FreezingCond), '{}','()')"/>}
 {<xsl:value-of select="translate( string(CrystalCond), '{}','()')"/>}
 {<xsl:value-of select="translate( string(Metal), '{}','()')"/>}
 {<xsl:value-of select="translate( string(Priority), '{}','()')"/>}
 {<xsl:value-of select="translate( string(Person), '{}','()')"/>}
 {<xsl:value-of select="translate( string(CrystalURL), '{}','()')"/>}
 {<xsl:value-of select="translate( string(ProteinURL), '{}','()')"/>}
 }
</xsl:template>

<!--
{A Port 4}
{B ID 6}
{C Comment 18}
{D Protein 8}
{E FreezingCond 8}
{F CrystalCond 8}
{G Metal 5}
{H Person 8}
{I Order 5}
{J Directory 25}
-->

</xsl:stylesheet>
