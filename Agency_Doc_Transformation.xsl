<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:functx="http://www.functx.com"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="functx xs" version="2.0">
  
    <xsl:output method="xml" indent="yes"/>
    <xsl:preserve-space elements="p bold strong i em a u font span"/>

<!-- Identify Various Types of Documents based on certain markup varieties.
     Anything unidentified will produce an error through the "unknown" value. -->
  
  <xsl:param name="stylesheetMap" select="'Parameter not passed'"/>

  <xsl:template name="get-map-parameter">
    <xsl:param name="param-name"/>
    <xsl:analyze-string select="string($stylesheetMap)" regex="{$param-name}=(.+?)((,\s[A-z]+=)|\}})">
      <xsl:matching-substring>
        <xsl:value-of select="regex-group(1)"/>
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <xsl:variable name="doc-type">
    <xsl:choose>
      <xsl:when test="//article[@role='article']">article</xsl:when>  <!-- PBGC -->
      <xsl:when test="//body[count(*)=2] and //body[count(table)=2]">single-table</xsl:when> <!-- SECAAER html -->
      <xsl:otherwise>unknown</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:variable name="source-name">
    <xsl:call-template name="get-map-parameter">
      <xsl:with-param name="param-name">sourceName</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:variable name="month-names">
    <xsl:text>janfebmaraprmayjunjulaugsepoctnovdec</xsl:text>
  </xsl:variable>

  <xsl:variable name="month-nums">
    <xsl:text>010203040506070809101112</xsl:text>
  </xsl:variable>

<!-- Identify the modification date of the document -->

  <xsl:variable name="found-date">
    <xsl:choose>
      <xsl:when test="$doc-type='article'">
        <!-- Expected form yyyy-mm-dd -->
        <xsl:choose>
            <xsl:when test="//span[@property='dc:date']">
                <xsl:value-of select="substring(//span[@property='dc:date']/@content,1,10)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="//div[@property='content:encoded']/p[1]"/>
            </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$doc-type='single-table'">
        <!-- Expected form Mmm. dd, yyyy, with comma and period stripped -->
        <xsl:value-of select="lower-case(translate(//meta[@name='date']/@content,'.,',''))"/>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

<!-- This variable takes the date stored in $found-date and
     converts it into the necessary yyyymmdd format          -->
  
  <xsl:variable name="formatted-date">
    <xsl:choose>
      <!-- For dates in form yyyy-mm-dd -->
      <xsl:when test="matches($found-date,'^\d{4}-\d{2}-\d{2}$')">
        <xsl:value-of select="translate($found-date,'-','')"/>
      </xsl:when>
      <!-- For dates in form mm-dd-yyyy -->
      <xsl:when test="matches($found-date,'^\d{2}-\d{2}-\d{4}$')">
        <xsl:value-of select="concat(substring($found-date,7,4),substring($found-date,1,2),substring($found-date,4,2))"/>
      </xsl:when>
      <!-- For dates in form (M/m)mm. d(d), yyyy (also if month is spelled out) -->
      <xsl:when test="matches($found-date,'^[a-z]\w{2,8}\s\d{1,2}\s\d{4}$')">
        <xsl:variable name="year" select="tokenize($found-date,' ')[3]"/>
        <xsl:variable name="monthnum">
          <xsl:call-template name="month-text-to-num">
            <xsl:with-param name="month" select="substring($found-date,1,3)"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="two-digit-day">
          <xsl:variable name="day" select="tokenize($found-date,' ')[2]"/>
          <xsl:if test="string-length($day)=1">0</xsl:if>
          <xsl:value-of select="$day"/>
        </xsl:variable>
        <xsl:value-of select="concat($year,$monthnum,$two-digit-day)"/>
      </xsl:when>
      <xsl:otherwise>
        <error.message type="content" code="unrecognized-date-format">
          <xsl:value-of select="$found-date"/>
        </error.message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

