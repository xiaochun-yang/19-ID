<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" indent="yes"/>

<xsl:param name="param1"/>
<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:param name="param4"/>
<xsl:param name="param5"/>
<xsl:param name="param6"/>
<xsl:variable name="accessID" select="$param1"/>
<xsl:variable name="userName" select="$param2"/>
<xsl:variable name="silFile" select="$param3"/>
<xsl:variable name="row" select="$param4"/>
<xsl:variable name="displayType" select="$param5"/>
<xsl:variable name="showImages" select="$param6"/>

<!--
tranform screening system crystallist XML -> HTML
-->

<xsl:template match="Sil">
<HTML>
<BODY>

<table border="1">
<tr><th bgcolor="#bed4e7">User Name</th><th bgcolor="#bed4e7">Sample Information ID</th><th bgcolor="#bed4e7">Locked</th></tr>
<tr><td bgcolor="#E9EEF5"><xsl:value-of select="$userName"/></td>
<td bgcolor="#E9EEF5"><xsl:value-of select="@name"/></td>
<td bgcolor="#E9EEF5"><xsl:value-of select="@lock"/></td></tr>
</table>

<br />
<form action="setCrystal1.jsp" target="_self" method="POST">
<input type="hidden" name="accessID" value="{$accessID}" />
<input type="hidden" name="userName" value="{$userName}" />
<input type="hidden" name="silId" value="{@name}" />
<input type="hidden" name="silFile" value="{$silFile}" />
<input type="hidden" name="row" value="{$row}" />
<input type="hidden" name="displayType" value="{$displayType}" />
<input type="hidden" name="showImages" value="{$showImages}" />

<TABLE border="1">
<tr bgcolor="#6699CC"><td colspan="2" align="left">
<input type="Submit" name="command" value="Save Changes" /><xsl:text>  </xsl:text>
<input type="Submit" name="command" value="Cancel" />
</td></tr>
<xsl:apply-templates select="Crystal"/>

</TABLE>

</form>
</BODY>
</HTML>
</xsl:template>
  
<xsl:template match="Crystal">
<xsl:variable name="ww" select="60"/>
<xsl:if test="@row=$row">
<tr><th bgcolor="#bed4e7">Port</th><td bgcolor="#E9EEF5"><xsl:value-of select="Port"/></td></tr>
<tr><th bgcolor="#bed4e7">CrystalID</th><td bgcolor="#E9EEF5"><xsl:choose>
    <xsl:when test="string-length(CrystalID)=0">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="CrystalID"/></xsl:otherwise>
  </xsl:choose></td></tr>
<tr><th bgcolor="#bed4e7">Protein</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Protein</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Protein), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr bgcolor="#E9EEF5"><th bgcolor="#bed4e7">Comment</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Comment</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Comment), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th bgcolor="#bed4e7">SystemWarning</th><td bgcolor="#E9EEF5"><xsl:value-of select="translate( string(SystemWarning), '{}','()')"/></td></tr>
<tr><th bgcolor="#bed4e7">Directory</th><td><xsl:choose>
    <xsl:when test="string-length(Directory)=0">null</xsl:when>
    <xsl:when test="string(Directory)='/'">null</xsl:when>
    <xsl:otherwise><xsl:value-of select="Directory"/></xsl:otherwise>
  </xsl:choose></td></tr>
<tr><th bgcolor="#bed4e7">FreezingCond</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">FreezingCond</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(FreezingCond), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th bgcolor="#bed4e7">CrystalCond</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">CrystalCond</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(CrystalCond), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th bgcolor="#bed4e7">Metal</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Metal</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Metal), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th bgcolor="#bed4e7">Priority</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Priority</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Priority), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th bgcolor="#bed4e7">Person</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">Person</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(Person), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th bgcolor="#bed4e7">CrystalURL</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">CrystalURL</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(CrystalURL), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>
<tr><th bgcolor="#bed4e7">ProteinURL</th><td bgcolor="#E9EEF5"><xsl:element name="input">
	<xsl:attribute name="type">text</xsl:attribute>
	<xsl:attribute name="size"><xsl:value-of select="$ww"/></xsl:attribute>
	<xsl:attribute name="name">ProteinURL</xsl:attribute>
	<xsl:attribute name="value"><xsl:value-of select="translate( string(ProteinURL), '{}','()')"/></xsl:attribute>
</xsl:element></td></tr>

</xsl:if>

</xsl:template>


</xsl:stylesheet>
