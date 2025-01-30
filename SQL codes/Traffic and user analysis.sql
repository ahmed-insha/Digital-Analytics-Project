select top 10 * from orders;
select top 10 * from products;
select top 10 * from website_sessions;
select top 10 * from website_pageviews;
select top 10 * from order_items;
select top 10 * from order_item_refunds;


--KPI
--Gsearch session (316035)

select
	count(distinct website_session_id)
from website_sessions
where utm_source='gsearch';

--gsearch conversion rate (6.750201718164)
select
	count(distinct order_id)*100.0/count(distinct w.website_session_id) as conversion_rate
from website_sessions w
left join orders o
on o.website_session_id=w.website_session_id
where utm_source='gsearch';

--repeat session rate (16.611930103558)

select
	(select count(distinct website_session_id) from website_sessions where is_repeat_session=1)*100.0 / count(distinct website_session_id) repeat_sessoion_rate

from website_sessions;

--conversion rate (6.833364702001)
select
	count(distinct order_id)*100.0/count(distinct w.website_session_id) as conversion_rate
from website_sessions w
left join orders o
on o.website_session_id=w.website_session_id;

--total orders (32313)
select 
	count(distinct order_id) total_orders
from orders;

--total session (472871)
select  
	count(distinct website_session_id) total_session
from website_sessions;

--new user (394318)
select
	count(distinct website_session_id) new_user
from website_sessions
where is_repeat_session=0;

--repeat_user (78553)
select
	count(distinct website_session_id) new_user
from website_sessions
where is_repeat_session=1;


--RFM SEGMENTATION
-- Calculate RFM values for each customer
WITH RFM AS (
    SELECT 
        user_id,
        DATEDIFF(day, MAX(created_at), GETDATE()) AS Recency,
        COUNT(distinct order_id) AS Frequency,
        SUM([price_usd]*items_purchased) AS Monetary
    FROM Orders
    GROUP BY user_id
)
-- Assign NTILE scores for Recency, Frequency, and Monetary
,RFM_Scores AS (
    SELECT 
        user_id,
		 Monetary,
        NTILE(4) OVER (ORDER BY Recency ASC) AS Recency_Score,
        NTILE(4) OVER (ORDER BY Frequency DESC) AS Frequency_Score,
        NTILE(4) OVER (ORDER BY Monetary DESC) AS Monetary_Score
    FROM RFM
),
-- Calculate combined RFM score
Combined_RFM AS (
    SELECT 
        user_id,
		 Monetary,
        Recency_Score,
        Frequency_Score,
        Monetary_Score,
        (Recency_Score + Frequency_Score + Monetary_Score) AS Combined_RFM_Score
    FROM RFM_Scores
)
-- Segment customers based on combined RFM score
,RFM_Segments AS (
    SELECT 
        user_id,
		 Monetary,
        Recency_Score,
        Frequency_Score,
        Monetary_Score,
        Combined_RFM_Score,
        CASE 
            WHEN Combined_RFM_Score >= 10 THEN 'Premium'
            WHEN Combined_RFM_Score >= 7 THEN 'Gold'
            WHEN Combined_RFM_Score >= 4 THEN 'Silver'
            ELSE 'Standard'
        END AS RFM_Segment
    FROM Combined_RFM
)
-- Select and display the final RFM segments
SELECT 
    RFM_Segment,count(user_id) customer_count,sum(Monetary) total_revenue,sum(Monetary)/count(user_id) avg_order_value
    
FROM RFM_Segments
group by RFM_Segment
order by 3 desc;




--1. finding top traffic sources

--1. Finding Top Traffic Sources: What is the breakdown of sessions by UTM source, campaign, and referring domain up to April 12, 2012 

select 
	utm_source,
	utm_campaign,
	http_referer,
	count(distinct website_session_id) as no_of_sessions
from website_sessions
where created_at < '2012-04-12'
group by utm_source,
		utm_campaign,
		http_referer
order by no_of_sessions desc;

--2. traffic conversion rates

--2. Calculate conversion rate (CVR) from sessions to order. If CVR is 4% >=, then increase bids to drive volume, otherwise reduce bids. (Filter sessions < 2012-04-12, utm_source = gsearch and utm_campaign = nonbrand)  

select 
	count(distinct w.website_session_id) as sessions,
	count(distinct o.order_id) as orders,
	count(distinct o.order_id)*100.0/count(distinct w.website_session_id) as session_to_order_cvr
from website_sessions as w
	left join orders as o
	on w.website_session_id=o.website_session_id
where w.created_at < '2012-04-14' and
	utm_source = 'gsearch' and utm_campaign = 'nonbrand';


--3. traffic source trending

--3.Traffic Source Trending: After bidding down on Apr 15, 2021, what is the trend and impact on sessions for gsearch nonbrand campaign? Find weekly sessions before 2012-05-10. 
select 
	min(cast(created_at as date)) as week_start,
	count(distinct website_session_id) as sessions
from website_sessions
where utm_source = 'gsearch' and
	utm_campaign ='nonbrand' and
	created_at < '2012-05-10'
group by datepart(year,created_at)*100 + datepart(week,created_at) 
order by week_start;


--4. traffice source bid optimization

--4. What is the conversion rate from session to order by device type? 

