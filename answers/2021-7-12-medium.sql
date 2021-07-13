/*
Acceptance Rate By Date
What is the overall friend acceptance rate by date? Your output should have the rate of acceptances by the date the request was sent. Order by the earliest date to latest.

Assume that each friend request starts by a user sending (i.e., user_id_sender) a friend request to another user (i.e., user_id_receiver) that's logged in the table with action = 'sent'. If the request is accepted, the table logs action = 'accepted'. If the request is not accepted, no record of action = 'accepted' is logged.
Table: fb_friend_requests

user_id_sender varchar
user_id_receiver varchar
date datetime
action varchar
*/

/*
date | acceptance rate

acceptance rate: number of requests accepted  number of requests sent on the date

example output
sender | receiver | date request sent | accepted
                                        1
                                        0

*/

WITH full_table AS
(SELECT * FROM
(SELECT r.user_id_sender, r.user_id_receiver, r.date 
FROM
fb_friend_requests r
WHERE r.action = 'sent') r
LEFT JOIN (SELECT r2.user_id_sender, r2.user_id_receiver, r2.action
FROM fb_friend_requests r2
WHERE r2.action = 'accepted') r2
ON r.user_id_sender = r2.user_id_sender
AND r.user_id_receiver = r2.user_id_receiver)

SELECT date,
    COUNT(CASE WHEN action='accepted' THEN action END)::numeric/
    COUNT(*) AS accept_rate
FROM full_table
GROUP BY date
ORDER BY date

/*
Facebook Accounts

Assuming we have accounts that were opened and closed by date in the 'fb_account_status' table, compute the percentage of accounts that were closed on January 10th, 2020 (01/10/2020)

Table: fb_account_status

acc_id int
date datetime
status varchar
*/

/*
pct: num accounts closed on 1/10/20 / num accounts on 1/10/20
*/

select 
    COUNT(CASE WHEN status='closed' THEN acc_id END)/COUNT(acc_id)::decimal * 100 AS pct
from fb_account_status
WHERE date = '2020-01-10';

/*
Spam Posts

Calculate the percentage of spam posts in all viewed posts by day. Note that the facebook_posts table stores all posts posted by users. The facebook_post_views table is an action table denoting if a user has viewed a post.

Tables: facebook_posts, facebook_post_views

facebook_posts

post_id int
poster int
post_text varchar
post_keywords varchar
post_date datetime

facebook_post_views

post_id int
viewer_id int
*/

select 
    post_date,
    COUNT(CASE WHEN post_keywords ILIKE '%spam%' THEN post_id END)/COUNT(post_id)::decimal * 100 AS pct_spam
from
(SELECT p.* 
from facebook_posts p
INNER JOIN facebook_post_views v
ON p.post_id = v.post_id) t
GROUP BY post_date
