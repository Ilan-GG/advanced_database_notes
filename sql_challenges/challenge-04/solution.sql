drop table bricks cascade constraints;
create table bricks (
  brick_id integer,
  colour   varchar2(10),
  shape    varchar2(10),
  weight   integer
);

insert into bricks values ( 1, 'blue', 'cube', 1 );
insert into bricks values ( 2, 'blue', 'pyramid', 2 );
insert into bricks values ( 3, 'red', 'cube', 1 );
insert into bricks values ( 4, 'red', 'cube', 2 );
insert into bricks values ( 5, 'red', 'pyramid', 3 );
insert into bricks values ( 6, 'green', 'pyramid', 1 );

commit;

/* 3. Try it */

select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median(weight) over (
         partition by shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

/* 5. Try it */

select b.brick_id, b.weight,
       round ( avg ( weight ) over (
         order by BRICK_ID
         ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

/* 9. Try it */

select b.*,
       min(colour) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count(*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;

/* 11. Try it */

with totals as (
  select b.*,
         sum(weight) over (
           partition by shape
         ) weight_per_shape,
         sum(weight) over (
           order by brick_id
           rows between unbounded preceding and current row
         ) running_weight_by_id
  from   bricks b
)
select *
from   totals
where  weight_per_shape > 4
and    running_weight_by_id > 4
order  by brick_id;

/* Data Lemur */

/* Part 1 */

SELECT 
  name,
  salary,
  department_id,
  DENSE_RANK() OVER (
    PARTITION BY department_id ORDER BY salary DESC) AS ranking
FROM employee;

/* Part 2 */
WITH ranked_salary AS (
  SELECT 
    name,
    salary,
    department_id,
    DENSE_RANK() OVER (
      PARTITION BY department_id ORDER BY salary DESC) AS ranking
  FROM employee
)

SELECT 
  d.department_name,
  s.name,
  s.salary
FROM ranked_salary AS s
INNER JOIN department AS d
  ON s.department_id = d.department_id
WHERE s.ranking <= 3
ORDER BY d.department_name ASC, s.salary DESC, s.name ASC;