SET search_path = pizza_runner;

-- ---- Data Cleaning ---- --

-- Remove any 'null's from customer and runner orders
UPDATE customer_orders
SET extras = NULL
WHERE extras = 'null';

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = 'null';

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null';

UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null';

-- Remove any ''s from customer and runner orders
UPDATE customer_orders
SET extras = NULL
WHERE extras = '';

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = '';

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = '';

UPDATE runner_orders
SET distance = NULL
WHERE distance = '';

UPDATE runner_orders
SET duration = NULL
WHERE duration = '';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '';


-- ---- A. Pizza Metrics ---- --

-- 1. How many pizzas were ordered?

SELECT COUNT(order_id) AS pizzas_ordered
FROM customer_orders;


-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS customer_orders
FROM customer_orders; 


-- 3. How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;


-- 4. How many of each type of pizza was delivered?

SELECT pizza_id, COUNT(customer_orders.order_id) AS delivered
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY pizza_id;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

WITH 
a AS (
	SELECT customer_id, COUNT(pizza_name) AS meatlovers
	FROM customer_orders
	LEFT JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
	AND pizza_name = 'Meatlovers'
	GROUP BY customer_id
),
b AS (
	SELECT customer_id, COUNT(pizza_name) AS vegetarian
	FROM customer_orders
	LEFT JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
	AND pizza_name = 'Vegetarian'
	GROUP BY customer_id
)
SELECT a.customer_id, a.meatlovers, b.vegetarian
FROM a
JOIN b ON a.customer_id = b.customer_id
ORDER BY customer_id;


-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT customer_orders.order_id, COUNT(pizza_id) AS pizzas
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY customer_orders.order_id
ORDER BY pizzas DESC
LIMIT 1;


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH
a AS (
	SELECT DISTINCT customer_id
	FROM customer_orders
),
b AS (
	SELECT customer_id, COUNT(exclusions) AS exclusions, COUNT(extras) AS extras
	FROM customer_orders
	JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
	AND cancellation IS NULL
	WHERE exclusions IS NOT NULL
	OR extras IS NOT NULL
	GROUP BY customer_id
)
SELECT a.customer_id,
CASE
	WHEN b.exclusions IS NULL THEN 0
ELSE
	b.exclusions
END AS exclusions,
CASE
	WHEN b.extras IS NULL THEN 0
ELSE
	b.extras
END AS extras
FROM a
LEFT JOIN b ON a.customer_id = b.customer_id
ORDER BY customer_id;


-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT customer_orders.order_id, COUNT(exclusions) AS exclusions, COUNT(extras) AS extras
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
WHERE exclusions IS NOT NULL
AND extras IS NOT NULL
GROUP BY customer_orders.order_id;


-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT 
	date_trunc('hour', order_time) AS time,
	COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders
GROUP BY time
ORDER BY time;


-- 10. What was the volume of orders for each day of the week?

WITH
a(day_of_the_week, dow) AS (
	VALUES
		('sunday', 0),
        ('monday', 1),
        ('tuesday', 2),
        ('wednesday', 3),
        ('thursday', 4),
        ('friday', 5),
        ('saturday', 6)
),
b AS (
	SELECT 
		EXTRACT(DOW FROM order_time) AS dow,
		LOWER(TO_CHAR(order_time, 'FMDay')) AS day_of_the_week,
		COUNT(DISTINCT order_id) AS total_orders
	FROM customer_orders
	GROUP BY day_of_the_week, DOW
)
SELECT a.day_of_the_week, 
CASE
	WHEN b.total_orders IS NULL THEN 0
ELSE
	b.total_orders
END
FROM a
LEFT JOIN b ON a.day_of_the_week = b.day_of_the_week
ORDER BY a.DOW;



-- ---- B. Runner and Customer Experience ---- --

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT date_trunc('week', registration_date) AS week, COUNT(runner_id) AS runners
FROM runners
GROUP BY week
ORDER BY week;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT DISTINCT 
	runner_id,
	AVG(EXTRACT(MINUTE FROM pickup_time::timestamp - order_time))::NUMERIC(10, 2) AS average_minutes_to_collect
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- Assuming the pickup_time is approximately the time it takes to prepare an order:

SELECT  
	customer_orders.order_id, 
	COUNT(pizza_id) AS pizzas_ordered, 
	EXTRACT(MINUTE FROM pickup_time::timestamp - order_time) AS minutes_to_prepare
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY customer_orders.order_id, minutes_to_prepare
ORDER BY pizzas_ordered, minutes_to_prepare;

