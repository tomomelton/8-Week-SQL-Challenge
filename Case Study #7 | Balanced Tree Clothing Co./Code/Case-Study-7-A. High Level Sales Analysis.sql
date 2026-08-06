SET search_path = balanced_tree;

-- 1. What was the total quantity sold for all products?

SELECT 
	product_name,
	SUM(qty) AS quantity_sold
FROM sales AS s
JOIN product_details AS d
ON s.prod_id = d.product_id
GROUP BY product_name;


-- 2. What is the total generated revenue for all products before discounts?

SELECT 
	product_name,
	SUM(d.price) AS total_revenue
FROM sales AS s
JOIN product_details AS d
ON s.prod_id = d.product_id
GROUP BY product_name;


-- 3. What was the total discount amount for all products?

SELECT 
	product_name,
	ROUND(SUM(d.price * discount / 100::NUMERIC), 2) AS total_discounted
FROM sales AS s
JOIN product_details AS d
ON s.prod_id = d.product_id
GROUP BY product_name;
