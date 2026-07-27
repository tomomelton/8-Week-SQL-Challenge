# Case Study #5 | Data Mart

<img src="https://8weeksqlchallenge.com/images/case-study-designs/5.png" width=500 alt="Data Bank Logo">

## Table of Contents

- [Problem Statement](#problem-statement)
- [Case Study Questions](#case-study-questions)
  - [1. Data Cleansing](#1-data-cleansing)
  - [2. Data Exploration](#2-data-exploration)
  - [3. Before & After Analysis](#3-before--after-analysis)
- [Links](#links)

## Problem Statement

Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce - Danny is asking for your support to analyse his sales performance.

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

The key business question he wants you to help him answer are the following:

- What was the quantifiable impact of the changes introduced in June 2020?
- Which platform, region, segment and customer types were the most impacted by this change?
- What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?



## Case Study Questions

### 1. Data Cleansing

#### Steps:

In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value:

| segment | age_band     |
|:--------|:-------------|
| 1       | Young Adults |
| 2       | Middle Aged  |
| 3 or 4  | Retirees     |

- Add a new demographic column using the following mapping for the first letter in the segment values:

| segment | demographic |
|:--------|:------------|
| C       | Couples     |
| F       | Families    |

- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

#### Solution

``` SQL
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
```

Below is a selection of the first 10 entries from this new table:

``` SQL
SELECT * FROM clean_weekly_sales
LIMIT 10;
```

| week_date  | week_number | month_number | calendar_year | region | platform | segment | age_band     | demographic | customer_type | transactions |    sales | avg_transaction |
| ---------- | ----------: | -----------: | ------------: | ------ | -------- | ------- | ------------ | ----------- | ------------- | -----------: | -------: | --------------: |
| 2020-08-31 |          36 |            8 |          2020 | ASIA   | Retail   | C3      | Retirees     | Couples     | New           |       120631 |  3656163 |           30.31 |
| 2020-08-31 |          36 |            8 |          2020 | ASIA   | Retail   | F1      | Young Adults | Families    | New           |        31574 |   996575 |           31.56 |
| 2020-08-31 |          36 |            8 |          2020 | USA    | Retail   | unknown | unknown      | unknown     | Guest         |       529151 | 16509610 |           31.20 |
| 2020-08-31 |          36 |            8 |          2020 | EUROPE | Retail   | C1      | Young Adults | Couples     | New           |         4517 |   141942 |           31.42 |
| 2020-08-31 |          36 |            8 |          2020 | AFRICA | Retail   | C2      | Middle Aged  | Couples     | New           |        58046 |  1758388 |           30.29 |
| 2020-08-31 |          36 |            8 |          2020 | CANADA | Shopify  | F2      | Middle Aged  | Families    | Existing      |         1336 |   243878 |          182.54 |
| 2020-08-31 |          36 |            8 |          2020 | AFRICA | Shopify  | F3      | Retirees     | Families    | Existing      |         2514 |   519502 |          206.64 |
| 2020-08-31 |          36 |            8 |          2020 | ASIA   | Shopify  | F1      | Young Adults | Families    | Existing      |         2158 |   371417 |          172.11 |
| 2020-08-31 |          36 |            8 |          2020 | AFRICA | Shopify  | F2      | Middle Aged  | Families    | New           |          318 |    49557 |          155.84 |
| 2020-08-31 |          36 |            8 |          2020 | AFRICA | Retail   | C3      | Retirees     | Couples     | New           |       111032 |  3888162 |           35.02 |

---

### 2. Data Exploration

#### 1. What day of the week is used for each week_date value?
``` SQL
SELECT
	EXTRACT('dow' FROM week_date) AS week_day,
	COUNT(week_date) 
FROM clean_weekly_sales
GROUP BY week_day;
```

| week_day | count |
| -------: | ----: |
|        1 | 17117 |

All rows have a week_day of 1. Therefore, the day of the week used in week_date is Monday


#### 2. What range of week numbers are missing from the dataset?
``` SQL
SELECT
	DISTINCT week_number
FROM clean_weekly_sales
ORDER BY week_number;
```
| week_number |
| ----------: |
|          13 |
|          14 |
|          15 |
|          16 |
|          17 |
|          18 |
|          19 |
|          20 |
|          21 |
|          22 |
|          23 |
|          24 |
|          25 |
|          26 |
|          27 |
|          28 |
|          29 |
|          30 |
|          31 |
|          32 |
|          33 |
|          34 |
|          35 |
|          36 |


Evidently, weeks 1 - 12 are missing. Also, since there are 52 weeks in a year, weeks 37 - 52 are also missing


#### 3. How many total transactions were there for each year in the dataset?
``` SQL
SELECT
	calendar_year,
	SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```
| calendar_year | total_transactions |
| ------------: | -----------------: |
|          2018 |          346406460 |
|          2019 |          365639285 |
|          2020 |          375813651 |


#### 4. What is the total sales for each region for each month?
``` SQL
SELECT
	region,
	month_number,
	SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;
```
| region        | month_number | total_sales |
| ------------- | ------------ | ----------: |
| AFRICA        | 3            |   567767480 |
| AFRICA        | 4            |  1911783504 |
| AFRICA        | 5            |  1647244738 |
| AFRICA        | 6            |  1767559760 |
| AFRICA        | 7            |  1960219710 |
| AFRICA        | 8            |  1809596890 |
| AFRICA        | 9            |   276320987 |
| ASIA          | 3            |   529770793 |
| ASIA          | 4            |  1804628707 |
| ASIA          | 5            |  1526285399 |
| ASIA          | 6            |  1619482889 |
| ASIA          | 7            |  1768844756 |
| ASIA          | 8            |  1663320609 |
| ASIA          | 9            |   252836807 |
| CANADA        | 3            |   144634329 |
| CANADA        | 4            |   484552594 |
| CANADA        | 5            |   412378365 |
| CANADA        | 6            |   443846698 |
| CANADA        | 7            |   477134947 |
| CANADA        | 8            |   447073019 |
| CANADA        | 9            |    69067959 |
| EUROPE        | 3            |    35337093 |
| EUROPE        | 4            |   127334255 |
| EUROPE        | 5            |   109338389 |
| EUROPE        | 6            |   122813826 |
| EUROPE        | 7            |   136757466 |
| EUROPE        | 8            |   122102995 |
| EUROPE        | 9            |    18877433 |
| OCEANIA       | 3            |   783282888 |
| OCEANIA       | 4            |  2599767620 |
| OCEANIA       | 5            |  2215657304 |
| OCEANIA       | 6            |  2371884744 |
| OCEANIA       | 7            |  2563459400 |
| OCEANIA       | 8            |  2432313652 |
| OCEANIA       | 9            |   372465518 |
| SOUTH AMERICA | 3            |    71023109 |
| SOUTH AMERICA | 4            |   238451531 |
| SOUTH AMERICA | 5            |   201391809 |
| SOUTH AMERICA | 6            |   218247455 |
| SOUTH AMERICA | 7            |   235582776 |
| SOUTH AMERICA | 8            |   221166052 |
| SOUTH AMERICA | 9            |    34175583 |
| USA           | 3            |   225353043 |
| USA           | 4            |   759786323 |
| USA           | 5            |   655967121 |
| USA           | 6            |   703878990 |
| USA           | 7            |   760331754 |
| USA           | 8            |   712002790 |
| USA           | 9            |   110532368 |



#### 5. What is the total count of transactions for each platform
``` SQL
SELECT
	platform,
	SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY platform;
```
| platform | total_transactions |
| -------- | -----------------: |
| Retail   |         1081934227 |
| Shopify  |            5925169 |


#### 6. What is the percentage of sales for Retail vs Shopify for each month?
``` SQL
SELECT
	platform,
	month_number,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY month_number) AS monthly_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY month_number) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
GROUP BY platform, month_number
ORDER BY percentage_sales DESC;
```
| platform | month_number | total_sales | monthly_sales | percentage_sales |
| -------- | ------------ | ----------: | ------------: | ---------------: |
| Retail   | 4            |  7735592234 |    7926304534 |            97.59 |
| Retail   | 3            |  2299188417 |    2357168735 |            97.54 |
| Retail   | 9            |  1104506857 |    1134276655 |            97.38 |
| Retail   | 5            |  6585838223 |    6768263125 |            97.30 |
| Retail   | 7            |  7688091448 |    7902330809 |            97.29 |
| Retail   | 6            |  7049949260 |    7247714362 |            97.27 |
| Retail   | 8            |  7191449998 |    7407576007 |            97.08 |
| Shopify  | 8            |   216126009 |    7407576007 |             2.92 |
| Shopify  | 6            |   197765102 |    7247714362 |             2.73 |
| Shopify  | 7            |   214239361 |    7902330809 |             2.71 |
| Shopify  | 5            |   182424902 |    6768263125 |             2.70 |
| Shopify  | 9            |    29769798 |    1134276655 |             2.62 |
| Shopify  | 3            |    57980318 |    2357168735 |             2.46 |
| Shopify  | 4            |   190712300 |    7926304534 |             2.41 |


#### 7. What is the percentage of sales by demographic for each year in the dataset?
``` SQL
SELECT
	demographic,
	calendar_year,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY calendar_year) AS anual_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY calendar_year) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
GROUP BY demographic, calendar_year
ORDER BY percentage_sales DESC;
```
| demographic | calendar_year | total_sales | anual_sales | percentage_sales |
| ----------- | ------------- | ----------: | ----------: | ---------------: |
| unknown     | 2018          |  5369434106 | 12897380827 |            41.63 |
| unknown     | 2019          |  5532862221 | 13746032500 |            40.25 |
| unknown     | 2020          |  5436315907 | 14100220900 |            38.55 |
| Families    | 2020          |  4614338065 | 14100220900 |            32.73 |
| Families    | 2019          |  4463918344 | 13746032500 |            32.47 |
| Families    | 2018          |  4125558033 | 12897380827 |            31.99 |
| Couples     | 2020          |  4049566928 | 14100220900 |            28.72 |
| Couples     | 2019          |  3749251935 | 13746032500 |            27.28 |
| Couples     | 2018          |  3402388688 | 12897380827 |            26.38 |


#### 8. Which age_band and demographic values contribute the most to Retail sales?

For age_band:
``` SQL
SELECT
	age_band,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY platform) AS platform_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY platform) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY platform, age_band
ORDER BY percentage_sales DESC;
```
| age_band     | total_sales | platform_sales | percentage_sales |
| ------------ | ----------: | -------------: | ---------------: |
| unknown      | 16067285533 |    39654616437 |            40.52 |
| Retirees     | 13005266930 |    39654616437 |            32.80 |
| Middle Aged  |  6208251884 |    39654616437 |            15.66 |
| Young Adults |  4373812090 |    39654616437 |            11.03 |

For demographic:
``` SQL
SELECT
	demographic,
	
	SUM(sales) AS total_sales,

	SUM(SUM(sales)) OVER (PARTITION BY platform) AS platform_sales,

	ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY platform) * 100, 2) AS percentage_sales
	
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY platform, demographic
ORDER BY percentage_sales DESC;
```
| demographic | total_sales | platform_sales | percentage_sales |
| ----------- | ----------: | -------------: | ---------------: |
| unknown     | 16067285533 |    39654616437 |            40.52 |
| Families    | 12759667763 |    39654616437 |            32.18 |
| Couples     | 10827663141 |    39654616437 |            27.30 |

---

### 3. Before & After Analysis

#### Task:

The goal of this case study section, is to analyse the difference in data before and after the week date **'2020-06-15'**, as this week is the first week of Data Marts sustainable packaging changes.

Before beginning the tasks, I decided to produce 2 **views** of the data for before and after:

``` SQL
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
```

#### 1. What are the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

##### Total sales 4 weeks before and after **2020-06015**:
``` SQL
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
WHERE week_date <= ('2020-06-15'::DATE + INTERVAL '4 weeks')
```
| week_range              | total_sales |
| ----------------------- | ----------: |
| 2020-05-18 → 2020-06-08 |  2345878357 |
| 2020-06-15 → 2020-07-13 |  2904930571 |


##### Growth / reduction rate (actual value and percentage)

Formula to calculate percentage_growth: 

$$ 
\text{percentage growth} = \frac{\text{sales after } - \text{ sales before}}{\text{sales before}} \times 100 
$$

``` SQL
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
FROM a
```
| growth_rate | percentage_growth |
| ----------: | ----------------: |
|   559052214 |             23.83 |



#### 2. What about the entire 12 weeks before and after?

For this, we can reuse the code for 1 and just modify the dates from 4 weeks to 12 weeks.

This gives us the tables:

| week_range              | total_sales |
| ----------------------- | ----------: |
| 2020-03-23 → 2020-06-08 |  7126273147 |
| 2020-06-15 → 2020-08-31 |  6973947753 |

| growth_rate | percentage_growth |
| ----------: | ----------------: |
|  -152325394 |             -2.14 |

These results tell us that although there was significant growth in the first 4 weeks before and after the changes, in the long-term sales have reduced



#### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

##### Sales rates for each year:
``` SQL
SELECT
	'2018' AS year,
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_before
WHERE week_date BETWEEN ('2018-06-15'::DATE - INTERVAL '12 weeks') AND '2018-06-15'::DATE

UNION

SELECT
	'2018' AS year,
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_before
WHERE week_date BETWEEN '2018-06-15'::DATE AND ('2018-06-15'::DATE + INTERVAL '12 weeks')

UNION

SELECT
	'2019' AS year,
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_before
WHERE week_date BETWEEN ('2019-06-15'::DATE - INTERVAL '12 weeks') AND '2019-06-15'::DATE

UNION

SELECT
	'2019' AS year,
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_before
WHERE week_date BETWEEN '2019-06-15'::DATE AND ('2019-06-15'::DATE + INTERVAL '12 weeks')

UNION

SELECT
	'2020' AS year,
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_before
WHERE week_date >= ('2020-06-15'::DATE - INTERVAL '12 weeks')

UNION

SELECT
	'2020' AS year,
	MIN(week_date) || ' → ' || MAX(week_date) AS week_range,
	SUM(sales) AS total_sales
FROM sales_after
WHERE week_date <= ('2020-06-15'::DATE + INTERVAL '12 weeks')

ORDER BY year, week_range
```
| year | week_range              | total_sales |
| ---- | ----------------------- | ----------: |
| 2018 | 2018-03-26 → 2018-06-11 |  6396562317 |
| 2018 | 2018-06-18 → 2018-09-03 |  6500818510 |
| 2019 | 2019-03-25 → 2019-06-10 |  6883386397 |
| 2019 | 2019-06-17 → 2019-09-02 |  6862646103 |
| 2020 | 2020-03-23 → 2020-06-08 |  7126273147 |
| 2020 | 2020-06-15 → 2020-08-31 |  6973947753 |

##### Sales growth for each year:
``` SQL
WITH
metrics AS (
-- Previous query
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
```
| year | sales_growth | sales_growth_percentage |
| ---- | -----------: | ----------------------: |
| 2018 |    104256193 |                    1.63 |
| 2019 |    -20740294 |                   -0.30 |
| 2020 |   -152325394 |                   -2.14 |

---

## Links

- All case study details, including the full problem statement, database diagram, and sample data used, can be found through the link:
	[8 Week SQL Challenge: Case Study #5 - Data Mart](https://8weeksqlchallenge.com/case-study-5/)

- I have not seen the official solutions for this case study. If you have any questions or feedback on my solutions please contact me on my LinkedIn: 
	[Tom Melton](https://LinkedIn.com/in/tom-melton-23a59b353/)
