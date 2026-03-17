-- ============================================================
-- HEALTHCARE PATIENT DEMOGRAPHICS & UTILIZATION ANALYTICS
-- MySQL Workbench Script
-- Dataset: 55,500 Records | Date Range: 2019-05-08 to 2024-05-07
-- ============================================================

-- ============================================================
-- DATABASE & TABLE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS healthcare_db;
USE healthcare_db;

DROP TABLE IF EXISTS patients;

CREATE TABLE patients (
    patient_id       INT AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(150),
    age              INT,
    gender           VARCHAR(10),
    blood_type       VARCHAR(5),
    medical_condition VARCHAR(100),
    date_of_admission DATE,
    doctor           VARCHAR(150),
    hospital         VARCHAR(200),
    insurance_provider VARCHAR(100),
    billing_amount   DECIMAL(12,2),
    room_number      INT,
    admission_type   VARCHAR(50),
    discharge_date   DATE,
    medication       VARCHAR(100),
    test_results     VARCHAR(50)
);

-- ============================================================
-- LOAD DATA FROM CSV
-- ============================================================

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/healthcare_dataset.csv'
INTO TABLE patients
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(name, age, gender, blood_type, medical_condition,
 @date_of_admission, doctor, hospital, insurance_provider,
 billing_amount, room_number, admission_type,
 @discharge_date, medication, test_results)
SET
  date_of_admission = STR_TO_DATE(@date_of_admission, '%Y-%m-%d'),
  discharge_date    = STR_TO_DATE(@discharge_date,    '%Y-%m-%d');

-- ============================================================
-- ADD COMPUTED COLUMNS
-- ============================================================

ALTER TABLE patients
  ADD COLUMN length_of_stay  INT AS (DATEDIFF(discharge_date, date_of_admission)) STORED,
  ADD COLUMN admission_year  INT AS (YEAR(date_of_admission)) STORED,
  ADD COLUMN admission_month INT AS (MONTH(date_of_admission)) STORED,
  ADD COLUMN admission_month_name VARCHAR(15) AS
    (MONTHNAME(date_of_admission)) STORED,
  ADD COLUMN admission_day   VARCHAR(15) AS
    (DAYNAME(date_of_admission)) STORED,
  ADD COLUMN age_group VARCHAR(20) AS (
    CASE
      WHEN age BETWEEN 13 AND 17 THEN '13–17 (Teen)'
      WHEN age BETWEEN 18 AND 34 THEN '18–34 (Young Adult)'
      WHEN age BETWEEN 35 AND 54 THEN '35–54 (Middle Age)'
      WHEN age BETWEEN 55 AND 69 THEN '55–69 (Senior)'
      ELSE '70+ (Elderly)'
    END) STORED,
  ADD COLUMN billing_tier VARCHAR(20) AS (
    CASE
      WHEN billing_amount < 10000  THEN 'Low (<10K)'
      WHEN billing_amount < 25000  THEN 'Medium (10K-25K)'
      WHEN billing_amount < 40000  THEN 'High (25K-40K)'
      ELSE 'Very High (>40K)'
    END) STORED;

-- ============================================================
-- KPI QUERIES 
-- ============================================================

-- KPI 1: Total Patients
SELECT COUNT(*) AS total_patients FROM patients;

-- KPI 2: Average Age
SELECT ROUND(AVG(age), 1) AS avg_age FROM patients;

-- KPI 3: Average Billing Amount
SELECT ROUND(AVG(billing_amount), 2) AS avg_billing FROM patients;

-- KPI 4: Average Length of Stay (days)
SELECT ROUND(AVG(length_of_stay), 1) AS avg_los FROM patients;

-- KPI 5: Emergency Admission Rate
SELECT
    ROUND(100.0 * SUM(admission_type = 'Emergency') / COUNT(*), 1) AS emergency_rate_pct
FROM patients;

-- KPI 6: Abnormal Test Result Rate
SELECT
    ROUND(100.0 * SUM(test_results = 'Abnormal') / COUNT(*), 1) AS abnormal_rate_pct
FROM patients;

-- KPI 7: Total Revenue (Billing)
SELECT ROUND(SUM(billing_amount), 2) AS total_revenue FROM patients;

-- KPI 8: Unique Hospitals
SELECT COUNT(DISTINCT hospital) AS total_hospitals FROM patients;

-- ============================================================
-- PATIENT DEMOGRAPHICS
-- ============================================================

-- 1: Gender Distribution
SELECT
    gender,
    COUNT(*)                                       AS patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patients), 1) AS pct
FROM patients
GROUP BY gender
ORDER BY patient_count DESC;

-- 2: Age Group Distribution
SELECT
    age_group,
    COUNT(*)                                       AS patient_count,
    ROUND(AVG(age), 1)                             AS avg_age,
    ROUND(AVG(billing_amount), 2)                  AS avg_billing,
    ROUND(AVG(length_of_stay), 1)                  AS avg_los