-- There is a relationship, typically bigger orders will take longer to be picked up / prepared


-- 4. What was the average distance travelled for each customer?

SELECT DISTINCT 
	customer_id, 
	AVG(regexp_replace(distance, '[^0-9.]', '', 'g')::numeric)::numeric(10, 2) AS average_distance
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;


-- 5. What was the difference between the longest and shortest delivery times for all orders?

WITH
a AS (
	SELECT order_id, regexp_replace(duration, '\D', '', 'g')::numeric AS duration
	FROM runner_orders
	WHERE cancellation IS NULL
)
SELECT MAX(duration) - MIN(duration) AS difference
FROM a;


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

-- Average speed = distance / duration

WITH
a AS (
SELECT 
	order_id, 
	runner_id,
	regexp_replace(distance, '[^0-9.]', '', 'g')::numeric AS distance_km,
	regexp_replace(duration, '\D', '', 'g')::numeric / 60 AS duration_hr
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY order_id
)
SELECT 
	order_id,
	runner_id,
	distance_km,
	duration_hr::numeric(10,2),
	(distance_km / duration_hr)::numeric(10,2) AS average_speed_km_per_hr
FROM a
ORDER BY average_speed_km_per_hr;


-- 7. What is the successful delivery percentage for each runner?

-- percentage = success / total orders * 100

WITH
a AS (
	SELECT 
		c.runner_id,
		COUNT(order_id)::numeric AS success
	FROM runner_orders AS r 
	RIGHT JOIN (SELECT DISTINCT runner_id FROM runner_orders) AS c 
		ON r.runner_id = c.runner_id
	AND cancellation IS NULL
	GROUP BY c.runner_id
),
b AS (
	SELECT
		runner_id,
		COUNT(order_id)::numeric AS total
	FROM runner_orders
	GROUP BY runner_id
)
SELECT 
	a.runner_id,
	(success / total * 100)::numeric(10,2) AS successful_delivery_percentage
FROM a
JOIN b ON a.runner_id = b.runner_id;



-- ---- C. Ingredient Optimisation ---- --

-- 1. What are the standard ingredients for each pizza?

WITH
-- Split toppings into rows
a AS (
	SELECT 
		pizza_id,
		UNNEST(string_to_array(toppings, ', ')) AS toppings
	FROM pizza_recipes
)
SELECT
	toppings AS standard_toppings
FROM a
GROUP BY toppings
HAVING COUNT(pizza_id) = (
	-- Number of different pizzas
	SELECT COUNT(DISTINCT pizza_id) FROM pizza_recipes
);


-- 2. What was the most commonly added extra?

WITH
extras AS (
	SELECT
		UNNEST(string_to_array(extras, ', ')) AS topping
	FROM customer_orders
	WHERE extras IS NOT NULL
),
extra_count AS (
	SELECT
		topping,
		COUNT(topping) AS times
	FROM extras
	GROUP BY topping
)
SELECT
	topping,
	times AS extra_requests	
FROM extra_count
WHERE times = (
	SELECT MAX(times) FROM extra_count
);


-- 3. What was the most common exclusion?

WITH
exclusions AS (
	SELECT
		UNNEST(string_to_array(exclusions, ', ')) AS topping
	FROM customer_orders
	WHERE exclusions IS NOT NULL
),
exclusions_count AS (
	SELECT
		topping,
		COUNT(topping) AS times
	FROM exclusions
	GROUP BY topping
)
SELECT
	topping,
	times AS exclusions_requests	
FROM exclusions_count
WHERE times = (
	SELECT MAX(times) FROM exclusions_count
);


