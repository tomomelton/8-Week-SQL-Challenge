# Case Study #7 | Balanced Tree Clothing Co.

## A. High Level Sales Analysis


### 1. What was the total quantity sold for all products?

``` SQL
SELECT 
	product_name,
	SUM(qty) AS quantity_sold
FROM sales AS s
JOIN product_details AS d
ON s.prod_id = d.product_id
GROUP BY product_name;
```
| product_name                     | quantity_sold |
| -------------------------------- | ------------: |
| White Tee Shirt - Mens           |          3800 |
| Navy Solid Socks - Mens          |          3792 |
| Grey Fashion Jacket - Womens     |          3876 |
| Navy Oversized Jeans - Womens    |          3856 |
| Pink Fluro Polkadot Socks - Mens |          3770 |
| Khaki Suit Jacket - Womens       |          3752 |
| Black Straight Jeans - Womens    |          3786 |
| White Striped Socks - Mens       |          3655 |
| Blue Polo Shirt - Mens           |          3819 |
| Indigo Rain Jacket - Womens      |          3757 |
| Cream Relaxed Jeans - Womens     |          3707 |
| Teal Button Up Shirt - Mens      |          3646 |


### 2. What is the total generated revenue for all products before discounts?
``` SQL
SELECT 
	product_name,
	SUM(d.price) AS total_revenue
FROM sales AS s
JOIN product_details AS d
ON s.prod_id = d.product_id
GROUP BY product_name;
```
| product_name                     | total_revenue |
| -------------------------------- | ------------: |
| White Tee Shirt - Mens           |         50720 |
| Navy Solid Socks - Mens          |         46116 |
| Grey Fashion Jacket - Womens     |         68850 |
| Navy Oversized Jeans - Womens    |         16562 |
| Pink Fluro Polkadot Socks - Mens |         36482 |
| Khaki Suit Jacket - Womens       |         28681 |
| Black Straight Jeans - Womens    |         39872 |
| White Striped Socks - Mens       |         21131 |
| Blue Polo Shirt - Mens           |         72276 |
| Indigo Rain Jacket - Womens      |         23750 |
| Cream Relaxed Jeans - Womens     |         12430 |
| Teal Button Up Shirt - Mens      |         12420 |


### 3. What was the total discount amount for all products?
``` SQL
SELECT 
	product_name,
	ROUND(SUM(d.price * discount / 100::NUMERIC), 2) AS total_discounted
FROM sales AS s
JOIN product_details AS d
ON s.prod_id = d.product_id
GROUP BY product_name;
```
| product_name                     | total_discounted |
| -------------------------------- | ---------------: |
| White Tee Shirt - Mens           |          6194.80 |
| Navy Solid Socks - Mens          |          5632.56 |
| Grey Fashion Jacket - Womens     |          8370.00 |
| Navy Oversized Jeans - Womens    |          2004.34 |
| Pink Fluro Polkadot Socks - Mens |          4334.34 |
| Khaki Suit Jacket - Womens       |          3373.87 |
| Black Straight Jeans - Womens    |          4882.24 |
| White Striped Socks - Mens       |          2528.41 |
| Blue Polo Shirt - Mens           |          8865.21 |
| Indigo Rain Jacket - Womens      |          2903.77 |
| Cream Relaxed Jeans - Womens     |          1506.50 |
| Teal Button Up Shirt - Mens      |          1500.30 |
