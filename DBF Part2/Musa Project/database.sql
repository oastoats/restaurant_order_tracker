CREATE TABLE restaurants (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
 id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('customer', 'staff')),
  restaurant_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE SET NULL
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL,
  staff_id INT NOT NULL,
  restaurant_id INT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'ready', 'collected')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  rating SMALLINT NULL CHECK (rating IN (0, 1)),

  FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (staff_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);
CREATE VIEW restaurant_avg_rating AS
SELECT r.id, r.name, AVG(o.rating) as avg_rating
FROM restaurants r
JOIN orders o ON r.id = o.restaurant_id
WHERE o.rating IS NOT NULL
GROUP BY r.id;

CREATE VIEW restaurant_rating_summary AS
SELECT 
  r.id,
  r.name,
  COUNT(o.id) as total_ratings,
  CONCAT(ROUND(AVG(o.rating) * 100), '% thumbs up') as rating_summary
FROM restaurants r
JOIN orders o ON r.id = o.restaurant_id
WHERE o.rating IS NOT NULL
GROUP BY r.id, r.name;

CREATE VIEW staff_avg_rating AS
SELECT 
  s.id as staff_id,
  s.username,
  COUNT(o.id) as total_rated_orders,
  AVG(o.rating) * 100 as avg_percentage,
  CONCAT(ROUND(AVG(o.rating) * 100),'%') as avg_display
FROM users s
JOIN orders o ON s.id = o.staff_id
WHERE o.rating IS NOT NULL
GROUP BY s.id, s.username;


CREATE OR REPLACE FUNCTION check_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rating IS NOT NULL AND  (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != 'collected')) THEN
    RAISE EXCEPTION 'Can only rate collected orders';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rating_trigger
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION check_rating();

INSERT INTO restaurants (name) VALUES 
('Pizza Hut'),
('KFC'),
('McDonalds'),
('Burger King'),
('Nando''s');

INSERT INTO users (username, password, role, restaurant_id) VALUES 
('john_staff', 'password123', 'staff', 1),
('jane_staff', 'password123', 'staff', 2),
('mike_staff', 'password123', 'staff', 3),   
('buhle_staff', 'password123', 'staff', 4),   
('jason_staff', 'password123', 'staff', 5);
INSERT INTO users (username, password, role, restaurant_id) VALUES    
('lisa_cust', 'lis@123', 'customer', NULL),
('alice_cust', '@lice123', 'customer', NULL),
('bob_cust', '6o6123', 'customer', NULL), 
('tom_cust', 't0m123', 'customer', NULL),
('amanda_cust', '@manda123', 'customer', NULL),
('oats_cust', 'o@ts123', 'customer', NULL);

INSERT INTO orders (customer_id, staff_id, restaurant_id, status, rating) VALUES 
(6, 1, 1, 'collected', 1),   
(6, 1, 4, 'collected', 0),   
(6, 1, 1, 'pending', NULL),
(7, 2, 2, 'collected', 1),     
(7, 2, 5, 'pending', NULL),   

(8, 3, 3, 'ready', NULL),   
(9, 2, 5, 'pending', NULL),  
(10, 4, 4, 'collected', 1),
(10, 5, 5, 'ready', NULL),
(11, 1, 3, 'ready', NULL);    

SELECT 
  o.id AS order_id,
  u.username AS customer_name,
  r.name AS restaurant,
  o.status,
  o.created_at,
  CASE 
    WHEN o.rating = 1 THEN '👍' 
    WHEN o.rating = 0 THEN '👎' 
    ELSE 'Not rated' 
  END AS rating
FROM orders o
JOIN users u ON o.customer_id = u.id
JOIN restaurants r ON o.restaurant_id = r.id
ORDER BY o.id; 

SELECT o.id, r.name, o.status, 
       CASE WHEN o.rating = 1 THEN '👍' WHEN o.rating = 0 THEN '👎' ELSE 'Not rated' END as rating
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
WHERE o.customer_id = 6;

