<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
	xmlns:impl="http://www.hannonhill.com/ws/ns/AssetOperationService"
	xmlns:schema="http://www.w3.org/2001/XMLSchema" 
	xmlns:exsl="http://exslt.org/common"
	extension-element-prefixes="exsl"
	exclude-result-prefixes="xd wsdl impl schema" version="1.0">

	<xd:doc scope="stylesheet">
		<xd:desc>
			<xd:p><xd:b>Created on:</xd:b> Sep 11, 2013</xd:p>
			<xd:p><xd:b>Author:</xd:b> Jason Aller</xd:p>
			<xd:p/>
		</xd:desc>
	</xd:doc>

	<xsl:output method="html"/>

	<!-- set the characters for indent. 4 spaces for JSLint, 2 spaces for github -->
	<xsl:variable name="indent" select="'    '"/>

	<xsl:variable name="operations">
		<operations>
			<xsl:for-each
				select="/wsdl:definitions/wsdl:binding/wsdl:operation[not(@name = 'read' or @name = 'create' or @name = 'edit' or @name = 'batch')]">
				<xsl:apply-templates select="."/>
			</xsl:for-each>
		</operations>
	</xsl:variable>

	<!-- process a call -->
	<xsl:template match="wsdl:operation">
		<xsl:variable name="operationName" select="@name"/>
		<operation name="{$operationName}">
		<xsl:apply-templates select="wsdl:input"/>
		<xsl:apply-templates select="wsdl:output"/>
		</operation>
	</xsl:template>

	<!-- process the arguments for the call -->
	<xsl:template match="wsdl:input">
		<xsl:variable name="inputName" select="@name"/>
		<soapArgs>
			<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $inputName]"/>
		</soapArgs>
	</xsl:template>

	<!-- process the return of the call -->
	<xsl:template match="wsdl:output">
		<xsl:variable name="outputName" select="@name"/>
		<response>
			<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $outputName]"/>
		</response>
	</xsl:template>

	<!-- messages of a call map to schema root elements of the same name -->
	<xsl:template match="wsdl:message">
		<xsl:variable name="messageName" select="substring-after(wsdl:part/@element, ':')"/>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:element[@name = $messageName]" mode="message"/>
	</xsl:template>

	<!-- schema element in message mode, see below for child element processing -->
	<xsl:template match="schema:element" mode="message">
		<xsl:for-each select="schema:complexType/schema:sequence/schema:element"> <!-- |schema:complexType/schema:sequence/comment() -->
			<xsl:variable name="elementPartName" select="@name"/>
			<xsl:variable name="elementPartType" select="@type"/>
			<xsl:choose>
				<xsl:when test="substring-before($elementPartType, ':') = 'impl'">
					<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:complexType[@name = substring-after($elementPartType, 'impl:')]">
						<xsl:with-param name="name" select="$elementPartName"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:when test="substring-before($elementPartType, ':') = 'xsd'">
					<xsl:apply-templates select=".">
						<xsl:with-param name="name" select="$elementPartName"/>
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
	</xsl:template>

	<!-- complexType -->
	<xsl:template match="schema:complexType">
		<xsl:param name="name"/>
		<xsl:param name="impl"/>
		<xsl:param name="maxOccurs"/>
		<complex>
			<xsl:attribute name="name">
				<xsl:value-of select="$name"/>
			</xsl:attribute>
		<xsl:choose>
			<xsl:when test="$impl = 'true'">
				<xsl:apply-templates select="schema:sequence|schema:complexContent/schema:extension|schema:choice/schema:element">
					<xsl:with-param name="impl"/>
					<xsl:with-param name="maxOccurs" select="$maxOccurs"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="schema:sequence|schema:complexContent/schema:extension|schema:choice/schema:element">
					<xsl:with-param name="maxOccurs" select="$maxOccurs"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
		</complex>
	</xsl:template>

	<xsl:template match="schema:extension">
		<xsl:param name="depth"/>
		<xsl:variable name="base" select="substring-after(@base, 'impl:')"/>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:complexType[@name = $base]">
			<xsl:with-param name="impl" select="'true'"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="schema:sequence">
			<xsl:with-param name="impl" select="'true'"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="schema:sequence">
		<xsl:param name="depth"/>
		<xsl:param name="impl"/>
		<xsl:for-each select="schema:element|schema:choice/schema:element|comment()">
			<xsl:apply-templates select=".">
				<xsl:with-param name="impl" select="$impl"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
    
    <!-- simpleTypes are generally strings with a predetermined set of valid values -->
    <xsl:template match="schema:simpleType">
        <xsl:param name="name"/>
		<element>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="name">
				<xsl:value-of select="$name"/>
			</xsl:attribute>
			<xsl:attribute name="list">
				<xsl:for-each select="schema:restriction/schema:enumeration">
					<xsl:text>'</xsl:text>
					<xsl:value-of select="@value"/>
					<xsl:text>'</xsl:text>
					<xsl:if test="not(position() = last())">
						<xsl:text>, </xsl:text>
					</xsl:if>
				</xsl:for-each>				
			</xsl:attribute>
		</element>
    </xsl:template>
    
	<xsl:template match="schema:element">
		<xsl:param name="impl"/>
		<xsl:variable name="elementName" select="@name"/>
		<xsl:variable name="elementType" select="substring-after(@type, 'impl:')"/>
		<xsl:choose>
			<xsl:when test="@type = 'impl:structured-data-nodes'">
				<xsl:copy-of select="."/>
			</xsl:when>
			<xsl:when test="substring(@type, 1, 5) = 'impl:'">
			    <!--
				<xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:complexType[@name = $elementType]">
					<xsl:with-param name="depth" select="$depth"/>
					<xsl:with-param name="name" select="$elementName"/>
					<xsl:with-param name="maxOccurs" select="@maxOccurs"/>
				</xsl:apply-templates>
			    -->
			    <xsl:apply-templates select="/wsdl:definitions/wsdl:types/schema:schema/schema:complexType[@name = $elementType]|/wsdl:definitions/wsdl:types/schema:schema/schema:simpleType[@name = $elementType]">
					<xsl:with-param name="name" select="$elementName"/>
					<xsl:with-param name="maxOccurs" select="@maxOccurs"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="substring(@type, 1, 4) = 'xsd:'">
				<element>
					<xsl:copy-of select="@*"/>
				</element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>You forgot one</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="substring(@type, 1, 5) = 'impl:' and @maxOccurs = 'unbounded'">
			<xsl:text>]</xsl:text>
		</xsl:if>


	</xsl:template>

	<!-- The main rule -->
	<xsl:template match="/">
		<xsl:copy-of select="exsl:node-set($operations)"/>
	</xsl:template>
	

	<xsl:template match="comment()">
		<xsl:comment><xsl:value-of select="normalize-space(.)"/></xsl:comment>
	</xsl:template>

	<xsl:template name="wrapAsString">
		<xsl:param name="name"/>
		<xsl:choose>
			<xsl:when test="string-length($name) &gt; string-length(translate($name, '-', ''))">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="$name"/>
				<xsl:text>'</xsl:text>
			</xsl:when>
			<xsl:when test="$name = 'delete'">
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
