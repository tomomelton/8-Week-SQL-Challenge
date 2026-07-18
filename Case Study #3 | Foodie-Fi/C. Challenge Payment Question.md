# Case Study #3 | Foodie-Fi
## C. Challenge Payment Question

### Scenario

The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments

### Solution

Firstly, I created the new table

``` SQL
CREATE TABLE payments (
	customer_id INT,
	plan_id INT,
	plan_name VARCHAR(13),
	payment_date DATE,
	amount DECIMAL(5,2),
	payment_order INT
);
```

``` mermaid
erDiagram
  payments {
    INT customer_id
    INT plan_id
    VARCHAR plan_name
    DATE payment_date
    DECIMAL(5,2) amount
    INT payment_order
  }
```

The next step was to get the data in the tables format, and calculate the payment amounts according to the rules specified above.
I constructed the following query which satisfied these requirements, and inserted into the table

``` SQL
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
```

Finally, to test that the insert was successful I ran the following query to produce the same data as provided in the example in the breif

``` SQL
SELECT * FROM payments
WHERE customer_id IN (1,2,13,15,16,18,19)
```

| customer_id | plan_id | plan_name     | payment_date | amount | payment_order |
| :---------: | :-----: | :-----------: | :----------: | :----: | :-----------: |
|      1      |    1    | basic monthly |  2020-08-08  |   9.90 |       1       |
|      1      |    1    | basic monthly |  2020-09-08  |   9.90 |       2       |
|      1      |    1    | basic monthly |  2020-10-08  |   9.90 |       3       |
|      1      |    1    | basic monthly |  2020-11-08  |   9.90 |       4       |
|      1      |    1    | basic monthly |  2020-12-08  |   9.90 |       5       |
|      2      |    3    | pro annual    |  2020-09-27  | 199.00 |       1       |
|      13     |    1    | basic monthly |  2020-12-22  |   9.90 |       1       |
|      15     |    2    | pro monthly   |  2020-03-24  |  19.90 |       1       |
|      15     |    2    | pro monthly   |  2020-04-24  |  19.90 |       2       |
|      16     |    1    | basic monthly |  2020-06-07  |   9.90 |       1       |
|      16     |    1    | basic monthly |  2020-07-07  |   9.90 |       2       |
|      16     |    1    | basic monthly |  2020-08-07  |   9.90 |       3       |
|      16     |    1    | basic monthly |  2020-09-07  |   9.90 |       4       |
|      16     |    1    | basic monthly |  2020-10-07  |   9.90 |       5       |
|      16     |    3    | pro annual    |  2020-10-21  | 189.10 |       6       |
|      18     |    2    | pro monthly   |  2020-07-13  |  19.90 |       1       |
|      18     |    2    | pro monthly   |  2020-08-13  |  19.90 |       2       |
|      18     |    2    | pro monthly   |  2020-09-13  |  19.90 |       3       |
|      18     |    2    | pro monthly   |  2020-10-13  |  19.90 |       4       |
|      18     |    2    | pro monthly   |  2020-11-13  |  19.90 |       5       |
|      18     |    2    | pro monthly   |  2020-12-13  |  19.90 |       6       |
|      19     |    2    | pro monthly   |  2020-06-29  |  19.90 |       1       |
|      19     |    2    | pro monthly   |  2020-07-29  |  19.90 |       2       |
|      19     |    3    | pro annual    |  2020-08-29  | 199.00 |       3       |
