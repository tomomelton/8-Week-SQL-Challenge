# Case Study #4 | Data Bank
## A. Customer Nodes Exploration

### 1. How many unique nodes are there on the Data Bank system?
``` SQL
SELECT
	COUNT(DISTINCT node_id) AS nodes
FROM customer_nodes;
```
| nodes |
|:-----:|
| 5     |

---

### 2. What is the number of nodes per region?
``` SQL
SELECT
	region_name,
	COUNT(node_id) AS nodes
FROM customer_nodes AS n
JOIN regions AS r
ON n.region_id = r.region_id
GROUP BY region_name;
```
| region_name | nodes |
| ----------- | ----: |
| America     |   735 |
| Australia   |   770 |
| Africa      |   714 |
| Asia        |   665 |
| Europe      |   616 |


### 3. How many customers are allocated to each region?
``` SQL
SELECT
	region_name,
	COUNT(DISTINCT customer_id) AS customers
FROM customer_nodes AS n
JOIN regions AS r
ON n.region_id = r.region_id
GROUP BY region_name;
```
| region_name | customers |
| ----------- | --------: |
| Africa      |       102 |
| America     |       105 |
| Asia        |        95 |
| Australia   |       110 |
| Europe      |        88 |


### 4. How many days on average are customers reallocated to a different node?
``` SQL
SELECT
	ROUND(AVG(end_date - start_date), 2) AS avg_days
FROM customer_nodes
WHERE end_date < '9999-12-31';
```
| avg_days |
|:--------:|
| 14.63    |


### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
``` SQL
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
```
| region_name | median | eightieth_percentile | ninety_fifth_percentile |
| ----------- | -----: | -------------------: | ----------------------: |
| Africa      |     15 |                   24 |                      28 |
| America     |     15 |                   23 |                      28 |
| Asia        |     15 |                   23 |                      28 |
| Australia   |     15 |                   23 |                      28 |
| Europe      |     15 |                   24 |                      28 |
