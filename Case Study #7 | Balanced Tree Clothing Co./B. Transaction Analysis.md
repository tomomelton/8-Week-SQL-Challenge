# Case Study #7 | Balanced Tree Clothing Co.

## B. Transaction Analysis

### 1. How many unique transactions were there?
``` SQL
SELECT
	COUNT(DISTINCT txn_id) AS transactions
FROM sales;
```
| transactions |
|-------------:|
| 2500 |


### 2. What is the average unique products purchased in each transaction?
``` SQL
SELECT DISTINCT
	ROUND(AVG(COUNT(DISTINCT prod_id)) OVER (), 2) avg_products
FROM sales
GROUP BY txn_id;
```
| avg_products |
|-------------:|
| 6.04 |


### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
``` SQL
SELECT
	PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY revenue) AS P25,
	PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY revenue) AS P50,
	PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY revenue) AS P75
FROM (
	SELECT
		ROUND(SUM(price - price * discount / 100::numeric), 2) AS revenue
	FROM sales
	GROUP BY txn_id
) AS r;
```
|    p25 |    p50 |    p75 |
| -----: | -----: | -----: |
| 116.16 | 150.50 | 185.12 |


### 4. What is the average discount value per transaction?
``` SQL
SELECT
	ROUND(AVG(discount), 2) AS avg_discount
FROM (
	SELECT
		DISTINCT txn_id,
		discount
	FROM sales
) AS d;
```
| avg_discount |
| -----------: |
|        12.09 |


### 5. What is the percentage split of all transactions for members vs non-members?
``` SQL
SELECT
	member,
	COUNT(DISTINCT txn_id) AS transactions,
	ROUND(COUNT(DISTINCT txn_id) / SUM(COUNT(DISTINCT txn_id)) OVER ()::NUMERIC * 100, 2) AS percentage
FROM sales
GROUP BY member;
```
| member | transactions | percentage |
| ------ | -----------: | ---------: |
| false  |          995 |      39.80 |
| true   |         1505 |      60.20 |


### 6. What is the average revenue for member transactions and non-member transactions?
``` SQL
SELECT
	member,
	ROUND(AVG(revenue), 2)
FROM (
	SELECT
		member,
		SUM(price - price * discount / 100::numeric) AS revenue
	FROM sales
	GROUP BY txn_id, member
) AS r
GROUP BY member;
```
| member |  round |
| ------ | -----: |
| false  | 150.35 |
| true   | 151.23 |
