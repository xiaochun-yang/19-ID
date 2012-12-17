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

  <xsl:template match="Row[@number>1]">
    <xsl:if test="count(*)">
  	<Row>
  		<xsl:attribute name="number"><xsl:value-of select="@number"/></xsl:attribute>
		<Port><xsl:value-of select="Port"/></Port>
		<CrystalID><xsl:value-of select="CrystalID"/></CrystalID>
		<Protein><xsl:value-of select="Protein"/></Protein>
		<Comment><xsl:value-of select="Comment"/></Comment>
		<FreezingCond><xsl:value-of select="FreezingCond"/></FreezingCond>
		<CrystalCond><xsl:value-of select="CrystalCond"/></CrystalCond>
		<Metal><xsl:value-of select="Metal"/></Metal>
		<Priority><xsl:value-of select="Priority"/></Priority>
		<CrystalURL><xsl:value-of select="CrystalURL"/></CrystalURL>
		<ProteinURL><xsl:value-of select="ProteinURL"/></ProteinURL>
		<Directory><xsl:value-of select="Directory"/></Directory>
		<Person><xsl:value-of select="Person"/></Person>
		<ContainerID><xsl:value-of select="ContainerID"/></ContainerID>
		<Image1><xsl:value-of select="Image1"/></Image1>
		<Jpeg1><xsl:value-of select="Jpeg1"/></Jpeg1>
		<IntegratedIntensity1><xsl:value-of select="IntegratedIntensity1"/></IntegratedIntensity1>
		<NumOverloadSpots1><xsl:value-of select="NumOverloadSpots1"/></NumOverloadSpots1>
		<Score1><xsl:value-of select="Score1"/></Score1>
		<Dir1><xsl:value-of select="Dir1"/></Dir1>
		<Resolution1><xsl:value-of select="Resolution1"/></Resolution1>
		<IceRing1><xsl:value-of select="IceRing1"/></IceRing1>
		<Small1><xsl:value-of select="Small1"/></Small1>
		<NumSpots1><xsl:value-of select="NumSpots1"/></NumSpots1>
		<Spotshape1><xsl:value-of select="Spotshape1"/></Spotshape1>
		<Quality1><xsl:value-of select="Quality1"/></Quality1>
		<Large1><xsl:value-of select="Large1"/></Large1>
		<DiffractionStrength1><xsl:value-of select="DiffractionStrength1"/></DiffractionStrength1>
		<Medium1><xsl:value-of select="Medium1"/></Medium1>
		<spotfinderDir1><xsl:value-of select="spotfinderDir1"/></spotfinderDir1>
		<Image2><xsl:value-of select="Image2"/></Image2>
		<Jpeg2><xsl:value-of select="Jpeg2"/></Jpeg2>
		<IntegratedIntensity2><xsl:value-of select="IntegratedIntensity2"/></IntegratedIntensity2>
		<NumOverloadSpots2><xsl:value-of select="NumOverloadSpots2"/></NumOverloadSpots2>
		<Score2><xsl:value-of select="Score2"/></Score2>
		<Dir2><xsl:value-of select="Dir2"/></Dir2>
		<Resolution2><xsl:value-of select="Resolution2"/></Resolution2>
		<IceRing2><xsl:value-of select="IceRing2"/></IceRing2>
		<Small2><xsl:value-of select="Small2"/></Small2>
		<NumSpots2><xsl:value-of select="NumSpots2"/></NumSpots2>
		<Spotshape2><xsl:value-of select="Spotshape2"/></Spotshape2>
		<Quality2><xsl:value-of select="Quality2"/></Quality2>
		<Large2><xsl:value-of select="Large2"/></Large2>
		<DiffractionStrength2><xsl:value-of select="DiffractionStrength2"/></DiffractionStrength2>
		<Medium2><xsl:value-of select="Medium2"/></Medium2>
		<spotfinderDir2><xsl:value-of select="spotfinderDir2"/></spotfinderDir2>
		<Image3><xsl:value-of select="Image3"/></Image3>
		<Jpeg3><xsl:value-of select="Jpeg3"/></Jpeg3>
		<IntegratedIntensity3><xsl:value-of select="IntegratedIntensity3"/></IntegratedIntensity3>
		<NumOverloadSpots3><xsl:value-of select="NumOverloadSpots3"/></NumOverloadSpots3>
		<Score3><xsl:value-of select="Score3"/></Score3>
		<Dir3><xsl:value-of select="Dir3"/></Dir3>
		<Resolution3><xsl:value-of select="Resolution3"/></Resolution3>
		<IceRing3><xsl:value-of select="IceRing3"/></IceRing3>
		<Small3><xsl:value-of select="Small3"/></Small3>
		<NumSpots3><xsl:value-of select="NumSpots3"/></NumSpots3>
		<Spotshape3><xsl:value-of select="Spotshape3"/></Spotshape3>
		<Quality3><xsl:value-of select="Quality3"/></Quality3>
		<Large3><xsl:value-of select="Large3"/></Large3>
		<DiffractionStrength3><xsl:value-of select="DiffractionStrength3"/></DiffractionStrength3>
		<Medium3><xsl:value-of select="Medium3"/></Medium3>
		<spotfinderDir3><xsl:value-of select="spotfinderDir3"/></spotfinderDir3>
		<AutoindexImages><xsl:value-of select="AutoindexImages"/></AutoindexImages>
		<Score><xsl:value-of select="Score"/></Score>
		<UnitCell><xsl:value-of select="UnitCell"/></UnitCell>
		<Mosaicity><xsl:value-of select="Mosaicity"/></Mosaicity>
		<Rmsr><xsl:value-of select="Rmsr"/></Rmsr>
		<BravaisLattice><xsl:value-of select="BravaisLattice"/></BravaisLattice>
		<Resolution><xsl:value-of select="Resolution"/></Resolution>
		<ISigma><xsl:value-of select="ISigma"/></ISigma>
		<AutoindexDir><xsl:value-of select="AutoindexDir"/></AutoindexDir>
	</Row>
	</xsl:if>
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