-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- 		- Meat Lovers
-- 		- Meat Lovers - Exclude Beef
-- 		- Meat Lovers - Extra Bacon
-- 		- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH
-- Use ctid to add an identifier to each row
a AS (
	SELECT ctid, * FROM customer_orders
),
-- Put lists of exclusions and extras on seperate rows
b AS (
	SELECT 
		a.ctid,
		order_id,
		pizza_id,
		-- Since UNNEST() doesn't return anything if it's input is NULL, 
		-- using COALESCE() and ARRAY[NULL] prevents rows with not extras or exceptions from being dropped
		UNNEST(COALESCE(string_to_array(exclusions, ', '), ARRAY[NULL])) AS exclusions,
		UNNEST(COALESCE(string_to_array(extras, ', '), ARRAY[NULL])) AS extras
	FROM a
),
-- Select toppings for exclusions and extras and regroup into lists
c AS (
	SELECT 
		order_id,
		pizza_id,
		string_agg(x.topping_name, ', ') AS exclusions,
		string_agg(e.topping_name, ', ') AS extras
	FROM b
	LEFT JOIN pizza_toppings AS x
	ON exclusions::int = x.topping_id
	LEFT JOIN pizza_toppings AS e
	ON extras::int = e.topping_id
	GROUP BY b.ctid, order_id, pizza_id
	ORDER BY order_id, pizza_id
)
-- Compile textual response
SELECT 
	order_id,
	pizza_name ||
	COALESCE(
		CASE
			WHEN exclusions IS NOT NULL THEN ' - Exclude ' || exclusions
		END,
		''
	) ||
	COALESCE(
		CASE
			WHEN extras IS NOT NULL THEN ' - Extra ' || extras
		END,
		''
	) AS order_item
FROM c
JOIN pizza_names AS p
ON p.pizza_id = c.pizza_id
ORDER BY order_id;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
--    and add a 2x in front of any relevant ingredients
-- 		- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH
-- Use ctid to add an identifier to each row
a AS (
	SELECT ctid, * FROM customer_orders
),
-- Put exclusions and extras into ARRAYS
b AS (
	SELECT 
		a.ctid,
		a.order_id,
		a.pizza_id,
		COALESCE(string_to_array(a.exclusions, ', '), ARRAY['0']) AS exclusions,
		COALESCE(string_to_array(a.extras, ', '), ARRAY['0']) AS extras
	FROM a
),
-- Add list of toppings and split values across rows
c AS (
	SELECT
		b.*,
		UNNEST(string_to_array(r.toppings, ', ')) AS topping
	FROM b
	JOIN pizza_recipes AS r
	ON r.pizza_id = b.pizza_id
),
-- Remove toppings which are excluded
d AS (
	SELECT *
	FROM c
	WHERE NOT topping = ANY(exclusions)
),
-- Replace toppings with their names and add 'x2' for any extras, and aggregate
e AS (
	SELECT 
		d.ctid,
		d.order_id,
		d.pizza_id,
		d.exclusions,
		d.extras,
		string_agg(
		COALESCE(
			CASE
				WHEN d.topping = ANY(extras) THEN 'x2' || t.topping_name
			END,
			t.topping_name
		), ', ')
		AS toppings
	FROM d
	
	JOIN pizza_toppings AS t
	ON d.topping::int = t.topping_id

	GROUP BY ctid, order_id, pizza_id, exclusions, extras
),
-- Replace pizza_id with its name
f AS (
	SELECT e.order_id, p.pizza_name, e.toppings
	FROM e
	JOIN pizza_names AS p
	ON e.pizza_id = p.pizza_id
)
-- Compile textual responce
SELECT 
	order_id,
	pizza_name || ': ' || toppings AS ingredient_list
FROM f
ORDER BY order_id;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH
-- Get a table of exclusions, extras, and pizza toppings for all delivered pizzas
-- Extras are added to the list of toppings where applicable
a AS (
	SELECT 
		co.order_id,
		COALESCE(string_to_array(co.exclusions, ', '), ARRAY['0']) AS exclusions,
		COALESCE(string_to_array(co.extras, ', '), ARRAY['0']) AS extras,
		COALESCE(
			CASE
				WHEN co.extras IS NOT NULL
				THEN r.toppings || ', ' || extras
			END,
			r.toppings
		) AS toppings
	FROM runner_orders AS ro
	
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id

	JOIN pizza_recipes AS r
	ON co.pizza_id = r.pizza_id
	
	WHERE cancellation IS NULL
),
-- Unnest the topping list
b AS (
	SELECT
		order_id,
		exclusions,
		extras,
		UNNEST(string_to_array(toppings, ', ')) AS topping
	FROM a
),
-- Remove exclusions
c AS (
	SELECT *
	FROM b
	WHERE NOT topping = ANY(exclusions)
),
-- Count each topping and get topping names
d AS (
	SELECT
		topping_name AS topping,
		COUNT(c.topping) AS quantity_delivered
	FROM c

	JOIN pizza_toppings AS t
	ON c.topping::int = t.topping_id
	
	GROUP BY topping_name
	ORDER BY quantity_delivered DESC
)
SELECT * FROM d;



