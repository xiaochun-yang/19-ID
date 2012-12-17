<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                   version="1.0"
                   xmlns:xalan="http://xml.apache.org/xalan"
                   exclude-result-prefixes="xalan">

<xsl:output method="html" indent="yes"/>
<xsl:param name="param1"/>
<xsl:param name="param2"/>
<xsl:param name="param3"/>
<xsl:param name="param4"/>
<xsl:param name="param5"/>
<xsl:param name="param6"/>
<xsl:param name="param7"/>
<xsl:param name="param8"/>
<xsl:param name="param9"/>
<xsl:param name="param10"/>
<xsl:param name="param11"/>
<xsl:param name="param12"/>
<xsl:variable name="owner" select="$param1"/>
<xsl:variable name="sessionId" select="$param2"/>
<xsl:variable name="downloadSilUrl" select="$param3"/>
<xsl:variable name="crystalsUrl" select="$param4"/>
<xsl:variable name="screeningSilId" select="$param5"/>
<xsl:variable name="screeningCassetteStr" select="$param6"/>
<xsl:variable name="row" select="$param7"/>
<xsl:variable name="screeningSilOwner" select="$param8"/>
<xsl:variable name="selectedSilId" select="$param9"/>
<xsl:variable name="sortColumn" select="$param10"/>
<xsl:variable name="sortDirection" select="$param11"/>
<xsl:variable name="sortType" select="$param12"/>

<xsl:template match="CassetteFileList">

<TABLE class="sil-list">
<tr>
<th><a href="setSilDisplayMode.do?sortDirection={$sortDirection}&amp;mode=allSils&amp;sortColumn=CassetteID&amp;sortType=number" target="_parent">SIL ID</a></th>
<th><a href="setSilDisplayMode.do?sortDirection={$sortDirection}&amp;mode=allSils&amp;sortColumn=UploadFileName&amp;sortType=text" target="_parent">Uploaded Spreadsheet</a></th>
<th>Upload Time</th>
<th colspan="4">Commands</th>
</tr>
<!--
use select "//Row" to avoid whitespace problems with position() in apache parser 
	<xsl:apply-templates select="*"/>
-->
	<xsl:for-each select="*">
	<xsl:sort select="*[name()=$sortColumn]" order="{$sortDirection}" data-type="{$sortType}" />
	<xsl:apply-templates select="."/>
	</xsl:for-each>
</TABLE>

<br/>
<a href="{$crystalsUrl}" target="_blank">Upload new spreadsheet.</a>

</xsl:template>

<xsl:template match="Row">
<xsl:element name="TR">
<xsl:choose>
	<xsl:when test="$selectedSilId != '' and $selectedSilId = CassetteID">
		<xsl:attribute name="class">selected</xsl:attribute>
	</xsl:when>
	<xsl:otherwise>
		<xsl:attribute name="class">unselected</xsl:attribute>
	</xsl:otherwise>
</xsl:choose>
 <TD>
	<xsl:value-of select="CassetteID"/>
</TD>
<TD>
	<xsl:choose>
		<xsl:when test="string(UploadFileName)='null' ">None<td></td></xsl:when>
	    <xsl:otherwise>
			<xsl:value-of select="UploadFileName"/>
			<td><xsl:value-of select="UploadTime"/></td>
	    </xsl:otherwise>
	</xsl:choose>



 </TD>
 <TD><a target="_parent" href="setSilDisplayMode.do?silId={CassetteID}&amp;mode=silOverview&amp;owner={$owner}">Summary</a></TD>
 <TD><a target="_parent" href="setSilDisplayMode.do?silId={CassetteID}&amp;mode=silDetails&amp;owner={$owner}">Details</a></TD>
 <TD>
	<A class="clsLinkX" href="{$downloadSilUrl}/{UploadFileName}?accessID={$sessionId}&amp;userName={$owner}&amp;silId={CassetteID}" target="_self">
		<xsl:text>Download Results</xsl:text>
	</A>
	<xsl:text>  </xsl:text>
 </TD>
 <TD>
	<A class="clsLinkX" href="sil_deleteCassette.do?silId={CassetteID}" target="_self">
		<xsl:text>Delete</xsl:text>
	</A>
	<xsl:text>  </xsl:text>
 </TD>
</xsl:element>
</xsl:template>

</xsl:stylesheet>
