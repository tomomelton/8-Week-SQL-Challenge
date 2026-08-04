SET search_path = clique_bait;

-- 1. How many users are there?

SELECT
	COUNT(DISTINCT user_id) AS total_users
FROM users;


-- 2. How many cookies does each user have on average?

SELECT
	ROUND(AVG(cookies), 2) AS average_cookies
FROM (
	SELECT
		COUNT(cookie_id) AS cookies
	FROM users
	GROUP BY user_id
) AS cookie_count;


-- 3. What is the unique number of visits by all users per month?

SELECT
	DATE_TRUNC('month', start_date)::DATE AS month,
	COUNT(cookie_id) AS visits
FROM users
GROUP BY month;


-- 4. What is the number of events for each event type?

SELECT
	event_name,
	COUNT(*) AS number_events
FROM events AS e
JOIN event_identifier AS i
ON e.event_type = i.event_type
GROUP BY event_name
ORDER BY number_events DESC;


-- 5. What is the percentage of visits which have a purchase event?

SELECT
	ROUND(
		COUNT(DISTINCT visit_id) FILTER(WHERE event_type = 3)
		/
		COUNT(DISTINCT visit_id)::NUMERIC
		*
		100,
		2
	) AS percentage_purchase_visits
FROM events;


-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

SELECT
	ROUND(
		100
		-
		COUNT(DISTINCT visit_id) FILTER(WHERE event_type = 3)
		/
		COUNT(DISTINCT visit_id)::NUMERIC
		*
		100,
		2
	) AS percentage_purchase_visits
FROM events AS a
WHERE EXISTS(
	SELECT 1
	FROM events AS b
	WHERE a.visit_id = b.visit_id
	AND b.page_id = 12
);


-- 7. What are the top 3 pages by number of views?

SELECT
	page_name,
	COUNT(*) AS views
FROM events AS e
JOIN page_hierarchy AS p
ON e.page_id = p.page_id
WHERE event_type = 1
GROUP BY page_name
ORDER BY views DESC
LIMIT 3;


-- 8. What is the number of views and cart adds for each product category?

SELECT
	product_category,
	COUNT(*) FILTER(WHERE event_type = 1) AS views,
	COUNT(*) FILTER(WHERE event_type = 2) AS cart_adds
FROM events AS e
JOIN page_hierarchy AS p
ON e.page_id = p.page_id
AND product_category IS NOT NULL
GROUP BY product_category;


-- 9. What are the top 3 products by purchases?

SELECT
	page_name AS product,
	COUNT(*) AS purchases
FROM events AS e
JOIN page_hierarchy AS p
ON e.page_id = p.page_id
-- Remove visits without a purchase event
WHERE EXISTS (
	SELECT 1
	FROM events AS b
	WHERE b.visit_id = e.visit_id
	AND event_type = 3
)
-- Remove product views
AND event_type = 2
-- Remove null products
AND product_category IS NOT NULL

GROUP BY page_name, product_id
HAVING product_id IS NOT NULL
ORDER BY purchases DESC
LIMIT 3;