<!-- Basic Error Handling for Unknown Elements/Attributes -->
  
  <xsl:template match="*" priority="-1">
    <error.message type="content" code="unhandled-element">
      <xsl:value-of select="name()"/>
      <xsl:choose>
        <xsl:when test="@id">
          <xsl:text>id="</xsl:text>
          <xsl:value-of select="@id"/>
          <xsl:text>"</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="@*">
            <xsl:text> </xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>: "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </error.message>
  </xsl:template>

  <xsl:template match="@*" priority="-1">
    <error.message type="content" code="unhandled-attribute">
      <xsl:value-of select="local-name()"/>
      <xsl:text>: "</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>"</xsl:text>
    </error.message>
  </xsl:template>

<!--  _______________________

      Root Element Processing
      _______________________  -->

  <xsl:template match="/">
    <agency.artifact>
      <irs.document>
        <xsl:call-template name="gather-metadata"/>
        <xsl:call-template name="handle-content"/>
      </irs.document>
    </agency.artifact>
  </xsl:template>

<!--  ________________________

      Document Head Processing
      ________________________  -->

  <xsl:template name="gather-metadata">
    <xsl:call-template name="record-dest-info"/>
    <xsl:call-template name="record-date-time"/>
    <irs.document.metadata>
      <xsl:call-template name="find-meta-title"/>
      <xsl:call-template name="record-source-name"/>
      <xsl:call-template name="process-filing-info"/>
    </irs.document.metadata>
  </xsl:template>

  <xsl:template name="record-dest-info">
    <xsl:choose>
      <xsl:when test="$source-name='Disaster Relief Announcements'">
        <xsl:attribute name="TYPE" select="'PBGCDRA'"/>
        <xsl:if test="//div[contains(@class,'disaster-relief-number')]">
          <xsl:attribute name="UID">
            <xsl:value-of select="//div[contains(@class,'disaster-relief-number')]/div/div"/>
          </xsl:attribute>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$source-name='News Releases'">
        <xsl:attribute name="TYPE" select="'PBGCNR'"/>
        <xsl:if test="//div[contains(@class,'pbgc-number')]">
          <xsl:attribute name="UID">
            <xsl:value-of select="//div[contains(@class,'pbgc-number')]/div/div"/>
          </xsl:attribute>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$source-name='Technical Updates'">
        <xsl:attribute name="TYPE" select="'PBGCTU'"/>
        <xsl:if test="contains(/html/head/title,'Technical Update')">
          <xsl:attribute name="UID">
            <xsl:analyze-string select='/html/head/title' regex=".*?([0-9\-]+):.*">
              <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
              </xsl:matching-substring>
            </xsl:analyze-string>
          </xsl:attribute>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="record-date-time">
    <date.line>
      <xsl:attribute name="datetime">
        <xsl:value-of select="$formatted-date"/>
        <xsl:text>000000</xsl:text>
      </xsl:attribute>
      <xsl:value-of select="$formatted-date"/>
      <xsl:text>000000</xsl:text>
    </date.line>
  </xsl:template>

  <xsl:template name="find-meta-title">
    <content.long.title>
      <individual.title>
        <xsl:choose>
          <xsl:when test="$doc-type='article'">
            <xsl:choose>
              <xsl:when test="contains('Disaster Relief Announcements News Releases',$source-name)">
                <xsl:variable name="text-to-process" select="/html/head/title/text()"/>
                <xsl:analyze-string select="$text-to-process" regex="(.*?)\.? \| .*">
                  <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                    <xsl:value-of select="$text-to-process"/>
                  </xsl:non-matching-substring>
                </xsl:analyze-string>
              </xsl:when>
              <xsl:when test="$source-name='Technical Updates'">
                <xsl:analyze-string select="/html/head/title/text()" regex="(.*?) [0-9\-]+(:.*?)\.? \| .*">
                  <xsl:matching-substring>
                    <xsl:value-of select="concat(regex-group(1),regex-group(2))"/>
                  </xsl:matching-substring>
                </xsl:analyze-string>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>TITLE NOT FOUND</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$doc-type='single-table'">
            <xsl:value-of select="//meta[@name='title']/@content"/>
          </xsl:when>
        </xsl:choose>
      </individual.title>
    </content.long.title>
  </xsl:template>

  <xsl:template name="record-source-name">
    <agency.source.name>
      <xsl:value-of select="$source-name"/>
    </agency.source.name>
  </xsl:template>

  <xsl:template name="process-filing-info">
    <filing.information>
      <filing.date>
        <date.line>
          <xsl:value-of select="$formatted-date"/>
        </date.line>
      </filing.date>
    </filing.information>
  </xsl:template>

  <xsl:template name="month-text-to-num">
    <xsl:param name="month"/>
    <xsl:value-of select="substring($month-nums,string-length(substring-before($month-names, $month)) div 3 * 2 + 1,2)"/>
  </xsl:template>

