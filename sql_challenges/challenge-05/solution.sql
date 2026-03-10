/*Union, Minus, and Intersect: Databases for Developers*/
/*5. Try it!*/
select colour from my_brick_collection
union
select colour from your_brick_collection
order by colour;

select shape from my_brick_collection
union all
select shape from your_brick_collection
order  by shape;

/*10. Try it!*/
select shape from my_brick_collection
MINUS
select shape from your_brick_collection;

select colour from my_brick_collection
union
select colour from your_brick_collection
order  by colour;
