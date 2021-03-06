<?xml version="1.0" encoding="UTF-8"?>
<stylesheet version="2.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:mei2svg="NS:MEI2SVG">
  
  <import href="preprocessor/reduceToMdiv.xsl"/>
  <import href="preprocessor/add-ids.xsl"/>
  <import href="preprocessor/canonicalize.xsl"/>
  <import href="preprocessor/addDurations.xsl"/>
  <import href="preprocessor/addSynchronicity.xsl"/>
  <import href="preprocessor/anyuri2idref.xsl"/>
  <import href="preprocessor/addPlists.xsl"/>
  <import href="mei2musx/mei2musx.xsl"/>
  <import href="formatter/createSubevents.xsl"/>
  <import href="formatter/accidentalFormatter.xsl"/>
  <import href="formatter/spacing.xsl"/>
  <import href="formatter/beams.xsl"/>
  <import href="musx2svg/musx2svg.xsl"/>
  <import href="postprocessor/svgCleaner.xsl"/>
  
  
  <!-- Additional imports to fix base-path problem -->
  <import href="preprocessor/fraction.xsl"/>
  <import href="preprocessor/contentChronologyKeys.xsl"/>
  
  <import href="musx2svg/math/math.xsl"/>
  <import href="musx2svg/math/internals.xsl"/>
  <import href="musx2svg/math/internals.logging.xsl"/>
  <import href="musx2svg/math/strings.xsl"/>
  
  <import href="formatter/update.xsl"/>
  
  <include href="mei2musx/beams.xsl"/>
  <include href="mei2musx/notes.xsl"/>
  
  
  <output exclude-result-prefixes="svg"/>
  
  <!-- Mainly for debugging purposes we allow a to-be-processed file to contain a processing instruction of the form
         <?mei2svg firstStep="foo" outputStep="bar" omitSteps="baz"?> 
       where foo and bar are names of steps, baz being a list of steps. They have the very same effect 
       a specifying them as parameters to the stylesheet. This way we can create test files that themselves
       tell the stylesheet what specific step(s) it's meant to test. -->
  <function name="mei2svg:extractPIattribute" as="xs:string?">
    <param name="attributeName" as="xs:string"/>
    <param name="piString" as="xs:string?"/>
    <analyze-string select="($piString,'')[1] (: In case $piString is an empty sequence, supply an empty string :)" 
        regex="{$attributeName}=&quot;([^&quot;]*)&quot;">
      <matching-substring>
        <value-of select="regex-group(1)"/>
      </matching-substring>
    </analyze-string>
  </function>
  
  <variable name="mei2svgProcessingInstruction" select="//processing-instruction()[local-name()='mei2svg']" as="xs:string?"/>
  <variable name="firstStepInPI" select="mei2svg:extractPIattribute('firstStep',$mei2svgProcessingInstruction)" as="xs:string?"/>
  <variable name="outputStepInPI" select="mei2svg:extractPIattribute('outputStep',$mei2svgProcessingInstruction)" as="xs:string?"/>
  <variable name="omitStepsInPI" select="mei2svg:extractPIattribute('omitSteps',$mei2svgProcessingInstruction)" as="xs:string?"/>
  
  <param name="omitSteps" select="($omitStepsInPI,'')[1]" as="xs:string"/>

  <variable name="fullStepList" select="('reducedMEI','MEIwithIDs','canonicalizedMEI',
    'MEIwithDurations','MEIwithSynch','MEIwithIDREFs','MEIwithPlists','musx','musxWithSubevents',
    'musxAccidentalsFormatted','spacedMusx','musxWithFormattedBeams','svg','cleanedSvg')" as="xs:string+"/>
  <variable name="steps" select="for $stepName in $fullStepList
                                 return if(not($stepName = tokenize($omitSteps,'\s+'))) 
                                        then $stepName 
                                        else ()" as="xs:string+"/>
  <param name="firstStep" select="($firstStepInPI,$steps[1])[1]" as="xs:string"/>
  <param name="outputStep" select="($outputStepInPI,$steps[last()])[1]" as="xs:string"/>
  
  <template match="/" priority="10">
    <param name="currentStep" select="$firstStep" as="xs:string"/>
    
    <message>Generating <value-of select="$currentStep"/>...</message>
    
    <variable name="intermediateDocument" as="document-node()">
      <document>
        <choose>
          <when test="not($currentStep = $steps)">
            <message terminate="yes">ERROR: Invalid step "<value-of select="$outputStep"/>"
              <if test="$currentStep = $fullStepList">This step has been suppressed using the omitSteps parameter or processing instruction.</if>
              Possible values for parameters firstStep and outputStep are:
              <value-of select="$steps" separator=", "/>
            </message>
          </when>
          <when test="$currentStep = 'reducedMEI'">
            <apply-templates select="." mode="reduceToMdiv"/>
          </when>
          <when test="$currentStep = 'MEIwithIDs'">
            <apply-templates select="." mode="add-ids"/>
          </when>
          <when test="$currentStep = 'canonicalizedMEI'">
            <apply-templates select="." mode="canonicalize"/>
          </when>
          <when test="$currentStep = 'MEIwithDurations'">
            <apply-templates select="." mode="addDurations"/>
          </when>
          <when test="$currentStep = 'MEIwithSynch'">
            <apply-templates select="." mode="addSynchronicity"/>
          </when>
          <when test="$currentStep = 'MEIwithIDREFs'">
            <apply-templates select="." mode="anyuri2idref"/>
          </when>
          <when test="$currentStep = 'MEIwithPlists'">
            <apply-templates select="." mode="add-plists"/>
          </when>
          <when test="$currentStep = 'musx'">
            <apply-templates select="." mode="mei2musx"/>
          </when>
          <when test="$currentStep = 'musxWithSubevents'">
            <apply-templates select="." mode="create-subevents"/>
          </when>
          <when test="$currentStep = 'musxAccidentalsFormatted'">
            <apply-templates select="." mode="accidentalFormatter"/>
          </when>
          <when test="$currentStep = 'spacedMusx'">
            <apply-templates select="." mode="spacing"/>
          </when>
          <when test="$currentStep = 'musxWithFormattedBeams'">
            <apply-templates select="." mode="format-beams"/>
          </when>
          <when test="$currentStep = 'svg'">
            <apply-templates select="." mode="musx2svg"/>
          </when>
          <when test="$currentStep = 'cleanedSvg'">
            <apply-templates select="." mode="clean-svg"/>
          </when>
        </choose>
      </document>
    </variable>
    
    <choose>
      <when test="$currentStep = $outputStep">
        <sequence select="$intermediateDocument"/>
        <message>Done.</message>
      </when>
      <otherwise>
        <variable name="nextStepIndex" select="index-of($steps,$currentStep)+1" as="xs:integer"/>
        <apply-templates select="$intermediateDocument">
          <with-param name="currentStep" select="$steps[$nextStepIndex]" as="xs:string"/>
        </apply-templates>
      </otherwise>
    </choose>
  </template>
  
</stylesheet>