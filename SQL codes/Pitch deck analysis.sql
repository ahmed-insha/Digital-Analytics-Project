
--CEO deck questions
--1. First, I’d like to show our volume growth.  Can you pull overall session and order volume, trended by quarter for the life of the business? Since the most recent quarter is incomplete, you can decide how to handle it. 
--order_volume
select DATEPART(YEAR, created_at) AS Year,DATEPART(QUARTER, created_at) AS Quarter,product_id,count(order_id) as Order_Volume
from
order_items
group by product_id,DATEPART(QUARTER, created_at),year(created_at)
order by year,Quarter,product_id

--traffic_volume
select DATEPART(YEAR, created_at) AS Year,DATEPART(QUARTER, created_at) AS Quarter,device_type,count(website_session_id) as session_volume
from
website_sessions
group by device_type,DATEPART(QUARTER, created_at),year(created_at)
order by year,Quarter,device_type



--2 .Next, let’s showcase all of our efficiency improvements.  I would love to show quarterly figures since we launched, for session-to-order conversion rate, revenue per order, and revenue per session. 
select
year,quarter,no_of_sessions,no_of_purchases,round(cast(no_of_purchases as float)/no_of_sessions*1000,2) as purchase_per_1000_sessions
from
(select DATEPART(YEAR, WS.created_at) AS Year, DATEPART(QUARTER, WS.created_at) AS Quarter,count(WS.website_session_id) as no_of_sessions,count(o.website_session_id) as no_of_purchases
from
website_sessions as WS
left join orders as O on O.website_session_id = WS.website_session_id
group by DATEPART(YEAR, WS.created_at),DATEPART(QUARTER, WS.created_at)) as tbl
order by year,Quarter


select sum(price_usd)/count(*) as revenue_per_order
from
orders



--3. Next, let’s show the overall session-to-order conversion rate trends for those same channels, by quarter.  Please also make a note of any periods where we made major improvements or optimizations. 
select
year,quarter,no_of_sessions,no_of_purchases,device_type,round(cast(no_of_purchases as float)/no_of_sessions*1000,2) as purchase_per_1000_sessions
from
(select DATEPART(YEAR, WS.created_at) AS Year, DATEPART(QUARTER, WS.created_at) AS Quarter,device_type,count(WS.website_session_id) as no_of_sessions,count(o.website_session_id) as no_of_purchases
from
website_sessions as WS
left join orders as O on O.website_session_id = WS.website_session_id
group by DATEPART(YEAR, WS.created_at),DATEPART(QUARTER, WS.created_at),device_type) as tbl
order by year,Quarter



--4. We’ve come a long way since the days of selling a single product.  Let’s pull monthly trending for revenue and margin by product, along with total sales and revenue.  Note anything you notice about seasonality. 
--company performance on monthly basis 
SELECT
    DATEPART(YEAR, created_at) AS Year,
    DATEPART(MONTH, created_at) AS Month,
    product_id,
    COUNT(order_id) AS TotalSales,
    SUM(price_usd) AS TotalRevenue,
    SUM(price_usd - cogs_usd) AS TotalMargin
FROM
    order_items
GROUP BY
    DATEPART(YEAR, created_at),
    DATEPART(MONTH, created_at),
    product_id
ORDER BY
    Year,
    Month,
    product_id;




--5. We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell item).  Could you please pull sales data since then, and show how well each product cross-sells from one another?

		WITH FilteredSales AS (
    SELECT
        order_id,
        product_id,
        is_primary_item,
        created_at
    FROM
        order_items
    WHERE
        created_at >= '2014-12-05'
)
, TotalSales AS (
    SELECT
        product_id,
        COUNT(order_id) AS TotalSales
    FROM
        FilteredSales
    WHERE
        is_primary_item = 1
    GROUP BY
        product_id
)
, CrossSellPerformance AS (
    SELECT
        fs1.product_id AS PrimaryProduct,
        fs2.product_id AS CrossSellProduct,
        COUNT(DISTINCT fs1.order_id) AS CrossSellCount
    FROM
        FilteredSales fs1
    JOIN
        FilteredSales fs2
    ON
        fs1.order_id = fs2.order_id
        AND fs1.product_id <> fs2.product_id
        AND fs1.is_primary_item = 1
        AND fs2.is_primary_item = 0
    GROUP BY
        fs1.product_id,
        fs2.product_id
)
SELECT
    t.product_id AS PrimaryProduct,
    t.TotalSales,
    c.CrossSellProduct,
    c.CrossSellCount,
    round((c.CrossSellCount * 1.0 / t.TotalSales)*1000,2) AS CrossSellRatio
