/*
https://www.interviewquery.com/questions/subscription-retention

subscriptions table

column	type
user_id	integer
start_date	datetime
end_date	datetime
plan_id	string
Given a table of subscriptions, write a query to get the rolling month-to-month retention for each plan_id for the three months after sign-up.

Note: End date field is NULL if the user has not canceled.

Example Output:

start_month	num_month	plan_id	retained
2020-01-01	1	plan1	0.90
2020-01-01	2	plan1	0.85
2020-01-01	3	plan1	0.74
2020-02-01	1	plan2	0.70
2020-02-01	2	plan2	0.65
2020-02-01	3	plan2	0.50
*/
/* retained: number of people who have not canceled/total number of sign ups

-- For each plan, get earliest start date, do a self-join by plan-id for start dates within 3 months
*/

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

-- Calculate retention, if  cumulative monthly retention
SELECT 
start_month, num_month, plan_id,
SUM(num_retain) OVER (PARTITION BY start_month, plan_id ORDER BY num_month)/SUM(num_users) OVER (PARTITION BY start_month, plan_id ORDER BY num_month) AS retained
FROM
(SELECT
    start_month, plan_id, num_month
    SUM(CASE WHEN end_date > DATEADD(start_month, INTERVAL 90 DAY) OR end_date IS NULL THEN 1 ELSE 0) AS num_retain,
    COUNT(*) AS num_users
FROM assign_month
GROUP BY start_month, plan_id, num_month) t

/*
users table

columns	type
id	int
name	varchar
created_at	datetime
 

Given a users table, write a query to get the cumulative number of new users added by day, with the total reset every month. 

 

Example Output:

Date	Monthly Cumulative
2020-01-01	5
2020-01-02	12
...	...
2020-02-01	8
2020-02-02	17
2020-02-03	23
*/
-- count number of users per day
-- sum users, partition by month

WITH users_day AS
(SELECT created_at AS Date, COUNT(DISTINCT id) AS num_users
FROM users
GROUP BY created_at)

SELECT Date,
, SUM(num_users) OVER (PARTITION BY MONTH(Date) ORDER BY Date) AS 'Monthly Cumulative'
FROM users_day


/*
https://www.interviewquery.com/questions/comments-histogram

users table

columns	type
id	integer
name	string
created_at	datetime
neighborhood_id	integer
mail	string
comments table

columns	type
user_id	integer
body	text
created_at	datetime
Write a SQL query to create a histogram of number of comments per user in the month of January 2020. Assume bin buckets class intervals of one.

Output:

column	type
comment_count	int
frequency	int
*/

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

/*
https://www.interviewquery.com/questions/employee-salaries

employees table

columns	types
id	int
first_name	varchar
last_name	varchar
salary	int
department_id	int
 

departments table

columns	types
id	int
name	varchar
 

Given the tables above, select the top 3 departments with at least ten employees and rank them according to the percentage of th
*/

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

/*
https://www.interviewquery.com/questions/liked-pages

`friends` table

column	type
user_id	integer
friend_id	integer
 

`page_likes` table

column	type
user_id	integer
page_id	integer
 

Let's say we want to build a naive recommender. We're given two tables, one table called `friends` with a user_id and friend_id columns representing each user's friends, and another table called `page_likes` with a user_id and a page_id representing the page each user liked.

Write an SQL query to create a metric to recommend pages for each user based on recommendations from their friends liked pages. 

Note: It shouldn't recommend pages that the user already likes.

Output:

column	type
user_id	integer
page_id	integer
num_friend_likes	integer
*/

/*
Friends

User_id | friend_id
1       |  2
5       |  7

User_id | friend_id
1          2
5          7
2          1        
7          5

INNER JOIN

User_id | page_id
1       | 70
2       | 50
1       | 50


User_id |  Friend_id | Page_id 
1       | 2          |   50      
2       | 1          |   70    
2         1              50
7         5              NULL
5         7              NULL

Remove page_id where original users like


Join friend_id from friends with user_id from page likes
concatenate
Join user_id from friends with user_id from page likes 
*/
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

/*
https://www.interviewquery.com/questions/upsell-transactions

`transactions` table

column	type
id	integer
user_id	integer
created_at	datetime
product_id	integer
quantity	integer
 

We're given a table of product purchases. Each row in the table represents an individual user product purchase.

Write a query to get the number of customers that were upsold by purchasing additional products.

Note that if the customer purchased two things on the same day that does not count as an upsell as they were purchased within a similar timeframe.

Output:

column	type
num_of_upsold_customers	integer
*/

-- Each user, how many distinct dates of purchase

SELECT COUNT(*) AS num_of_upsold_customers
FROM
(SELECT user_id, COUNT(DISTINCT created_at) AS num_dates
FROM transactions
GROUP BY user_id
HAVING num_dates > 1) t

/*
https://www.interviewquery.com/questions/first-touch-attribution

`attribution` table

column	type
session_id	integer
channel	string
conversion	boolean
 

`user_sessions` table

column	type
session_id	integer
created_at	datetime
user_id	integer
 

The schema above is for a retail online shopping company consisting of two tables, attribution and user_sessions. 

The attribution table logs a session visit for each row.
If conversion is true, then the user converted to buying on that session.
The channel column represents which advertising platform the user was attributed to for that specific session.
Lastly the `user_sessions` table maps many to one session visits back to one user.
First touch attribution is defined as the channel to which the converted user was associated with when they first discovered the website.

Calculate the first touch attribution for each user_id that converted. 

Example output:

user_id	channel
123	facebook
145	google
153	facebook
172	organic
173	email
*/

/*
user_id | time | session  | channel | conversion
1         12        a         email    0
1         13        b         null     null
1         14        c         fb        1

session | channel | conversion
a          email        0
c          fb           1

-- Each user, channel for earliest session datetime where Conversion = True

*/

WITH converted_users AS
(SELECT s.user_id, s.created_at, s.session_id, a.channel
FROM user_sessions s
LEFT JOIN attribution a
ON a.session_id = s.session_id
WHERE a.conversion=1)

SELECT user_id, channel
FROM
(SELECT user_id, channel, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) AS rnk
FROM converted_users) t
WHERE rnk = 1