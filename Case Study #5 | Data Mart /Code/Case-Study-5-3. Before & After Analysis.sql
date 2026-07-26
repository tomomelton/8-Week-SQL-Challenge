SET search_path = data_mart;

-- Views of before and after data to assist with analysis

CREATE OR REPLACE VIEW sales_before
AS (
	SELECT * FROM clean_weekly_sales
	WHERE week_date < '2020-06-15'
);

CREATE OR REPLACE VIEW sales_after
AS (
	SELECT * FROM clean_weekly_sales
	WHERE week_date >= '2020-06-15'
);


-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? 
--    What is the growth or reduction rate in actual values and percentage of sales?

-- Total sales 4 weeks before and after

SELECT
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_before
WHERE week_date >= ('2020-06-15'::DATE - INTERVAL '4 weeks')

UNION

SELECT
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_after
WHERE week_date <= ('2020-06-15'::DATE + INTERVAL '4 weeks');


-- Growth / reduction rate (actual value and percentage)

WITH
a AS (
	SELECT
		1 AS rn,
		SUM(sales) AS sales
	FROM sales_before
	WHERE week_date >= ('2020-06-15'::DATE - INTERVAL '4 weeks')
	
	UNION
	
	SELECT
		2 AS rn,
		SUM(sales) AS sales
	FROM sales_after
	WHERE week_date <= ('2020-06-15'::DATE + INTERVAL '4 weeks')
)
SELECT 
	MAX(sales) FILTER(WHERE rn = 2) - MAX(sales) FILTER(WHERE rn = 1) AS growth_rate,
	ROUND(
		(MAX(sales) FILTER(WHERE rn = 2) - MAX(sales) FILTER(WHERE rn = 1)) 
		/ MAX(sales) FILTER(WHERE rn = 1)::numeric * 100,
		2	
	) AS percentage_growth
FROM a;


-- 2. What about the entire 12 weeks before and after?

SELECT
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_before
WHERE week_date >= ('2020-06-15'::DATE - INTERVAL '12 weeks')

UNION

SELECT
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_after
WHERE week_date <= ('2020-06-15'::DATE + INTERVAL '12 weeks');


-- Growth / reduction rate (actual value and percentage)

WITH
a AS (
	SELECT
		1 AS rn,
		SUM(sales) AS sales
	FROM sales_before
	WHERE week_date >= ('2020-06-15'::DATE - INTERVAL '12 weeks')
	
	UNION
	
	SELECT
		2 AS rn,
		SUM(sales) AS sales
	FROM sales_after
	WHERE week_date <= ('2020-06-15'::DATE + INTERVAL '12 weeks')
)
SELECT 
	MAX(sales) FILTER(WHERE rn = 2) - MAX(sales) FILTER(WHERE rn = 1) AS growth_rate,
	ROUND(
		(MAX(sales) FILTER(WHERE rn = 2) - MAX(sales) FILTER(WHERE rn = 1)) 
		/ MAX(sales) FILTER(WHERE rn = 1)::numeric * 100,
		2	
	) AS percentage_growth
FROM a;


-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

WITH
metrics AS (
	-- Sales rates for each year:
	SELECT
		'2018' AS year,
		MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
		SUM(sales) AS sales
	FROM sales_before
	WHERE week_date BETWEEN ('2018-06-15'::DATE - INTERVAL '12 weeks') AND '2018-06-15'::DATE
	
	UNION
	
	SELECT
		'2018' AS year,
		MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
		SUM(sales) AS sales
	FROM sales_before
	WHERE week_date BETWEEN '2018-06-15'::DATE AND ('2018-06-15'::DATE + INTERVAL '12 weeks')
	
	UNION
	
	SELECT
		'2019' AS year,
		MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
		SUM(sales) AS sales
	FROM sales_before
	WHERE week_date BETWEEN ('2019-06-15'::DATE - INTERVAL '12 weeks') AND '2019-06-15'::DATE
	
	UNION
	
	SELECT
		'2019' AS year,
		MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
		SUM(sales) AS sales
	FROM sales_before
	WHERE week_date BETWEEN '2019-06-15'::DATE AND ('2019-06-15'::DATE + INTERVAL '12 weeks')
	
	UNION
	
	SELECT
		'2020' AS year,
		MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
		SUM(sales) AS sales
	FROM sales_before
	WHERE week_date >= ('2020-06-15'::DATE - INTERVAL '12 weeks')
	
	UNION
	
	SELECT
		'2020' AS year,
		MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
		SUM(sales) AS sales
	FROM sales_after
	WHERE week_date <= ('2020-06-15'::DATE + INTERVAL '12 weeks')
	
	ORDER BY year, week_range
),
ordered_metrics AS (
	SELECT
		ROW_NUMBER() OVER(
			PARTITION BY year
			ORDER BY week_range
		) AS rn,
		*
	FROM metrics
)
-- Growth / reduction rate (actual value and percentage)
SELECT
	bef.year,
	aft.sales - bef.sales AS sales_growth,
	ROUND (
		(aft.sales - bef.sales) / bef.sales::numeric * 100,
		2
	) AS sales_growth_percentage
FROM ordered_metrics AS bef
JOIN ordered_metrics AS aft
ON bef.year = aft.year
AND bef.rn = aft.rn - 1

