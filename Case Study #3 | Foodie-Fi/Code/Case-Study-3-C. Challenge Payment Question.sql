SET search_path = foodie_fi;

DROP TABLE payments;
CREATE TABLE IF NOT EXISTS payments (
	customer_id INT,
	plan_id INT,
	plan_name VARCHAR(13),
	payment_date DATE,
	amount DECIMAL(5,2),
	payment_order INT
);



WITH
-- Number rows based on customers sequence of plans
x AS (
	SELECT
		*,
		ROW_NUMBER() OVER(
			PARTITION BY s.customer_id
			ORDER BY s.start_date
		) AS plan_stage
	FROM subscriptions AS s
),
-- Find the end date of each customers plan
a AS (
	SELECT
		x.customer_id,
		x.plan_id,
		x.plan_stage,
		x.start_date,
		y.plan_id AS next_plan,
		CASE
			WHEN y.start_date IS NOT NULL THEN y.start_date - 1
			ELSE '2021-01-01'::DATE - 1
		END AS end_date
	FROM x
	
	LEFT JOIN x AS y
	ON x.customer_id = y.customer_id
	AND x.plan_stage = y.plan_stage - 1
	
	WHERE x.plan_id != 0
	AND x.start_date < '2021-01-01'
),
-- Seperate payments and add prices (without any subtractions)
b AS (
	SELECT 
		a.customer_id,
		a.plan_id,
		p.plan_name,
		CASE
			WHEN payment_date IS NULL THEN start_date::DATE
			ELSE payment_date::DATE
		END AS payment_date,
		CASE
			WHEN a.plan_id = 1 THEN 9.90
			WHEN a.plan_id = 2 THEN 19.90
			WHEN a.plan_id = 3 THEN 199.00
		END AS amount,
		ROW_NUMBER() OVER(
			PARTITION BY customer_id
			ORDER BY payment_date
		) AS payment_order
	FROM a
	
	LEFT JOIN LATERAL generate_series(
		start_date,
		end_date,
		INTERVAL '1 month'
	) AS payment_date
	ON a.plan_id != 3
	
	JOIN plans AS p
	ON a.plan_id = p.plan_id
	
	WHERE a.plan_id != 4
)
INSERT INTO payments(
	customer_id,
	plan_id,
	plan_name,
	payment_date,
	amount,
	payment_order
)
SELECT 
	b.customer_id,
	b.plan_id,
	b.plan_name,
	b.payment_date,
	CASE
		WHEN y.payment_date < b.payment_date + INTERVAL '1 month'
			THEN b.amount - y.amount
		ELSE b.amount
	END AS amount,
	b.payment_order
FROM b

LEFT JOIN b AS y
ON b.customer_id = y.customer_id
AND b.payment_order = y.payment_order + 1
AND b.plan_id IN (2, 3)
AND y.plan_id = 1

WHERE b.payment_date < '2021-01-01';




SELECT * FROM payments
WHERE customer_id IN (1,2,13,15,16,18,19)