<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     version="2.0">

  <xsl:output method="text"/>

  <xsl:template match="files">

    <xsl:for-each-group select="file" group-by="@project">
      <xsl:value-of select="current-grouping-key()"/>
      <xsl:text>
</xsl:text>
    </xsl:for-each-group>

  </xsl:template>
</xsl:stylesheet>