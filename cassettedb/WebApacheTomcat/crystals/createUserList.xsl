<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                   version="1.0">
<xsl:output method="html" indent="yes"/>
<xsl:param name="param1"/>
<xsl:param name="param2"/>

<!-- createUserList.xsl
used by CassetteInfo.jsp
transform a XML user-list into an HTML dropdown list
-->

<xsl:variable name="selectedUserID" select="$param1"/>
<xsl:variable name="hasStaffPrivilege" select="$param2"/>

<!--
tranform userList XML -> HTML-OPTION list
-->
<xsl:template match="/">
    <xsl:if test="'false'=$hasStaffPrivilege">
        <xsl:value-of select="//Row[UserID=$selectedUserID]/LoginName"/>
    </xsl:if>
    <xsl:if test="'true'=$hasStaffPrivilege">
	<!--SELECT-->
	<xsl:element name="SELECT">
		<xsl:attribute name="id">user</xsl:attribute>
		<xsl:attribute name="name">user</xsl:attribute>
		<xsl:attribute name="onchange">
			<xsl:text>user_onchange()</xsl:text>
		</xsl:attribute>
		<xsl:if test="'false'=$hasStaffPrivilege">
			<xsl:attribute name="disabled">1</xsl:attribute>
			<xsl:attribute name="onfocus">this.blur()</xsl:attribute>
 		</xsl:if>
	<xsl:apply-templates select="*"/>
	<xsl:text> 
	</xsl:text>
	</xsl:element>
	<xsl:text> 
	</xsl:text>
	<!--SELECT-->
    </xsl:if>
</xsl:template>

<xsl:template match="Row">
		<xsl:text> 
		</xsl:text>
		<!--OPTION-->
		<xsl:element name="OPTION">
			<xsl:attribute name="value"><xsl:value-of select="UserID"/></xsl:attribute>
			<xsl:if test="UserID=$selectedUserID">
				<xsl:attribute name="selected"></xsl:attribute>
			</xsl:if>
			<xsl:value-of select="LoginName"/>
		</xsl:element>
		<!--OPTION-->
		<xsl:text> 
		</xsl:text>
</xsl:template>


</xsl:stylesheet>
