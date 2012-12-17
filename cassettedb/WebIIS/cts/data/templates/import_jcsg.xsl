<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">

<!--
tranform JSCG excel-xml -> screening system crystallist XML
-->

   <xsl:output method="xml" indent="yes"/>
   <xsl:param name="param1"/>
  
  <xsl:template match="/">
	<CrystalData>
	<xsl:apply-templates select="*"/>
	</CrystalData>
  </xsl:template>
  
  <xsl:template match="Row">
  	<Row>
  		<xsl:attribute name="number"><xsl:value-of select="@number"/></xsl:attribute>
		<Port>
		<xsl:choose>
			<xsl:when test="Port">
				<xsl:value-of select="Port"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@number"/>
			</xsl:otherwise>
		</xsl:choose>
		</Port>
		<CrystalID><xsl:value-of select="cane_loop"/></CrystalID>
		<Comment><xsl:value-of select="protein_description"/></Comment>
		<Protein><xsl:value-of select="TM"/></Protein>
		<FreezingCond><xsl:value-of select="cryo"/></FreezingCond>
		<CrystalCond><xsl:value-of select="Crystall_cond"/></CrystalCond>
		<Metal><xsl:value-of select="CC_remarks"/></Metal>
		<Priority><xsl:value-of select="PRI_score1"/></Priority>
		<Person>null</Person>
		<Order>1</Order>
		<!--
		<Directory><xsl:value-of select="directory"/></Directory>
		-->
		<Directory>
		<xsl:choose>
			<xsl:when test="directory">
				<xsl:value-of select="directory"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="TM"/><xsl:text>/</xsl:text><xsl:value-of select="cane_loop"/>
			</xsl:otherwise>
		</xsl:choose>
		</Directory>

	</Row>
  </xsl:template>

<!--
	data+= "{"+ rowIndex +"} "
	data+= "{"+ rs("cane_loop") +"} "
	data+= "{"+ rs("protein_description") +"} "
	data+= "{"+ rs("TM") +"} "
	data+= "{"+ rs("cryo") +"} "
	data+= "{"+ rs("Crystall_cond") +"} "
	data+= "{"+ rs("CC_remarks") +"} "
	data+= "{"+ rs("PRI_score1") +"} "
	data+= "{"+ "1" +"} "
	data+= "{"+ rs("directory") +"} "

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