<!--  ________________________

      Document Body Processing
      ________________________  -->
  
  <xsl:template name="handle-content">
    <irs.document.body>
      <xsl:call-template name="find-display-title"/>
      <xsl:call-template name="process-content"/>
    </irs.document.body>
  </xsl:template>

  <xsl:template name="find-display-title">
    <xsl:choose>
      <xsl:when test="$doc-type='article'">
        <xsl:choose>
          <xsl:when test="//body[contains(@class,'pbgc-no-title')]"/>
          <xsl:when test="//body//div[@role='main']/h1">
            <xsl:apply-templates select="//body//div[@role='main']/h1"/>
          </xsl:when>
          <xsl:otherwise>
            <error.message type="content" code="no-display-title-found"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$doc-type='single-table'"/>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="process-content">
    <xsl:choose>
      <xsl:when test="$doc-type='article'">
        <xsl:apply-templates select="//article[@role='article']/*"/>
      </xsl:when>
      <xsl:when test="$doc-type='single-table'">
        <xsl:apply-templates select="//body/table[2]/tbody/tr/td[last()]/*"/>
      </xsl:when>
      <xsl:otherwise>
        <error.message type="content" code="no-content-root-found">
          <xsl:text>Could not find the content root for document type </xsl:text>
          <xsl:value-of select="$doc-type"/>
          <xsl:text>.</xsl:text>
        </error.message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!--  _______________________

      Head Element Processing
      _______________________  -->

  <xsl:template match="h1|h2|h3|h4|h5|h6">
    <head>
      <headtext>
        <xsl:attribute name="level">
          <xsl:value-of select="substring(local-name(),2,1)"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()"/>
      </headtext>
    </head>
  </xsl:template>
  
