




--1. Finding Top Traffic Sources: What is the breakdown of sessions by UTM source, campaign, and referring domain up to April 12, 2012 

 

select utm_source,  

utm_campaign,  

http_referer,  

count(distinct website_session_id) as session_count 

from website_sessions 

where created_at < '2012-04-12' 

group by utm_source,  

utm_campaign,  

http_referer 

order by session_count desc 

  

--2. Traffic Conversion Rates: Calculate conversion rate (CVR) from sessions to order. If CVR is 4% >=, then increase bids to drive volume, otherwise reduce bids. (Filter sessions < 2012-04-12, utm_source = gsearch and utm_campaign = nonbrand)  

 

select  

count(distinct w.website_session_id) as sessions, 

count(distinct o.order_id) as orders, 

count(distinct o.order_id)*100.0/count(distinct w.website_session_id) as session_to_order_cvr 

from  

website_sessions as w 

left join orders as o 

on w.website_session_id=o.website_session_id 

where  

w.created_at < '2012-04-14' and 

utm_source = 'gsearch' and utm_campaign = 'nonbrand'; 



 

--3. Traffic Source Trending: After bidding down on Apr 15, 2021, what is the trend and impact on sessions for gsearch nonbrand campaign? Find weekly sessions before 2012-05-10. 

 

select  

min(cast(created_at as date)) as week_start, 

count(distinct website_session_id) as sessions 

from website_sessions 

where utm_source = 'gsearch' and 

utm_campaign ='nonbrand' and 

created_at < '2012-05-10' 

group by  

datepart(year,created_at)*100 + datepart(week,created_at)  

order by  

week_start; 

 

 

--4. Traffic Source Bid Optimization: What is the conversion rate from session to order by device type?  

 

select 

device_type, 

count(distinct w. website_session_id) as sessions, 

count(distinct o.order_id) as orders, 

count(distinct o.order_id)*100.0/count(distinct w. website_session_id) as session_to_orders_cvr 

from  

website_sessions w 

left join orders o 

on o.website_session_id=w.website_session_id	 

where  

w.created_at <'2012-05-11' 

and utm_source='gsearch' 

and utm_campaign='nonbrand' 

group by  

device_type 

order by  

orders desc; 

 
 

--5. Traffic Source Segment Trending: After bidding up on desktop channel on 2012-05-19, what is the weekly session trend for both desktop and mobile?  

 

select  

min(cast(created_at as date)) as week_start, 

count(distinct case when device_type = 'desktop' then website_session_id else null end) as desktop_sessions, 

count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_sessions 

from  

website_sessions 

where  

created_at > '2012-04-15' 

and created_at < '2012-06-09' 

and utm_source='gsearch' 

and utm_campaign='nonbrand' 

group by  

datepart(year,created_at)*100 + datepart(week,created_at)  

order by  

week_start; 

 


--6. Identifying Top Website Pages: What are the most viewed website pages ranked by session volume?  

SELECT  

  pageview_url,  

  COUNT(DISTINCT website_pageview_id) AS page_views 

FROM website_pageviews 

WHERE created_at < '2012-06-09' 

GROUP BY pageview_url 

ORDER BY page_views DESC; 

 

 

--7. Identifying Top Entry Pages: Pull a list of top entry pages? 

 

SELECT wp.pageview_url AS landing_page_url, 

    COUNT(DISTINCT lp.website_session_id) AS count 

FROM  

    (SELECT website_session_id, 

            MIN(website_pageview_id) AS landing_page -- Find the first page landed for each session 

        FROM website_pageviews 

        WHERE created_at < '2012-06-12' 

        GROUP BY website_session_id 

    ) lp 

LEFT JOIN  

    website_pageviews wp 

    ON lp.landing_page = wp.website_pageview_id 

GROUP BY wp.pageview_url 

ORDER BY landing_page_url DESC; 

 

 

--8. Calculating Bounce Rates: Pull out the bounce rates for traffic landing on home page by sessions, bounced sessions and bounce rate?  

 

SELECT  

    COUNT(DISTINCT lp.website_session_id) AS total_sessions, -- Total sessions 

    COUNT(DISTINCT bv.website_session_id) AS bounced_sessions, -- Bounced sessions (sessions with only one pageview) 

    ROUND(100.0 * COUNT(DISTINCT bv.website_session_id) / COUNT(DISTINCT lp.website_session_id), 2) AS bounce_rate -- Bounce rate as a percentage 

