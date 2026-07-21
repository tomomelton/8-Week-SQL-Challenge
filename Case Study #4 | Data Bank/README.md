# Case Study #4 | Data Bank

<img src="https://8weeksqlchallenge.com/images/case-study-designs/4.png" width=500 alt="Data Bank Logo">

## Table of Contents

- [Problem Statement](#problem-statement)
- [Case Study Questions](#case-study-questions)
  - [A. Customer Nodes Exploration](#a-customer-nodes-exploration)
  - [B. Customer Transactions](#b-customer-transactions)
- [Links](#links)

## Problem Statement

There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.

Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank!

Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help!

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

## Case Study Questions

### A. Customer Nodes Exploration

#### 1. How many unique nodes are there on the Data Bank system?
``` SQL
SELECT
	COUNT(DISTINCT node_id) AS nodes
FROM customer_nodes;
```
| nodes |
|:-----:|
| 5     |

---

#### 2. What is the number of nodes per region?
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


#### 3. How many customers are allocated to each region?
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


#### 4. How many days on average are customers reallocated to a different node?
``` SQL
SELECT
	ROUND(AVG(end_date - start_date), 2) AS avg_days
FROM customer_nodes
WHERE end_date < '9999-12-31';
```
| avg_days |
|:--------:|
| 14.63    |


#### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
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

---

### B. Customer Transactions

#### 1. What is the unique count and total amount for each transaction type?
``` SQL
SELECT
	txn_type,
	COUNT(*) as unique_count,
	SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;
```
| txn_type   | unique_count | total_amount |
| ---------- | -----------: | -----------: |
| purchase   |         1617 |       806537 |
| withdrawal |         1580 |       793003 |
| deposit    |         2671 |      1359168 |



#### 2. What is the average total historical deposit counts and amounts for all customers?
``` SQL
WITH
-- Calculate count of customer deposits and total amount
a AS (
	SELECT 
		COUNT(*) AS total_deposits,
		SUM(txn_amount) AS total_amount
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
)
SELECT
	ROUND(AVG(total_deposits), 2) AS avg_deposits,
	ROUND(AVG(total_amount), 2) AS avg_amount
FROM a;
```
| avg_deposits | avg_amount |
| -----------: | ---------: |
|         5.34 |    2718.34 |



#### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
``` SQL
SELECT 
	date_trunc('month', txn_date)::date AS month,
	COUNT(DISTINCT customer_id) AS customers
FROM customer_transactions AS t

-- JOIN number of deposits
LEFT JOIN LATERAL (
	SELECT COUNT(*)::numeric AS deposits
	FROM customer_transactions AS x
	WHERE txn_type = 'deposit'
	AND date_trunc('month', x.txn_date)::date = date_trunc('month', t.txn_date)::date
	AND x.customer_id = t.customer_id
) AS d ON true

-- JOIN number of purchaces
LEFT JOIN LATERAL (
	SELECT COUNT(*)::numeric AS perchases
	FROM customer_transactions AS x
	WHERE txn_type = 'purchase'
	AND date_trunc('month', x.txn_date)::date = date_trunc('month', t.txn_date)::date
	AND x.customer_id = t.customer_id
) AS p ON true

-- JOIN number of withdrawals
LEFT JOIN LATERAL (
	SELECT COUNT(*)::numeric AS withdrawals
	FROM customer_transactions AS x
	WHERE txn_type = 'withdrawal'
	AND date_trunc('month', x.txn_date)::date = date_trunc('month', t.txn_date)::date
	AND x.customer_id = t.customer_id
) AS w ON true

-- >= 1 deposit AND (1 purchase XOR 1 withdrawl) 
WHERE deposits >= 1
AND (
	(perchases = 1) <> (withdrawals = 1)
)

GROUP BY month;
```
| month      | customers |
| ---------- | --------: |
| 2020-01-01 |       170 |
| 2020-02-01 |       154 |
| 2020-03-01 |       163 |
| 2020-04-01 |        88 |



#### 4. What is the closing balance for each customer at the end of the month?
``` SQL
WITH 
-- Calculate net deposits per customer per month
a AS (
	SELECT
		customer_id,
		date_trunc('month', txn_date)::date AS txn_month,
		
		SUM(
			CASE 
				WHEN txn_type = 'deposit'
				THEN txn_amount
				ELSE 0
			END
		)
		-
		SUM(
			CASE
				WHEN txn_type = 'purchase'
				THEN txn_amount
				ELSE 0
			END
		)
		-
		SUM(
			CASE
				WHEN txn_type = 'withdrawal'
				THEN txn_amount
				ELSE 0
			END
		) AS net_deposits
	
	FROM customer_transactions
	GROUP BY
		customer_id,
		txn_month
),
-- Number customers net deposits in order of months
b AS (
	SELECT 
		*,
		ROW_NUMBER() OVER(
			PARTITION BY customer_id
			ORDER BY txn_month
		) AS rn
	FROM a
)
-- Add previous net deposits to get the final total per month
SELECT 
	b.customer_id,
	b.txn_month,
	b.net_deposits,
	
	b.net_deposits + COALESCE(
		x.net_deposits, 0
	) AS closing_balance
FROM b
LEFT JOIN b AS x
ON b.rn = x.rn + 1
AND b.customer_id = x.customer_id

ORDER BY b.customer_id, b.rn
```

Just showing closing balances for customers 1, 2, and 3:

| customer_id | txn_month  | net_deposits | closing_balance |
| ----------: | ---------- | -----------: | --------------: |
|           1 | 2020-01-01 |          312 |             312 |
|           1 | 2020-03-01 |         -952 |            -640 |
|           2 | 2020-01-01 |          549 |             549 |
|           2 | 2020-03-01 |           61 |             610 |
|           3 | 2020-01-01 |          144 |             144 |
|           3 | 2020-02-01 |         -965 |            -821 |
|           3 | 2020-03-01 |         -401 |           -1366 |
|           3 | 2020-04-01 |          493 |              92 |

---

## Links

- All case study details, including the full problem statement, database diagram, and sample data used, can be found through the link:
	[8 Week SQL Challenge: Case Study #4 - Data Bank](https://8weeksqlchallenge.com/case-study-4/)

- I have not seen the official solutions for this case study. If you have any questions or feedback on my solutions please contact me on my LinkedIn: 
	[Tom Melton](https://LinkedIn.com/in/tom-melton-23a59b353/)
