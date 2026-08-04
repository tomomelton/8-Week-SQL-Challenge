SET search_path = clique_bait;

-- Product Funnel Analysis

-- Using a single SQL query - create a new output table which has the following details:

	-- - How many times was each product viewed?
	-- - How many times was each product added to cart?
	-- - How many times was each product added to a cart but not purchased (abandoned)?
	-- - How many times was each product purchased?

DROP TABLE product_analytics;

CREATE TABLE product_analytics AS
SELECT
	page_name AS product,
	COUNT(*) FILTER(WHERE event_type = 1) AS views,
	
	COUNT(*) FILTER(WHERE event_type = 2) AS carted,
	
	COUNT(*) FILTER(WHERE NOT EXISTS(
		SELECT 1
		FROM events AS b
		WHERE b.visit_id = e.visit_id
		AND event_type = 3
		)
		AND event_type = 2
	) AS abandoned,
	
	COUNT(*) FILTER(WHERE EXISTS(
		SELECT 1
		FROM events AS b
		WHERE b.visit_id = e.visit_id
		AND event_type = 3
		)
		AND event_type = 2
	) AS purchases
	
FROM events AS e
JOIN page_hierarchy AS p
ON e.page_id = p.page_id

GROUP BY product_id, page_name
HAVING product_id IS NOT NULL;


SELECT * FROM product_analytics;


	
-- Additionally, create another table which further aggregates the data for the above points 
-- but this time for each product category instead of individual products.


DROP TABLE category_analytics;

CREATE TABLE category_analytics AS
SELECT
	product_category,
	SUM(views) AS views,
	SUM(carted) AS carted,
	SUM(abandoned) AS abandoned,
	SUM(purchases) AS purchases
	
FROM product_analytics AS a
JOIN page_hierarchy AS h
ON a.product = h.page_name

GROUP BY product_category;


SELECT * FROM category_analytics;



-- Use your 2 new output tables - answer the following questions:

-- 1. Which product had the most views, cart adds and purchases?

SELECT
    (ARRAY_AGG(product ORDER BY views DESC))[1] AS most_views,
    (ARRAY_AGG(product ORDER BY carted DESC))[1] AS most_carted,
    (ARRAY_AGG(product ORDER BY purchases DESC))[1] AS most_purchased
FROM product_analytics;


-- 2. Which product was most likely to be abandoned?

SELECT
	(ARRAY_AGG(product ORDER BY abandoned DESC))[1] AS most_abandoned
FROM product_analytics;


-- 3. Which product had the highest view to purchase percentage?

SELECT 
	product,
	view_purchase_percentage
FROM product_analytics AS a

JOIN LATERAL (
	SELECT
		ROUND(purchases / (views + carted)::NUMERIC * 100, 2) AS view_purchase_percentage
	FROM product_analytics
	WHERE product = a.product
) AS p ON TRUE

ORDER BY view_purchase_percentage DESC
LIMIT 1;


-- 4. What is the average conversion rate from view to cart add?

SELECT 
	ROUND(AVG(conversion_rate), 2) AS average_conversion_rate
FROM product_analytics AS a

JOIN LATERAL (
	SELECT
		carted / (views + carted)::NUMERIC * 100 AS conversion_rate
	FROM product_analytics
	WHERE product = a.product
) AS p ON TRUE;


-- 5. What is the average conversion rate from cart add to purchase?

SELECT 
	ROUND(AVG(conversion_rate), 2) AS average_conversion_rate
FROM product_analytics AS a

JOIN LATERAL (
	SELECT
		purchases / carted::NUMERIC * 100 AS conversion_rate
	FROM product_analytics
	WHERE product = a.product
) AS p ON TRUE;

