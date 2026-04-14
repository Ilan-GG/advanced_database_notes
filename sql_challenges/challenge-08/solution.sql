--  — Indexes: Setup
-- Creates the patient_visits table and populates 100,000 rows
-- Run this once before the other scripts
-- Oracle 23ai / freesql.com
-- ============================================================

-- Drop if exists (safe to re-run)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE patient_visits';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Create the table
CREATE TABLE patient_visits (
    visit_id     NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id   NUMBER         NOT NULL,
    site_id      NUMBER         NOT NULL,
    visit_date   DATE           NOT NULL,
    status       VARCHAR2(20)   NOT NULL,   -- 'scheduled', 'completed', 'cancelled'
    diagnosis    VARCHAR2(100),
    amount_usd   NUMBER(10,2)
);

-- Insert 100,000 rows using a single INSERT with CONNECT BY
-- patient_id: 1–10,000 (high cardinality — good for indexing)
-- site_id: 1–5 (low cardinality — bad for indexing)
-- status: 3 values (very low cardinality)
INSERT INTO patient_visits (patient_id, site_id, visit_date, status, diagnosis, amount_usd)
SELECT
    TRUNC(DBMS_RANDOM.VALUE(1, 10001))           AS patient_id,
    TRUNC(DBMS_RANDOM.VALUE(1, 6))               AS site_id,
    SYSDATE - TRUNC(DBMS_RANDOM.VALUE(0, 730))  AS visit_date,
    CASE TRUNC(DBMS_RANDOM.VALUE(1, 4))
        WHEN 1 THEN 'scheduled'
        WHEN 2 THEN 'completed'
        ELSE        'cancelled'
    END                                          AS status,
    CASE TRUNC(DBMS_RANDOM.VALUE(1, 6))
        WHEN 1 THEN 'Hypertension'
        WHEN 2 THEN 'Diabetes'
        WHEN 3 THEN 'Routine checkup'
        WHEN 4 THEN 'Fracture'
        ELSE        'Respiratory infection'
    END                                          AS diagnosis,
    ROUND(DBMS_RANDOM.VALUE(50, 500), 2)         AS amount_usd
FROM dual
CONNECT BY LEVEL <= 50000;

COMMIT;

-- Collect stats so Oracle's optimizer has accurate information
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'PATIENT_VISITS',
        cascade => TRUE
    );
END;
/

-- Verify the data
SELECT COUNT(*) AS total_rows FROM patient_visits;
SELECT status, COUNT(*) AS cnt FROM patient_visits GROUP BY status ORDER BY status;
SELECT MIN(patient_id), MAX(patient_id), COUNT(DISTINCT patient_id) AS unique_patients
FROM patient_visits;

-- =============================================================
-- =============================================================
SELECT * FROM patient_visits WHERE site_id = 3;

-- Questions:
-- a) What scan type do you see? Why?
-- A full scan on every element of the table. There is no index
-- b) site_id has values 1–5. Is this high or low cardinality?
-- Low Cardinality
-- c) Would adding an index on site_id help? Why or why not?
-- Yes, but just a little thanks to the Low Cardinality

-- =============================================================
-- =============================================================
-- Step 3: Run the range query and check the plan
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

-- Questions:
-- a) Does Oracle use the index for this range?
-- Yes
-- b) Change the range to the last 7 days. Does the plan change?
-- Yes, the index should be more eficient
-- c) Change to the last 700 days. What happens?
-- The index should be less efficient cause we are biggering the search
-- d) Why does the range size affect whether Oracle uses the index?
-- Oracle uses a cost-based optimizier

-- ============================================================
-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

-- Questions:
-- a) Does the plan use the composite index?
-- Yes, thanks to the where
-- b) Now try querying ONLY on visit_date (no patient_id).
--    Does the composite index get used? Why not?
-- No because the idex starts with the patient_id so the search needs to search it too
-- c) What's the rule about column order in composite indexes?
-- Leftmost prefix rule


-- ============================================================
-- Exercise 4 — Function that breaks an index
--
-- There IS an index on patient_id (from lesson 03).
-- Predict what happens when you wrap the column in a function.
-- ============================================================

-- This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;
-- This one cannot — why?
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

-- Questions:
-- a) What scan type did the second query use?
-- full Table Scan
-- b) Why does wrapping a column in a function break index use?
-- The Index only searches for the original values
-- c) How would you rewrite the second query to allow index use?
-- Change it to be like the first query

-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
-- ============================================================

-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why? 
--   yes, I would add an index in the respective date search,
--   Mainly because it would be a high cardinality column so a
--   Index would help greatly

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add?
--   I would add one in customer_id. Because one in order_status shouldn't be
--   efficient due to the low Cardinality

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here?
--   A UNIQUE index for email, due to the high cardinality and it will be
--   exact searches