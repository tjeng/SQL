/*
Most Active Users On Messenger
Facebook Messenger stores the number of messages between users in a table named 'fb_messages'. In this table 'user1' is the sender, 'user2' is the receiver, and 'msg_count' is the number of messages exchanged between them.
Find the top 10 most active users on Facebook Messenger by counting their total number of messages sent and received. Your solution should output usernames and the count of the total messages they sent or received

Table: fb_messages

id	int
date	datetime
user1	varchar
user2	varchar
msg_count	int

Since user1 is sending the messages and user2 is receiving the messages, to get total messages sent and received, we do a union to of user1 and user2 into a column username, groupyby username, and sum the number of messages sent and received
*/

SELECT username, SUM(msg_count) AS total_msg
FROM
(SELECT user1 AS username, msg_count
FROM fb_messages 
UNION ALL
SELECT user2 AS username, msg_count
FROM fb_messages) t
GROUP BY username
ORDER BY SUM(msg_count) DESC
LIMIT 10

SELECT username, total_msg
FROM
(SELECT username, SUM(msg_count) AS total_msg, RANK() OVER (ORDER BY SUM(msg_count) DESC) AS rnk
FROM
(SELECT user1 AS username, msg_count
FROM fb_messages 
UNION ALL
SELECT user2 AS username, msg_count
FROM fb_messages) t
GROUP BY username) t1
WHERE rnk <= 10

/*
SMS Confirmations From Users
Facebook sends SMS texts when users attempt to 2FA (2-factor authenticate) into the platform to log in. In order to successfully 2FA they must confirm they received the SMS text message. Confirmation texts are only valid on the date they were sent. Unfortunately, there was an ETL problem with the database where friend requests and invalid confirmation records were inserted into the logs, which are stored in the 'fb_sms_sends' table. These message types should not be in the table. Fortunately, the 'fb_confirmers' table contains valid confirmation records so you can use this table to identify SMS text messages that were confirmed by the user.

Calculate the percentage of confirmed SMS texts for August 4, 2020.
Tables: fb_sms_sends, fb_confirmers

fb_sms_sends

ds datetime
country varchar
carrier varchar
phone_number int
type varchar

fb_confirmers

date datetime
phone_number int
*/

-- pct confirmed: num confirmed/total num messages * 100
-- num text send that are in confirmed
-- remember this line "where friend requests and invalid confirmation records were inserted into the logs, which are stored in the 'fb_sms_sends' table. These message types should not be in the table."

WITH num AS
(SELECT *
FROM fb_sms_sends
WHERE ds = '2020-08-04'
AND type = 'message')

SELECT 
(SELECT COUNT(phone_number)
FROM num
WHERE phone_number IN 
(SELECT phone_number 
FROM fb_confirmers conf
WHERE date = '2020-08-04')) :: numeric / (SELECT COUNT(phone_number)
FROM num) * 100 AS pct

/*
SMS Confirmations by FB
Find the number of phone numbers that were sent a confirmation SMS text by carrier on August 7, 2020 (08-07-2020). Group the counts by country and create a separate column for each of the three carriers (at&t, sprint, rogers). Sort by country code in ascending order.

Table: fb_sms_sends

ds datetime
country varchar
carrier varchar
phone_number int
type varchar
*/

-- Use of CASE WHEN
-- Pay attention to filters of columns

SELECT country,
    SUM (CASE WHEN carrier = 'at&t' THEN 1 ELSE 0 END) AS atnt,
    SUM (CASE WHEN carrier = 'rogers' THEN 1 ELSE 0 END) AS rogers, 
    SUM (CASE WHEN carrier = 'sprint' THEN 1 ELSE 0 END) AS sprint
FROM fb_sms_sends
WHERE ds = '08-07-2020'
AND type = 'confirmation'
GROUP BY country
ORDER BY country;

/*
Top Engagements
We have two tables that contain search results. The 'fb_search_results' table contains the search results from a user's search. In this table the `result_id` column is a key that corresponds to the `search_id` column of the `fb_search_events` table. The `position` column refers to the position that the result was displayed to the user. The 'fb_search_events' is a table that stores whether or not the user clicked on a particular search result.

Write a query to calculate the percentage of search results, out of all the results, that were positioned in the top 3 and clicked by the user.

Tables: fb_search_results, fb_search_events

fb_search_results

query varchar
result_id int
position int
notes varchar

fb_search_events

search_id int
query varchar
has_clicked varchar
*/

/* Numerator:
 search results where has_clicked = yes and position <= 3
 Denominator:
 total search results

 Note: inner join here as question is asking about search results: searches that have results
*/

WITH full_table AS
(SELECT event.*, result.position
FROM fb_search_events event
INNER JOIN fb_search_results result
ON event.search_id = result.result_id)

SELECT
(SELECT COUNT(search_id)
FROM full_table
WHERE position <= 3
AND has_clicked = 'yes') :: numeric / 
(SELECT COUNT(search_id)
FROM full_table)
* 100 AS pct

/*
Algorithm Performance

Facebook has developed a search algorithm that will parse through user comments and present the results of the search to a user. To evaluate the performance of the algorithm, we are given a table that consists of the search result the user clicked on ('notes' column), the user's search query, and the resulting search position that was returned for the specific comment. 

The higher the position, the better, since these comments were exactly what the user was searching for. Write a query that evaluates the performance of the search algorithm against each user query. Refer to the hint section for more specifics on how to write the query.

Table: fb_search_results

query varchar
result_id int
position int
notes varchar
*/

/*
percentage search results in top 3 for each query
*/

SELECT query,
COUNT(CASE WHEN position <= 3 THEN result_id END) :: numeric/COUNT(result_id) * 100 AS pct_top_3
FROM fb_search_results
GROUP BY query