<!--  ___________________________

      Standard Element Processing
      ___________________________  -->

  <xsl:template match="li/p">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

  <xsl:template match="p">
    <para>
      <paratext>
        <xsl:apply-templates select="@*"/>
        <xsl:if test="parent::blockquote">
          <set.line.indent lroi="24" rroi="24"/>
        </xsl:if>
        <xsl:apply-templates select="node()"/>
      </paratext>
    </para>
  </xsl:template>

  <xsl:template match="ol">
    <xsl:choose>
      <xsl:when test="ancestor::ol|ancestor::ul">
        <ol>
          <xsl:apply-templates select="@*|node()[not(local-name(.)='p')]"/>
        </ol>
        <xsl:apply-templates select="p"/>
      </xsl:when>
      <xsl:otherwise>
        <para>
          <ol>
            <xsl:apply-templates select="@*|node()[not(local-name(.)='p')]"/>
          </ol>
        </para>
        <xsl:apply-templates select="p"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ul">
    <xsl:choose>
      <xsl:when test="ancestor::ol|ancestor::ul">
        <ul>
          <xsl:apply-templates select="@*|node()[not(local-name(.)='p')]"/>
        </ul>
        <xsl:apply-templates select="p"/>
      </xsl:when>
      <xsl:otherwise>
        <para>
          <ul>
            <xsl:apply-templates select="@*|node()[not(local-name(.)='p')]"/>
          </ul>
        </para>
        <xsl:apply-templates select="p"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ul/@type"/>

  <xsl:template match="li">
    <li>
      <xsl:apply-templates select="@*|node()"/>
    </li>
  </xsl:template>
  
  <xsl:template match="li/@style"/>

  <xsl:template match="b|strong">
    <xsl:choose>
      <xsl:when test="parent::div">
        <para>
          <paratext>
            <bold>
              <xsl:apply-templates select="node()"/>
            </bold>
          </paratext>
        </para>
      </xsl:when>
      <xsl:otherwise>
        <bold>
          <xsl:apply-templates select="node()"/>
        </bold>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="i|em">
    <xsl:choose>
      <xsl:when test="parent::div">
        <para>
          <paratext>
            <ital>
              <xsl:apply-templates select="node()"/>
            </ital>
          </paratext>
        </para>
      </xsl:when>
      <xsl:otherwise>
        <ital>
          <xsl:apply-templates select="node()"/>
        </ital>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="u">
    <underscore>
      <xsl:apply-templates select="node()"/>
    </underscore>
  </xsl:template>

  <xsl:template match="blockquote">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

  <xsl:template match="a">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

  <xsl:template match="date">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

  <xsl:template match="personname">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="br">
    <xsl:if test="following-sibling::*[not(contains('br,table,p,div',name()))] or following-sibling::text()[normalize-space()!='']">
      <eol/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="div">
    <xsl:apply-templates select="*"/>
  </xsl:template>
  
  <xsl:template match="font">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="center">
    <para>
      <paratext align="center">
      <xsl:choose>
        <xsl:when test="descendant::b">
          <xsl:apply-templates select="node()"/>
        </xsl:when>
        <xsl:otherwise>
          <bold>
            <xsl:apply-templates select="node()"/>
          </bold>
        </xsl:otherwise>
      </xsl:choose>
      </paratext>
    </para>
  </xsl:template>
  
  <xsl:template match="sup|span[@class='superscript']|span[@class='MsoFootnoteReference']">
    <super>
      <xsl:apply-templates select="node()"/>
    </super>
  </xsl:template>
  
  <xsl:template match="@align">
    <xsl:if test="not(parent::*/@style)">
      <xsl:attribute name="align">
        <xsl:value-of select="."/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@style[contains(string(.),'text-align')]">
    <xsl:attribute name="align">
      <xsl:value-of select="normalize-space(substring-before(substring-after(string(.),'text-align:'),';'))"/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="article//header"/>

  <xsl:template match="script"/>
  
  <xsl:template match="span[@property='dc:date']"/>
  
  <xsl:template match="span[@class='print-link']"/>

  <xsl:template match="span[@class='smallBold']"/>
  
  <xsl:template match="span[@class='ext']"/>
  
  <xsl:template match="span[@class='sf']"/>
  
  <xsl:template match="@class[string(.)=('rxbodyfield','Level1','MsoNormal','level1','MsoHeader','headersmall','header','MsoPlainText','MsoBodyText','MsoBodyTextIndent')]"/>

  <xsl:template match="@style[string(.)=('page-break-after: auto;','margin-top: 0in;')]"/>

  <xsl:template match="ul/@style"/>

  <xsl:template match="@dir"/>

  <xsl:template match="p/@id"/>
  
  <xsl:template match="ins|span[@style='text-decoration: underline;']">
    <underscore>
      <xsl:apply-templates select="node()"/>
    </underscore>
  </xsl:template>
  
  <xsl:template match="span[@style='font-size: small;']|span[@style='font-size: x-small;']">
    <typo.format pointsize="8.0">
      <xsl:apply-templates select="node()"/>
    </typo.format>
  </xsl:template>
  
  <xsl:template match="span[not(@*)]">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="p/@style" priority="-0.5"/>
  
  <xsl:template match="span[@style]" priority="-0.5">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="span[@title]" priority="-0.5">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="span[@dir='ltr']|span[@lang]" priority="-0.5">
      <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="span[@class='GramE']|span[@class='SpellE']|span[@class='rxbodyfield']|span[@class='level1']|span[@class='Level1']|span[@class='headertext3']|span[@class='mailto']|span[@class='MsoFootnoteText']" priority="-0.5">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="span" priority="-1">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  
  <xsl:template match="hr">
    <separator.line></separator.line>
  </xsl:template>
  
  <xsl:template match="img"/>

