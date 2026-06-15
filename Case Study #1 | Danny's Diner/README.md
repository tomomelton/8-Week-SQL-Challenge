# Case Study #1 | Danny's Diner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" width=500 alt="Danny's Diner Logo">

## Table of Contents

- [Problem Statement](#Problem-Statement)
- [Solutions](#Solutions)
- [Links](#Links)

## Problem Statement

Danny's Diner has been collecting data about its customers but needs help using it. I have been tasked with taking this data and creating queries to answer questions Danny has about his customers.

## Solutions

### 1. What is the total amount each customer spent at the restaurant?

```SQL
SELECT customer_id, SUM(price) AS total_spent
FROM menu, sales
WHERE sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;
```
| customer_id  | total_spent |
| :----------: |:-----------:|
| A            | 76          |
| B            | 74          |
| C            | 36          |

#### Steps:
- Linked **menu** and **sales** together via a common product id
- Used **SUM** to calculate the total amount spent by each customer
- Group the results by **customer_id**

---

### 2. How many days has each customer visited the restaurant?

```SQL
SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id  | days_visited |
| :----------: |:------------:|
| A            | 4            |
| B            | 6            |
| C            | 2            |

#### Steps:
- Used **DISTINCT** to remove duplicate dates
- Used **COUNT** to get the number of unique dates
- Grouped by **customer_id**

---

### 3. What was the first item from the menu purchased by each customer?

```SQL
SELECT DISTINCT ON (a.customer_id) a.customer_id, product_name
FROM sales, menu, (
	SELECT customer_id, MIN(order_date) AS min_date
	FROM sales
	GROUP BY customer_id
)	AS a
WHERE sales.customer_id = a.customer_id
AND sales.product_id = menu.product_id
AND sales.order_date = a.min_date
ORDER BY customer_id, product_name;
```

| customer_id | product_name |
|:-----------:|:------------:|
| A           | curry        |
| B           | curry        |
| C           | ramen        |

#### Steps:
- In a sub query, I used **MIN** to find and return the customer's earliest **order_date** as **min_date**
- Ordered by **customer_id** and **product_name**
- Used **DISTINCT ON (customer_id)** to select only the first occurrence of each customer. Due to the ordering, this selects the first product the customer ordered

---

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```SQL
SELECT product_name, COUNT(sales.product_id) AS times_ordered
FROM sales
JOIN menu ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY times_ordered DESC
LIMIT 1;
```

| product_name | times_ordered |
|:------------:|:-------------:|
| ramen        |8              |

#### Steps:
- Used **COUNT** to get the number of times each product is ordered
- Ordered, **descending**, by **times_ordered**. This is so that the most ordered product is at the top
- Used **LIMIT 1** to only select the first row of the query

---

### 5. Which item was the most popular for each customer?

Assuming that if a customer has ordered different items the same number of times, the item which was ordered first is their favourite

```SQL
SELECT DISTINCT ON (customer_id) customer_id, product_name, MAX(times_ordered) AS times_ordered
FROM menu, (
	SELECT customer_id, product_id, COUNT(product_id) AS times_ordered
	FROM sales
	GROUP BY customer_id, product_id
	ORDER BY times_ordered
)	AS a
WHERE menu.product_id = a.product_id
GROUP BY customer_id, product_name
ORDER BY customer_id, times_ordered DESC;
```

| customer_id  | product_name | times_ordered |
|:------------:|:------------:|:-------------:| 
| A            | ramen        | 3             |
| B            | curry        | 2             |
| C            | ramen        | 3             |

#### Steps:
- In a sub query, I use **COUNT(product_id)** to get the number of times each customer has ordered each product, ordered by **times_ordered**
- Used **MAX(times_ordered)** to get each customer's most ordered product
- Used **DISTINCT ON (customer_id)** to only select each customer's most ordered product and remove duplicates

---

### 6. Which item was purchased first by the customer after they became a member?

```SQL
SELECT DISTINCT ON (members.customer_id) members.customer_id, product_name
FROM members
JOIN sales ON members.customer_id = sales.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date >= join_date
ORDER BY customer_id, order_date;
```

| customer_id | product_name |
|:-----------:|:------------:|
| A           | curry        |
| B           | sushi        |

#### Steps:
- Joined together **members, sales, and menu**
- Used clause **WHERE order_date >= join_date** to restrict the rows of sales to ones after and including a members **join_date**
- Ordered by **customer_id, order_date** so that a customer's first order after becoming a member is at the top
- Used **DISTINCT ON (members.customer_id)** to get only the first order made by a member 

---

### 7. Which item was purchased just before the customer became a member?

```SQL
SELECT DISTINCT ON (members.customer_id) members.customer_id, product_name
FROM members
JOIN sales ON members.customer_id = sales.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date < join_date
ORDER BY customer_id, order_date DESC;
```

| customer_id | product_name |
|:-----------:|:------------:|
| A           | sushi        |
| B           | sushi        |

#### Steps:
- Joined together **members, sales, and menu**
- Used clause **WHERE order_date < join_date** to restrict the rows of sales to ones before a members **join_date**
- Ordered, **descending** by **customer_id, order_date** so that a customer's last order before becoming a member is at the top
- Used **DISTINCT ON (members.customer_id)** to get only the last order made by a customer before becoming a member  

---

### 8. What is the total items and amount spent for each member before they became a member?

```SQL
SELECT 
  members.customer_id, 
  SUM(price) AS amount_spent, 
  COUNT(sales.product_id) AS total_sales
FROM members
JOIN sales ON members.customer_id = sales.customer_id
JOIN menu ON menu.product_id = sales.product_id
WHERE order_date < join_date
GROUP BY members.customer_id
ORDER BY members.customer_id;
```

| customer_id | amount_spent | total_sales |
|:-----------:|:------------:|:-----------:|
| A           | 25           |2            |
| B           | 40           |3            |

#### Steps:
- Joined together **members, sales, and menu**
- Used clause **WHERE order_date < join_date** to restrict the rows of sales to ones before a member's **join_date**
- Used **SUM(price)** to get the customer's total amount spent
- Used **COUNT(sales.product_id)** to get the customer's total sales made

---

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```SQL
SELECT customer_id, SUM(score) AS score
FROM (
	-- Select sushi score
	SELECT customer_id, price * 10 * 2 AS score
	FROM sales
	JOIN menu ON menu.product_id = sales.product_id
	AND product_name = 'sushi'
	
	UNION ALL
	
	-- Select not sushi score
	SELECT customer_id, price * 10 AS score
	FROM sales
	JOIN menu ON menu.product_id = sales.product_id
	AND product_name != 'sushi'
) AS a
GROUP BY customer_id
ORDER BY customer_id;
```
| customer_id | score |
|:-----------:|:-----:|
| A           | 860   |
| B           | 940   |
| C           | 360   |

#### Steps:
- Selected the customer's scores for **sushi** using the multiplier **price x 10 x 2**
- Selected the customer's scores for items which aren't **sushi** using the multiplier **price x 10**
- Used **SUM(score)** to calculate the sum of scores for each customer from the two selections using **UNION ALL** to include any duplicates 

---

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```SQL
SELECT customer_id, SUM(score) AS score
FROM (

	-- Select scores within 1st week
	SELECT members.customer_id, product_name, order_date, price * 10 * 2 AS score
	FROM members
	JOIN sales ON members.customer_id = sales.customer_id
	JOIN menu ON sales.product_id = menu.product_id
	AND order_date BETWEEN join_date AND join_date + 7
	
	-- Select sales excluding 1st week
	
	UNION ALL
	
	-- Select sushi scores
	SELECT members.customer_id, product_name, order_date, price * 10 * 2 AS score
	FROM members
	JOIN sales ON members.customer_id = sales.customer_id
	JOIN menu ON sales.product_id = menu.product_id
	AND order_date NOT BETWEEN join_date AND join_date + 7
	AND product_name = 'sushi'
	
	UNION ALL
	
	-- Select non-sushi scores
	SELECT members.customer_id, product_name, order_date, price * 10 AS score
	FROM members
	JOIN sales ON members.customer_id = sales.customer_id
	JOIN menu ON sales.product_id = menu.product_id
	AND order_date NOT BETWEEN join_date AND join_date + 7 
	AND product_name != 'sushi'

	ORDER BY customer_id, order_date
) AS a
WHERE order_date < '2021-02-01'
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | score |
|:-----------:|:-----:|
| A           | 1370  |
| B           | 940   |

#### Steps:
- Selected the member's scores for all sales made using their **1st** week of membership using the multiplier **price x 10 x 2**. The statement **order_date BETWEEN join_date AND join_date + 7** ensures that only sales from their **1st** week of membership are included
- Selected the member's scores for **sushi** made outside of their **1st** week of membership using the multiplier **price x 10 x 2**. The statement **NOT BETWEEN join_date AND join_date + 7** ensures that only sales made outside their **1st** week of membership are included
- Selected the member's scores for items which **aren't sushi** made outside of their **1st** week of membership using the multiplier **price x 10**. The statement **NOT BETWEEN join_date AND join_date + 7** ensures that only sales made outside their **1st** week of membership are included
- Included the clause **WHERE order_date < '2021-02-01'** to only select the members scores within **January**
- Used **SUM(score)** to calculate the sum of scores for each customer from the two selections using **UNION ALL** to include any duplicates 



## Links

- All case study details, including the full problem statement, database diagram, and sample data used, can be found through the link:
	[8 Week SQL Challenge: Case Study #1 - Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)

- I have not seen the official solutions for this case study. If you have any questions or feedback on my solutions please contact me on my LinkedIn: 
	[Tom Melton](https://LinkedIn.com/in/tom-melton-23a59b353/)