FROM patients
GROUP BY age_group
ORDER BY MIN(age);

-- 3: Blood Type Distribution
SELECT
    blood_type,
    COUNT(*)                                       AS patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patients), 1) AS pct
FROM patients
GROUP BY blood_type
ORDER BY patient_count DESC;

-- 4: Age Stats by Gender
SELECT
    gender,
    COUNT(*)                  AS patient_count,
    MIN(age)                  AS min_age,
    MAX(age)                  AS max_age,
    ROUND(AVG(age), 1)        AS avg_age,
    ROUND(STDDEV(age), 1)     AS stddev_age
FROM patients
GROUP BY gender;

-- ============================================================
-- MEDICAL CONDITIONS & DIAGNOSES
-- ============================================================

-- 1: Admissions by Medical Condition
SELECT
    medical_condition,
    COUNT(*)                                       AS total_admissions,
    ROUND(AVG(billing_amount), 2)                  AS avg_billing,
    ROUND(AVG(length_of_stay), 1)                  AS avg_los,
    ROUND(100.0 * SUM(test_results='Abnormal') / COUNT(*), 1) AS abnormal_pct
FROM patients
GROUP BY medical_condition
ORDER BY total_admissions DESC;

-- 2: Medical Condition by Gender
SELECT
    medical_condition,
    gender,
    COUNT(*) AS patient_count
FROM patients
GROUP BY medical_condition, gender
ORDER BY medical_condition, gender;

-- 3: Medical Condition by Age Group
SELECT
    medical_condition,
    age_group,
    COUNT(*) AS patient_count
FROM patients
GROUP BY medical_condition, age_group
ORDER BY medical_condition, MIN(age);

-- 4: Test Results Distribution
SELECT
    test_results,
    COUNT(*)                                       AS patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patients), 1) AS pct
FROM patients
GROUP BY test_results;

-- 5: Test Results by Medical Condition
SELECT
    medical_condition,
    SUM(test_results = 'Normal')       AS normal_count,
    SUM(test_results = 'Abnormal')     AS abnormal_count,
    SUM(test_results = 'Inconclusive') AS inconclusive_count,
    COUNT(*)                           AS total
FROM patients
GROUP BY medical_condition
ORDER BY abnormal_count DESC;

-- ============================================================
-- UTILIZATION — ADMISSIONS OVER TIME
-- ============================================================

-- 1: Monthly Admissions Trend
SELECT
    admission_year,
    admission_month,
    admission_month_name,
    COUNT(*)                        AS total_admissions,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(AVG(length_of_stay), 1)   AS avg_los
FROM patients
GROUP BY admission_year, admission_month, admission_month_name
ORDER BY admission_year, admission_month;

-- 2: Admissions by Day of Week
SELECT
    admission_day,
    COUNT(*)                        AS total_admissions,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(AVG(length_of_stay), 1)   AS avg_los
FROM patients
GROUP BY admission_day
ORDER BY FIELD(admission_day,
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- 3: Yearly Summary
SELECT
    admission_year,
    COUNT(*)                        AS total_admissions,
    ROUND(SUM(billing_amount), 2)   AS total_billing,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(AVG(length_of_stay), 1)   AS avg_los,
    SUM(admission_type='Emergency') AS emergency_count,
    SUM(admission_type='Urgent')    AS urgent_count,
    SUM(admission_type='Elective')  AS elective_count
FROM patients
GROUP BY admission_year
ORDER BY admission_year;

-- 4: Admission Type Distribution
SELECT
    admission_type,
    COUNT(*)                                       AS patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patients), 1) AS pct,
    ROUND(AVG(billing_amount), 2)                  AS avg_billing,
    ROUND(AVG(length_of_stay), 1)                  AS avg_los
FROM patients
GROUP BY admission_type
ORDER BY patient_count DESC;

-- 5: Monthly Admission Type Mix 
SELECT
    admission_year,
    admission_month,
    admission_month_name,
    admission_type,
    COUNT(*) AS admissions
FROM patients
GROUP BY admission_year, admission_month, admission_month_name, admission_type
ORDER BY admission_year, admission_month;

-- ============================================================
-- FINANCIAL ANALYSIS
-- ============================================================

-- 1: Billing by Insurance Provider
SELECT
    insurance_provider,
    COUNT(*)                        AS patient_count,
    ROUND(SUM(billing_amount), 2)   AS total_billing,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(MIN(billing_amount), 2)   AS min_billing,
    ROUND(MAX(billing_amount), 2)   AS max_billing
FROM patients
GROUP BY insurance_provider
ORDER BY total_billing DESC;

-- 2: Billing by Medical Condition
SELECT
    medical_condition,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(SUM(billing_amount), 2)   AS total_billing,
    COUNT(*)                        AS patient_count
FROM patients
GROUP BY medical_condition
ORDER BY avg_billing DESC;

-- 3: Billing by Admission Type
SELECT
    admission_type,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(SUM(billing_amount), 2)   AS total_billing,
    COUNT(*)                        AS patient_count
