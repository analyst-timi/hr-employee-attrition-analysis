SELECT * FROM hr_employee_attrition;
SELECT COUNT(*) FROM hr_employee_attrition;

-- Create Staging data for cleaning 
CREATE TABLE hr_attrition_backup LIKE hr_employee_attrition;

-- Copy all data into the backup table
INSERT INTO hr_attrition_backup SELECT * FROM hr_employee_attrition;

-- Check backup dataset 
SELECT * FROM hr_attrition_backup;
SELECT COUNT(*) FROM hr_attrition_backup;

-- Check for duplicates using Employee Number (Employee Number should be unique)
SELECT EmployeeNumber, COUNT(*)
FROM hr_employee_attrition
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;

-- Check for NULLS
SELECT
  SUM(Age IS NULL) AS age_nulls,
  SUM(Department IS NULL OR Department = '') AS dept_nulls,
  SUM(MonthlyIncome IS NULL) AS income_nulls,
  SUM(JobSatisfaction IS NULL) AS satisfaction_nulls
FROM hr_attrition_backup;

-- Check and drop constant / non-informative columns
SELECT * FROM hr_attrition_backup;

SELECT DISTINCT EmployeeCount FROM hr_attrition_backup;
SELECT DISTINCT `Over18` FROM hr_attrition_backup;
SELECT DISTINCT StandardHours FROM hr_attrition_backup;

ALTER TABLE hr_attrition_backup
DROP COLUMN EmployeeCount,
DROP COLUMN `Over18`,
DROP COLUMN StandardHours; 


-- Standardize categorical list
SELECT DISTINCT Attrition FROM hr_attrition_backup;
SELECT DISTINCT Department FROM hr_attrition_backup;
SELECT DISTINCT EducationField FROM hr_attrition_backup;
SELECT DISTINCT JobRole FROM hr_attrition_backup;

UPDATE hr_attrition_backup SET
 Attrition = TRIM(Attrition),
 Department = TRIM(Department),
 EducationField = TRIM(EducationField),
 JobRole = TRIM(JobRole);
 
-- Check Age range and Satisfaction level  
SELECT MIN(Age), MAX(Age) FROM hr_attrition_backup;
SELECT DISTINCT JobSatisfaction FROM hr_attrition_backup ORDER BY 1;

-- Check for outliers in numeric fields
SELECT MIN(MonthlyIncome), MAX(MonthlyIncome), AVG(MonthlyIncome)
FROM hr_attrition_backup;

-- Recheck primary key integrity
SELECT COUNT(*), COUNT(DISTINCT EmployeeNumber) FROM hr_attrition_backup;

-- Attrition Analysis
SELECT * FROM hr_attrition_backup;

-- Overall attrition rate
SELECT
  COUNT(*) AS total_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS attrition_rate_pct
FROM hr_attrition_backup;

-- Attrition Rate by department
SELECT
  Department,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS attrition_rate_pct
FROM hr_attrition_backup
GROUP BY Department
ORDER BY attrition_rate_pct DESC;

-- Attrition Rate by JobRole
SELECT
  JobRole,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS attrition_rate_pct
FROM hr_attrition_backup
GROUP BY JobRole
ORDER BY attrition_rate_pct DESC;

-- Attrition Rate by Tenure Bucket
SELECT
  CASE
    WHEN YearsAtCompany < 2 THEN '0-2 years'
    WHEN YearsAtCompany < 5 THEN '2-5 years'
    WHEN YearsAtCompany < 10 THEN '5-10 years'
    ELSE '10+ years'
  END AS tenure_group,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS attrition_rate_pct
FROM hr_attrition_backup
GROUP BY tenure_group
ORDER BY attrition_rate_pct DESC;

SELECT YearsAtCompany FROM hr_attrition_backup;

-- Attrition Rate by Salary band
SELECT
  CASE
    WHEN MonthlyIncome < 3000 THEN 'Low'
    WHEN MonthlyIncome < 7000 THEN 'Medium'
    ELSE 'High'
  END AS salary_band,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS attrition_rate_pct
FROM hr_attrition_backup
GROUP BY salary_band
ORDER BY attrition_rate_pct DESC;

-- Average satisfaction scores: stayed vs left
SELECT
  Attrition,
  AVG(JobSatisfaction) AS avg_job_satisfaction,
  AVG(EnvironmentSatisfaction) AS avg_environment_satisfaction,
  AVG(WorkLifeBalance) AS avg_work_life_balance
FROM hr_attrition_backup
GROUP BY Attrition;

-- Overtime Vs Attrition
SELECT
  OverTime,
  COUNT(*) AS total_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS attrition_rate_pct
FROM hr_attrition_backup
GROUP BY OverTime;

-- High-Risk Segment Query
SELECT
  EmployeeNumber,
  JobRole,
  Department,
  JobSatisfaction,
  WorkLifeBalance,
  OverTime,
  YearsAtCompany,
  MonthlyIncome
FROM hr_attrition_backup
WHERE JobSatisfaction <= 2
  AND WorkLifeBalance <= 2
  AND OverTime = 'Yes'
  AND YearsAtCompany < 3
ORDER BY JobSatisfaction ASC;  -- This flags employees who are low on satisfaction, low on work-life balance, working overtime, 
-- and still early in tenure to predict someone leaving

-- Count how many employees fall into this group
SELECT
  COUNT(*) AS high_risk_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS actually_left,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS attrition_rate_within_group
FROM hr_attrition_backup
WHERE JobSatisfaction <= 2
  AND WorkLifeBalance <= 2
  AND OverTime = 'Yes'
  AND YearsAtCompany < 3; -- % of employees matching this risk profile actually left, compared to the % company-wide average.
  
SELECT * FROM hr_attrition_backup;