SET search_path = data_bank;

-- 1. How many unique nodes are there on the Data Bank system?

SELECT
	COUNT(DISTINCT node_id) AS nodes
FROM customer_nodes;


-- 2. What is the number of nodes per region?

SELECT
	region_name,
	COUNT(node_id) AS nodes
FROM customer_nodes AS n
JOIN regions AS r
ON n.region_id = r.region_id
GROUP BY region_name;


-- 3. How many customers are allocated to each region?

SELECT
	region_name,
	COUNT(DISTINCT customer_id) AS customers
FROM customer_nodes AS n
JOIN regions AS r
ON n.region_id = r.region_id
GROUP BY region_name;


-- 4. How many days on average are customers reallocated to a different node?

SELECT
	ROUND(AVG(end_date - start_date), 2) AS avg_days
FROM customer_nodes
WHERE end_date < '9999-12-31';
	

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH
-- Add column for days difference
a AS (
	SELECT
		*,
		end_date - start_date AS days_difference
	FROM customer_nodes
	WHERE end_date < '9999-12-31'
)
SELECT
	region_name,
	
	PERCENTILE_CONT(0.5) WITHIN GROUP (
		ORDER BY days_difference
	) AS median,

	PERCENTILE_CONT(0.8) WITHIN GROUP (
		ORDER BY days_difference
	) AS eightieth_percentile,

	PERCENTILE_CONT(0.95) WITHIN GROUP (
		ORDER BY days_difference
	) AS ninety_fifth_percentile
FROM a

JOIN regions AS r
ON a.region_id = r.region_id

GROUP BY region_name;

