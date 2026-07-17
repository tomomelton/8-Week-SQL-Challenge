# Case Study #3 | Foodie-Fi
## B. Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
``` SQL
SELECT 
	COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions;
```
| customer_count |
|:--------------:|
| 1000           |

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
``` SQL
SELECT
	date_trunc('month', start_date)::date AS month_starting,
	COUNT(customer_id) AS trials_started
FROM subscriptions
GROUP BY month_starting
ORDER BY month_starting;
```
| month_starting | trials_started |
|:--------------:|:--------------:|
| 2020-01-01	   | 159            |
| 2020-02-01	   | 148            |
| 2020-03-01	   | 200            |
| 2020-04-01	   | 184            |
| 2020-05-01	   | 214            |
| 2020-06-01	   | 204            |
| 2020-07-01	   | 221            |
| 2020-08-01	   | 235            |
| 2020-09-01	   | 225            |
| 2020-10-01	   | 230            |
| 2020-11-01	   | 208            |
| 2020-12-01	   | 220            |
| 2021-01-01	   | 77             |
| 2021-02-01	   | 47             |
| 2021-03-01	   | 45             |
| 2021-04-01     | 33             |

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
``` SQL
SELECT
	p.plan_name,
	COUNT(s.customer_id) AS customers 
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_name
ORDER BY customers DESC;
```
|   plan_name   | customers |
|:-------------:|:---------:|
| churn	        | 71        |
| pro annual    | 63        |
| pro monthly   | 60        |
| basic monthly |	8         |

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
``` SQL
WITH
-- Counts of churned and total customers
a AS (
	SELECT
		COUNT(DISTINCT s.customer_id)::numeric AS total_customers,
		COUNT(DISTINCT c.customer_id)::numeric AS churned_customers
	FROM subscriptions AS s
	LEFT JOIN subscriptions AS c
	ON s.customer_id = c.customer_id
	AND c.plan_id = 4
)
SELECT 
	churned_customers,
	round(churned_customers / total_customers * 100, 1) AS percentage_churned
FROM a;
```
| churned_customers | percentage_churned |
|:-----------------:|:------------------:|
| 307               | 30.7               |

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
``` SQL
WITH
-- Counts of churned and total customers
a AS (
	SELECT
		COUNT(DISTINCT s.customer_id)::numeric AS total_customers,
		COUNT(DISTINCT x.customer_id)::numeric AS churned_customers
	FROM subscriptions AS s
	
	LEFT JOIN subscriptions AS c
	ON s.customer_id = c.customer_id
	AND s.plan_id = c.plan_id
	AND c.plan_id = 4

	LEFT JOIN subscriptions AS x
	ON c.customer_id = x.customer_id
	AND x.plan_id = 0
	AND c.start_date <= x.start_date + 7
)
SELECT 
	churned_customers,
	round(churned_customers / total_customers * 100) AS percentage_churned
FROM a;
```
| churned_customers | percentage_churned |
|:-----------------:|:------------------:|
| 92                | 9                  |

