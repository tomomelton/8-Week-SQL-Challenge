# Case Study #2 | Pizza Runner
## C. Ingredient Optimisation

### 1. What are the standard ingredients for each pizza?
``` SQL
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
```
| standard_toppings |
|:-----------------:|
| 4                 |
| 6                 |

---

### 2. What was the most commonly added extra?
``` SQL
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
```
| topping | extra_requests |
|:-------:|:--------------:|
| 1       |	4              |

---

### 3. What was the most common exclusion?
``` SQL
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
```
| topping | exclusions_requests |
|:-------:|:-------------------:|
| 4       |	4                   |

---

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
 - Meat Lovers
 - Meat Lovers - Exclude Beef
 - Meat Lovers - Extra Bacon
 - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
``` SQL
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
```
| order_id | order_item                                                      |
|:--------:|:----------------------------------------------------------------|
| 1	       | Meatlovers                                                      |
| 2	       | Meatlovers                                                      |
| 3	       | Meatlovers                                                      |
| 3	       | Vegetarian                                                      |
| 4	       | Meatlovers - Exclude Cheese                                     |
| 4	       | Meatlovers - Exclude Cheese                                     |
| 4	       | Vegetarian - Exclude Cheese                                     |
| 5	       | Meatlovers - Extra Bacon                                        |
| 6	       | Vegetarian                                                      |
| 7	       | Vegetarian - Extra Bacon                                        |
| 8	       | Meatlovers                                                      |
| 9	       | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| 10	     | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |
| 10	     | Meatlovers                                                      |

---

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
``` SQL
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
```
| order_id | ingredient_list                                                                     |
|:--------:|:------------------------------------------------------------------------------------|
| 1	       | Meatlovers: Salami, Mushrooms, Cheese, Beef, Pepperoni, BBQ Sauce, Bacon, Chicken   |
| 2	       | Meatlovers: Mushrooms, Bacon, Cheese, Pepperoni, Salami, BBQ Sauce, Chicken, Beef   |
| 3	       | Vegetarian: Onions, Mushrooms, Tomatoes, Cheese, Tomato Sauce, Peppers              |
| 3	       | Meatlovers: BBQ Sauce, Salami, Beef, Cheese, Mushrooms, Chicken, Bacon, Pepperoni   |
| 4	       | Meatlovers: Salami, BBQ Sauce, Chicken, Mushrooms, Beef, Bacon, Pepperoni           |
| 4	       | Meatlovers: Beef, Chicken, Salami, BBQ Sauce, Bacon, Pepperoni, Mushrooms           |
| 4	       | Vegetarian: Tomato Sauce, Mushrooms, Peppers, Onions, Tomatoes                      |
| 5	       | Meatlovers: Cheese, Beef, Chicken, x2Bacon, BBQ Sauce, Mushrooms, Salami, Pepperoni |
| 6	       | Vegetarian: Onions, Cheese, Tomatoes, Tomato Sauce, Peppers, Mushrooms              |
| 7	       | Vegetarian: Tomato Sauce, Tomatoes, Peppers, Onions, Mushrooms, Cheese              |
| 8	       | Meatlovers: Pepperoni, BBQ Sauce, Beef, Chicken, Cheese, Mushrooms, Bacon, Salami   |
| 9	       | Meatlovers: x2Chicken, Mushrooms, Salami, x2Bacon, Beef, BBQ Sauce, Pepperoni       |
| 10	     | Meatlovers: Beef, Pepperoni, Chicken, x2Bacon, x2Cheese, Salami                     |
| 10	     | Meatlovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |

---

### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
``` SQL
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
```
|    topping   | quantity_delivered |
|:------------:|:------------------:|
| Bacon 	     | 12                 |
| Mushrooms	   | 11                 |
| Cheese	     | 10                 |
| Pepperoni	   | 9                  |
| Chicken	     | 9                  |
| Salami	     | 9                  |
| Beef	       | 9                  |
| BBQ Sauce	   | 8                  |
| Tomato Sauce | 3                  |
| Onions	     | 3                  |
| Tomatoes	   | 3                  |
| Peppers	     | 3                  |



























