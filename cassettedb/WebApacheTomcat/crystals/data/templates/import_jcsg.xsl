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
			<xsl:when test="CurrentPosition">
				<xsl:value-of select="CurrentPosition"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@number"/>
			</xsl:otherwise>
		</xsl:choose>
		</Port>
		<CrystalID><xsl:value-of select="XtalID"/></CrystalID>
		<Protein><xsl:value-of select="AccessionID"/></Protein>
		<Comment><xsl:value-of select="CCRemarks"/></Comment>
		<FreezingCond><xsl:value-of select="Cryo"/></FreezingCond>
		<CrystalCond><xsl:value-of select="CrystalConditions"/></CrystalCond>
		<Metal><xsl:value-of select="SelMetOrNative"/></Metal>
		<Priority><xsl:value-of select="PRIScore"/></Priority>
		<CrystalURL><xsl:value-of select="CrystalURL"/></CrystalURL>
		<ProteinURL>
		<xsl:choose>
			<xsl:when test="ProteinURL">
				<xsl:value-of select="ProteinURL"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>http://www1.jcsg.org/cgi-bin/psat/analyzer.cgi?acc=</xsl:text>
				<xsl:value-of select="AccessionID"/>
			</xsl:otherwise>
		</xsl:choose>
		</ProteinURL>
		<Directory>
		<xsl:choose>
			<xsl:when test="directory">
				<xsl:value-of select="directory"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="AccessionID"/><xsl:text>/</xsl:text><xsl:value-of select="XtalID"/>
			</xsl:otherwise>
		</xsl:choose>
		</Directory>
		<ContainerID><xsl:value-of select="CurrentCasette"/></ContainerID>

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