FROM
    TotalSales t
LEFT JOIN
    CrossSellPerformance c
ON
    t.product_id = c.PrimaryProduct
ORDER BY
    PrimaryProduct,
    CrossSellProduct;

-----------------------------------------------------------------XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX--------------------------------------------------

--Website manager deck question : 

 

--1.I’d like to tell the story of our website performance improvements over the course of the first 8 months.  

--Could you pull session to order  conversion rates, by month? 

  

WITH MonthlySessions AS ( 

    SELECT  

        YEAR(session_time) AS year, 

        MONTH(session_time) AS month, 

        COUNT(DISTINCT website_session_id) AS total_sessions 

    FROM JoinedTable 

    WHERE session_time BETWEEN '2012-03-19 08:04:16.0000000' AND '2012-09-19 08:04:16.0000000' 

    GROUP BY YEAR(session_time), MONTH(session_time) 

), 

MonthlyOrders AS ( 

    SELECT  

        YEAR(created_at) AS year, 

        MONTH(created_at) AS month, 

        COUNT(DISTINCT order_id) AS total_orders 

    FROM orders 

    WHERE created_at BETWEEN '2012-03-19 08:04:16.0000000' AND '2012-09-19 08:04:16.0000000' 

    GROUP BY YEAR(created_at), MONTH(created_at) 

) 

SELECT  

    s.year, 

    s.month, 

    s.total_sessions, 

    o.total_orders, 

    (CAST(o.total_orders AS FLOAT) / s.total_sessions) * 100 AS conversion_rate 

FROM MonthlySessions s 

LEFT JOIN MonthlyOrders o ON s.year = o.year AND s.month = o.month 

ORDER BY s.year, s.month;


--2.For the gsearch lander test, please estimate the revenue that test earned us  

--(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use nonbrand sessions and revenue since  

--then to calculate incremental value). 

--Calculate the Baseline CVR Before the Test 

  

select  * from JoinedTable  --min(session_time),max(session_time) 

  