select
	device_type,
	count(distinct w. website_session_id) as sessions,
	count(distinct o.order_id) as orders,
	count(distinct o.order_id)*100.0/count(distinct w. website_session_id) as session_to_orders_cvr
from website_sessions w
	left join orders o
	on o.website_session_id=w.website_session_id	
where w.created_at <'2012-05-11'
and utm_source='gsearch'
and utm_campaign='nonbrand'
group by device_type
order by orders desc;

--5. traffic source segment trending

--5. after bidding up on desktop channel on 2012-05-19, what is the weekly session trend for both desktop and mobile?

select 
	min(cast(created_at as date)) as week_start,
	count(distinct case when device_type = 'desktop' then website_session_id else null end) as desktop_sessions,
	count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_sessions
from website_sessions
where 
created_at > '2012-04-15'
and created_at < '2012-06-09'
and utm_source='gsearch'
and utm_campaign='nonbrand'
group by datepart(year,created_at)*100 + datepart(week,created_at) 
order by week_start;


--27. identifying repeat visitors

--27. please pull data on how many of our website visitors come back for another session? 2014 to date is good.

with sessions_w_repeats as(                     --using the of user_id to find any repeat sessions those users had
	select new_session.user_id,
			session new_session_id,
			w.website_session_id repeat_session_id
	from(
		select									--subquery for finding new session /first session
			user_id,
			website_session_id session
		from
			website_sessions
		where created_at >= '2014-01-01'
			and created_at < '2014-11-01'
		   	and is_repeat_session=0
		) as new_session

		left join website_sessions as w				
		on  w.user_id=new_session.user_id
		and is_repeat_session=1
		and created_at >= '2014-01-01'
		and created_at < '2014-11-01'
	)

select							--grouping repeat sessions and count of users
	repeat_sessions,
	count(distinct user_id) users
from (                   
		select					--how many sessions did each user have
			user_id,
			count(distinct repeat_session_id) as repeat_sessions
		from sessions_w_repeats
		group by user_id) as user_level
group by repeat_sessions
order by users desc;


--28. analyzing repeat behavior
--28. what is the minimum , maximum and average time between the first and second session for customers who do come back?2014 to date is good

with sessions_w_repeats as(                                --using the of user_id to find any repeat sessions those users had
	select new_session.user_id,
			new_session.session new_session_id,
			new_session.created_at new_session_date,
			w.website_session_id repeat_session_id,
			w.created_at repeat_session_date
	from(
		select									--subquery for finding new session /first session and date
			user_id,
			website_session_id session,
			created_at 
		from
			website_sessions
		where created_at >= '2014-01-01'
			and created_at < '2014-11-03'
			and is_repeat_session=0
		) as new_session

		left join website_sessions as w				
		on  w.user_id=new_session.user_id
		and  is_repeat_session=1)

,users_first_to_second as(					--find difference between first and second sessions at a user level
select
	user_id,
	datediff(day,new_session_date,second_session_date) days
from
	(select									--finding the created_at times for first and second sessions
		user_id,
		new_session_id,
		new_session_date,
		min(repeat_session_id) second_session_id,
		min(repeat_session_date) second_session_date
	
	from sessions_w_repeats
	where repeat_session_id is not null
	group by user_id,
		new_session_id,
		new_session_date) as first_second)

select					--calculate avg min max for repeat customer
	avg(days) as avg_days_first_second_session,
	min(days) as min_days_first_second_session,
	max(days) as max_days_first_second_session
from users_first_to_second;


--29. new vs. repeat channel patterns

--29. analyze the channels through which repeat customers return to our website, comparing them to new sessions? specifically, interested in understanding if repeat customers predominantly come through direct type-in or if there’s a significant portion that originates from paid search ads. this analysis should cover the period from the beginning of 2014 to the present date.

select
    case
        when utm_source = 'null' and http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com') then 'organic search'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_campaign = 'null' and http_referer = 'null' then 'direct_type_in'
        when utm_source = 'socialbook' then 'paid_social'
     
    end as channel,
    count(case when is_repeat_session = 0 then website_session_id else null end) as new_sessions,
    count(case when is_repeat_session = 1 then website_session_id else null end) as repeat_sessions
from website_sessions
where created_at >= '2014-01-01'
and created_at < '2014-11-05'
group by  case
        when utm_source = 'null' and http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com') then 'organic search'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand'
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_campaign = 'null' and http_referer = 'null' then 'direct_type_in'
        when utm_source = 'socialbook' then 'paid_social' end
order by repeat_sessions desc;


--30. new vs.  repeat performance

--30. provide analysis on comparison of conversion rates and revenue per session for repeat sessions vs new sessions?2014 to date is good


select 
	case when is_repeat_session =0 then 'New user' else 'Repeat user' end as users,
	count(distinct w.website_session_id) sessions,
	count(distinct o.order_id)*100.0/count(distinct w.website_session_id) conversion_rate,
	sum(price_usd)/count(distinct w.website_session_id) revenue_per_session
from website_sessions w

left join orders o
on o.website_session_id=w.website_session_id
where w.created_at >= '2014-01-01'
and  w.created_at < '2014-11-08'
group by case when is_repeat_session =0 then 'New user' else 'Repeat user' end ;