-- ====================================================================
-- 1. CREATE CONNECTION & INITIALIZE GEMINI MODEL
-- ====================================================================
-- Instantiate the Gemini 2.5 Flash Model within BigQuery
CREATE OR REPLACE MODEL 
  `your-project-id.property_matcher_dataset.gemini_flash_resolver`
REMOTE WITH CONNECTION 
  `us-central1.gemini-bq-conn`
OPTIONS (
  ENDPOINT = 'gemini-2.5-flash'
);

-- ====================================================================
-- 2. STAGING LAND REGISTRY RAW DATA
-- ====================================================================
CREATE OR REPLACE TABLE
  `your-project-id.property_matcher_dataset.tmp_land_registry_stg`
AS
SELECT
  MD5(
    CONCAT(postcode, '_', address_line1, '_', deed_date)
  ) AS unique_id,
  UPPER(postcode) AS postcode,
  UPPER(address_line1) AS full_address_land,
  price_paid,
  property_type,
  deed_date
FROM
  `your-project-id.property_matcher_dataset.land_raw`
WHERE
  postcode LIKE 'SY1%';

-- ====================================================================
-- 3. STAGING EPC REGISTRY RAW DATA
-- ====================================================================
CREATE OR REPLACE TABLE
  `your-project-id.property_matcher_dataset.tmp_epc_registry_stg`
AS
SELECT
  lmk_key,
  UPPER(postcode) AS postcode,
  UPPER(address) AS full_address_epc,
  total_floor_area,
  construction_age_band,
  inspection_date
FROM
  `your-project-id.property_matcher_dataset.epc_raw`
WHERE
  postcode LIKE 'SY1%';

-- ====================================================================
-- 4. RUN AI-DRIVEN ADDRESS RESOLUTION (GEMINI LLM)
-- ====================================================================
CREATE OR REPLACE TABLE
  `your-project-id.property_matcher_dataset.tmp_matched_results_raw`
AS
SELECT
  L.unique_id,
  E.lmk_key,
  L.full_address_land,
  E.full_address_epc,
  L.price_paid,
  L.property_type,
  E.total_floor_area,
  E.construction_age_band,
  L.deed_date,
  E.inspection_date,
  
  ML.GENERATE_TEXT(
    MODEL 
      `your-project-id.property_matcher_dataset.gemini_flash_resolver`,
    (
      SELECT CONCAT(
        'You are an expert UK real estate data auditor. ',
        'Compare these two addresses from different registries ',
        'and determine if they represent the EXACT same ',
        'physical property unit.\n\n',
        'Land Registry Address: ', L.full_address_land, '\n',
        'EPC Registry Address: ', E.full_address_epc, '\n\n',
        'Respond STRICTLY with a valid JSON object matching ',
        'this schema:\n',
        '{\n',
        '  "is_identical_property": boolean,\n',
        '  "confidence_score": float (0.0 to 1.0),\n',
        '  "reasoning": "string explanation in English"\n',
        '}'
      ) AS prompt
    ),
    STRUCT(
      0.0 AS temperature, 
      'json' AS response_mime_type
    )
  ) AS ai_response_raw
FROM
  `your-project-id.property_matcher_dataset.tmp_land_registry_stg` AS L
INNER JOIN
  `your-project-id.property_matcher_dataset.tmp_epc_registry_stg` AS E
ON
  L.postcode = E.postcode;

-- ====================================================================
-- 5. PARSE AI RESPONSE AND STRUCTURE DATA
-- ====================================================================
CREATE OR REPLACE TABLE
  `your-project-id.property_matcher_dataset.analytic_matched_properties_final`
AS
WITH parsed_data AS (
  SELECT
    unique_id,
    lmk_key,
    full_address_land,
    full_address_epc,
    price_paid,
    property_type,
    total_floor_area,
    construction_age_band,
    deed_date,
    inspection_date,
    
    SAFE_CAST(
      JSON_VALUE(ai_response_raw, '$.is_identical_property') 
      AS BOOL
    ) AS is_identical_property,
    
    SAFE_CAST(
      JSON_VALUE(ai_response_raw, '$.confidence_score') 
      AS NUMERIC
    ) AS confidence_score,
    
    JSON_VALUE(
      ai_response_raw, '$.reasoning'
    ) AS ai_reasoning
  FROM
    `your-project-id.property_matcher_dataset.tmp_matched_results_raw`
)
SELECT 
  * FROM 
  parsed_data
WHERE 
  is_identical_property IS NOT NULL;

-- ====================================================================
-- 6. GENERATE INITIAL DATA MART FOR VALIDATED PROPERTIES
-- ====================================================================
CREATE OR REPLACE TABLE
  `your-project-id.property_matcher_dataset.mart_matched_properties_validated`
AS
SELECT 
  unique_id,
  lmk_key,
  full_address_land,
  full_address_epc,
  deed_date,
  inspection_date,
  
  DATE_DIFF(
    CAST(deed_date AS DATE), 
    CAST(inspection_date AS DATE), 
    YEAR
  ) AS transaction_inspection_year_diff,
  
  price_paid,
  property_type,
  total_floor_area,
  
  SAFE_DIVIDE(
    price_paid, 
    total_floor_area
  ) AS price_per_sqm,
  
  construction_age_band,
  confidence_score,
  ai_reasoning
FROM 
  `your-project-id.property_matcher_dataset.analytic_matched_properties_final`
WHERE 
  is_identical_property = TRUE;

-- ====================================================================
-- 7. AUDIT DATA TIMELINE & GAP ANALYSIS
-- ====================================================================
SELECT 
  transaction_inspection_year_diff,
  COUNT(*) as record_count
FROM 
  `your-project-id.property_matcher_dataset.mart_matched_properties_validated`
GROUP BY 
  transaction_inspection_year_diff
ORDER BY 
  transaction_inspection_year_diff DESC;

-- ====================================================================
-- 8. PRODUCE OPTIMIZED DATA MART V2 (DEDUPLICATED & OUTLIER FILTERED)
-- ====================================================================
CREATE OR REPLACE TABLE
  `your-project-id.property_matcher_dataset.mart_matched_properties_validated_v2`
AS
WITH ranked_matches AS (
  SELECT 
    unique_id,
    lmk_key,
    full_address_land,
    full_address_epc,
    deed_date,
    inspection_date,
    transaction_inspection_year_diff,
    price_paid,
    property_type,
    total_floor_area,
    price_per_sqm,
    construction_age_band,
    confidence_score,
    ai_reasoning,
    
    ROW_NUMBER() OVER(
      PARTITION BY unique_id 
      ORDER BY ABS(transaction_inspection_year_diff) ASC
    ) AS proximity_rank
  FROM 
    `your-project-id.property_matcher_dataset.mart_matched_properties_validated`
  WHERE 
    ABS(transaction_inspection_year_diff) <= 10
)
SELECT 
  R.unique_id,
  R.lmk_key,
  R.full_address_land,
  R.full_address_epc,
  RAW.postcode, 
  R.deed_date,
  R.inspection_date,
  R.transaction_inspection_year_diff,
  R.price_paid,
  R.property_type,
  R.total_floor_area,
  R.price_per_sqm,
  R.construction_age_band,
  R.confidence_score,
  R.ai_reasoning
FROM 
  ranked_matches AS R
INNER JOIN
  `your-project-id.property_matcher_dataset.land_raw` AS RAW
ON
  R.unique_id = RAW.unique_id
WHERE 
  R.proximity_rank = 1
ORDER BY 
  R.deed_date DESC;
