SET search_path = data_mart;

CREATE TABLE IF NOT EXISTS clean_weekly_sales AS
SELECT
	week_date::DATE,
	EXTRACT('week' FROM week_date::DATE) AS week_number,
	EXTRACT('month' FROM week_date::DATE) AS month_number,
	EXTRACT('year' FROM week_date::DATE) AS calendar_year,
	
	region,
	platform,
	
	CASE
		WHEN segment LIKE '__' THEN segment
		ELSE 'unknown'
	END AS segment,
	
	CASE
		WHEN segment LIKE '%1' THEN 'Young Adults'
		WHEN segment LIKE '%2' THEN 'Middle Aged'
		WHEN segment LIKE '%3' THEN 'Retirees'
		WHEN segment LIKE '%4' THEN 'Retirees'
		ELSE 'unknown'
	END AS age_band,
	
	CASE
		WHEN segment LIKE 'C%' THEN 'Couples'
		WHEN segment LIKE 'F%' THEN 'Families'
		ELSE 'unknown'
	END AS demographic,

	customer_type, 
	transactions, 
	sales,

	ROUND(sales / transactions::numeric, 2) AS avg_transaction
	
FROM weekly_sales;



SELECT * FROM clean_weekly_sales
LIMIT 10;
