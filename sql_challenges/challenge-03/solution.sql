/* Lesson 10 */
/* 1. */
SELECT MAX(years_employed) AS Max_years_employed FROM employees;

/* 2. */
SELECT role, AVG(years_employed) AS Average_years_employed FROM employees
GROUP BY role;

/* 3. */
SELECT building, SUM(years_employed) AS Total_years_employed FROM employees
GROUP BY building;

/* Lesson 11 */
/* 1. */
SELECT role, COUNT(*) AS Number_of_artists FROM employees
WHERE role = "Artist";

/* 2. */
SELECT role, COUNT(*) FROM employees
GROUP BY role;

/* 3. */
SELECT role, SUM(years_employed) FROM employees
GROUP BY role
HAVING role = "Engineer";

/* FREE-SQL */
/* 4. Try it */
SELECT  COUNT(UNIQUE shape) AS number_of_shapes,
        STDDEV(UNIQUE weight) AS  distinct_weight_stddev
FROM   bricks;

/* 6. Try it */
SELECT shape, SUM(weight) AS shape_weight
FROM   bricks
GROUP BY shape;

/* 8. Try it */
SELECT shape, SUM(weight) FROM  bricks
GROUP BY shape
HAVING SUM(weight) < 4;