### 6. What is the number and percentage of customer plans after their initial free trial?
``` SQL
WITH 
-- Number the stages of customer life-cycle. 2 is the plan after trial
a AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY start_date
           ) AS rn
    FROM subscriptions
),
-- Count number of customers
t AS (
	SELECT COUNT(DISTINCT customer_id)::numeric AS total
	FROM subscriptions
)
SELECT 
	p.plan_name,
	COUNT(DISTINCT b.customer_id) AS customer_number,
	ROUND(COUNT(DISTINCT b.customer_id)::numeric
	/
	t.total
	* 100, 1)
	AS customer_percentage
FROM a

CROSS JOIN t

LEFT JOIN a AS b
ON a.customer_id = b.customer_id
AND a.plan_id = b.plan_id
AND b.rn = 2

LEFT JOIN plans AS p
ON b.plan_id = p.plan_id

WHERE b.plan_id != 4

GROUP BY p.plan_name, t.total;
```
|   plan_name   | customer_number | customer_percentage |
|:-------------:|:---------------:|:-------------------:|
| basic monthly |	546	            |54.6                 |
| pro annual    | 37	            |3.7                  |
| pro monthly   | 325	            |32.5                 |

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
``` SQL
WITH
-- Calculate end_date
a AS (
	SELECT
		*,
		CASE
			WHEN plan_id = 0 THEN start_date + 7
			WHEN plan_id = 1 THEN start_date + interval '1 month'
			WHEN plan_id = 2 THEN start_date + interval '1 month'
			WHEN plan_id = 3 THEN start_date + interval '1 year'
			ELSE 'infinity'
		END::date AS end_date
	FROM subscriptions
),
-- Get counts at 2020-12-31
b AS (
	SELECT
		p.plan_name,
		COUNT(DISTINCT customer_id)::numeric AS customer_count
	FROM a
	
	JOIN plans AS p
	ON a.plan_id = p.plan_id
	
	WHERE '2020-12-31' BETWEEN start_date AND end_date
	GROUP BY plan_name
),
-- Total customers at this point
t AS (
	SELECT
		SUM(customer_count)::numeric AS total_customers
	FROM b
)
SELECT 
	plan_name,
	customer_count,
	ROUND(customer_count / total_customers * 100, 2) AS customer_percentage
FROM b
CROSS JOIN t
ORDER BY customer_count DESC;
```
|   plan_name   | customer_number | customer_percentage |
|:-------------:|:---------------:|:-------------------:|
| churn         |	236	            | 43.62               |
| pro annual    |	195	            | 36.04               |
| pro monthly   |	48	            | 8.87                |
| basic monthly |	43	            | 7.95                |
| trial         |	19	            | 3.51                |

### 8. How many customers have upgraded to an annual plan in 2020?
``` SQL
SELECT
	COUNT(DISTINCT customer_id) AS number_upgraded
FROM subscriptions AS s
WHERE plan_id = 3
AND EXTRACT(YEAR FROM start_date) = 2020;
```
| number_upgraded |
|:---------------:|
| 195             |

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
``` SQL
WITH
-- Get join date
a AS (
	SELECT
		DISTINCT ON(customer_id)
		customer_id,
		start_date AS join_date
	FROM subscriptions
	ORDER BY customer_id, plan_id ASC
)
SELECT 
	ROUND(AVG(start_date - join_date)) AS average_days_to_annual
FROM subscriptions AS s
JOIN a
ON s.customer_id = a.customer_id
WHERE plan_id = 3;
```
| average_days_to_annual |
|:----------------------:|
| 195                    |

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
``` SQL
WITH
-- Get join date
a AS (
	SELECT
		DISTINCT ON(customer_id)
		customer_id,
		start_date AS join_date
	FROM subscriptions
	ORDER BY customer_id, plan_id ASC
),
-- Get days from join to annual plan
b AS (
	SELECT 
		start_date - join_date AS days_to_annual
	FROM subscriptions AS s
	JOIN a
	ON s.customer_id = a.customer_id
	WHERE plan_id = 3
)
SELECT
	(FLOOR(days_to_annual / 30) * 30)::int
	|| ' - ' ||
	(FLOOR(days_to_annual / 30) * 30 + 29)::int
	|| ' days'
	AS days_to_annual,
	COUNT(*) AS customers
FROM b
GROUP BY FLOOR(days_to_annual / 30)
ORDER BY FLOOR(days_to_annual / 30);
```
| days_to_annual | customers |
| :------------: | :-------: |
|   0 - 29 days  |     48    |
|  30 - 59 days  |     25    |
|  60 - 89 days  |     33    |
|  90 - 119 days |     35    |
| 120 - 149 days |     43    |
| 150 - 179 days |     35    |
| 180 - 209 days |     27    |
| 210 - 239 days |     4     |
| 240 - 269 days |     5     |
| 270 - 299 days |     1     |
| 300 - 329 days |     1     |
| 330 - 359 days |     1     |

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
``` SQL
WITH
-- Get basic plans
a AS (
	SELECT
		*
	FROM subscriptions
	WHERE plan_id = 1
),
-- Get pro plans
b AS (
	SELECT
		*
	FROM subscriptions
	WHERE plan_id = 2
)
SELECT
	COUNT(DISTINCT a.customer_id) AS customers_downgraded
FROM a

JOIN b
ON a.customer_id = b.customer_id

WHERE a.start_date > b.start_date
AND EXTRACT(YEAR FROM a.start_date) = 2020
```
| customers_downgraded |
|:--------------------:|
| 0                    |

No customers have downgraded from a pro monthly to a basic monthly plan in the year 2020








