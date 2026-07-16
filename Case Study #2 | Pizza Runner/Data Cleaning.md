# Case Study #2 | Pizza Runner
## Data Cleaning

### Removing 'null's
The first thing I noticed was that many of the NULL values in customer and runner orders aren't actually NULL. Instead, they are stored as the string 'null'.
To fix this, I simply replaced these values with actual NULL values.

```SQL
-- Remove any 'null's from customer and runner orders
UPDATE customer_orders
SET extras = NULL
WHERE extras = 'null';

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = 'null';

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null';

UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null';
```

### Removing Empty Strings
As well as 'null's, I also noticed that empty strings were being used instead of NULL. I remedied this in the same way I fixed the first issue.

```SQL
-- Remove any ''s from customer and runner orders
UPDATE customer_orders
SET extras = NULL
WHERE extras = '';

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = '';

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = '';

UPDATE runner_orders
SET distance = NULL
WHERE distance = '';

UPDATE runner_orders
SET duration = NULL
WHERE duration = '';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '';
```
