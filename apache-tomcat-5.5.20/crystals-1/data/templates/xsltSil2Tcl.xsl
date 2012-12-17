<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" indent="yes"/>
<xsl:template match="Sil">
{
 {<xsl:value-of select="@name"/>} {<xsl:value-of select="@eventId"/>} {load}
 <xsl:call-template name="headers" />
 <xsl:apply-templates select="Crystal" />
}
</xsl:template>

<xsl:template name="headers">
  {
    {Selected 4 hide}
    {Port 4 readonly}
    {ContainerID 8 readonly}
    {CrystalID 10 readonly}
    {Protein 8 editable}
    {Comment 35 editable}
    {SystemWarning 15 readonly}
    {Directory 22 readonly}
    {FreezingCond 12}
    {CrystalCond 12}
    {Metal 5}
    {Priority 8}
    {Person 8}
    {CrystalURL 25 readonly}
    {ProteinURL 25 readonly}
    {AutoindexImages 20 readonly}
    {Score 10 readonly}
    {UnitCell 20 readonly}
    {Mosaicity 8 readonly}
    {Rmsr 8 readonly}
    {BravaisLattice 10 readonly}
    {Resolution 10 readonly}
    {ISigma 10 readonly hide}
    {Images}
  }
</xsl:template>

<xsl:template match="Crystal">
  {
    {<xsl:value-of select="@selected"/>}
    {<xsl:value-of select="Port"/>}
    {<xsl:value-of select="ContainerID"/>}
    {<xsl:value-of select="CrystalID"/>}
    {<xsl:value-of select="translate( string(Protein), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Comment), '{}','()')"/>}
    {<xsl:value-of select="translate( string(SystemWarning), '{}','()')"/>}
    {<xsl:value-of select="Directory"/>}
    {<xsl:value-of select="translate( string(FreezingCond), '{}','()')"/>}
    {<xsl:value-of select="translate( string(CrystalCond), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Metal), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Priority), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Person), '{}','()')"/>}
    {<xsl:value-of select="translate( string(CrystalURL), '{}','()')"/>}
    {<xsl:value-of select="translate( string(ProteinURL), '{}','()')"/>}
    {<xsl:value-of select="translate( string(AutoindexImages), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Score), '{}','()')"/>}
    {<xsl:value-of select="translate( string(UnitCell), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Mosaicity), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Rmsr), '{}','()')"/>}
    {<xsl:value-of select="translate( string(BravaisLattice), '{}','()')"/>}
    {<xsl:value-of select="translate( string(Resolution), '{}','()')"/>}
    {<xsl:value-of select="translate( string(ISigma), '{}','()')"/>}
    {<xsl:apply-templates select="Images" />
    }
  }
</xsl:template>

<xsl:template match="Images">
      {<xsl:apply-templates select="Group[@name='1']/Image"/>
      }
      {<xsl:apply-templates select="Group[@name='2']/Image"/>
      }
      {<xsl:apply-templates select="Group[@name='3']/Image"/>
      }
</xsl:template>
	 
<xsl:template match="Image">
        {
          {<xsl:value-of select="@dir" />}
          {<xsl:value-of select="@name" />}
          {<xsl:value-of select="@jpeg" />}
          {<xsl:value-of select="@small" />}
          {<xsl:value-of select="@medium" />}
          {<xsl:value-of select="@large" />}
          {<xsl:value-of select="@quality" />}
          {<xsl:value-of select="@spotShape" />}
          {<xsl:value-of select="@resolution" />}
          {<xsl:value-of select="@iceRings" />}
          {<xsl:value-of select="@diffractionStrength" />}
          {<xsl:value-of select="@score" />}
          {<xsl:value-of select="@numSpots" />}
          {<xsl:value-of select="@numOverloadSpots" />}
        }</xsl:template>

</xsl:stylesheet>
