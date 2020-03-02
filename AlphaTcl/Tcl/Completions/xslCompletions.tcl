# File : "xslCompletions.tcl"
#                        Created : 2003-03-15 18:08:09
#              Last modification : 2003-03-17 11:56:49
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# www : <http://webperso.easyconnect.fr/bdesgraupes/>
# Description : completions for xsl mode.


# # Electrics
# # =========
# These electrics are defined for convenience. The required attributes are 
# present but some elements might accept other optional attributes. For 
# example, the 'templ' electrics inserts xsl:template with a 'match' attribute 
# which is not required but is used most of the time (other possible attributes are 
# 'name', 'priority', 'mode').

set xslelectrics(choose) "×kill0<xsl:choose>
  <xsl:when test=\"¥¥\">
  ¥¥
  </xsl:when>
  <xsl:otherwise>
  ¥¥
  </xsl:otherwise>
</xsl:choose>
"

set xslelectrics(templ) "×kill0<xsl:template match=\"¥¥\">\r\t¥¥\r</xsl:template>"

set xslelectrics(foreach) "×kill0<xsl:for-each select=\"¥¥\">\r\t¥¥\r</xsl:for-each>"

set xslelectrics(if) "×kill0<xsl:if test=\"¥¥\">\r\t¥¥\r</xsl:if>"

set xslelectrics(sort) "×kill0<xsl:sort select=\"¥¥\">\r\t¥¥\r</xsl:sort>"

set xslelectrics(value) "×kill0<xsl:value-of select=\"¥¥\"/>\r"

set xslelectrics(import) "×kill0<xsl:import href=\"¥¥\"/>\r"

set xslelectrics(include) "×kill0<xsl:include href=\"¥¥\"/>\r"

set xslelectrics(output) "×kill0<xsl:output href=\"¥¥\"/>\r"

set xslelectrics(key) "×kill0<xsl:key name=\"¥¥\" match=\"¥¥\" use=\"¥¥\"/>\r"

set xslelectrics(copyof) "×kill0<xsl:copy-of select=\"¥¥\"/>\r"

set xslelectrics(attr) "×kill0<xsl:attribute name=\"¥¥\">\r\t¥¥\r</xsl:attribute>"

set xslelectrics(applyt) "×kill0<xsl:apply-templates select=\"¥¥\">\r\t¥¥\r</xsl:apply-templates>"
