<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                   version="1.0"
                   xmlns:xalan="http://xml.apache.org/xalan"
                   exclude-result-prefixes="xalan">
<!--
createTable.xsl
used by CassetteInfo.jsp
tranform cassette list XML -> HTML-Table
-->

<xsl:output method="html" indent="yes"/>
<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:param name="param4"/>
<xsl:variable name="getCassetteURL" select="$param1"/>
<xsl:variable name="uploadURL" select="$param2"/>
<xsl:variable name="deleteCassetteURL" select="$param3"/>
<xsl:variable name="beamlineListURL" select="$param4"/>

<xsl:template match="/">

<TABLE>
  <TR BGCOLOR="#E9EEF5">
	<TH colspan="5" align="left">Excel Spreadsheet</TH>
	<TH align="left">Beamline</TH>
  </TR>
<!--
use select "//Row" to avoid whitespace problems with position() in apache parser 
	<xsl:apply-templates select="*"/>
-->
	<xsl:apply-templates select="//Row"/>
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
	<xsl:value-of select="CassetteID"/>
	<xsl:text> </xsl:text>
	
	<xsl:choose>
		<xsl:when test="string(UploadFileName)='null' ">None</xsl:when>
	    <xsl:otherwise>
			<xsl:value-of select="UploadFileName"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="UploadTime"/>
	    </xsl:otherwise>
	</xsl:choose>



 </TD>
 <TD>
	<A class="clsLinkX" href="{$getCassetteURL}{FileName}.html">
		<xsl:text>View</xsl:text>
	</A>
	<xsl:text>  </xsl:text>
 </TD>
 <TD>
	
	<A class="clsLinkX" href="{$getCassetteURL}{FileName}_src.xls">
		<xsl:text>Download Excel file</xsl:text>
	</A>
	<xsl:text>  </xsl:text>
 </TD>
 <TD>
	
	<xsl:call-template name="uploadButton">
		<xsl:with-param name="cassetteID" select="CassetteID"/>
	</xsl:call-template>
	<xsl:text>  </xsl:text>
 </TD>
 <TD>
	
	<xsl:call-template name="deleteCassetteButton">
		<xsl:with-param name="cassetteID" select="CassetteID"/>
	</xsl:call-template>
 </TD>
 <TD>
	<xsl:call-template name="BeamLineList">
		<xsl:with-param name="cassetteID" select="CassetteID"/>
		<xsl:with-param name="selectedBeamLine" select="BeamLineID"/>
	</xsl:call-template>
 </TD>
</xsl:element>
</xsl:template>

<!--
create elements of dropdown list
-->
<xsl:template name="BeamLineList">
<xsl:param name="cassetteID"/>
<xsl:param name="selectedBeamLine"/>

<xsl:variable name="dropdownID">
<xsl:text>beamline</xsl:text>
<xsl:value-of select="$cassetteID"/>
</xsl:variable>

	<!--SELECT-->
	<xsl:element name="SELECT">
		<xsl:attribute name="id"><xsl:value-of select="$dropdownID"/></xsl:attribute>
		<xsl:attribute name="name"><xsl:value-of select="$dropdownID"/></xsl:attribute>
		<xsl:attribute name="onchange">
			<xsl:text>beamline_onchange("</xsl:text>
			<xsl:value-of select="$dropdownID"/>
			<xsl:text>",</xsl:text>
			<xsl:value-of select="$cassetteID"/>
			<xsl:text>)</xsl:text>
		</xsl:attribute>
	<xsl:for-each select="document($beamlineListURL)//Beamlines/BeamLine">
		<xsl:text> </xsl:text>
		<!--OPTION-->
		<xsl:element name="OPTION">
			<xsl:attribute name="value"><xsl:value-of select="@bid"/></xsl:attribute>
			<xsl:if test="@bid=$selectedBeamLine">
				<xsl:attribute name="selected"></xsl:attribute>
			</xsl:if>
			<xsl:value-of select="."/>
		</xsl:element>
		<!--OPTION-->
	</xsl:for-each>
	<xsl:text> 
	</xsl:text>
	</xsl:element>
	<xsl:text> 
	</xsl:text>
	<!--SELECT-->
</xsl:template>

<!--
create upload button
-->
<xsl:template name="uploadButton">
<xsl:param name="cassetteID"/>
	<xsl:element name="A">
		<xsl:attribute name="href">
			<xsl:copy-of select="$uploadURL"/>
			<xsl:text>forCassetteID=</xsl:text>
			<xsl:value-of select="$cassetteID"/>
		</xsl:attribute>
		<xsl:text>Upload new file</xsl:text>
	</xsl:element>

</xsl:template>


<!--
create deleteCassette button
-->
<xsl:template name="deleteCassetteButton">
<xsl:param name="cassetteID"/>
	<xsl:element name="A">
		<xsl:attribute name="href">
			<xsl:copy-of select="$deleteCassetteURL"/>
			<xsl:text>forCassetteID=</xsl:text>
			<xsl:value-of select="$cassetteID"/>
		</xsl:attribute>
		<xsl:text>Delete entry</xsl:text>
	</xsl:element>

</xsl:template>

</xsl:stylesheet>