WITH BaselineData AS ( 

    SELECT  

        COUNT(distinct website_session_id) AS total_sessions, 

        SUM(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS total_conversions 

    FROM JoinedTable 

    WHERE session_time < '2012-06-19 08:04:16.0000000' 

      AND utm_campaign = 'nonbrand' 

      AND utm_source = 'gsearch' 

) 

SELECT  

    (CAST(total_conversions AS FLOAT) / total_sessions) * 100 AS baseline_cvr 

FROM BaselineData; 

WITH LanderTestData AS ( 

    SELECT  

        sum(o.price_usd) as revenue 

    FROM JoinedTable ws left join orders o on ws.website_session_id=o.website_session_id 

    WHERE utm_source = 'gsearch' 

      AND utm_campaign = 'nonbrand' 

      AND session_time < '2012-06-19 08:04:16.0000000'  

) 

SELECT  

    revenue 

FROM LanderTestData; 

 

---deck question 3 

--3. For the landing page test you analyzed previously, 

--it would be great to show a full conversion funnel from each of the two pages to orders.      ------******step1 

--You can use the same time period you analyzed last time (Jun 19 – Jul 28).                    -----*****step2 

  

--  Identification of sessions that viewed specific pages 

WITH flagged_sessions AS ( 

  SELECT 

    s.website_session_id, 

    MAX(CASE WHEN p.pageview_url = '/home' THEN 1 ELSE 0 END) AS saw_homepage, 

    MAX(CASE WHEN p.pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS saw_custom_lander, 

    MAX(CASE WHEN p.pageview_url = '/products' THEN 1 ELSE 0 END) AS product_made_it, 

    MAX(CASE WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mrfuzzy_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankyou_page_made_it 

  FROM website_sessions s 

  LEFT JOIN website_pageviews p 

    ON s.website_session_id = p.website_session_id 

  WHERE s.utm_source = 'gsearch' 

    AND s.utm_campaign = 'nonbrand' 

    AND s.created_at BETWEEN '2012-06-19' AND '2012-07-28' 

  GROUP BY s.website_session_id 

), 

  

--  Group sessions by landing page and calculate conversion funnel metrics 

conversion_funnel AS ( 

  SELECT 

    CASE  

      WHEN saw_homepage = 1 THEN 'saw_homepage' 

      WHEN saw_custom_lander = 1 THEN 'saw_custom_lander' 

      ELSE 'check logic'  

    END AS segment, 

    COUNT(DISTINCT website_session_id) AS sessions, 

    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products, 

    COUNT(DISTINCT CASE WHEN mrfuzzy_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy, 

    COUNT(DISTINCT CASE WHEN cart_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart, 

    COUNT(DISTINCT CASE WHEN shipping_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping, 

    COUNT(DISTINCT CASE WHEN billing_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing, 

    COUNT(DISTINCT CASE WHEN thankyou_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou 

  FROM flagged_sessions 

  GROUP BY  

    CASE  

      WHEN saw_homepage = 1 THEN 'saw_homepage' 

      WHEN saw_custom_lander = 1 THEN 'saw_custom_lander' 

      ELSE 'check logic'  

    END 

) 

  

--Calculate click-through rates 

SELECT 

  segment, 

  sessions, 

  ROUND(100.0 * to_products / sessions, 2) AS product_click_rt, 

  ROUND(100.0 * to_mrfuzzy / sessions, 2) AS mrfuzzy_click_rt, 

  ROUND(100.0 * to_cart / sessions, 2) AS cart_click_rt, 

  ROUND(100.0 * to_shipping / sessions, 2) AS shipping_click_rt, 

  ROUND(100.0 * to_billing / sessions, 2) AS billing_click_rt, 

  ROUND(100.0 * to_thankyou / sessions, 2) AS thankyou_click_rt 

FROM conversion_funnel; 


--deck questioon 4 

--4. I’d love for you to quantify the impact of our billing test,-----------**********************-------------step1 

--as well. Please analyze the lift generated from the test (Sep 10 – Nov 10), -------------*************-------step2 

--in terms of revenue per billing page session, -------------------------------**********************-----------step3 

--and then pull the number of billing page sessions for the past month to understand monthly impact.-**-*--*-------step4 

 --===========>>>>>>>>>>>>>>>>>>>>--------time period 10sept to 10nov     

 ----session count and distribution respectively from page view and order tables 

  

----session count 

SELECT  

  COUNT(website_session_id) AS sessions 

FROM website_pageviews 

WHERE pageview_url IN ('/billing', '/billing-2') 

  AND created_at BETWEEN  '2012-09-10' AND '2012-11-10'; 

  

--session count distribution and revenue per billing page 

  

-- Pull out relevant fields ie. website session id, page url, order id and prices associated with the billing pages 

WITH billing_revenue AS ( 

SELECT  

  p.website_session_id,  

  p.pageview_url AS billing_version, -- Page url associated with the website session id 

  o.order_id, --  

  o.price_usd -- Billing associated with each order id. It represents the revenue 

FROM website_pageviews as p 

LEFT JOIN orders as o 

  ON p.website_session_id = o.website_session_id 

WHERE p.created_at BETWEEN '2012-09-10' AND '2012-11-10' 

  AND p.pageview_url IN ('/billing', '/billing-2')) 

  

  

SELECT billing_version, 

  COUNT(DISTINCT website_session_id) AS sessions, --  

  SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page 

FROM billing_revenue 

GROUP BY billing_version; 

  

  

  

  

  

  

--===========>>>>>>>>>>>>>>>>>>>>--------time period 10july to 10sept    pre billing test 

  

-----session count and distribution respectively from page view and order tables 

  

----session count 

SELECT  

  COUNT(website_session_id) AS sessions 

FROM website_pageviews 

WHERE pageview_url IN ('/billing', '/billing-2') 

  AND created_at BETWEEN  '2012-07-10' AND '2012-09-10'; 

  

--session count distribution and revenue per billing page 

  

-- Pull out relevant fields ie. website session id, page url, order id and prices associated with the billing pages 

WITH billing_revenue AS ( 

SELECT  

  p.website_session_id,  

  p.pageview_url AS billing_version, -- Page url associated with the website session id 

  o.order_id, --  

  o.price_usd -- Billing associated with each order id. It represents the revenue 

FROM website_pageviews as p 

LEFT JOIN orders as o 

  ON p.website_session_id = o.website_session_id 

WHERE p.created_at BETWEEN '2012-07-10' AND '2012-09-10' 

  AND p.pageview_url IN ('/billing', '/billing-2')) 

  

  

SELECT billing_version, 

  COUNT(DISTINCT website_session_id) AS sessions, --  

  SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page 

FROM billing_revenue 

GROUP BY billing_version; 

  

  

  

  

  

  

--===========>>>>>>>>>>>>>>>>>>>>--------time period (10nov to 10jan)   post billing test 

  

-----session count and distribution respectively from page view and order tables 

  

----session count 

SELECT  

  COUNT(website_session_id) AS sessions 

FROM website_pageviews 

WHERE pageview_url IN ('/billing', '/billing-2') 

  AND created_at BETWEEN  '2012-11-10' AND '2013-01-10'; 

  

--session count distribution and revenue per billing page 

  

-- Pull out relevant fields ie. website session id, page url, order id and prices associated with the billing pages 

WITH billing_revenue AS ( 

SELECT  

  p.website_session_id,  

  p.pageview_url AS billing_version, -- Page url associated with the website session id 

  o.order_id, --  

  o.price_usd -- Billing associated with each order id. It represents the revenue 

FROM website_pageviews as p 

LEFT JOIN orders as o 

  ON p.website_session_id = o.website_session_id 

WHERE p.created_at BETWEEN '2012-11-10' AND '2013-01-10' 

  AND p.pageview_url IN ('/billing', '/billing-2')) 

  

  

SELECT billing_version, 

  COUNT(DISTINCT website_session_id) AS sessions, --  

  SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page 

FROM billing_revenue 

GROUP BY billing_version; 


-----------------------------------------XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX------------------------------------------------------------------

--DECK QUESTIONS FOR MARKETING MANAGER 

--Q1. Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for Gsearch sessions and orders so that we can showcase the growth there?  

-- Combined Monthly View of Sessions and Orders from Gsearch 

SELECT 

    DATEPART(YEAR, ws.created_at) AS Year, 

    DATEPART(MONTH, ws.created_at) AS Month, 

    CONCAT(DATEPART(YEAR, ws.created_at), '-', DATEPART(MONTH, ws.created_at)) AS Year_Month, 

    COUNT(DISTINCT ws.website_session_id) AS Total_Sessions, 

    COUNT(DISTINCT o.order_id) AS Total_Orders, 

  

	 -- Conversion Rate (CVR) 

    CASE  

        WHEN COUNT(DISTINCT ws.website_session_id) = 0 THEN 0 

        ELSE 100.0 * COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id)  

    END AS CVR, 

  

    SUM(o.items_purchased) AS Units_Sold, 

    SUM(o.price_usd) AS Revenue_Generated 

  

FROM  

    website_sessions ws 

LEFT JOIN  

    Orders o ON o.website_session_id = ws.website_session_id 

WHERE  

    ws.utm_source = 'gsearch' 

GROUP BY 

    DATEPART(YEAR, ws.created_at), 

    DATEPART(MONTH, ws.created_at) 

ORDER BY 

    Year, 

    Month; 


--Q2.  Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately.  I am wondering if brand is picking up at all.  If so, this is a good story to tell.   

WITH Gsearch_Sessions AS ( 

    SELECT 

        DATEPART(YEAR, ws.created_at) AS Year, 

        DATEPART(MONTH, ws.created_at) AS Month, 

        ws.utm_campaign, 

        COUNT(ws.website_session_id) AS Total_Sessions 

    FROM 

        website_sessions ws 

    WHERE  

        ws.utm_source = 'gsearch' 

    GROUP BY 

        DATEPART(YEAR, ws.created_at), 

        DATEPART(MONTH, ws.created_at), 

        ws.utm_campaign 

), 

Gsearch_Orders AS ( 

    SELECT 

        DATEPART(YEAR, o.created_at) AS Year, 

        DATEPART(MONTH, o.created_at) AS Month, 

        ws.utm_campaign, 

        COUNT(o.order_id) AS Total_Orders 

    FROM  

		website_sessions ws 

	LEFT JOIN  

		Orders o ON o.website_session_id = ws.website_session_id 

    WHERE  

        ws.utm_source = 'gsearch' 

    GROUP BY 

        DATEPART(YEAR, o.created_at), 

        DATEPART(MONTH, o.created_at), 

        ws.utm_campaign 

) 

SELECT 

    s.Year, 

    s.Month, 

    s.utm_campaign, 

    s.Total_Sessions, 

    ISNULL(o.Total_Orders, 0) AS Total_Orders, 

    CASE  

        WHEN s.Total_Sessions > 0 THEN (CAST(o.Total_Orders AS FLOAT) / s.Total_Sessions) * 100  

        ELSE 0  

    END AS Conversion_Rate 

FROM 

    Gsearch_Sessions s 

LEFT JOIN  

    Gsearch_Orders o ON s.Year = o.Year AND s.Month = o.Month AND s.utm_campaign = o.utm_campaign 

ORDER BY 

    s.Year, 

    s.Month, 

    s.utm_campaign; 




--Q3. While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? I want to flex our analytical muscles a little and show the board we really know our traffic sources.  

WITH Gsearch_Nonbrand_Sessions AS ( 

    SELECT 

        DATEPART(YEAR, ws.created_at) AS Year, 

        DATEPART(MONTH, ws.created_at) AS Month, 

        ws.device_type, 

        COUNT(ws.website_session_id) AS Total_Sessions 

    FROM 

        website_sessions ws 

    WHERE  

        ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' 

    GROUP BY 

        DATEPART(YEAR, ws.created_at), 

        DATEPART(MONTH, ws.created_at), 

        ws.device_type 

), 

Gsearch_Nonbrand_Orders AS ( 

    SELECT 

        DATEPART(YEAR, o.created_at) AS Year, 

        DATEPART(MONTH, o.created_at) AS Month, 

        ws.device_type, 

        COUNT(o.order_id) AS Total_Orders 

    FROM  

        website_sessions ws 

    LEFT JOIN  

        Orders o ON o.website_session_id = ws.website_session_id 

    WHERE  

        ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' 

    GROUP BY 

        DATEPART(YEAR, o.created_at), 

        DATEPART(MONTH, o.created_at), 

        ws.device_type 

) 

SELECT 

    s.Year, 

    s.Month, 

    CONCAT(s.Year, '-', s.Month) AS Year_Month, 

    SUM(CASE WHEN s.device_type = 'Desktop' THEN s.Total_Sessions ELSE 0 END) AS Desktop_Sessions, 

    SUM(CASE WHEN s.device_type = 'Desktop' THEN o.Total_Orders ELSE 0 END) AS Desktop_Orders, 

	100.00*(SUM(CASE WHEN s.device_type = 'Desktop' THEN o.Total_Orders ELSE 0 END))/(SUM(CASE WHEN s.device_type = 'Desktop' THEN s.Total_Sessions ELSE 0 END)) AS Desktop_CVR, 

    SUM(CASE WHEN s.device_type = 'Mobile' THEN s.Total_Sessions ELSE 0 END) AS Mobile_Sessions, 

    SUM(CASE WHEN s.device_type = 'Mobile' THEN o.Total_Orders ELSE 0 END) AS Mobile_Orders, 

	100.00* (SUM(CASE WHEN s.device_type = 'Mobile' THEN o.Total_Orders ELSE 0 END))/(SUM(CASE WHEN s.device_type = 'Mobile' THEN s.Total_Sessions ELSE 0 END)) AS Mobile_CVR 

     

FROM 

    Gsearch_Nonbrand_Sessions s 

LEFT JOIN  

    Gsearch_Nonbrand_Orders o ON s.Year = o.Year AND s.Month = o.Month AND s.device_type = o.device_type 

GROUP BY 

    s.Year, 

    s.Month 

ORDER BY 

    s.Year, 

    s.Month; 




--Q4.  I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch.  Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?  

WITH Monthly_Sessions AS ( 

    SELECT 

        DATEPART(YEAR, ws.created_at) AS Year, 

        DATEPART(MONTH, ws.created_at) AS Month, 

        ws.utm_source, 

        ws.http_referer, 

        COUNT(ws.website_session_id) AS Total_Sessions 

    FROM 

        website_sessions ws 

    GROUP BY 

        DATEPART(YEAR, ws.created_at), 

        DATEPART(MONTH, ws.created_at), 

        ws.utm_source, 

        ws.http_referer 

), 

Monthly_Orders AS ( 

    SELECT 

        DATEPART(YEAR, o.created_at) AS Year, 

        DATEPART(MONTH, o.created_at) AS Month, 

        ws.utm_source, 

        ws.http_referer, 

        COUNT(o.order_id) AS Total_Orders 

    FROM  

		website_sessions ws 

	LEFT JOIN  

		Orders o ON o.website_session_id = ws.website_session_id 

    GROUP BY 

        DATEPART(YEAR, o.created_at), 

        DATEPART(MONTH, o.created_at), 

        ws.utm_source, 

        ws.http_referer 

) 

SELECT 

    s.Year, 

    s.Month, 

	CONCAT(s.Year, '-', s.Month) AS Year_Month, 

    SUM(CASE WHEN s.utm_source = 'gsearch' THEN s.Total_Sessions ELSE 0 END) AS gsearch_sessions, 

    SUM(CASE WHEN s.utm_source = 'bsearch' THEN s.Total_Sessions ELSE 0 END) AS bsearch_sessions, 

    SUM(CASE WHEN s.utm_source = 'socialbook' THEN s.Total_Sessions ELSE 0 END) AS socialbook_sessions, 

    SUM(CASE WHEN s.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook') AND s.http_referer NOT IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN s.Total_Sessions ELSE 0 END) AS direct_typein_sessions, 

    SUM(CASE WHEN s.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook') AND s.http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN s.Total_Sessions ELSE 0 END) AS organic_sessions, 

    SUM(CASE WHEN o.utm_source = 'gsearch' THEN o.Total_Orders ELSE 0 END) AS gsearch_orders, 

    SUM(CASE WHEN o.utm_source = 'bsearch' THEN o.Total_Orders ELSE 0 END) AS bsearch_orders, 

    SUM(CASE WHEN o.utm_source = 'socialbook' THEN o.Total_Orders ELSE 0 END) AS socialbook_orders, 

    SUM(CASE WHEN o.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook') AND o.http_referer NOT IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN o.Total_Orders ELSE 0 END) AS direct_typein_orders, 

    SUM(CASE WHEN o.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook') AND o.http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN o.Total_Orders ELSE 0 END) AS organic_orders 

FROM 

    Monthly_Sessions s 

LEFT JOIN  

    Monthly_Orders o ON s.Year = o.Year AND s.Month = o.Month AND s.utm_source = o.utm_source AND s.http_referer = o.http_referer 

GROUP BY 

    s.Year, 

    s.Month 

ORDER BY 

    s.Year, 

    s.Month; 




--Q5.  I’d like to show how we’ve grown specific channels.  Could you pull a quarterly view of orders from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?  

-- Combined Quarterly View of Orders 

SELECT 

    DATEPART(YEAR, o.created_at) AS year, 

    DATEPART(QUARTER, o.created_at) AS quarter, 

    CONCAT(DATEPART(YEAR, o.created_at), '-', DATEPART(QUARTER, o.created_at)) AS year_quarter, 

     

    -- Orders from Gsearch nonbrand 

    SUM(CASE  

        WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'  

        THEN 1 ELSE 0  

    END) AS gsearch_nonbrand, 

  

    -- Orders from Bsearch nonbrand 

    SUM(CASE  

        WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand'  

        THEN 1 ELSE 0  

    END) AS bsearch_nonbrand, 

  

    -- Orders from brand search overall 

    SUM(CASE  

        WHEN ws.utm_campaign = 'brand'  

        THEN 1 ELSE 0  

    END) AS brand_search, 

  

    -- Orders from Organic Search 

    SUM(CASE  

        WHEN ws.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook')  

             AND ws.http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com')  

        THEN 1 ELSE 0  

    END) AS organic, 

  

    -- Orders from Direct Type-In 

    SUM(CASE  

        WHEN ws.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook')  

             AND ws.http_referer NOT IN ('https://www.gsearch.com', 'https://www.bsearch.com')  

        THEN 1 ELSE 0  

    END) AS direct_type_in 

  

FROM  

    Orders o 

LEFT JOIN  

    website_sessions ws ON o.website_session_id = ws.website_session_id 

  

GROUP BY  

    DATEPART(YEAR, o.created_at), 

    DATEPART(QUARTER, o.created_at) 

  

ORDER BY  

    year,  

    quarter; 