-- ---- D. Pricing and Ratings ---- --

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges 
-- 	  for changes - how much money has Pizza Runner made so far if there are no delivery 
-- 	  fees?
WITH
-- Pair each delivered pizza with its price
a AS (
	SELECT 
		co.order_id,
		co.pizza_id,
		CASE
			WHEN pizza_id::int = 2 THEN 10
			ELSE 12
		END AS price
	FROM runner_orders AS ro
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id

	WHERE cancellation IS NULL
)
SELECT 
	SUM(price) AS revenue_dollars
FROM a;


-- 2. What if there was an additional $1 charge for any pizza extras?
-- 		- Add cheese is $1 extra

WITH
-- Pair each delivered pizza with its price and unnest extras
a AS (
	SELECT 
		co.order_id,
		co.pizza_id,
		UNNEST(COALESCE(string_to_array(co.extras, ', '), ARRAY['0'])) AS extras,
		CASE
			WHEN pizza_id::int = 2 THEN 10
			ELSE 12
		END AS price
	FROM runner_orders AS ro
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id

	WHERE cancellation IS NULL
),
-- Add $1 to price when there is an extra
b AS (
	SELECT 
		order_id,
		pizza_id,
		COALESCE(
			CASE
				WHEN extras::int > 0
				THEN price + 1
			END,
			price
		) AS price
	FROM a
)
SELECT 
	SUM(price) AS revenue_dollars
FROM b;


-- 3. The Pizza Runner team now wants to add an additional ratings system that allows 
-- 	  customers to rate their runner, how would you design an additional table for this new 
-- 	  dataset - generate a schema for this new table and insert your own data for ratings for 
-- 	  each successful customer order between 1 to 5.

DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  	"order_id" INTEGER,
  	"runner_id" INTEGER,
  	"rating" INTEGER
  	CHECK (rating >= 1 AND rating <= 5)
);


INSERT INTO runner_ratings
	(order_id, runner_id, rating)
VALUES
	(1, 1, 3),
	(2, 1, 4),
	(3, 1, 4),
	(4, 2, 2),
	(5, 3, 4),
	(7, 2, 5),
	(8, 2, 5),
	(10, 1, 5);


SELECT * FROM runner_ratings;


-- 4. Using your newly generated table - can you join all of the information together to 
-- 	  form a table which has the following information for successful deliveries?
-- 		- customer_id
-- 		- order_id
-- 		- runner_id
-- 		- rating
-- 		- order_time
-- 		- pickup_time
-- 		- Time between order and pickup
-- 		- Delivery duration
-- 		- Average speed
-- 		- Total number of pizzas

SELECT 
	co.customer_id,
	ro.order_id,
	ro.runner_id,
	rr.rating,
	co.order_time,
	ro.pickup_time,
	
	TO_TIMESTAMP(
		ro.pickup_time,
		'YYYY-MM-DD HH24:MI:SS'
	) 
	- co.order_time
	AS time_between_order_and_pickup,
	
	ro.duration,
	
	ROUND(
		REGEXP_REPLACE(ro.distance, '[[:alpha:]]', '', 'g')::numeric
			/
		REGEXP_REPLACE(ro.duration, '[[:alpha:]]', '', 'g')::numeric * 60,
		2
	) AS average_speed_km_per_h,

	COUNT(co.pizza_id) AS number_of_pizzas
	
FROM runner_orders AS ro

JOIN runner_ratings AS rr
ON ro.order_id = rr.order_id

JOIN customer_orders AS co
ON ro.order_id = co.order_id

GROUP BY
	co.customer_id,
	ro.order_id,
	ro.runner_id,
	rr.rating,
	co.order_time,
	ro.pickup_time,
	time_between_order_and_pickup,
	ro.duration,
	average_speed_km_per_h;


-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
-- 	  and each runner is paid $0.30 per kilometre traveled - how much money does Pizza 
-- 	  Runner have left over after these deliveries?

WITH
-- Pair each delivered pizza with its price
-- and calculate the runners fee for each delivery
a AS (
	SELECT 
		co.order_id,
		co.pizza_id,
		ROUND(
			REGEXP_REPLACE(ro.distance, '[[:alpha:]]', '', 'g')::numeric
		) 
		* 0.3 --$0.30
		AS runner_fee,
		CASE
			WHEN pizza_id::int = 2 THEN 10
			ELSE 12
		END AS price
	FROM runner_orders AS ro
	
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id

	WHERE cancellation IS NULL
)
SELECT 
	SUM(price)
	-
	SUM(runner_fee)
	AS revenue_dollars
FROM a;



