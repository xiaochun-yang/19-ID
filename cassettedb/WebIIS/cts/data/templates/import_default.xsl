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
  		<xsl:attribute name="CassetteID"><xsl:value-of select="//Row[@number=2]/CrystalID"/></xsl:attribute>
		<xsl:apply-templates select="*"/>
	</CrystalData>
  </xsl:template>

  <xsl:template match="Row[@number=2]">
	<!-- suppress the row 2 (reserved for the CassetteID) -->
  </xsl:template>
  
  <xsl:template match="Row[@number>2]">
  	<Row>
  		<xsl:attribute name="number"><xsl:value-of select="@number"/></xsl:attribute>
		<Port><xsl:value-of select="Port"/></Port>
		<CrystalID><xsl:value-of select="CrystalID"/></CrystalID>
		<Comment><xsl:value-of select="Comment"/></Comment>
		<Protein><xsl:value-of select="Protein"/></Protein>
		<FreezingCond><xsl:value-of select="FreezingCond"/></FreezingCond>
		<CrystalCond><xsl:value-of select="CrystalCond"/></CrystalCond>
		<Metal><xsl:value-of select="Metal"/></Metal>
		<Priority><xsl:value-of select="Priority"/></Priority>
		<Person>null</Person>
		<Order>1</Order>
		<Directory><xsl:value-of select="Directory"/></Directory>
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
