<?xml version="1.0"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="module">
    <xsl:choose>
      <xsl:when test="starts-with(web/web-uri, 'paysol-web') or starts-with(ejb, 'paysol-ejb')">
        <sc />
        <xsl:copy-of select="." />
        <ec />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="." />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:transform>