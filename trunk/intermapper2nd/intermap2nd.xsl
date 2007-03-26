<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text" omit-xml-declaration="yes" />

  <xsl:template match="device">
    <xsl:value-of select="Address"/>
    <xsl:text>&#9;</xsl:text>
    <xsl:value-of select="Name"/>
    <xsl:text>&#9;</xsl:text>
    <xsl:value-of select="document('Vertices.xml')/vertices/vertice[Id=current()/Id]/MapName"/>
    <xsl:text>&#9;</xsl:text>
    <xsl:value-of select="document('Vertices.xml')/vertices/vertice[Id=current()/Id]/Origin"/>
    <xsl:text>&#9;</xsl:text>
    <xsl:value-of select="document('Vertices.xml')/vertices/vertice[Id=current()/Id]/XCoordinate"/>
    <xsl:text>&#9;</xsl:text>
    <xsl:value-of select="document('Vertices.xml')/vertices/vertice[Id=current()/Id]/YCoordinate"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="text()">
  </xsl:template>

</xsl:transform>
