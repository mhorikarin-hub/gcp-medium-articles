-- ==========================================
-- 1. Ensuring Data Integrity in BigQuery
-- ==========================================
SELECT
  LMK_KEY,
  SAFE_CAST(
    CURRENT_ENERGY_EFFICIENCY 
    AS INT64
  ) AS current_score,
  SAFE_CAST(
    POTENTIAL_ENERGY_EFFICIENCY 
    AS INT64
  ) AS potential_score
FROM 
  `your_project.dataset.table`;  

-- ==========================================
-- 2. Consolidate Recommendations into a Roadmap
-- ==========================================
SELECT
  LMK_KEY,
  STRING_AGG(
    improvement_descr, ' > ' 
    ORDER BY sequence_number
  ) AS renovation_roadmap
FROM 
  `your_project.recommendations_table`
GROUP BY 
  LMK_KEY;
