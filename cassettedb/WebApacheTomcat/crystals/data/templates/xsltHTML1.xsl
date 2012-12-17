<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" indent="yes"/>
<xsl:param name="param1"/>

<!--
tranform screening system crystallist XML -> HTML
-->
  
<xsl:template match="/">
<HTML>
<BODY>

<TABLE>
<TR BGCOLOR="#E9EEF5">
<TH>Port</TH>
<TH>ID</TH>
<TH>Protein</TH>
<TH>Comment</TH>
<TH>Directory</TH>
<TH>FreezingCond</TH>
<TH>CrystalCond</TH>
<TH>Metal</TH>
<TH>Priority</TH>
<TH>Person</TH>
<TH>CrystalURL</TH>
<TH>ProteinURL</TH>
</TR>
<!--
	<xsl:apply-templates select="*"/>
-->
	<xsl:apply-templates select="*"/>
</TABLE>

</BODY>
</HTML>
</xsl:template>
  
<xsl:template match="Row">
<xsl:element name="TR">
<xsl:choose>
	<xsl:when test="(position() mod 2) = 0">
		<xsl:attribute name="BGCOLOR">#E9EEF5</xsl:attribute>
	</xsl:when>
	<xsl:otherwise>
		<xsl:attribute name="BGCOLOR">#bed4e7</xsl:attribute>
	</xsl:otherwise>
</xsl:choose>
 
 <TD><xsl:value-of select="Port"/></TD>
 <TD><xsl:choose>
    <xsl:when test="string-length(CrystalID)=0">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string(CrystalID), '{}()[]/\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxxxxxxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose></TD>
 <TD><xsl:value-of select="translate( string(Protein), '{}','()')"/></TD>
 <TD><xsl:value-of select="translate( string(Comment), '{}','()')"/></TD>
 <TD><xsl:choose>
    <xsl:when test="string-length(Directory)=0">null</xsl:when>
    <xsl:when test="string(Directory)='/'">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string(Directory), '{}()[]\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxx/xxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose></TD>
 <TD><xsl:value-of select="translate( string(FreezingCond), '{}','()')"/></TD>
 <TD><xsl:value-of select="translate( string(CrystalCond), '{}','()')"/></TD>
 <TD><xsl:value-of select="translate( string(Metal), '{}','()')"/></TD>
 <TD><xsl:value-of select="translate( string(Priority), '{}','()')"/></TD>
 <TD><xsl:value-of select="translate( string(Person), '{}','()')"/></TD>
 <TD><xsl:value-of select="translate( string(CrystalURL), '{}','()')"/></TD>
 <TD><xsl:value-of select="translate( string(ProteinURL), '{}','()')"/></TD>
</xsl:element>
</xsl:template>

<!--
{A Port 4}
{B ID 6}
{C Comment 18}
{D Protein 8}
{E FreezingCond 8}
{F CrystalCond 8}
{G Metal 5}
{H Priority 8}
{I Order 5}
{J Directory 25}
-->

</xsl:stylesheet>