FROM patients
GROUP BY admission_type
ORDER BY avg_billing DESC;

-- 4: Billing Tier Distribution
SELECT
    billing_tier,
    COUNT(*)                                       AS patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patients), 1) AS pct
FROM patients
GROUP BY billing_tier
ORDER BY MIN(billing_amount);

-- 5: Revenue by Year
SELECT
    admission_year,
    ROUND(SUM(billing_amount), 2)   AS total_revenue,
    ROUND(AVG(billing_amount), 2)   AS avg_revenue,
    COUNT(*)                        AS admissions
FROM patients
GROUP BY admission_year
ORDER BY admission_year;

-- ============================================================
-- HOSPITAL & PROVIDER ANALYSIS
-- ============================================================

-- 1: Top 10 Hospitals by Admissions
SELECT
    hospital,
    COUNT(*)                        AS total_admissions,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(AVG(length_of_stay), 1)   AS avg_los,
    COUNT(DISTINCT doctor)          AS doctor_count
FROM patients
GROUP BY hospital
ORDER BY total_admissions DESC
LIMIT 10;

-- 2: Top 10 Doctors by Patient Volume
SELECT
    doctor,
    hospital,
    COUNT(*)                        AS patient_count,
    ROUND(AVG(billing_amount), 2)   AS avg_billing,
    ROUND(AVG(length_of_stay), 1)   AS avg_los
FROM patients
GROUP BY doctor, hospital
ORDER BY patient_count DESC
LIMIT 10;

-- 3: Medication Frequency
SELECT
    medication,
    COUNT(*)                                       AS prescriptions,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patients), 1) AS pct,
    ROUND(AVG(billing_amount), 2)                  AS avg_billing
FROM patients
GROUP BY medication
ORDER BY prescriptions DESC;

-- 4: Room Utilization (Room Number Distribution)
SELECT
    FLOOR(room_number / 100) * 100 AS room_block,
    COUNT(*)                       AS patient_count,
    ROUND(AVG(length_of_stay), 1)  AS avg_los
FROM patients
GROUP BY room_block
ORDER BY room_block;

-- ============================================================
-- CAPACITY PLANNING VIEWS
-- ============================================================

-- 1: Main Analytics View 
CREATE OR REPLACE VIEW vw_patient_analytics AS
SELECT
    patient_id,
    name,
    age,
    age_group,
    gender,
    blood_type,
    medical_condition,
    date_of_admission,
    admission_year,
    admission_month,
    admission_month_name,
    admission_day,
    admission_type,
    discharge_date,
    length_of_stay,
    doctor,
    hospital,
    insurance_provider,
    billing_amount,
    billing_tier,
    room_number,
    medication,
    test_results
FROM patients;

-- 2: Monthly KPI Summary View
CREATE OR REPLACE VIEW vw_monthly_kpi AS
SELECT
    admission_year,
    admission_month,
    admission_month_name,
    COUNT(*)                         AS total_admissions,
    ROUND(AVG(billing_amount), 2)    AS avg_billing,
    ROUND(SUM(billing_amount), 2)    AS total_billing,
    ROUND(AVG(length_of_stay), 1)    AS avg_los,
    SUM(admission_type='Emergency')  AS emergency_count,
    SUM(admission_type='Urgent')     AS urgent_count,
    SUM(admission_type='Elective')   AS elective_count,
    SUM(test_results='Abnormal')     AS abnormal_results,
    SUM(test_results='Normal')       AS normal_results
FROM patients
GROUP BY admission_year, admission_month, admission_month_name
ORDER BY admission_year, admission_month;

-- 3: Condition Risk View 
CREATE OR REPLACE VIEW vw_condition_risk AS
SELECT
    medical_condition,
    age_group,
    COUNT(*)                                      AS patient_count,
    ROUND(AVG(billing_amount), 2)                 AS avg_billing,
    ROUND(AVG(length_of_stay), 1)                 AS avg_los,
    ROUND(100.0 * SUM(test_results='Abnormal') / COUNT(*), 1) AS abnormal_pct,
    ROUND(100.0 * SUM(admission_type='Emergency') / COUNT(*), 1) AS emergency_pct
FROM patients
GROUP BY medical_condition, age_group;

-- ============================================================
-- QUICK VALIDATION CHECKS
-- ============================================================

SELECT 'Total Rows'     AS metric, COUNT(*)                        AS value FROM patients UNION ALL
SELECT 'Null Ages'      AS metric, SUM(age IS NULL)                AS value FROM patients UNION ALL
SELECT 'Negative Bills' AS metric, SUM(billing_amount < 0)        AS value FROM patients UNION ALL
SELECT 'Zero LOS'       AS metric, SUM(length_of_stay = 0)        AS value FROM patients UNION ALL
SELECT 'Date Range Start', MIN(date_of_admission)                  AS value FROM patients UNION ALL
SELECT 'Date Range End',   MAX(date_of_admission)                  AS value FROM patients;

