
### `sql_challenges/challenge-01/README.md`

```md
# SQL Lesson 2: Queries with constraints (Pt. 1)

## Answer
1. SELECT * FROM movies where id = 6;
2. SELECT * FROM movies where year between 2000 and 2010;
3. SELECT * FROM movies where year not between 2000 and 2010;
4. SELECT * FROM movies order by year limit 5;

# SQL Lesson 3: Queries with constraints

## Answer
1. SELECT * FROM movies where title like "%Toy%";
2. SELECT * FROM movies where director like "%John%";
3. SELECT * FROM movies where director NOT like "%John%";
4. SELECT * FROM movies where title like "%WALL-%";

# SQL Lesson 4: Filtering and sorting Query results

## Answer
1. SELECT distinct director FROM movies order by director asc;
2. SELECT * from movies order by year desc limit 4;
3. SELECT * from movies order by title asc limit 5;
4. SELECT * from movies order by title asc limit 5 offset 5;

# SQL Review: Simple SELECT Queries

## Answer
1. SELECT * FROM north_american_cities where country = "Canada";
2. SELECT * FROM north_american_cities where country = "United States" order by latitude desc;
3. SELECT * FROM north_american_cities where longitude < -87.629798 order by longitude asc;
4. SELECT * FROM north_american_cities where country = "Mexico" order by population desc limit 2;
5. SELECT * FROM north_american_cities where country = "United States" order by population desc limit 2 offset 2;