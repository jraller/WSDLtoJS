<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
	xmlns:impl="http://www.hannonhill.com/ws/ns/AssetOperationService"
	xmlns:schema="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="xd" version="1.0">
	<xd:doc scope="stylesheet">
		<xd:desc>
			<xd:p><xd:b>Created on:</xd:b> Sep 11, 2013</xd:p>
			<xd:p><xd:b>Author:</xd:b> Jason Aller</xd:p>
			<xd:p/>
		</xd:desc>
	</xd:doc>
	
	<xsl:output method="text"/>
	
	<xsl:variable name="indent" select="'    '"/>
	
	<xsl:template match="/">
		<xsl:apply-templates select="/wsdl:definitions/wsdl:binding/wsdl:operation[@name = 'move']"/> <!-- [@name = 'read'] -->
	</xsl:template>
	
	<xsl:template match="wsdl:operation">
		<xsl:variable name="operationName" select="@name"/>
		<xsl:if test="not(position() = 1)">
			<xsl:text>&#10;</xsl:text>
		</xsl:if>
		<xsl:text>/*&#10;  Operation: </xsl:text>
		<xsl:value-of select="$operationName"/>
		<xsl:text>&#10;*/&#10;</xsl:text>
		<xsl:apply-templates select="wsdl:input">
			<xsl:with-param name="operationName" select="$operationName"/>
		</xsl:apply-templates>
		<!--
		<xsl:apply-templates select="wsdl:output">
			<xsl:with-param name="operationName" select="$operationName"/>
		</xsl:apply-templates>
		-->
	</xsl:template>
	
	<xsl:template match="wsdl:input">
		<xsl:param name="operationName"/>
		<xsl:variable name="inputName" select="@name"/>
		<xsl:text>&#10;/* </xsl:text>
		<xsl:value-of select="$operationName"/>
		<xsl:text> soapArgs */</xsl:text>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $inputName]"/>
	</xsl:template>
	
	<xsl:template match="wsdl:output">
		<xsl:param name="operationName"/>
		<xsl:variable name="outputName" select="@name"/>
		<xsl:text>&#10;/* </xsl:text>
		<xsl:value-of select="$operationName"/>
		<xsl:text> return */</xsl:text>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $outputName]"/>
	</xsl:template>
	
	<xsl:template match="wsdl:message">
		<xsl:variable name="messageName" select="substring-after(wsdl:part/@element, ':')"/>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:element[@name = $messageName]" mode="message"/>
	</xsl:template>
	
	<xsl:template match="schema:element" mode="message">
		<xsl:text>&#10;var </xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:text> = {</xsl:text>
		<xsl:for-each select="schema:complexType/schema:sequence/schema:element|schema:complexType/schema:sequence/comment()">
			<xsl:variable name="elementPartName" select="@name"/>
			<xsl:variable name="elementPartType" select="@type"/>
			<xsl:choose>
				<xsl:when test="substring-before($elementPartType, ':') = 'impl'">
					<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:complexType[@name = substring-after($elementPartType, 'impl:')]">
						<xsl:with-param name="depth" select="$indent"/>
						<xsl:with-param name="name" select="$elementPartName"/>
						<xsl:with-param name="position" select="position()"/>
						<xsl:with-param name="last" select="last()"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:when test="substring-before($elementPartType, ':') = 'xsd'">
					<xsl:apply-templates select=".">
						<xsl:with-param name="depth" select="$indent"/>
						<xsl:with-param name="name" select="$elementPartName"/>
						<xsl:with-param name="position" select="position()"/>
						<xsl:with-param name="last" select="last()"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:when test="name(.) = ''">
					<xsl:apply-templates select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>&#10;I missed something</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<xsl:text>};</xsl:text>
	</xsl:template>
	
	<xsl:template match="schema:simpleType">
		<xsl:param name="depth"/>
		<xsl:param name="name"/>
		<xsl:param name="position"/>
		<xsl:param name="last"/>
		<xsl:text>&#10;</xsl:text>
		<xsl:value-of select="$depth"/>
		<xsl:value-of select="$name"/>
		<xsl:text>: ''</xsl:text>
		<xsl:if test="not($position = $last)">
			<xsl:text>,</xsl:text>
		</xsl:if>
		<xsl:text> // one of: </xsl:text>
		<xsl:for-each select="schema:restriction/schema:enumeration">
			<xsl:text>'</xsl:text>
			<xsl:value-of select="@value"/>
			<xsl:text>'</xsl:text>
			<xsl:if test="not(position() = last())">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="schema:complexType">
		<xsl:param name="depth"/>
		<xsl:param name="name"/>
		<xsl:param name="position"/>
		<xsl:param name="last"/>
		<xsl:param name="impl"/>
		<xsl:param name="maxOccurs"/>
		<xsl:choose>
			<xsl:when test="$impl = 'true'">
				<xsl:apply-templates select="schema:sequence">
					<xsl:with-param name="depth" select="$depth"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="schema:complexContent">
					<xsl:with-param name="depth" select="$depth"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="schema:choice">
					<xsl:with-param name="depth" select="$depth"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&#10;</xsl:text>
				<xsl:value-of select="$depth"/>
				<xsl:variable name="rawName">
					<xsl:choose>
						<xsl:when test="string-length($name) &gt; 0">
							<xsl:value-of select="$name"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:call-template name="wrapAsString">
					<xsl:with-param name="name" select="$rawName"/>
				</xsl:call-template>
				<xsl:text>: </xsl:text>
				<xsl:if test="$maxOccurs = 'unbounded'">
					<xsl:text>[</xsl:text>
				</xsl:if>
				<xsl:text>{</xsl:text>
				<xsl:apply-templates select="schema:sequence">
					<xsl:with-param name="depth" select="concat($depth, $indent)"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="schema:complexContent">
					<xsl:with-param name="depth" select="concat($depth, $indent)"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="schema:choice">
					<xsl:with-param name="depth" select="concat($depth, $indent)"/>
				</xsl:apply-templates>
				<xsl:text>&#10;</xsl:text>
				<xsl:value-of select="$depth"/>
				<xsl:text>}</xsl:text>
				<xsl:choose>
					<xsl:when test="not($position = $last)">
						<xsl:text>,</xsl:text>
					</xsl:when>
					<xsl:when test="string-length($depth) &gt; string-length($indent)">
						<xsl:text/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>&#10;</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="schema:sequence">
		<xsl:param name="depth"/>
		<xsl:for-each select="schema:element|comment()">
			<xsl:apply-templates select=".">
				<xsl:with-param name="depth" select="$depth"/>
				<xsl:with-param name="position" select="position()"/>
				<xsl:with-param name="last" select="last()"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:apply-templates select="schema:choice">
			<xsl:with-param name="depth" select="$depth"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="schema:complexContent">
		<xsl:param name="depth"/>
		<xsl:apply-templates select="schema:extension">
			<xsl:with-param name="depth" select="$depth"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="schema:extension">
		<xsl:param name="depth"/>
		<xsl:variable name="base" select="substring-after(@base, 'impl:')" />
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:complexType[@name = $base]">
			<xsl:with-param name="depth" select="$depth"/>
			<xsl:with-param name="impl" select="'true'"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="schema:sequence">
			<xsl:with-param name="depth" select="$depth"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="schema:choice">
		<xsl:param name="depth"/>
		<xsl:apply-templates select="schema:element">
			<xsl:with-param name="depth" select="$depth"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="schema:element">
		<xsl:param name="depth"/>
		<xsl:param name="position"/>
		<xsl:param name="last"/>
		<xsl:variable name="elementName" select="@name"/>
		<xsl:variable name="elementType" select="substring-after(@type, 'impl:')"/>
		
		<xsl:if test="substring(@type, 1, 4) = 'xsd:' or type = 'impl:structured-data-nodes'">
			<xsl:text>&#10;</xsl:text>
			<xsl:value-of select="$depth"/>
			<xsl:value-of select="@name"/>
			<xsl:text>: </xsl:text>           
		</xsl:if>
		<xsl:choose>
			<xsl:when test="@type = 'impl:structured-data-nodes'">
				<xsl:text>impl:structured-data-nodes</xsl:text>
			</xsl:when>
			<xsl:when test="substring(@type, 1, 5) = 'impl:'">
				<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:complexType[@name = $elementType]">
					<xsl:with-param name="depth" select="$depth"/>
					<xsl:with-param name="name" select="$elementName"/>
					<xsl:with-param name="maxOccurs" select="@maxOccurs"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:simpleType[@name = $elementType]">
					<xsl:with-param name="depth" select="$depth"/>
					<xsl:with-param name="name" select="$elementName"/>
					<xsl:with-param name="maxOccurs" select="@maxOccurs"/>
					<xsl:with-param name="position" select="$position"/>
					<xsl:with-param name="last" select="$last"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="@type = 'xsd:anyURI'">
				<xsl:text>'http://hannonhill.com'</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'xsd:base64Binary'">
				<xsl:text>'base64 encoded content'</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'xsd:boolean'">
				<xsl:text>'false'</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'xsd:dateTime'">
				<xsl:text>new Date()</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'xsd:nonNegativeInteger'">
				<xsl:text>2</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'xsd:positiveInteger'">
				<xsl:text>42</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'xsd:string'">
				<xsl:text>''</xsl:text>
			</xsl:when>
			<xsl:when test="@type = 'xsd:time'">
				<xsl:text>new Date()</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>You forgot one</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="substring(@type, 1, 5) = 'impl:' and @maxOccurs = 'unbounded'">
			<xsl:text>]</xsl:text>
		</xsl:if>
		<xsl:if test="not($position = $last) and count(/wsdl:definitions/wsdl:types/schema:schema/schema:simpleType[@name = $elementType]) = 0">
			<xsl:text>,</xsl:text>
		</xsl:if>
		<xsl:text> // </xsl:text>
		<xsl:value-of select="@type"/>
		<xsl:if test="@nillable = 'true'">
			<xsl:text> nillable</xsl:text>
		</xsl:if>
		<xsl:if test="@minOccurs > 0">
			<xsl:text> required</xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="@maxOccurs = 1"/>
			<xsl:when test="@maxOccurs = 'unbounded'">
				<xsl:text> unbounded</xsl:text>
			</xsl:when>
			<xsl:when test="string-length(@maxOccurs) = 0"/>			
			<xsl:otherwise>
				<xsl:text> occurs </xsl:text>
				<xsl:value-of select="@maxOccurs"/>
				<xsl:text> times</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="string-length($depth) &gt; string-length($indent)">
				<xsl:text/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&#10;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="comment()">
		<xsl:text> /* </xsl:text>
		<xsl:value-of select="normalize-space(.)"/>
		<xsl:text> */</xsl:text>
	</xsl:template>
	
	<xsl:template name="wrapAsString">
		<xsl:param name="name"/>
		<xsl:choose>
			<xsl:when test="string-length($name) &gt; string-length(translate($name, '-', '')) or $name = 'delete'">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="$name"/>
				<xsl:text>'</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$name"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>