SELECT o.id, r.name, o.status, 
       CASE WHEN o.rating = 1 THEN '👍' WHEN o.rating = 0 THEN '👎' ELSE 'Not rated' END as rating
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
WHERE o.customer_id = 7;

SELECT o.id, r.name, o.status, 
       CASE WHEN o.rating = 1 THEN '👍' WHEN o.rating = 0 THEN '👎' ELSE 'Not rated' END as rating
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
WHERE o.customer_id = 10;

SELECT o.id, u.username as customer, o.status, o.created_at
FROM orders o
JOIN users u ON o.customer_id = u.id
WHERE o.restaurant_id = 1 AND o.status = 'pending';

SELECT o.id, u.username as customer, o.status, o.created_at
FROM orders o
JOIN users u ON o.customer_id = u.id
WHERE o.restaurant_id = 5 AND o.status = 'pending';

SELECT o.id, u.username as customer, o.status, o.created_at
FROM orders o
JOIN users u ON o.customer_id = u.id
WHERE o.restaurant_id = 2;

SELECT o.id, u.username as customer, o.status, o.created_at
FROM orders o
JOIN users u ON o.customer_id = u.id
WHERE o.restaurant_id = 5;

SELECT o.id, u.username as customer, o.status, o.created_at
FROM orders o
JOIN users u ON o.customer_id = u.id
WHERE o.restaurant_id = 1;

SELECT o.id, u.username as customer, o.status, o.created_at
FROM orders o
JOIN users u ON o.customer_id = u.id
WHERE o.restaurant_id = 4;

SELECT o.id, u.username as customer, o.status, o.created_at
FROM orders o
JOIN users u ON o.customer_id = u.id
WHERE o.restaurant_id = 3;

UPDATE orders SET status = 'ready' WHERE id = 3;
SELECT id, status FROM orders WHERE id = 3;

UPDATE orders SET status = 'ready' WHERE id = 5;
SELECT id, status FROM orders WHERE id = 5;

UPDATE orders SET status = 'ready' WHERE id = 7;
SELECT id, status FROM orders WHERE id = 7;

UPDATE orders SET status = 'collected', rating = 1 WHERE id = 3;
SELECT id, status, rating FROM orders WHERE id = 3;

UPDATE orders SET status = 'collected', rating =0  WHERE id = 5;
SELECT id, status, rating FROM orders WHERE id = 5;

UPDATE orders SET status = 'collected', rating = 1 WHERE id = 7;
SELECT id, status, rating FROM orders WHERE id = 7;

SELECT * FROM restaurant_avg_rating;
SELECT * FROM restaurant_rating_summary;

SELECT AVG(rating) as avg_rating
FROM orders
WHERE staff_id = 1 AND rating IS NOT NULL;

SELECT AVG(rating) as avg_rating
FROM orders
WHERE staff_id = 2 AND rating IS NOT NULL;
SELECT AVG(rating) as avg_rating
FROM orders
WHERE staff_id = 3 AND rating IS NOT NULL;

SELECT AVG(rating) as avg_rating
FROM orders
WHERE staff_id = 4 AND rating IS NOT NULL;

SELECT r.name, CONCAT(ROUND(AVG(o.rating) * 100), '% thumbs up') as avg_rating
FROM restaurants r
JOIN orders o ON r.id = o.restaurant_id
WHERE o.rating IS NOT NULL
GROUP BY r.name;

SELECT 
  o.id,
  u.username AS customer,
  r.name AS restaurant,
  o.status,
  to_char(o.created_at, 'YYYY-MM-DD HH24:MI') AS order_time,
  CASE 
    WHEN o.rating = 1 THEN '👍 Thumbs Up'
    WHEN o.rating = 0 THEN '👎 Thumbs Down'
    ELSE ' Not Rated Yet'
  END AS rating_status
FROM orders o
JOIN users u ON o.customer_id = u.id
JOIN restaurants r ON o.restaurant_id = r.id
ORDER BY o.created_at DESC;
