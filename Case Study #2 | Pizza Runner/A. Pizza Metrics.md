# Case Study #2 | Pizza Runner
## A. Pizza Metrics

### 1. How many pizzas were ordered?
``` SQL
SELECT COUNT(order_id) AS pizzas_ordered
FROM customer_orders;
```
| pizzas_ordered  |
| :-------------: |
| 14              |

---

### 2. How many unique customer orders were made?
``` SQL
SELECT COUNT(DISTINCT order_id) AS customer_orders
FROM customer_orders;
```
| customer_orders  |
| :--------------: |
| 10               |

---

### 3. How many successful orders were delivered by each runner?
``` SQL
SELECT runner_id, COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;
```
| runner_id  | successful_orders |
| :--------: |:-----------------:|
| 1          | 4                 |
| 2          | 3                 |
| 3          | 1                 |

---

### 4. How many of each type of pizza was delivered?
``` SQL
SELECT pizza_id, COUNT(customer_orders.order_id) AS delivered
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY pizza_id;
```
| pizza_id  | delivered |
| :-------: |:---------:|
| 1         | 9         |
| 2         | 3         |

---

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
``` SQL
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
```
| customer_id  | meatlovers | vegetarian |
| :----------: |:----------:|:----------:|
| 101          | 2          | 1          |
| 102          | 2          | 1          |
| 103          | 3          | 1          |
| 104          | 3          | 0          |
| 105          | 0          | 1          |

---

### 6. What was the maximum number of pizzas delivered in a single order?
``` SQL
SELECT customer_orders.order_id, COUNT(pizza_id) AS pizzas
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY customer_orders.order_id
ORDER BY pizzas DESC
LIMIT 1;
```
| order_id  | pizzas |
| :-------: |:------:|
| 4         | 3      |

---

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
``` SQL
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
```
| customer_id  | exclusions | extras |
| :----------: |:----------:|:------:|
| 101          | 0          | 0      |
| 102          | 0          | 0      |
| 103          | 0          | 0      |
| 104          | 2          | 2      |
| 105          | 1          | 1      |

2 orders had changes, and 3 has none

---

### 8. How many pizzas were delivered that had both exclusions and extras?
``` SQL
SELECT customer_orders.order_id, COUNT(exclusions) AS exclusions, COUNT(extras) AS extras
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
WHERE exclusions IS NOT NULL
AND extras IS NOT NULL
GROUP BY customer_orders.order_id;
```
| order_id | exclusions | extras |
| :------: |:----------:|:------:|
| 10       | 1          | 1      |

So only one pizza had an exclusion and an extra

---

### 9. What was the total volume of pizzas ordered for each hour of the day?
``` SQL
SELECT 
	date_trunc('hour', order_time) AS time,
	COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders
GROUP BY time
ORDER BY time;
```
|        time         | pizzas_ordered |
|:-------------------:|:--------------:|
| 2020-01-01 18:00:00 |	1              |
| 2020-01-01 19:00:00 |	1              |
| 2020-01-02 23:00:00 |	2              |
| 2020-01-04 13:00:00 |	3              |
| 2020-01-08 21:00:00 |	3              |
| 2020-01-09 23:00:00 |	1              |
| 2020-01-10 11:00:00 |	1              |
| 2020-01-11 18:00:00 |	2              |

---

### 10. What was the volume of orders for each day of the week?
``` SQL
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
```
| day_of_the_week |	total_orders |
|:---------------:|:------------:|
| sunday	        | 0            |
| monday	        | 0            |
| tuesday	        | 0            |
| wednesday	      | 5            |
| thursday	      | 2            |
| friday	        | 1            |
| saturday	      | 2            |
