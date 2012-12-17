<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">

	<xsl:param name="param1"/>
	<xsl:param name="param2"/>
	<xsl:variable name="cassetteID" select="$param1"/>
	<xsl:variable name="PIN_Number" select="$param2"/>

	<xsl:output method="xml" indent="yes" encoding="UTF-8" />
	<xsl:template match="CrystalData">
		<Sil>
			<xsl:attribute name="name"><xsl:value-of select="$cassetteID"/></xsl:attribute>
			<xsl:attribute name="lock">false</xsl:attribute>
			<xsl:attribute name="eventId">0</xsl:attribute>
			<xsl:attribute name="version">1.0</xsl:attribute>
			<xsl:for-each select="Row">
				<Crystal>
					<xsl:call-template name="eachRow" />
				</Crystal>
			</xsl:for-each>
		</Sil>
	</xsl:template>

	<xsl:template name="eachRow">
		<xsl:attribute name="row"><xsl:number value="position()-1" format="1" /></xsl:attribute>
		<xsl:attribute name="excelRow"><xsl:value-of select="@number" /></xsl:attribute>
		<xsl:attribute name="selected">1</xsl:attribute>
		<ContainerID>
			<xsl:choose>
				<xsl:when test="ContainerID!=''">
					<xsl:value-of select="ContainerID" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$PIN_Number"/>
				</xsl:otherwise>
			</xsl:choose>
		</ContainerID>
		<Port>
			<xsl:value-of select="Port" />
		</Port>
		<CrystalID>
			<xsl:value-of select="CrystalID" />
		</CrystalID>
		<Protein>
			<xsl:value-of select="Protein" />
		</Protein>
		<Comment>
			<xsl:value-of select="Comment" />
		</Comment>
		<FreezingCond>
			<xsl:value-of select="FreezingCond" />
		</FreezingCond>
		<CrystalCond>
			<xsl:value-of select="CrystalCond" />
		</CrystalCond>
		<Metal>
			<xsl:value-of select="Metal" />
		</Metal>
		<Priority>
			<xsl:value-of select="Priority" />
		</Priority>
		<Person>
			<xsl:value-of select="Person" />
		</Person>
		<CrystalURL>
			<xsl:value-of select="CrystalURL" />
		</CrystalURL>
		<ProteinURL>
			<xsl:value-of select="ProteinURL" />
		</ProteinURL>
		<Directory>
			<xsl:value-of select="Directory" />
		</Directory>
		<SystemWarning>
			<xsl:value-of select="SystemWarning" />
		</SystemWarning>
		<Images>
			<Group name="1">
			<xsl:if test="(count(Image1) &gt;= 1) and (string-length(Image1) > 0)">
					<Image>
					<xsl:attribute name="name"><xsl:value-of select="Image1"/></xsl:attribute>
					<xsl:attribute name="jpeg"><xsl:value-of select="Jpeg1"/></xsl:attribute>
					<xsl:attribute name="integratedIntensity"><xsl:value-of select="IntegratedIntensity1"/></xsl:attribute>
					<xsl:attribute name="numOverloadSpots"><xsl:value-of select="NumOverloadSpots1"/></xsl:attribute>
					<xsl:attribute name="score"><xsl:value-of select="Score1"/></xsl:attribute>
					<xsl:attribute name="dir"><xsl:value-of select="Dir1"/></xsl:attribute>
					<xsl:attribute name="resolution"><xsl:value-of select="Resolution1"/></xsl:attribute>
					<xsl:attribute name="iceRings"><xsl:value-of select="IceRing1"/></xsl:attribute>
					<xsl:attribute name="small"><xsl:value-of select="Small1"/></xsl:attribute>
					<xsl:attribute name="numSpots"><xsl:value-of select="NumSpots1"/></xsl:attribute>
					<xsl:attribute name="spotShape"><xsl:value-of select="Spotshape1"/></xsl:attribute>
					<xsl:attribute name="quality"><xsl:value-of select="Quality1"/></xsl:attribute>
					<xsl:attribute name="large"><xsl:value-of select="Large1"/></xsl:attribute>
					<xsl:attribute name="diffractionStrength"><xsl:value-of select="DiffractionStrength1"/></xsl:attribute>
					<xsl:attribute name="medium"><xsl:value-of select="Medium1"/></xsl:attribute>
					<xsl:attribute name="spotfinderDir"><xsl:value-of select="spotfinderDir1"/></xsl:attribute>
					</Image>
			</xsl:if>
			</Group>
			<Group name="2">
			<xsl:if test="(count(Image2) &gt;= 1) and (string-length(Image2) > 0)">
					<Image>
					<xsl:attribute name="name"><xsl:value-of select="Image2"/></xsl:attribute>
					<xsl:attribute name="jpeg"><xsl:value-of select="Jpeg2"/></xsl:attribute>
					<xsl:attribute name="integratedIntensity"><xsl:value-of select="IntegratedIntensity2"/></xsl:attribute>
					<xsl:attribute name="numOverloadSpots"><xsl:value-of select="NumOverloadSpots2"/></xsl:attribute>
					<xsl:attribute name="score"><xsl:value-of select="Score2"/></xsl:attribute>
					<xsl:attribute name="dir"><xsl:value-of select="Dir2"/></xsl:attribute>
					<xsl:attribute name="resolution"><xsl:value-of select="Resolution2"/></xsl:attribute>
					<xsl:attribute name="iceRings"><xsl:value-of select="IceRing2"/></xsl:attribute>
					<xsl:attribute name="small"><xsl:value-of select="Small2"/></xsl:attribute>
					<xsl:attribute name="numSpots"><xsl:value-of select="NumSpots2"/></xsl:attribute>
					<xsl:attribute name="spotShape"><xsl:value-of select="Spotshape2"/></xsl:attribute>
					<xsl:attribute name="quality"><xsl:value-of select="Quality2"/></xsl:attribute>
					<xsl:attribute name="large"><xsl:value-of select="Large2"/></xsl:attribute>
					<xsl:attribute name="diffractionStrength"><xsl:value-of select="DiffractionStrength2"/></xsl:attribute>
					<xsl:attribute name="medium"><xsl:value-of select="Medium2"/></xsl:attribute>
					<xsl:attribute name="spotfinderDir"><xsl:value-of select="spotfinderDir2"/></xsl:attribute>
					</Image>
			</xsl:if>
			</Group>
			<Group name="3">
			<xsl:if test="(count(Image3) &gt;= 1) and (string-length(Image3) > 0)">
					<Image>
					<xsl:attribute name="name"><xsl:value-of select="Image3"/></xsl:attribute>
					<xsl:attribute name="jpeg"><xsl:value-of select="Jpeg3"/></xsl:attribute>
					<xsl:attribute name="integratedIntensity"><xsl:value-of select="IntegratedIntensity3"/></xsl:attribute>
					<xsl:attribute name="numOverloadSpots"><xsl:value-of select="NumOverloadSpots3"/></xsl:attribute>
					<xsl:attribute name="score"><xsl:value-of select="Score3"/></xsl:attribute>
					<xsl:attribute name="dir"><xsl:value-of select="Dir3"/></xsl:attribute>
					<xsl:attribute name="resolution"><xsl:value-of select="Resolution3"/></xsl:attribute>
					<xsl:attribute name="iceRings"><xsl:value-of select="IceRing3"/></xsl:attribute>
					<xsl:attribute name="small"><xsl:value-of select="Small3"/></xsl:attribute>
					<xsl:attribute name="numSpots"><xsl:value-of select="NumSpots3"/></xsl:attribute>
					<xsl:attribute name="spotShape"><xsl:value-of select="Spotshape3"/></xsl:attribute>
					<xsl:attribute name="quality"><xsl:value-of select="Quality3"/></xsl:attribute>
					<xsl:attribute name="large"><xsl:value-of select="Large2"/></xsl:attribute>
					<xsl:attribute name="diffractionStrength"><xsl:value-of select="DiffractionStrength3"/></xsl:attribute>
					<xsl:attribute name="medium"><xsl:value-of select="Medium3"/></xsl:attribute>
					<xsl:attribute name="spotfinderDir"><xsl:value-of select="spotfinderDir3"/></xsl:attribute>
					</Image>
			</xsl:if>
			</Group>
		</Images>
		<AutoindexImages><xsl:value-of select="AutoindexImages" /></AutoindexImages>
		<Score><xsl:value-of select="Score" /></Score>
		<UnitCell><xsl:value-of select="UnitCell" /></UnitCell>
		<Mosaicity><xsl:value-of select="Mosaicity" /></Mosaicity>
		<Rmsr><xsl:value-of select="Rmsr" /></Rmsr>
		<BravaisLattice><xsl:value-of select="BravaisLattice" /></BravaisLattice>
		<Resolution><xsl:value-of select="Resolution" /></Resolution>
		<ISigma><xsl:value-of select="ISigma" /></ISigma>
		<AutoindexDir><xsl:value-of select="AutoindexDir" /></AutoindexDir>
	</xsl:template>

</xsl:stylesheet>
