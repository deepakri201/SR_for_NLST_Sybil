WITH
  contentSequenceLevel3 AS (
  SELECT
    PatientID,
    SOPInstanceUID,
    SeriesInstanceUID,
    trackingIdentifier,
    trackingUniqueIdentifier,
    contentSequence.ConceptNameCodeSequence [
  OFFSET
    (0)] AS ConceptNameCodeSequence,
    contentSequence.ConceptCodeSequence [
  OFFSET
    (0)] AS ConceptCodeSequence
  FROM
    `idc-external-018.sr_nlst_sybil.measurement_groups`
  CROSS JOIN
    UNNEST (contentSequence.ContentSequence) AS contentSequence
  WHERE
    contentSequence.ValueType = "CODE" ),

  contentSequenceLevel3SCOORD AS (
  SELECT
    PatientID,
    SOPInstanceUID,
    SeriesInstanceUID,
    trackingIdentifier,
    trackingUniqueIdentifier,
    contentSequence
  FROM
    `idc-external-018.sr_nlst_sybil.measurement_groups`
  CROSS JOIN
    UNNEST (contentSequence.ContentSequence) AS contentSequence
  WHERE
    contentSequence.ValueType = "SCOORD"), 

  findingsAndFindingSites AS (
  WITH
    findings AS (
    SELECT
      PatientID,
      SOPInstanceUID,
      trackingIdentifier,
      trackingUniqueIdentifier,
      ConceptCodeSequence AS finding
    FROM
      contentSequenceLevel3
    WHERE
      ConceptNameCodeSequence.CodeValue = "121071"
      AND ConceptNameCodeSequence.CodingSchemeDesignator = "DCM" ),

    findingSites AS (
    SELECT
      PatientID,
      SOPInstanceUID,
      trackingIdentifier,
      ConceptCodeSequence AS findingSite
    FROM
      contentSequenceLevel3
    WHERE
      # ConceptNameCodeSequence.CodeValue = "G-C0E3"
      # AND ConceptNameCodeSequence.CodingSchemeDesignator = "SRT" 
      ConceptNameCodeSequence.CodeValue = "363698007" 
      AND ConceptNameCodeSequence.CodingSchemeDesignator = "SCT")
  SELECT
    findings.PatientID,
    findings.SOPInstanceUID,
    findings.finding,
    findings.trackingIdentifier,
    findings.trackingUniqueIdentifier,
    findingSites.findingSite
  FROM
    findings
  JOIN
    findingSites
  ON
    findings.SOPInstanceUID = findingSites.SOPInstanceUID 
    AND findings.trackingIdentifier = findingSites.trackingIdentifier )
    
SELECT
  contentSequenceLevel3.PatientID,
  contentSequenceLevel3.SeriesInstanceUID,
  contentSequenceLevel3.SOPInstanceUID,
  findingsAndFindingSites.trackingIdentifier,
  findingsAndFindingSites.trackingUniqueIdentifier,
  findingsAndFindingSites.finding,
  findingsAndFindingSites.findingSite,
  contentSequenceLevel3SCOORD.contentSequence.ContentSequence[OFFSET(0)].ReferencedSOPSequence[OFFSET(0)].ReferencedSOPInstanceUID,
  contentSequenceLevel3SCOORD.contentSequence.ConceptNameCodeSequence,
  contentSequenceLevel3SCOORD.contentSequence.GraphicType,
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(0)] as x0, 
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(1)] as y0, 
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(2)] as x1, 
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(3)] as y1, 
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(4)] as x2, 
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(5)] as y2, 
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(6)] as x3, 
  contentSequenceLevel3SCOORD.contentSequence.GraphicData[OFFSET(7)] as y3
FROM
  contentSequenceLevel3
JOIN
  findingsAndFindingSites
ON
  contentSequenceLevel3.SOPInstanceUID = findingsAndFindingSites.SOPInstanceUID 
  AND contentSequenceLevel3.trackingIdentifier = findingsAndFindingSites.trackingIdentifier
JOIN
  contentSequenceLevel3SCOORD
ON
  findingsAndFindingSites.SOPInstanceUID = contentSequenceLevel3SCOORD.SOPInstanceUID 
  AND findingsAndFindingSites.trackingIdentifier = contentSequenceLevel3SCOORD.trackingIdentifier
WHERE
  # exclude
  ( ConceptNameCodeSequence.CodeMeaning <> "121071"
    AND ConceptNameCodeSequence.CodingSchemeDesignator <> "DCM" ) AND # Finding
  ( ConceptNameCodeSequence.CodeMeaning <> "G-C0E3"
    AND ConceptNameCodeSequence.CodingSchemeDesignator <> "SRT" ) # Finding Site
ORDER BY 
  contentSequenceLevel3.PatientID, 
  contentSequenceLevel3.SeriesInstanceUID, 
  CAST(findingsAndFindingSites.trackingIdentifier AS INT64)
