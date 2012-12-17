<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" indent="yes"/>

<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:param name="param4"/>
<xsl:param name="param5"/>
<xsl:param name="param6"/>
<xsl:variable name="accessID" select="$param1"/>
<xsl:variable name="owner" select="$param2"/>
<xsl:variable name="row" select="$param3"/>
<xsl:variable name="showImages" select="$param4"/>
<xsl:variable name="displayTemplate" select="$param5"/>
<xsl:variable name="userName" select="$param6"/>

<!--
tranform screening system crystallist XML -> HTML
-->

<xsl:template match="Sil">
<!--<HTML>
<BODY>-->

<form name="silForm" action="handleSilCommand.do" target="_self" method="GET">
<input type="hidden" name="accessID" value="{$accessID}" />
<input type="hidden" name="userName" value="{$owner}" />
<input type="hidden" name="silId" value="{@name}" />

<table class="sil-list">
<tr class="selected"><th colspan="2" align="left">
<!--<xsl:text>  </xsl:text><input style="background-color:yellow;color:black" type="submit" name="command" value="All Cassettes"/>
<xsl:text>  </xsl:text><input style="background-color:yellow;color:black" type="submit" name="command" value="Cassette Summary"/>
<xsl:text>  </xsl:text><input
style="background-color:yellow;color:black" type="submit"
name="command" value="Cassette Details"/> --> 
<xsl:text>  </xsl:text><input class="actionbutton1" type="submit" name="command" value="Set Crystal"/>
</th></tr>
<xsl:apply-templates select="Crystal"/>
</table>
</form>
</xsl:template>

<xsl:template match="Crystal">
<xsl:variable name="ww" select="60"/>
<xsl:if test="@row=$row">
<tr><th>Port</th><td><xsl:value-of select="Port"/></td></tr>
<tr><th>CrystalID</th><td><xsl:choose>
    <xsl:when test="string-length(CrystalID)=0">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string(CrystalID), '{}()[]/\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxxxxxxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose></td></tr>
<tr><th>Protein</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Protein</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Protein), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>Comment</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Comment</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Comment), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>SystemWarning</th><td><xsl:value-of select="translate( string(SystemWarning), '{}','()')"/></td></tr>
<tr><th>Directory</th><td><xsl:choose>
    <xsl:when test="string-length(Directory)=0">null</xsl:when>
    <xsl:when test="string(Directory)='/'">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="translate( string(Directory), '{}()[]\;:-*,?&#36;&amp;&quot;&lt;&gt;','xxxxxx/xxxxxxxxxxx')"/></xsl:otherwise>
  </xsl:choose></td></tr>
<tr><th>FreezingCond</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">FreezingCond</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(FreezingCond), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>CrystalCond</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">CrystalCond</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(CrystalCond), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>Metal</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Metal</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Metal), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>Priority</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Priority</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Priority), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>Person</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Person</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Person), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>CrystalURL</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">CrystalURL</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(CrystalURL), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th>ProteinURL</th><td><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">ProteinURL</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(ProteinURL), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
</xsl:if>

</xsl:template>

</xsl:stylesheet>