FROM  

    ( 

        -- Identify the first landing page for each session 

        SELECT  

            p.website_session_id, 

            MIN(p.website_pageview_id) AS first_landing_page_id -- Get the first pageview ID for each session 

        FROM website_pageviews p 

        INNER JOIN website_sessions s 

            ON p.website_session_id = s.website_session_id 

            AND s.created_at < '2012-06-14' -- Filter sessions created before the specified date 

        WHERE p.pageview_url = '/home' -- Filter for the home page 

        GROUP BY p.website_session_id 

    ) lp 

LEFT JOIN  

    ( 

        -- Count the pageviews for each session to identify bounces 

        SELECT  

            lp.website_session_id, 

            COUNT(p.website_pageview_id) AS pageviews_count -- Count the number of pageviews for each session 

        FROM  

            ( 

                -- Subquery to identify the first landing page for each session 

                SELECT  

                    p.website_session_id, 

                    MIN(p.website_pageview_id) AS first_landing_page_id -- Get the first pageview ID for each session 

                FROM website_pageviews p 

                INNER JOIN website_sessions s 

                    ON p.website_session_id = s.website_session_id 

                    AND s.created_at < '2012-06-14' -- Filter sessions created before the specified date 

                WHERE p.pageview_url = '/home' -- Filter for the home page 

                GROUP BY p.website_session_id 

            ) lp 

        INNER JOIN website_pageviews p 

            ON lp.website_session_id = p.website_session_id 

        GROUP BY lp.website_session_id 

        HAVING COUNT(p.website_pageview_id) = 1 -- Filter for sessions with only one pageview (bounced sessions) 

    ) bv 

    ON lp.website_session_id = bv.website_session_id; -- Join the two subqueries on website_session_id 

  

 
--9. Analyzing Landing Page Tests: What are the bounce rates for \lander-1 and \home in the A/B test conducted by ST for the gsearch nonbrand campaign, considering traffic received by \lander-1 and \home before <2012-07-28 to ensure a fair comparison?  

 

-- Step 1: DATE AT WHICH `/lander-1` was created and first displayed to user on the website 

SELECT  

  MIN(created_at) AS lander1_created_at, 

  MIN(website_pageview_id) AS lander1_website_pageview_id 

FROM website_pageviews 

WHERE pageview_url = '/lander-1'; 

-- Step 2: Find first landing page and filter to test time period '2012-06-19' to '2012-07-28' for gsearch and nonbrand campaign 

WITH landing_page_cte AS ( 

SELECT  

  p.website_session_id, 

  MIN(p.website_pageview_id) AS landing_page_id, 

  p.pageview_url AS landing_page 

FROM website_pageviews p 

INNER JOIN website_sessions s 

  ON p.website_session_id = s.website_session_id 

  AND s.created_at BETWEEN '2012-06-19' AND '2012-07-28' --TIME PERIOD FOR 1 MONTH SINCE THE START OF THE LANDING PAGE  

  AND utm_source = 'gsearch' 

  AND utm_campaign = 'nonbrand' 

  AND p.pageview_url IN ('/home','/lander-1')  

GROUP BY p.website_session_id, p.pageview_url 

), 

  

-- Step 3: Count page views for each session to identify bounces 

bounced_views_cte AS ( 

SELECT  

  lp.website_session_id, 

  COUNT(p.website_pageview_id) AS bounced_views 

FROM landing_page_cte lp 

LEFT JOIN website_pageviews p 

  ON lp.website_session_id = p.website_session_id -- join where session id with first landing page 

GROUP BY lp.website_session_id 

HAVING COUNT(p.website_pageview_id) = 1 -- Filter for page views = 1 view = bounced view 

) 

-- Step 4: Summarize total sessions and bounced sessions and calculate bounce rate 

SELECT  

  landing_page, 

  COUNT(DISTINCT lp.website_session_id) AS total_sessions, -- number of sessions by landing page 

  COUNT(DISTINCT b.website_session_id) AS bounced_sessions, -- number of bounced sessions by landing page 

  ROUND(100 * COUNT(DISTINCT b.website_session_id)/ 

    COUNT(DISTINCT lp.website_session_id),2) AS bounce_rate 

FROM landing_page_cte lp -- use left join to preserve all sessions with 1 page view 

LEFT JOIN bounced_views_cte b 

  ON lp.website_session_id = b.website_session_id 

GROUP BY lp.landing_page; 

 

 

--10. Landing Page Trend Analysis: What is the trend of weekly paid gsearch nonbrand campaign traffic on /home and /lander-1 pages since June 1, 2012, along with their respective bounce rates, as requested by ST? Please limit the results to the period between June 1, 2012, and August 31, 2012, based on the email received on August 31, 2021.  

 

 

