WITH ninety_d AS (
SELECT s1.plan_id, MIN(s1.start_date) AS start_month, s2.start_date, s2.end_date
FROM subscriptions s1
INNER JOIN subscriptions s2
ON s1.plan_id = s2.plan_id
AND s2.start_date <= DATEADD(s1.min_start_date, INTERVAL 90 DAY)
),
-- Assign month
assign_month AS (
SELECT *,
    CASE WHEN 
        s2.start_date <= DATEADD(start_month, INTERVAL 30 DAY) THEN 1
        WHEN s2.start_date BETWEEN(DATEADD(start_month, INTERVAL 30 DAY), DATEADD(start_month, INTERVAL 60 DAY)) THEN 2
        ELSE 3 END AS num_month
FROM ninety_d
)

-- Calculate retention, if cumulative monthly retention
SELECT 
start_month, num_month, plan_id,
SUM(num_users) OVER (PARTITION BY start_month, plan_id ORDER BY num_month)/SUM(num_cancelled) OVER (PARTITION BY start_month, plan_id ORDER BY num_month) AS retained
FROM
(SELECT
    start_month, plan_id, num_month
    SUM(CASE WHEN end_date > DATEADD(start_month, INTERVAL 90 DAY) OR end_date IS NULL THEN 1 ELSE 0) AS num_cancelled,
    COUNT(*) AS num_users
FROM assign_month
GROUP BY start_month, plan_id, num_month) t
---------------------------------------------------
WITH users_day AS
(SELECT created_at AS Date, COUNT(DISTINCT id) AS num_users
FROM users
GROUP BY created_at)

SELECT Date,
, SUM(num_users) OVER (PARTITION BY MONTH(Date) ORDER BY Date) AS 'Monthly Cumulative'
FROM users_day
--------------------------------------------------
WITH CTE as
(SELECT u.id, c.body, c.created_at
FROM users u
LEFT JOIN comments c
ON u.id = c.user_id
WHERE DATE_FORMAT(c.created_at, '%Y %m') = '2020 01')


SELECT DISTINCT(num_comments) AS comment_count, COUNT(num_comments) AS frequency
FROM
(SELECT id, COUNT(body) AS num_comments
FROM CTE
GROUP BY id) t
GROUP BY num_comments

-----------------------------------------------------
SELECT 
    (SUM(CASE WHEN e.salary > 100000 THEN 1 ELSE 0 END)/COUNT(DISTINCT e.id)) AS percentage_over_100K,
    d.name AS department_name, COUNT(DISTINCT e.id) AS number_of_employees
FROM departments d
LEFT JOIN employees e
ON d.id = e.id
GROUP BY 2
HAVING COUNT(DISTINCT e.id) > 10
ORDER BY 3 DESC
LIMIT 3

----------------------------------------------------

WITH user_friends AS
(SELECT f.user_id, f.friend_id, p.page_id
FROM friends f
INNER JOIN page_likes p
ON p.user_id = f.friend_id
)

-- Get table of page_id a user's friends like
SELECT t.user_id, t.page_id, COUNT(DISTINCT t.friend_id) AS num_friend_likes
FROM user_friends t
LEFT JOIN page_likes pl 
ON t.user_id = pl.user_id AND t.page_id = pl.page_id
WHERE pl.user_id IS NULL
GROUP BY t.user_id, t.page_id