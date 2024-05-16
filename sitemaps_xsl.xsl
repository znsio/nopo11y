<?xml version="1.0" encoding="UTF-8"?><xsl:stylesheet version="2.0"
				xmlns:html="http://www.w3.org/TR/REC-html40"
				xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
				xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>XML Sitemaps</title><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<style type="text/css">
	* {
		margin: 0;
		padding: 0;
		box-sizing: border-box;
	}
	body {
		background: #F7F7F7;
		font-size: 14px;
		font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;
	}
	h1 {
		color: #23282d;
		font-weight:bold;
		font-size:20px;
		margin: 20px 0;
	}
	p {
		margin: 0 0 15px 0;
	}
	p a {
		color: rgb(0, 135, 190);
	}
	p.footer {
		padding: 15px;
	    background: rgb(250, 251, 252) none repeat scroll 0% 0%;
	    margin: 10px 0px 0px;
	    display: inline-block;
	    width: 100%;
	    color: rgb(68, 68, 68);
	    font-size: 13px;
	    border-top: 1px solid rgb(224, 224, 224);
	}
	#main {
		margin: 0 auto;
		max-width: 55rem;
		padding: 1.5rem;
		width: 100%;
	}
	#sitemaps {
		width: 100%;
		box-shadow: 0 0 0 1px rgba(224, 224, 224, 0.5),0 1px 2px #a8a8a8;
		background: #fff;
		margin-top: 20px;
		display: inline-block;
	}
	#sitemaps .loc, #sitemaps .lastmod {
	    font-weight: bold;
	    display: inline-block;
	    border-bottom: 1px solid rgba(224, 224, 224, 1);
	    padding: 15px;
	}
	#sitemaps .loc {
		width: 70%;
	}
	#sitemaps .lastmod {
		width: 30%;
		padding-left: 0;
	}
	#sitemaps ul {
	    margin: 10px 0;
	    padding: 0;
	}
	#sitemaps li {
	    list-style: none;
	    padding: 10px 15px;
	}
	#sitemaps li a {
	    color: rgb(0, 135, 190);
	    text-decoration: none;
	}
	#sitemaps li:hover{
		background:#F3F6F8;
	}
	#sitemaps .item-loc {
	    width: 70%;
	    display: inline-block;
	}
	#sitemaps .item-lastmod {
		width: 30%;
	    display: inline-block;
		padding: 0 10px;
	}</style></head><body><div id="main"><h1>XML Sitemaps</h1><p><a href="/sitemaps.xml">Index sitemaps</a></p><xsl:if test="sitemap:sitemapindex/sitemap:sitemap"><p>This XML Sitemap Index file contains <xsl:value-of select="count(sitemap:sitemapindex/sitemap:sitemap)"/> sitemaps.</p></xsl:if><xsl:if test="sitemap:urlset/sitemap:url"><p>This XML Sitemap contains <xsl:value-of select="count(sitemap:urlset/sitemap:url)"/> URL(s).</p></xsl:if><div id="sitemaps"><div class="loc">URL</div><div class="lastmod">Last update</div><ul><xsl:for-each select="sitemap:sitemapindex/sitemap:sitemap"><li><xsl:variable name="sitemap_loc"><xsl:value-of select="sitemap:loc"/></xsl:variable><span class="item-loc"><a href="{$sitemap_loc}"><xsl:value-of select="sitemap:loc" /></a></span><span class="item-lastmod"><xsl:value-of select="sitemap:lastmod" /></span></li></xsl:for-each></ul><ul><xsl:for-each select="sitemap:urlset/sitemap:url"><li><xsl:variable name="url_loc"><xsl:value-of select="sitemap:loc"/></xsl:variable><span class="item-loc"><a href="{$url_loc}"><xsl:value-of select="sitemap:loc" /></a></span><xsl:if test="sitemap:lastmod"><span class="item-lastmod"><xsl:value-of select="sitemap:lastmod" /></span></xsl:if></li></xsl:for-each></ul></div></div></body></html></xsl:template></xsl:stylesheet>