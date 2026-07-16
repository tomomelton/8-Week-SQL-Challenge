SET search_path = foodie_fi;

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