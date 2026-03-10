SELECT * FROM movies where id = 6;
SELECT * FROM movies where year between 2000 and 2010;
SELECT * FROM movies where year not between 2000 and 2010;
SELECT * FROM movies order by year limit 5;

SELECT * FROM movies where title like "%Toy%";
SELECT * FROM movies where director like "%John%";
SELECT * FROM movies where director NOT like "%John%";
SELECT * FROM movies where title like "%WALL-%";

SELECT distinct director FROM movies order by director asc;
SELECT * from movies order by year desc limit 4;
SELECT * from movies order by title asc limit 5;
SELECT * from movies order by title asc limit 5 offset 5;

SELECT * FROM north_american_cities where country = "Canada";
SELECT * FROM north_american_cities where country = "United States" order by latitude desc;
SELECT * FROM north_american_cities where longitude < -87.629798 order by longitude asc;
SELECT * FROM north_american_cities where country = "Mexico" order by population desc limit 2;
SELECT * FROM north_american_cities where country = "United States" order by population desc limit 2 offset 2;