<!--  ________________________

      Table Element Processing
      ________________________  -->
  
  <xsl:template match="table[$doc-type='single-table']">
    <xsl:apply-templates select=".//h6"/>
  </xsl:template>

  <xsl:template match="thead|tfoot|tbody|tr|colgroup|col|caption">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="table">
    <xsl:variable name="inline-css">
      <xsl:call-template name="table-style-attributes">
        <xsl:with-param name="attr-count" as="xs:integer" select="1"/>
        <xsl:with-param name="attrs" select="@*"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="string-length($inline-css) &gt; 0">
        <xsl:attribute name="style" select="$inline-css"/>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="table-style-attributes">
    <xsl:param name="attr-count"/>
    <xsl:param name="attrs"/>
    <xsl:param name="style-ret"/>
    <xsl:choose>
      <xsl:when test="$attr-count &gt; count($attrs)">
        <xsl:value-of select="$style-ret"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="table-style-attributes">
          <xsl:with-param name="attr-count" select="$attr-count+1"/>
          <xsl:with-param name="attrs" select="$attrs"/>
          <xsl:with-param name="style-ret">
            <xsl:choose>
              <xsl:when test="local-name($attrs[$attr-count])=('cellspacing','cellpadding','border','width')">
                <xsl:value-of select="concat($style-ret,local-name($attrs[$attr-count]),':',$attrs[$attr-count],';')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$style-ret"/>
              </xsl:otherwise>  
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="td|th">
    <xsl:variable name="inline-css">
      <xsl:call-template name="cell-style-attributes">
        <xsl:with-param name="attr-count" as="xs:integer" select="1"/>
        <xsl:with-param name="attrs" select="@*"/>
        <xsl:with-param name="style-ret"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="string-length($inline-css) &gt; 0">
        <xsl:attribute name="style" select="$inline-css"/>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="cell-style-attributes">
    <xsl:param name="attr-count"/>
    <xsl:param name="attrs"/>
    <xsl:param name="style-ret"/>
    <xsl:choose>
      <xsl:when test="$attr-count &gt; count($attrs)">
        <xsl:value-of select="$style-ret"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="cell-style-attributes">
          <xsl:with-param name="attr-count" select="$attr-count+1"/>
          <xsl:with-param name="attrs" select="$attrs"/>
          <xsl:with-param name="style-ret">
            <xsl:choose>
              <xsl:when test="local-name($attrs[$attr-count])='width'">
                <xsl:value-of select="concat($style-ret,local-name($attrs[$attr-count]),':',$attrs[$attr-count],';')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$style-ret"/>
              </xsl:otherwise>  
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="col/@width">
    <xsl:attribute name="colwidth" select="."/>
  </xsl:template>
  
  <xsl:template match="col/@span">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="table/@frame|table/@rowsep|table/@type">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="table/@cellpadding|table/@cellspacing|table/@border|table/@style|table/@width|table/@summary"/>
  
  <xsl:template match="td/@colspan|th/@colspan|td/@rowspan|th/@rowspan|td/@bgcolor|th/@bgcolor|td/@align|th/@align|td/@valign|th/@valign">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="td/@width|th/@width|td/@style|th/@style|td/@id|th/@id|td/@scope|th/@scope|td/@rteleft|th/@rteleft"/>

<!--  _______________

      Text Processing
      _______________  -->

  <xsl:template match="text()">
    <xsl:if test="contains(' &#160;',substring(.,1,1))">
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:value-of select="normalize-space(translate(.,'&#160;',' '))"/>
    <xsl:if test="contains(' &#160;',substring(.,string-length(.),1))">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

