<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                   version="1.0"
                   xmlns:xalan="http://xml.apache.org/xalan"
                   exclude-result-prefixes="xalan">
<!--
createBeamlineTable.xsl
used by BeamlineInfo.jsp
tranform cassette list XML -> HTML-Table
-->

<xsl:output method="html" indent="yes"/>
<xsl:param name="param1"/>
<xsl:variable name="hasStaffPrivilege" select="$param1"/>

<xsl:template match="/">

<TABLE>
  <TR BGCOLOR="#E9EEF5">
	<TH>Beamline</TH>
	<TH>Position</TH>
	<TH>User</TH>
	<TH colspan="2">Cassette</TH>
  </TR>
<!--
use select "//Row" to avoid whitespace problems with position() in apache parser 
	<xsl:apply-templates select="*"/>
-->
	<xsl:apply-templates select="//Row[BeamLineName!='None']"/>
</TABLE>

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
<TD>
    <xsl:value-of select="BeamLineName"/>
    <xsl:text> </xsl:text>
</TD>
<TD>
	<xsl:value-of select="BeamLinePosition"/>
</TD>
<TD>
    <xsl:if test="CassetteID!='null'">
	<xsl:value-of select="UserName"/>
    </xsl:if>
    <xsl:text>  </xsl:text>
</TD>
<TD>
    <xsl:if test="CassetteID!='null'">
	<xsl:value-of select="CassetteID"/>
	<xsl:text> </xsl:text>
      <xsl:if test="Pin!='null'">
	  <xsl:value-of select="Pin"/>
      </xsl:if>
      <xsl:text> - </xsl:text>
	<xsl:value-of select="UploadFileName"/>
	<xsl:text> </xsl:text>
	<xsl:value-of select="UploadTime"/>
    </xsl:if>
    <xsl:text> </xsl:text>
 </TD>

 <xsl:if test="'true'=$hasStaffPrivilege">
 <TD>
    <xsl:if test="CassetteID!='null'">
	<xsl:call-template name="uploadButton">
		<xsl:with-param name="cassetteID" select="CassetteID"/>
	</xsl:call-template>
    </xsl:if>
 </TD>
</xsl:if>

</xsl:element>
</xsl:template>

<!--
create upload button
-->
<xsl:template name="uploadButton">
<xsl:param name="cassetteID"/>
	<xsl:element name="INPUT">
		<xsl:attribute name="type">button</xsl:attribute>
		<xsl:attribute name="value">Remove</xsl:attribute>
		<xsl:attribute name="class">clsButton</xsl:attribute>
		<xsl:attribute name="onclick">
			<xsl:text>remove_onclick(</xsl:text>
			<xsl:value-of select="CassetteID"/>
			<xsl:text>)</xsl:text>
		</xsl:attribute>
	</xsl:element>

<!--		
	<xsl:element name="A">
		<xsl:attribute name="class">clsButtonX</xsl:attribute>
		<xsl:attribute name="href">
			<xsl:copy-of select="$uploadURL"/>
			<xsl:text>forCassetteID=</xsl:text>
			<xsl:value-of select="$cassetteID"/>
		</xsl:attribute>
		<xsl:text>Upload New...</xsl:text>
	</xsl:element>

        <A class="clsButtonX" href="{$uploadURL}forCassetteID={$cassetteID}">
		<xsl:text>Upload New...</xsl:text>
	</A>

	<INPUT type="button" value="qwer" name="xsq" />
-->
</xsl:template>


</xsl:stylesheet>