WITH CampaignSessions AS ( 

    SELECT  

        wp.website_session_id, 

        wp.pageview_url AS entry_page, 

         DATEADD(WEEK, DATEDIFF(WEEK, 0, wp.created_at), 0) AS week_start_date, 

        COUNT(*) OVER (PARTITION BY wp.website_session_id) AS page_count 

    FROM  

        website_pageviews wp 

    JOIN  

        website_sessions cd 

    ON  

        wp.website_session_id = cd.website_session_id 

    WHERE  

        cd.utm_campaign =  'nonbrand' and cd.utm_source='gsearch' 

        AND wp.created_at BETWEEN '2012-06-01' AND '2012-08-31' 

), 

FilteredSessions AS ( 

    SELECT  

        website_session_id, 

        entry_page, 

        week_start_date, 

        page_count 

    FROM  

        CampaignSessions 

    WHERE  

        entry_page IN ('/home', '/lander-1') 

) 

SELECT 

    week_start_date, 

    entry_page, 

    COUNT(DISTINCT website_session_id) AS total_sessions, 

    COUNT(DISTINCT CASE WHEN page_count = 1 THEN website_session_id END) AS bounced_sessions, 

    (COUNT(DISTINCT CASE WHEN page_count = 1 THEN website_session_id END) * 100.0 /  

     COUNT(DISTINCT website_session_id)) AS bounce_rate 

FROM  

    FilteredSessions 

GROUP BY 

    week_start_date, entry_page 

ORDER BY 

    week_start_date, entry_page; 

 

 

--11. Build Conversion Funnels for gsearch nonbrand traffic from /lander-1 to /thank you page: What are the session counts and click percentages for \lander-1, product, mrfuzzy, cart, shipping, billing, and thank you pages from August 5, 2012, to September 5, 2012?  

 

 

-- Step 1: Summarize the page views for each session 

