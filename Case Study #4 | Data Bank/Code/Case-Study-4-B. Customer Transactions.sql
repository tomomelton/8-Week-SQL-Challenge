SET search_path = data_bank;

-- 1. What is the unique count and total amount for each transaction type?

SELECT
	txn_type,
	COUNT(*) as unique_count,
	SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;


-- 2. What is the average total historical deposit counts and amounts for all customers?

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


-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

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


-- 4. What is the closing balance for each customer at the end of the month?

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