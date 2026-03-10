/* SQL Lesson 6: Multi-table queries with JOINs */
/* 1. */
SELECT title, domestic_sales, international_sales FROM movies
JOIN boxoffice
ON movies.id = boxoffice.movie_id;

/* 2. */
SELECT title, domestic_sales, international_sales FROM movies
JOIN boxoffice
ON movies.id = boxoffice.movie_id
WHERE international_sales > domestic_sales;

/* 3. */
SELECT title, rating
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
ORDER BY rating DESC;

/* SQL Lesson 7: OUTER JOINs */
/* 1. */
SELECT DISTINCT building FROM employees;

/* 2. */
SELECT * FROM buildings;

/* 3. */
SELECT DISTINCT building_name, role FROM buildings 
LEFT JOIN employees
ON building_name = building;

/* Page With No Likes */
SELECT pages.page_id FROM pages
LEFT OUTER JOIN page_likes AS likes
ON pages.page_id = likes.page_id
WHERE likes.page_id IS NULL
order by page_id;