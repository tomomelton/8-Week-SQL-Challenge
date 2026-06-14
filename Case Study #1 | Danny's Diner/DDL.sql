SET SEARCH_PATH TO dannys_diner;

CREATE TABLE members 
(
	customer_id VARCHAR PRIMARY KEY,
	join_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE menu 
(
	product_id INT PRIMARY KEY,
	product_name VARCHAR NOT NULL,
	price INT NOT NULL,
	
	CHECK (price > 0)
);

CREATE TABLE sales
(
	customer_id VARCHAR NOT NULL,
	order_date DATE DEFAULT CURRENT_DATE,
	product_id INT NOT NULL,

	FOREIGN KEY (customer_id) REFERENCES members(customer_id)
		ON UPDATE CASCADE
		ON DELETE RESTRICT
);

