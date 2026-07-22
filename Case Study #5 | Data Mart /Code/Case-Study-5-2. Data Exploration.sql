SET search_path = data_mart;

-- 1. What day of the week is used for each week_date value?

SELECT
	EXTRACT('dow' FROM week_date) AS week_day,
	COUNT(week_date) 
FROM clean_weekly_sales
GROUP BY week_day;

-- All rows have a week_day of 1. Therefore, the day of the week used in week_date is Monday


-- 2. What range of week numbers are missing from the dataset?

SELECT
	DISTINCT week_number
FROM clean_weekly_sales
ORDER BY week_number;

-- Evidently, weeks 1 - 12 are missing. Also, since there are 52 weeks in a year, weeks 37 - 52 are also missing


-- 3. How many total transactions were there for each year in the dataset?

SELECT
	calendar_year,
	SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;


-- 4. What is the total sales for each region for each month?

SELECT
	region,
	month_number,
	SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;


-- 5. What is the total count of transactions for each platform

SELECT
	platform,
	SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY platform;


-- 6. What is the percentage of sales for Retail vs Shopify for each month?

SELECT
	platform,
	month_number,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY month_number) AS monthly_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY month_number) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
GROUP BY platform, month_number
ORDER BY percentage_sales DESC;


-- 7. What is the percentage of sales by demographic for each year in the dataset?

SELECT
	demographic,
	calendar_year,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY calendar_year) AS anual_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY calendar_year) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
GROUP BY demographic, calendar_year
ORDER BY percentage_sales DESC;


-- 8. Which age_band and demographic values contribute the most to Retail sales?

-- For age_band:

SELECT
	age_band,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY platform) AS platform_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY platform) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY platform, age_band
ORDER BY percentage_sales DESC;

-- For demographic:

SELECT
	demographic,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY platform) AS platform_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY platform) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY platform, demographic
ORDER BY percentage_sales DESC;

