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
	<xsl:variable name="indent" select="'  '"/>

	<xsl:variable name="operations">
		<operations>
			<xsl:for-each select="/wsdl:definitions/wsdl:binding/wsdl:operation">
				<!-- [not(@name = 'read' or @name = 'create' or @name = 'edit' or @name = 'batch')] -->
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
		
		<xsl:choose>
			<xsl:when test="$name">
				<complex>
					<xsl:attribute name="name">
						<xsl:value-of select="$name"/>
					</xsl:attribute>
					<xsl:attribute name="maxOccurs">
						<xsl:value-of select="$maxOccurs"/>
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
			</xsl:when>
			<xsl:otherwise>
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
			</xsl:otherwise>
		</xsl:choose>
		
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
				<element>
					<xsl:copy-of select="@*"/>
				</element>
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
	</xsl:template>

	<!-- The main rule -->
	<xsl:template match="/">
		<xsl:apply-templates select="exsl:node-set($operations)/operations" mode="js"/>
<!--		<xsl:copy-of select="exsl:node-set($operations)/operations"/>-->
	</xsl:template>

	<xsl:template match="operation" mode="js">
		<xsl:text>/* </xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:text> */&#10;</xsl:text>
		<xsl:apply-templates mode="js"/>
	</xsl:template>

	<xsl:template match="soapArgs" mode="js">
		<xsl:text>var </xsl:text>
		<xsl:call-template name="wrapAsString">
			<xsl:with-param name="name" select="concat('soapArgsFor', ../@name)"/>
		</xsl:call-template>
		<xsl:text> = {&#10;</xsl:text>
		<xsl:apply-templates mode="js">
			<xsl:with-param name="depth" select="$indent"/>
		</xsl:apply-templates>
		<xsl:text>};&#10;</xsl:text>
	</xsl:template>

	<xsl:template match="response" mode="js">
		<xsl:text>var </xsl:text>
		<xsl:call-template name="wrapAsString">
			<xsl:with-param name="name" select="concat('responseFor', ../@name)"/>
		</xsl:call-template>
		<xsl:text> = {&#10;</xsl:text>
		<xsl:apply-templates mode="js">
			<xsl:with-param name="depth" select="$indent"/>
		</xsl:apply-templates>
		<xsl:text>};&#10;</xsl:text>
	</xsl:template>

	<xsl:template match="complex" mode="js">
		<xsl:param name="depth"/>
		<xsl:param name="more"/>
		<xsl:choose>
			<xsl:when test="string-length(@name) &gt; 0">
				<xsl:value-of select="$depth"/>
				<xsl:call-template name="wrapAsString">
					<xsl:with-param name="name" select="@name"/>
				</xsl:call-template>
				<xsl:text>: </xsl:text>
				<xsl:if test="@maxOccurs = 'unbounded'">
					<xsl:text>[</xsl:text>
				</xsl:if>
				<xsl:text>{&#10;</xsl:text>
				<xsl:apply-templates mode="js">
					<xsl:with-param name="depth" select="concat($depth, $indent)"/>
				</xsl:apply-templates>
				<xsl:value-of select="$depth"/>
				<xsl:text>}</xsl:text>
				<xsl:if test="@maxOccurs = 'unbounded'">
					<xsl:text>]</xsl:text>
				</xsl:if>
				<xsl:if test="not(position() = last()) or $more">
					<xsl:text>,</xsl:text>
				</xsl:if>
				<xsl:if test="position() = last() and not($depth)">
					<xsl:text>;</xsl:text>
				</xsl:if>
				<xsl:text>&#10;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="js">
					<xsl:with-param name="depth" select="$depth"/>
					<xsl:with-param name="more" select="'flag'"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="element" mode="js">
		<xsl:param name="depth"/>
		<xsl:param name="more"/>
		<xsl:value-of select="$depth"/>
		<xsl:call-template name="wrapAsString">
			<xsl:with-param name="name" select="@name"/>
		</xsl:call-template>
		<xsl:text>: </xsl:text>

		<xsl:choose>
			<xsl:when test="@list">
				<xsl:text>''</xsl:text>
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
			<xsl:when test="@type = 'impl:structured-data-nodes'">
				<xsl:text>{}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>You forgot one</xsl:text>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:if test="not(position() = last()) or $more">
			<xsl:text>,</xsl:text>
		</xsl:if>

		<xsl:text>  // </xsl:text>
		
		<xsl:if test="@list">
			<xsl:text> one of: </xsl:text>
			<xsl:value-of select="@list"/>
			<xsl:text> </xsl:text>
		</xsl:if>
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
		
		<xsl:text>&#10;</xsl:text>
	</xsl:template>

	<xsl:template match="comment()" mode="js">
		<xsl:param name="depth"/>
		<xsl:value-of select="$depth"/>
		<xsl:text>/* </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text> */</xsl:text>
		<xsl:text>&#10;</xsl:text>
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
			<xsl:when test="$name = 'delete' or $name = 'value'">
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
