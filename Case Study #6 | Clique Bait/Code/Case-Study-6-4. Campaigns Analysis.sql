SET search_path = clique_bait;

-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:

-- - user_id
-- - visit_id
-- - visit_start_time: the earliest event_time for each visit
-- - page_views: count of page views for each visit
-- - cart_adds: count of product cart add events for each visit
-- - purchase: 1/0 flag if a purchase event exists for each visit
-- - campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- - impression: count of ad impressions for each visit
-- - click: count of ad clicks for each visit
-- - (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

DROP TABLE visits;

CREATE TABLE visits AS 
SELECT
	user_id,
	visit_id,
	MIN(event_time) AS visit_start_time,
	COUNT(*) FILTER (WHERE event_type = 1) AS page_views,
	COUNT(*) FILTER (WHERE event_type = 2) AS cart_adds,
	BOOL_OR(event_type = 3)::INT AS purchase,
	campaign_name,
	COUNT(*) FILTER (WHERE event_type = 4) AS impression,
	COUNT(*) FILTER (WHERE event_type = 5) AS click,
	STRING_AGG(page_name, ', ' ORDER BY sequence_number) FILTER (WHERE event_type = 2) AS cart_products
	
FROM events AS e

JOIN users AS u
ON e.cookie_id = u.cookie_id

JOIN campaign_identifier AS c
ON e.event_time BETWEEN c.start_date AND c.end_date

JOIN page_hierarchy AS p
ON e.page_id = p.page_id

GROUP BY user_id, visit_id, campaign_name;

SELECT * FROM visits;



-- Identifying users who have received impressions during each campaign period and 
-- comparing each metric with other users who did not have an impression event

SELECT 
	campaign_name,
	'True' AS has_impressions,
	COUNT(visit_id) AS visitors,
	ROUND(AVG(page_views), 2) AS avg_page_views,
	ROUND(AVG(cart_adds), 2) AS avg_cart_adds,
	SUM(purchase) AS purchases,
	ROUND(AVG(impression), 2) AS avg_impressions,
	ROUND(AVG(click), 2) AS avg_clicks
FROM visits
WHERE impression > 0
GROUP BY campaign_name

UNION

SELECT 
	campaign_name,
	'False' AS has_impressions,
	COUNT(visit_id) AS visitors,
	ROUND(AVG(page_views), 2) AS avg_page_views,
	ROUND(AVG(cart_adds), 2) AS avg_cart_adds,
	SUM(purchase) AS purchases,
	ROUND(AVG(impression), 2) AS avg_impressions,
	ROUND(AVG(click), 2) AS avg_clicks
FROM visits
WHERE impression = 0
GROUP BY campaign_name

ORDER BY campaign_name, has_impressions DESC;



-- Does clicking on an impression lead to higher purchase rates?

SELECT
	'True' AS has_clicked,
	COUNT(visit_id) AS visitors,
	SUM(purchase) AS purchases,
	ROUND(SUM(purchase) / COUNT(visit_id)::NUMERIC * 100, 2) AS purchase_rate
FROM visits
WHERE click > 0

UNION
	
SELECT
	'False' AS has_clicked,
	COUNT(visit_id) AS visitors,
	SUM(purchase) AS purchases,
	ROUND(SUM(purchase) / COUNT(visit_id)::NUMERIC * 100, 2) AS purchase_rate
FROM visits
WHERE click = 0;




-- What is the uplift in purchase rate when comparing users who click on a campaign impression 
-- versus users who do not receive an impression? 
-- What if we compare them with users with just an impression but do not click?


SELECT
	click > 0 AS clicked,
	impression > 0 AS impressioned,
	COUNT(visit_id) AS visitors,
	SUM(purchase) AS purchases,
	ROUND(SUM(purchase) / COUNT(visit_id)::NUMERIC * 100, 2) AS purchase_rate
FROM visits
GROUP BY clicked, impressioned
ORDER BY purchase_rate DESC
