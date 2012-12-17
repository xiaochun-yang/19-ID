<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rs="urn:schemas-microsoft-com:rowset" 
	xmlns:z="#RowsetSchema"
	version="1.0">

<!--
transform ADO recordests from ADO-XML Persistence Format -> more simpler XML format:
<Data>
<Row number="1"><col1>val1</col1><col2>val2</col2>...</Row>
<Row number="2"><col1>val1</col1><col2>val2</col2>...</Row>
...
</Data>

for ADO - XML persistent format see:
MDAC Technical Article
Saving ADO Recordsets in XML Format
January 2000
By Kamaljit Bath and Dax Hawkins
http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wp/htm/wp_xmlxsltrans.asp
-->

   <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
   <xsl:param name="param1"/>
  
  <xsl:template match="/">
	<xsl:element name="Data">
		<xsl:apply-templates select="*"/>
	</xsl:element>
  </xsl:template>
  
  <xsl:template match="rs:data/z:row">
	<xsl:element name="Row">
  		<xsl:attribute name="number"><xsl:value-of select="position()+1"/></xsl:attribute>
		<xsl:for-each select="@*">
			<xsl:element name="{name(.)}">
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:for-each>
	</xsl:element>
  </xsl:template>

</xsl:stylesheet>