WITH summary_cte AS ( 

  SELECT 

    s.website_session_id, 

    MAX(CASE WHEN p.pageview_url = '/products' THEN 1 ELSE 0 END) AS product_views, 

    MAX(CASE WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mrfuzzy_views, 

    MAX(CASE WHEN p.pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_views, 

    MAX(CASE WHEN p.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_views, 

    MAX(CASE WHEN p.pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing_views, 

    MAX(CASE WHEN p.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankyou_views 

  FROM website_sessions s 

  LEFT JOIN website_pageviews p 

    ON s.website_session_id = p.website_session_id 

  WHERE s.created_at BETWEEN '2012-08-05' AND '2012-09-05' 

    AND s.utm_campaign = 'nonbrand' 

    AND s.utm_source = 'gsearch' 

  GROUP BY s.website_session_id 

) 

  

-- Step 2: Calculate the conversion rates 

SELECT 

  COUNT(DISTINCT website_session_id) AS sessions, -- Total sessions 

  ROUND(100.0 * SUM(product_views) / COUNT(*), 2) AS products_click_rate, -- Product views / total sessions 

  ROUND(100.0 * SUM(mrfuzzy_views) / NULLIF(SUM(product_views), 0), 2) AS mrfuzzy_click_rate, -- MrFuzzy views / product views 

  ROUND(100.0 * SUM(cart_views) / NULLIF(SUM(mrfuzzy_views), 0), 2) AS cart_click_rate, -- Cart views / MrFuzzy views 

  ROUND(100.0 * SUM(shipping_views) / NULLIF(SUM(cart_views), 0), 2) AS shipping_click_rate, -- Shipping views / cart views 

  ROUND(100.0 * SUM(billing_views) / NULLIF(SUM(shipping_views), 0), 2) AS billing_click_rate, -- Billing views / shipping views 

  ROUND(100.0 * SUM(thankyou_views) / NULLIF(SUM(billing_views), 0), 2) AS thankyou_click_rate -- Thank you views / billing views 

FROM summary_cte; 

 

 

 

--12. Analyze Conversion Funnel Tests for /billing vs. new /billing-2 pages: what is the traffic and billing to order conversion rate of both pages new/billing-2 page? 

 

WITH PageViewCounts AS ( 

    SELECT  

        pageview_url, 

        COUNT(*) AS TotalPageViews 

    FROM website_pageviews 

where pageview_url in ('/billing','/billing-2') and created_at<'2012-10-10' 

    GROUP BY pageview_url 

), 

OrderCounts AS ( 

    SELECT  

        pageview_url, 

        COUNT(*) AS TotalOrders 

    FROM Orders o join website_pageviews wp on o.website_session_id=wp.website_session_id 

where pageview_url in ('/billing','/billing-2') and wp.created_at<'2012-10-10' 

    GROUP BY pageview_url 

) 

SELECT  

    pv.pageview_url, 

    pv.TotalPageViews, 

    COALESCE(oc.TotalOrders, 0) AS TotalOrders, 

    CASE  

        WHEN pv.TotalPageViews > 0 THEN  

            CAST(COALESCE(oc.TotalOrders, 0) AS FLOAT) / pv.TotalPageViews 

        ELSE  

            0 

    END AS ConversionRate 

FROM  

    PageViewCounts pv 

LEFT JOIN  

    OrderCounts oc 

ON  

    pv.pageview_url = oc.pageview_url; 

  

 

--13. Analyzing Channel Portfolios: What are the weekly sessions data for both gsearch and bsearch from August 22nd to November 29th? 

-- Calculate the nearest Sunday after August 22nd, 2012, and adjust week_start to start on Sundays 

WITH AdjustedSessions AS ( 

    SELECT  

        created_at, 

        website_session_id, 

        utm_source, 

        utm_campaign, 

        DATEADD(DAY, (7 - DATEPART(WEEKDAY, '2012-08-22') + 1) % 7, '2012-08-22') AS first_sunday 

    FROM  

        website_sessions 

    WHERE  

        created_at >= DATEADD(DAY, (7 - DATEPART(WEEKDAY, '2012-08-22') + 1) % 7, '2012-08-22') 

) 

SELECT 

    CAST(DATEADD(WEEK, DATEDIFF(WEEK, first_sunday, created_at), first_sunday) AS DATE) AS week_start, 

    DATEDIFF(WEEK, first_sunday, created_at) + 1 AS week_no, 

    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions, 

    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions 

FROM 

    AdjustedSessions 

WHERE 

    created_at < '2012-11-29' 

    AND utm_campaign = 'nonbrand' 

GROUP BY 

    CAST(DATEADD(WEEK, DATEDIFF(WEEK, first_sunday, created_at), first_sunday) AS DATE),  

    DATEDIFF(WEEK, first_sunday, created_at) 

ORDER BY 

    week_start, week_no; 

 

 
 

--14. Comparing Channel Characteristics: What are the mobile sessions data for non-brand campaigns of gsearch and bsearch from August 22nd to November 30th, including details such as utm_source, total sessions, mobile sessions, and the percentage of mobile sessions?  

 

SELECT 

    utm_source, 

    COUNT(DISTINCT website_session_id) AS total_sessions, 

    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions, 

    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) * 100.0 / COUNT(DISTINCT website_session_id) AS pct_mobile 

FROM 

    website_sessions 

WHERE 

    utm_campaign = 'nonbrand' 

    AND created_at >= '2012-08-22' 

    AND created_at < '2012-11-30' 

GROUP BY 

    utm_source 

ORDER BY 

    utm_source; 

 

 

 

--15. Cross-Channel Bid Optimization: provide the conversion rates from sessions to orders for non-brand campaigns of gsearch and bsearch by device type, for the period spanning from August 22nd to September 18th? Additionally, include details such as device type, utm_source, total sessions, total orders, and the corresponding conversion rates.  

 

SELECT 

    ws.device_type, 

    ws.utm_source, 

    COUNT(DISTINCT ws.website_session_id) AS sessions, 

    COUNT(DISTINCT o.order_id) AS orders, 

    (COUNT(DISTINCT o.order_id) * 100.0 / COUNT(DISTINCT ws.website_session_id)) AS conversion_rate 

FROM 

    website_sessions ws 

LEFT JOIN 

    Orders o 

ON 

    ws.website_session_id = o.website_session_id 

WHERE 

    ws.created_at >= '2012-08-22' 

    AND ws.created_at <= '2012-09-18' 

    AND ws.utm_campaign = 'nonbrand' 

    AND ws.utm_source IN ('gsearch', 'bsearch') 

GROUP BY 

    ws.device_type, 

    ws.utm_source 

ORDER BY 

ws.device_type, 

    ws.utm_source; 

 

 

 

--16. Channel Portfolio Trends: Retrieve the data for gsearch and bsearch non-brand sessions segmented by device type from November 4th to December 22nd? Additionally, include details such as the start date of each week, device type, utm_source, total sessions, bsearch comparision. 

 

-- Calculate weekly sessions for gsearch and bsearch nonbrand traffic by device type 

WITH WeeklySessions AS ( 

    SELECT 

        CAST(DATEADD(WEEK, DATEDIFF(WEEK, '2012-11-04', created_at), '2012-11-04') AS DATE) AS week_start_date, 

        device_type, 

        utm_source, 

        COUNT(DISTINCT website_session_id) AS sessions 

    FROM 

        website_sessions 

    WHERE 

        created_at >= '2012-11-04' 

        AND created_at <= '2012-12-22' 

        AND utm_campaign = 'nonbrand' 

        AND utm_source IN ('gsearch', 'bsearch') 

    GROUP BY 

        DATEADD(WEEK, DATEDIFF(WEEK, '2012-11-04', created_at), '2012-11-04'), 

        device_type, 

        utm_source 

), 

-- Pivot data for easier comparison 

PivotData AS ( 

    SELECT 

        week_start_date, 

        SUM(CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN sessions ELSE 0 END) AS gsearch_desktop_session, 

        SUM(CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN sessions ELSE 0 END) AS bsearch_desktop_session, 

        SUM(CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN sessions ELSE 0 END) AS gsearch_mobile_session, 

        SUM(CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN sessions ELSE 0 END) AS bsearch_mobile_session 

    FROM 

        WeeklySessions 

    GROUP BY 

        week_start_date 

), 

-- Calculate percentages 

Comparison AS ( 

    SELECT 

        week_start_date, 

        gsearch_desktop_session, 

        bsearch_desktop_session, 

        CASE 

            WHEN gsearch_desktop_session > 0 THEN (bsearch_desktop_session * 1.0 / gsearch_desktop_session) * 100 

            ELSE NULL 

        END AS b_prec_of_g_desktop, 

        gsearch_mobile_session, 

        bsearch_mobile_session, 

        CASE 

            WHEN gsearch_mobile_session > 0 THEN (bsearch_mobile_session * 1.0 / gsearch_mobile_session) * 100 

            ELSE NULL 

        END AS b_prec_of_g_mobile 

    FROM 

        PivotData 

) 

-- Final result 

SELECT * 

FROM 

    Comparison 

ORDER BY 

    week_start_date; 

 

 

--17.Analyzing Free Channels: Could you pull organic search, direct type in and paid brand sessions by month and show those sessions as a % of paid search non brand? 

select 

datepart(year, created_at) as year, 

datepart(month, created_at) as month, 

sum(case when utm_campaign = 'nonbrand' then 1 else 0 end) as nonbrand, 

sum(case when utm_campaign = 'brand' then 1 else 0 end) as brand, 

round(cast(sum(case when utm_campaign = 'brand' then 1 else 0 end) as float) / nullif(sum(case when utm_campaign = 'nonbrand' then 1 else 0 end), 0),5) as brand_pct_of_nonbrand, 

sum(case when utm_campaign = 'direct' then 1 else 0 end) as direct, 

round(cast(sum(case when utm_campaign = 'direct' then 1 else 0 end) as float) / nullif(sum(case when utm_campaign = 'nonbrand' then 1 else 0 end), 0),5) as direct_pct_of_nonbrand, 

sum(case when utm_campaign = 'organic' then 1 else 0 end) as organic, 

round(cast(sum(case when utm_campaign = 'organic' then 1 else 0 end) as float) / nullif(sum(case when utm_campaign = 'nonbrand' then 1 else 0 end), 0),5) as organic_pct_of_nonbrand 

from  

website_sessions 

group by 

datepart(year, created_at), 

datepart(month, created_at) 

order by  

year, month 
 

 

--18. Analyzing Seasonality: Pull out sessions and orders by year, monthly and weekly for 2012? 

 
--Pull out sessions and orders by year, monthly and weekly for 2012? 

-- Monthly Sessions and Orders for 2012 
select 

datepart(year, ws.created_at) as year, 

datepart(month, ws.created_at) as month, 

count(distinct ws.website_session_id) as session_count, 

count(distinct o.order_id) as order_count, 

round(cast(count(distinct o.order_id) as float) / cast(count(distinct ws.website_session_id) as float),4) as order_rate 

from 

website_sessions ws 

left join 

orders o on ws.website_session_id = o.website_session_id 

where 

datepart(year, ws.created_at) = 2012 

group by 

datepart(year, ws.created_at), 

datepart(month, ws.created_at) 

order by 

year, month 

 
-- Weekly Sessions, Orders, and Order Rate for 2012 with Week Start Date (Date Only) 

select 

cast(dateadd(day, -datepart(weekday, ws.created_at) + 1, ws.created_at) as date) as week_start_date, 

count(distinct ws.website_session_id) as session_count, 

count(distinct o.order_id) as order_count, 

round(cast(count(distinct o.order_id) as float) / cast(count(distinct ws.website_session_id) as float),4) as order_rate 

from 

website_sessions ws 

left join 

orders o on ws.website_session_id = o.website_session_id 

where 

datepart(year, ws.created_at) = 2012 

group by 

datepart(year, ws.created_at), 

cast(dateadd(day, -datepart(weekday, ws.created_at) + 1, ws.created_at) as date) 

order by 

week_start_date 

 
 

 

--19. Analyzing Business Patterns: What is the average website session volume, categorized by hour of the day and day of the week, between September 15th and November 15th ,2013, excluding holidays to assist in determining appropriate staffing levels for live chat support on the website?  

 
-- Average website session volume categorized by hour of the day and day of the week 

select  

case  

when datepart(weekday, hour_of_day) = 2 then 'monday' 

when datepart(weekday, hour_of_day) = 3 then 'tuesday' 

when datepart(weekday, hour_of_day) = 4 then 'wednesday' 

when datepart(weekday, hour_of_day) = 5 then 'thursday' 

when datepart(weekday, hour_of_day) = 6 then 'friday' 

end as day_of_week, 

datepart(hour, hour_of_day) as hour_of_day, 

avg(session_count) as avg_session_volume 

from ( 

select 

dateadd(hour, datediff(hour, 0, ws.created_at), 0) as hour_of_day, 

count(distinct ws.website_session_id) as session_count 

from  

website_sessions ws 

where  

ws.created_at between '2013-09-15' and '2013-11-15' 

-- exclude Saturdays and Sundays 

and datepart(weekday, ws.created_at) not in (1, 7)  

-- exclude Columbus Day and Veterans Day 

and ws.created_at not in ('2013-10-14', '2013-11-11')  

group by  

dateadd(hour, datediff(hour, 0, ws.created_at), 0) 

) as hourly_sessions 

group by  

case  

when datepart(weekday, hour_of_day) = 2 then 'monday' 

when datepart(weekday, hour_of_day) = 3 then 'tuesday' 

when datepart(weekday, hour_of_day) = 4 then 'wednesday' 

when datepart(weekday, hour_of_day) = 5 then 'thursday' 

when datepart(weekday, hour_of_day) = 6 then 'friday' 

end, 

datepart(hour, hour_of_day) 

order by  

day_of_week, 

hour_of_day 

 

 


 

--20. Product Level Sales Analysis: What is monthly trends to date for number of sales , total revenue and total margin generated for business?  

--What is monthly trends to date for number of sales , total revenue and total margin generated for business? 

  

select  

datepart(year, o.created_at) as year, 

datepart(month, o.created_at) as month, 

count(distinct o.order_id) as number_of_sales, 

sum(oi.price_usd) as total_revenue, 

sum(oi.price_usd - oi.cogs_usd) as total_margin 

from  

orders o 

join  

order_items oi on o.order_id = oi.order_id 

group by  

datepart(year, o.created_at), 

datepart(month, o.created_at) 

order by  

year, month 
 


 

--21. Product Launch Sales Analysis: Could you generate trended analysis including monthly order volume, overall conversion rates, revenue per session, and a breakdown of sales by product since April 1, 2013, considering the launch of the second product on January 6th?  

 

select  

    datepart(year, ws.created_at) as year, 

    datepart(month, ws.created_at) as month, 

    sum(oi.price_usd) as total_revenue, 

    count(distinct ws.website_session_id) as session_count, 

count(distinct o.order_id) as order_count, 

cast(count(distinct o.order_id) as float) / cast(count(distinct ws.website_session_id) as float) * 100 as conversion_rate, 

    sum(oi.price_usd) / count(distinct ws.website_session_id) as revenue_per_session 

from  

    website_sessions ws 

left join  

    orders o on ws.website_session_id = o.website_session_id 

left join  

    order_items oi on o.order_id = oi.order_id 

where  

    ws.created_at >= '2013-04-01' 

group by  

    datepart(year, ws.created_at), 

    datepart(month, ws.created_at) 

order by  

    year, month 

  

  

--Breakdown of Sales by Product Since Launch of Second Product 

select  

    datepart(year, o.created_at) as year, 

    datepart(month, o.created_at) as month, 

    p.product_name, 

    sum(oi.price_usd) as total_revenue, 

    count(oi.product_id) as total_sales_volume 

from  

    orders o 

join  

    order_items oi on o.order_id = oi.order_id 

join  

    products p on oi.product_id = p.product_id 

join 

website_sessions ws on ws.website_session_id = o.website_session_id 

where  

    o.created_at >= '2013-04-01' 

group by  

    datepart(year, o.created_at), 

    datepart(month, o.created_at), 

    p.product_name 

order by  

    year, month, total_sales_volume desc 

 



 

--22. Product Pathing Analysis: What are the clickthrough rates from /products since the new product launch on January 6th 2013,by product and compare to the 3 months leading up to launch as a baseline?  

WITH imp_post AS ( 

    SELECT COUNT(website_session_id) AS impressions 

    FROM JoinedTable 

    WHERE session_time >= '2013-01-06' AND session_time < '2013-04-06' AND pageview_url = '/products' 

), 

mrfurry_post AS ( 

    SELECT COUNT(website_session_id) AS clicks_of_furry 

    FROM JoinedTable 

    WHERE session_time >= '2013-01-06' AND session_time < '2013-04-06' AND pageview_url = '/the-original-mr-fuzzy' 

), 

lovebear_post AS ( 

    SELECT COUNT(website_session_id) AS clicks_of_bear 

    FROM JoinedTable 

    WHERE session_time >= '2013-01-06' AND session_time < '2013-04-06' AND pageview_url = '/the-forever-love-bear' 

) 

-- Calculate clickthrough rates for the post-launch period 

SELECT  

    ((mrfurry_post.clicks_of_furry)*1.0 / (imp_post.impressions) * 100) AS click_rate_of_furry_post, 

    ((lovebear_post.clicks_of_bear)*1.0 / (imp_post.impressions) * 100) AS click_rate_of_bear_post 

 

FROM  

    imp_post, mrfurry_post, lovebear_post; 

 

 

 

 

--23. Product Conversion Funnels: provide a comparison of the conversion funnels from the product pages to conversion for two products since January 6th, analyzing all website traffic? 

-- Post-launch period conversion funnel 

with funnel_post AS ( 

    SELECT 

        WP.website_session_id, 

        COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN 1 ELSE NULL END) AS step1, 

        COUNT(DISTINCT CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END) AS step2, 

        COUNT(DISTINCT CASE WHEN pageview_url = '/the-forever-love-bear' THEN 1 ELSE NULL END) AS step3, 

        COUNT(DISTINCT CASE WHEN pageview_url IN ('/cart', '/shipping', '/billing', '/thank-you-for-your-order', '/billing-2') THEN 1 ELSE NULL END) AS step4 

    FROM  

        website_pageviews AS WP 

INNER JOIN website_sessions AS WS 

ON WP.website_session_id=WS.website_session_id 

  

WHERE  

        WP.created_at >= '2013-01-06' AND WP.created_at < '2013-04-06' 

    GROUP BY  

        WP.website_session_id 

) 

SELECT 

    sum(step1) AS start, 

    sum(step2) AS to_fuzzy, 

    sum(step3) AS to_bear, 

    sum(step4) AS to_checkout, 

    (100.0 * sum(step2) /sum(step1)) AS fuzzy_rate, 

    (100.0 * sum(step3) / sum(step1)) AS bear_rate, 

    (100.0 * sum(step4) / (sum(step3)+sum(step2))) AS checkout_rate 

FROM 

    funnel_post; 

 

 

 

--24. Cross-Sell Analysis: Analyze the impact of offering customers the option to add a second product on the /cart page, comparing the metrics from the month before the change to the month after? Specifically, in comparing the click-through rate (CTR) from the /cart page, average products per order, average order value (AOV), and overall revenue per /cart page view.   

WITH ProductPairs AS ( 

    SELECT  

        o1.product_id AS product1, 

        o2.product_id AS product2, 

        COUNT(*) AS pair_count 

    FROM  

        order_items o1 

    JOIN  

        order_items o2 ON o1.order_id = o2.order_id 

    WHERE  

        o1.product_id < o2.product_id 

    GROUP BY  

        o1.product_id, o2.product_id 

) 

SELECT  

    p1.product_name AS product1, 

    p2.product_name AS product2, 

    pp.pair_count 

FROM  

    ProductPairs pp 

JOIN  

    products p1 ON pp.product1 = p1.product_id 

JOIN  

    products p2 ON pp.product2 = p2.product_id 

ORDER BY  

    pp.pair_count DESC; 

 

 
 

--25. Portfolio Expansion Analysis: Conduct a pre-post analysis comparing the month before and the month after the launch of the “Birthday Bear” product on December 12th, 2013? Specifically, containing the changes in session-to-order conversion rate, average order value (AOV), products per order, and revenue per session. 

DECLARE @launch_date DATE = '2013-12-12'; 

  

-- Pre-launch period: November 12, 2013 to December 11, 2013 

-- Post-launch period: December 12, 2013 to January 11, 2014 

  

WITH PreLaunchSessions AS ( 

SELECT 

COUNT(DISTINCT ws.website_session_id) AS session_count, 

COUNT(DISTINCT o.order_id) AS order_count, 

SUM(oi.price_usd) AS total_revenue, 

COUNT(oi.order_item_id) AS total_products 

FROM 

website_sessions ws 

LEFT JOIN  

orders o ON ws.website_session_id = o.website_session_id 

LEFT JOIN  

order_items oi ON o.order_id = oi.order_id 

WHERE 

ws.created_at BETWEEN DATEADD(MONTH, -1, @launch_date) AND DATEADD(DAY, -1, @launch_date) 

),  

PostLaunchSessions AS ( 

SELECT 

COUNT(DISTINCT ws.website_session_id) AS session_count, 

COUNT(DISTINCT o.order_id) AS order_count, 

SUM(oi.price_usd) AS total_revenue, 

COUNT(oi.order_item_id) AS total_products 

FROM 

website_sessions ws 

LEFT JOIN  

orders o ON ws.website_session_id = o.website_session_id 

LEFT JOIN  

order_items oi ON o.order_id = oi.order_id 

WHERE 

ws.created_at BETWEEN @launch_date AND DATEADD(MONTH, 1, @launch_date) 

) 

SELECT  

'Pre-launch' AS period, 

pre.session_count, 

pre.order_count, 

CAST(pre.order_count AS FLOAT) / CAST(pre.session_count AS FLOAT) * 100 AS conversion_rate, 

pre.total_revenue / pre.order_count AS average_order_value, 

CAST(pre.total_products AS FLOAT) / pre.order_count AS products_per_order, 

pre.total_revenue / pre.session_count AS revenue_per_session 

FROM  

PreLaunchSessions pre 

  

UNION ALL 

  

SELECT  

'Post-launch' AS period, 

post.session_count, 

post.order_count, 

CAST(post.order_count AS FLOAT) / CAST(post.session_count AS FLOAT) * 100 AS conversion_rate, 

post.total_revenue / post.order_count AS average_order_value, 

CAST(post.total_products AS FLOAT) / post.order_count AS products_per_order, 

post.total_revenue / post.session_count AS revenue_per_session 

FROM  

PostLaunchSessions post ;

 

 
 

--26.Product Refund Rates: What is monthly product refund rates, by product and confirm quality issues are now fixed?  

 

 
 

 

 

 

 

--27. Identifying Repeat Visitors: Please pull data on how many of our website visitors come back for another session?2014 to date is good. 

 

--using the of user_id to find any repeat sessions those users had 

with sessions_w_repeats as(                     	 

select  

new_session.user_id, 

session new_session_id, 

w.website_session_id repeat_session_id 

from( 

--subquery for finding new session /first session 

 

select	

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

and created_at < '2014-11-01') 

 


--grouping repeat sessions and count of users 

select							 

repeat_sessions, 

count(distinct user_id) users 

from (                    

--how many sessions did each user have 

select		 

user_id, 

count(distinct repeat_session_id) as repeat_sessions 

from sessions_w_repeats 

group by user_id) as user_level 

group by repeat_sessions 

order by users desc; 


 

 

--28.Analyzing Repeat Behavior: What is the minimum , maximum and average time between the first and second session for customers who do come back?2014 to date is good. 

 

--using the of user_id to find any repeat sessions those users had 

 

with sessions_w_repeats as(                                

select 		 

new_session.user_id, 

new_session.session new_session_id, 

new_session.created_at new_session_date, 

w.website_session_id repeat_session_id, 

w.created_at repeat_session_date 

from( 

 

--subquery for finding new session /first session and date 

select	

user_id, 

website_session_id session, 

created_at  

from 

website_sessions 

where  

created_at >= '2014-01-01' 

and created_at < '2014-11-03' 

and is_repeat_session=0 

) as new_session 

  

left join website_sessions as w				 

on  w.user_id=new_session.user_id 

and  is_repeat_session=1) 

 --find difference between first and second sessions at a user level 

 

,users_first_to_second as(	 

select 

user_id, 

datediff(day,new_session_date,second_session_date) days 

From 

--finding the created_at times for first and second sessions 

 

(select	

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

 

--calculate avg min max for repeat customer  

select					 

avg(days) as avg_days_first_second_session, 

min(days) as min_days_first_second_session, 

max(days) as max_days_first_second_session 

from users_first_to_second; 

 

 

 

 

--29.New Vs. Repeat Channel Patterns: Analyze the channels through which repeat customers return to our website, comparing them to new sessions? Specifically, interested in understanding if repeat customers predominantly come through direct type-in or if there’s a significant portion that originates from paid search ads. This analysis should cover the period from the beginning of 2014 to the present date? 

 

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

 


 

--30.New Vs. Repeat Performance: Provide analysis on comparison of conversion rates and revenue per session for repeat sessions vs new sessions?2014 to date is good. 

 

 

 

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

 

 

 