# Case Study #3 | Foodie-Fi
## A. Customer Journey

Based on the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

### Solution

``` SQL
SELECT 
	s.customer_id,
	s.plan_id,
	p.plan_name,
	s.start_date
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE customer_id IN (
	1, 2, 11, 13, 15, 16, 18, 19
)
ORDER BY customer_id, plan_id;
```

| customer_id | plan_id |    plan_name    | start_date |
|:-----------:|:-------:|:---------------:|:----------:|
| 1           | 0       | trial           | 2020-08-01 |
| 1           | 1       | basic monthly   | 2020-08-08 |
| 2           | 0       | trial           | 2020-09-20 |
| 2           | 3       | pro annual      | 2020-09-27 |
| 11          | 0       | trial           | 2020-11-19 |
| 11          | 4       | churn           | 2020-11-26 |
| 13          | 0       | trial           | 2020-12-15 |
| 13          | 1       | basic monthly   | 2020-12-22 |
| 13          | 2       | pro monthly     | 2021-03-29 |
| 15          | 0       | trial           | 2020-03-17 |
| 15          | 2       | pro monthly     | 2020-03-24 |
| 15          | 4       | churn           | 2020-04-29 |
| 16          | 0       | trial           | 2020-05-31 |
| 16          | 1       | basic monthly   | 2020-06-07 |
| 16          | 3       | pro annual      | 2020-10-21 |
| 18          | 0       | trial           | 2020-07-06 |
| 18          | 2       | pro monthly     | 2020-07-13 |
| 19          | 0       | trial           | 2020-06-22 |
| 19          | 2       | pro monthly     | 2020-06-29 |
| 19          | 3       | pro annual      | 2020-08-29 |

From this table, it is clear that customers typically begin with a free trial. They then either choose a paid plan or cancel their subscription.

``` mermaid
flowchart LR
    n1["Trial"] --> n2["Paid Plan"] & n3["Cancel"]
    n2 --> n3
```
