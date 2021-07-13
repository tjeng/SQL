/*
Popularity Percentage
Find the popularity percentage for each user on Facebook. The popularity percentage is defined as the total number of friends the user has divided by the total number of users on the platform, then converted into a percentage by multiplying by 100.
Output each user along with their popularity percentage. Order records in ascending order by user id.
The 'user1' and 'user2' column are pairs of friends.
Table: facebook_friends

user1 int
user2 int
*/

/* example output
user | pop_pct

pop_pct : num friends/total num users

user | num_friends
*/

WITH tb AS
(select *
from
((select u1.user1, u1.user2
from facebook_friends u1)
UNION
(select u2.user2, u2.user1
from facebook_friends u2)) t)

SELECT user1, COUNT(user2):: numeric/ (SELECT(COUNT(DISTINCT user1)) FROM tb) * 100 AS pop_pct
FROM tb
GROUP BY user1
ORDER BY user1

/*
Comments Distribution
Write a query to calculate the distribution of comments by the count of users that joined Facebook between 2018 and 2020, for the month of January 2020. 

The output should contain a count of comments and the corresponding number of users that made that number of comments in Jan-2020. For example, you'll be counting how many users made 1 comment, 2 comments, 3 comments, 4 comments, etc in Jan-2020. Your left column in the output will be the number of comments while your right column in the output will be the number of users. Sort the output from the least number of comments to highest.

To add some complexity, there might be a bug where an user post is dated before the user join date. You'll want to remove these posts from the result.
Tables: fb_users, fb_comments

fb_users

id int
name varchar
joined_at datetime
city_id int
device int

fb_comments
user_id int
body varchar
created_at datetime
*/

/*
num comments | num users
*/

WITH tb AS
(SELECT * FROM
(select * from fb_users
WHERE joined_at >= '2018-01-01' AND joined_at <= '2020-12-31') u
LEFT JOIN
(SELECT user_id, body, created_at
FROM fb_comments
WHERE created_at >= '2020-01-01' AND created_at < '2020-02-01') c
ON u.id = c.user_id
WHERE c.created_at >= u.joined_at)

SELECT num_comments, COUNT(id)
FROM
(SELECT id, COUNT(*) AS num_comments
FROM tb
GROUP BY id) t
GROUP BY num_comments
ORDER BY num_comments

/*
Users By Avg Session Time

Calculate each user's average session time. A session is defined as the time difference between a page_load and page_exit. For simplicity, assume an user has only 1 session per day and if there are multiple of the same events in that day, consider only the latest page_load and earliest page_exit. Output the user_id and their average session time.

Table: facebook_web_log

user_id int
timestamp datetime
action varchar
*/

/*
Thought process: separate timestamp into 2 columns, date and time separately

For each user and date, take maximum time for page exit and load. Now we have 1 row of page exit, 1 row of page load, per user per day.

Self-join by user id and day to get page load and page exit in the same row as 2 columns, subtract page exit by page load to get session time

Group by user id and average session time
*/

WITH tab AS 
(select user_id, CAST(timestamp AS date) AS dte, 
MAX(CAST(timestamp AS time)) AS tme, action
from facebook_web_log
WHERE action = 'page_load' OR action = 'page_exit'
GROUP BY user_id, dte, action)

SELECT user_id, AVG(session_time)
FROM
(SELECT e.user_id, e.dte, e.tme - l.tme As session_time
FROM
(SELECT user_id, dte, tme, action AS exit
FROM tab
WHERE action = 'page_exit') e
INNER JOIN
(SELECT user_id, dte, tme, action AS load
FROM tab
WHERE action = 'page_load') l
ON e.user_id = l.user_id
AND e.dte = l.dte) t
GROUP BY user_id

/*
Fans vs Opposition

Facebook is quite keen on pushing their new programming language Hack to all their offices. They ran a survey to quantify the popularity of the language and send it to their employees. To promote Hack they have decided to pair developers which love Hack with the ones who hate it so the fans can convert the opposition. Their pair criteria is to match the biggest fan with biggest opposition, second biggest fan with second biggest opposition, and so on. Write a query which returns this pairing. 
Output employee ids of paired employees and sort users with the same popularity value by id in ascending order. You can limit the number of rows to 7 so that the employees don't repeat.

Table: facebook_hack_survey

facebook_hack_survey

employee_id int
age int
gender varchar
popularity int
*/

/*
employee_id1 | popularity1 | employee_id2 | popularity2

rank by populairty in descending and ascending order as 2 separate cols

Join tables by popularity ranking, most popular paired with least popular

Order by most popular ranking ascending order, as lowest number indicates highest ranking
*/
WITH tab AS
(select *, ROW_NUMBER() OVER (ORDER BY popularity DESC, employee_id) AS most_popular, ROW_NUMBER() OVER (ORDER BY popularity, employee_id) AS least_popular
from facebook_hack_survey)

SELECT mp.employee_id, lp.employee_id
FROM tab mp
INNER JOIN tab lp
ON mp.most_popular = lp.least_popular
ORDER BY mp.most_popular
LIMIT 7