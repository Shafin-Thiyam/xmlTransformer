<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     version="2.0">

  <xsl:output method="xml"/>

  <xsl:template match="files">
    <files>
    <xsl:for-each-group select="file" group-by="@project">
      <file>
      <xsl:value-of select="current-grouping-key()"/>
      </file>
    </xsl:for-each-group>
</files>
  </xsl:template>
</xsl:stylesheet>