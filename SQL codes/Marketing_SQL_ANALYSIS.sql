create database StuffedToys_digital;
use StuffedToys_digital;

SELECT * FROM order_item_refunds
SELECT * FROM order_items
SELECT * FROM orders
SELECT * FROM products
SELECT * FROM website_pageviews
SELECT * FROM website_sessions


/*******************PITCH Questions***********************/

/**Q1.Quarterly orders Gsearch, Bsearch nonbrand, brand search overall, organic search, and direct type-in?**/

/*Quarterly view of orders from Gsearch nonbrand, Bsearch nonbrand*/
SELECT 
    DATEPART(YEAR, o.created_at) AS year,
    DATEPART(QUARTER, o.created_at) AS quarter,
    CONCAT(DATEPART(YEAR, o.created_at), '-', DATEPART(QUARTER, o.created_at)) AS year_quarter,
    SUM(CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN 1 ELSE 0 END) AS gsearch_nonbrand,
    SUM(CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN 1 ELSE 0 END) AS bsearch_nonbrand
FROM 
    website_sessions ws
LEFT JOIN 
    Orders o ON o.website_session_id = ws.website_session_id
WHERE 
    ws.utm_source IN ('gsearch', 'bsearch') 
    AND ws.utm_campaign = 'nonbrand'
GROUP BY 
    DATEPART(YEAR, o.created_at),
    DATEPART(QUARTER, o.created_at)
ORDER BY 
    year, 
    quarter;


/*Quarterly view of orders from brand search overall*/
SELECT 
    DATEPART(QUARTER, o.created_at) AS quarter,
    DATEPART(YEAR, o.created_at) AS year,
    COUNT(o.order_id) AS total_orders
FROM 
    website_sessions ws
LEFT JOIN 
    Orders o ON o.website_session_id = ws.website_session_id
WHERE 
    ws.utm_campaign = 'brand'
GROUP BY 
    DATEPART(QUARTER, o.created_at), 
    DATEPART(YEAR, o.created_at)
ORDER BY 
    year, 
    quarter;


-- Quarterly View of Orders Grouped by Year, Quarter, utm_source, and http_referer
SELECT
    DATEPART(YEAR, o.order_created_at) AS Year,
    DATEPART(QUARTER, o.order_created_at) AS Quarter,
    ws.utm_source,
    ws.http_referer,
    COUNT(o.order_id) AS Total_Orders
FROM
    Orders_website_session o
JOIN 
    website_sessions ws ON o.website_session_id = ws.website_session_id
WHERE ws.utm_source NOT IN ('gsearch','bsearch','socialbook')
GROUP BY
    DATEPART(YEAR, o.order_created_at),
    DATEPART(QUARTER, o.order_created_at),
    ws.utm_source,
    ws.http_referer
ORDER BY
    Year,
    Quarter,
    ws.utm_source,
    ws.http_referer;

-- Quarterly View of Orders from Direct Type-In and Organic Search
SELECT
    CONCAT(DATEPART(YEAR, o.order_created_at), '-', DATEPART(QUARTER, o.order_created_at)) AS Year_Quarter,
    SUM(CASE 
        WHEN ws.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook') 
             AND ws.http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
        THEN 1 ELSE 0 END) AS Organic,
    SUM(CASE 
        WHEN ws.utm_source NOT IN ('gsearch', 'bsearch', 'socialbook') 
             AND ws.http_referer NOT IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
        THEN 1 ELSE 0 END) AS Direct_Type_In
FROM
    Orders_website_session o
JOIN 
    website_sessions ws ON o.website_session_id = ws.website_session_id
GROUP BY
    DATEPART(YEAR, o.order_created_at),
    DATEPART(QUARTER, o.order_created_at)
ORDER BY
    Year_Quarter;



/**********************************************************************************************************/

/**Q2.monthly trends for Gsearch sessions and orders**/

SELECT
	DATEPART(YEAR, ws.created_at) AS Year,
    DATEPART(MONTH, ws.created_at) AS MONTH,
    CONCAT(DATEPART(YEAR, ws.created_at), '-', DATEPART(MONTH, ws.created_at)) AS Year_Month,
    COUNT(DISTINCT ws.website_session_id) AS Total_Sessions
FROM 
    website_sessions ws
WHERE 
    ws.utm_source = 'gsearch'
GROUP BY
    DATEPART(YEAR, ws.created_at),
    DATEPART(MONTH, ws.created_at)
ORDER BY
    Year, MONTH;

/**/
SELECT
	DATEPART(YEAR, o.created_at) AS Year,
    DATEPART(MONTH, o.created_at) AS MONTH,
	CONCAT(DATEPART(YEAR, o.created_at), '-', DATEPART(MONTH, o.created_at)) AS Year_Month,
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    SUM(o.items_purchased) AS Units_Sold,
    SUM(o.price_usd) AS Revenue_Generated
FROM 
    website_sessions ws
LEFT JOIN 
    Orders o ON o.website_session_id = ws.website_session_id
WHERE 
    ws.utm_source = 'gsearch'
GROUP BY
    DATEPART(YEAR, o.created_at),
    DATEPART(MONTH, o.created_at)
ORDER BY
    Year,
    Month;

SELECT
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    SUM(o.items_purchased) AS Units_Sold
FROM 
    Orders o
LEFT JOIN 
    website_sessions ws ON o.website_session_id = ws.website_session_id
WHERE 
    ws.utm_source = 'gsearch';



/**********************************************************************************************************/

/**Q3.monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately**/

/*Monthly Trends for Gsearch Sessions (Nonbrand vs. Brand)*/
SELECT
    DATEPART(YEAR, ws.created_at) AS Year,
    DATEPART(MONTH, ws.created_at) AS Month,
	CONCAT(DATEPART(YEAR, ws.created_at), '-', DATEPART(MONTH, ws.created_at)) AS Year_Month,
    SUM(CASE WHEN ws.utm_campaign = 'nonbrand' THEN 1 ELSE 0 END) AS Nonbrand_Sessions,
    SUM(CASE WHEN ws.utm_campaign = 'brand' THEN 1 ELSE 0 END) AS Brand_Sessions
FROM
    website_sessions ws
WHERE 
    ws.utm_source = 'gsearch'
GROUP BY
    DATEPART(YEAR, ws.created_at),
    DATEPART(MONTH, ws.created_at)
ORDER BY
    Year,
    Month;

/*Monthly Trends for Gsearch Orders (Nonbrand vs. Brand)*/
SELECT
    DATEPART(YEAR, o.created_at) AS Year,
    DATEPART(MONTH, o.created_at) AS Month,
    CONCAT(DATEPART(YEAR, o.created_at), '-', DATEPART(MONTH, o.created_at)) AS Year_Month,
    SUM(CASE WHEN ws.utm_campaign = 'nonbrand' THEN 1 ELSE 0 END) AS Nonbrand_Orders,
    SUM(CASE WHEN ws.utm_campaign = 'brand' THEN 1 ELSE 0 END) AS Brand_Orders
FROM 
    website_sessions ws
LEFT JOIN 
    Orders o ON o.website_session_id = ws.website_session_id
WHERE 
    ws.utm_source = 'gsearch'
GROUP BY
    DATEPART(YEAR, o.created_at),
    DATEPART(MONTH, o.created_at)
ORDER BY
    DATEPART(YEAR, o.created_at),
    DATEPART(MONTH, o.created_at);



/*Monthly Trends for Gsearch Revenue (Nonbrand vs. Brand)*/
SELECT
    DATEPART(YEAR, o.created_at) AS Year,
    DATEPART(MONTH, o.created_at) AS Month,
	CONCAT(DATEPART(YEAR, ws.created_at), '-', DATEPART(MONTH, ws.created_at)) AS Year_Month,
    SUM(CASE WHEN ws.utm_campaign = 'nonbrand' THEN o.price_usd ELSE 0 END) AS Nonbrand_Revenue,
    SUM(CASE WHEN ws.utm_campaign = 'brand' THEN o.price_usd ELSE 0 END) AS Brand_Revenue
FROM 
    website_sessions ws
LEFT JOIN 
    Orders o ON o.website_session_id = ws.website_session_id
WHERE 
    ws.utm_source = 'gsearch'
GROUP BY
    DATEPART(YEAR, o.created_at),
    DATEPART(MONTH, o.created_at)
ORDER BY
    Year,
    Month;

/*Monthly Trends for Gsearch Profit (Nonbrand vs. Brand)*/
SELECT
    DATEPART(YEAR, o.created_at) AS Year,
    DATEPART(MONTH, o.created_at) AS Month,
	CONCAT(DATEPART(YEAR, ws.created_at), '-', DATEPART(MONTH, ws.created_at)) AS Year_Month,
    SUM(CASE WHEN ws.utm_campaign = 'nonbrand' THEN (o.price_usd - o.cogs_usd) ELSE 0 END) AS Nonbrand_Profit,
    SUM(CASE WHEN ws.utm_campaign = 'brand' THEN (o.price_usd - o.cogs_usd) ELSE 0 END) AS Brand_Profit
FROM 
    website_sessions ws
LEFT JOIN 
    Orders o ON o.website_session_id = ws.website_session_id
WHERE 
    ws.utm_source = 'gsearch'
GROUP BY
    DATEPART(YEAR, o.created_at),
    DATEPART(MONTH, o.created_at)
ORDER BY
    Year,
    Month;

/*Monthly Trends for Gsearch Refund (Nonbrand vs. Brand)*/
SELECT
    DATEPART(YEAR, r.created_at) AS Year,
    DATEPART(MONTH, r.created_at) AS Month,
	CONCAT(DATEPART(YEAR, ws.created_at), '-', DATEPART(MONTH, ws.created_at)) AS Year_Month,
    SUM(CASE WHEN ws.utm_campaign = 'nonbrand' THEN r.refund_amount_usd ELSE 0 END) AS Nonbrand_Refund,
    SUM(CASE WHEN ws.utm_campaign = 'brand' THEN r.refund_amount_usd ELSE 0 END) AS Brand_Refund
FROM
    website_sessions ws
LEFT JOIN 
    Orders o ON o.website_session_id = ws.website_session_id
LEFT JOIN
    order_item_refunds r ON r.order_id = o.order_id
WHERE 
    ws.utm_source = 'gsearch'
GROUP BY
    DATEPART(YEAR, r.created_at),
    DATEPART(MONTH, r.created_at)
ORDER BY
    Year,
    Month;

/*Monthly Trends for Gsearch Conversion Rate (Nonbrand vs. Brand)*/
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


/**********************************************************************************************************/

/**Q4.Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type?**/

/**/

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
    SUM(CASE WHEN s.device_type = 'Mobile' THEN s.Total_Sessions ELSE 0 END) AS Mobile_Sessions,
    SUM(CASE WHEN s.device_type = 'Mobile' THEN o.Total_Orders ELSE 0 END) AS Mobile_Orders
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

/**********************************************************************************************************/

/**Q5.more pessimistic board members may be concerned about the large % of traffic from Gsearch.  
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our 
other channels**/

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


/**********************************************************************************************************/
--Q6. what are the weekly sessions data for both gsearch and bsearch from august 22nd to november 29th
SELECT
    DATEADD(WEEK, DATEDIFF(WEEK, '2012-08-22', created_at), '2012-08-22') AS week_start,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM
    website_sessions
WHERE
    created_at >= '2012-08-22'
    AND created_at < '2012-11-29'
    AND utm_campaign = 'nonbrand'
GROUP BY
    DATEADD(WEEK, DATEDIFF(WEEK, '2012-08-22', created_at), '2012-08-22')
ORDER BY
    week_start;

--Q7. what are the mobile sessions data for non-brand campaigns of gsearch and bsearch from august 22nd 
--to november 30th, including details such as utm_source, total sessions, mobile sessions, 
--and the percentage of mobile sessions?

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


/**********************************************************************************************************/

/******************************CHANNEL PORTFOLIO MANAGEMENT*********************************/

/*************Analyzing Free Channels Vs Paid***************/
WITH OrganicSearchSessions AS (
    SELECT
        DATEPART(YEAR, ws.created_at) AS Year,
        DATEPART(MONTH, ws.created_at) AS Month,
        COUNT(DISTINCT ws.website_session_id) AS OrganicSessions
    FROM
        website_sessions ws
    WHERE
        ws.utm_source NOT IN  ('gsearch', 'bsearch', 'socialbook') 
        AND ws.http_referer IS NOT NULL
        AND ws.http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com')
    GROUP BY
        DATEPART(YEAR, ws.created_at),
        DATEPART(MONTH, ws.created_at)
),
DirectTypeInSessions AS (
    SELECT
        DATEPART(YEAR, ws.created_at) AS Year,
        DATEPART(MONTH, ws.created_at) AS Month,
        COUNT(DISTINCT ws.website_session_id) AS DirectTypeInSessions
    FROM
        website_sessions ws
    WHERE
        ws.utm_source NOT IN  ('gsearch', 'bsearch', 'socialbook') 
        AND ws.http_referer NOT IN ('https://www.gsearch.com', 'https://www.bsearch.com')
    GROUP BY
        DATEPART(YEAR, ws.created_at),
        DATEPART(MONTH, ws.created_at)
),
PaidBrandSessions AS (
    SELECT
        DATEPART(YEAR, ws.created_at) AS Year,
        DATEPART(MONTH, ws.created_at) AS Month,
        COUNT(DISTINCT ws.website_session_id) AS PaidBrandSessions
    FROM
        website_sessions ws
    WHERE
        ws.utm_source IN ('gsearch', 'bsearch')
        AND ws.utm_campaign = 'brand'
    GROUP BY
        DATEPART(YEAR, ws.created_at),
        DATEPART(MONTH, ws.created_at)
),
PaidNonbrandSessions AS (
    SELECT
        DATEPART(YEAR, ws.created_at) AS Year,
        DATEPART(MONTH, ws.created_at) AS Month,
        COUNT(DISTINCT ws.website_session_id) AS PaidNonbrandSessions
    FROM
        website_sessions ws
    WHERE
        ws.utm_source IN ('gsearch', 'bsearch')
        AND ws.utm_campaign = 'nonbrand'
    GROUP BY
        DATEPART(YEAR, ws.created_at),
        DATEPART(MONTH, ws.created_at)
),
SocialbookSessions AS (
    SELECT
        DATEPART(YEAR, ws.created_at) AS Year,
        DATEPART(MONTH, ws.created_at) AS Month,
        COUNT(DISTINCT ws.website_session_id) AS SocialbookSessions
    FROM
        website_sessions ws
    WHERE
        ws.utm_source = 'socialbook'
    GROUP BY
        DATEPART(YEAR, ws.created_at),
        DATEPART(MONTH, ws.created_at)
)
SELECT
    o.Year,
    o.Month,
    o.OrganicSessions,
    d.DirectTypeInSessions,
    pb.PaidBrandSessions,
    pn.PaidNonbrandSessions,
    s.SocialbookSessions,
    (o.OrganicSessions * 100.0 / pn.PaidNonbrandSessions) AS OrganicToPaidNonbrandPercent,
    (d.DirectTypeInSessions * 100.0 / pn.PaidNonbrandSessions) AS DirectTypeInToPaidNonbrandPercent,
	(o.OrganicSessions + d.DirectTypeInSessions) AS FreeSessions,
    (o.OrganicSessions + d.DirectTypeInSessions) * 100.0 / pn.PaidNonbrandSessions AS FreeToPaidNonbrandPercent,
    (o.OrganicSessions + d.DirectTypeInSessions) * 100.0 / pb.PaidBrandSessions AS FreeToPaidBrandPercent,
    (pb.PaidBrandSessions * 100.0 / pn.PaidNonbrandSessions) AS PaidBrandToPaidNonbrandPercent,
    (s.SocialbookSessions * 100.0 / pn.PaidNonbrandSessions) AS SocialbookToPaidNonbrandPercent
FROM
    OrganicSearchSessions o
JOIN
    DirectTypeInSessions d ON o.Year = d.Year AND o.Month = d.Month
JOIN
    PaidBrandSessions pb ON o.Year = pb.Year AND o.Month = pb.Month
JOIN
    PaidNonbrandSessions pn ON o.Year = pn.Year AND o.Month = pn.Month
JOIN
    SocialbookSessions s ON o.Year = s.Year AND o.Month = s.Month
ORDER BY
    o.Year, o.Month;


/*KPIs Metrics*/
WITH OverallSessions AS (
    SELECT
        SUM(o.OrganicSessions) AS TotalOrganicSessions,
        SUM(d.DirectTypeInSessions) AS TotalDirectTypeInSessions,
        SUM(pb.PaidBrandSessions) AS TotalPaidBrandSessions,
        SUM(pn.PaidNonbrandSessions) AS TotalPaidNonbrandSessions,
        SUM(s.SocialbookSessions) AS TotalSocialbookSessions
    FROM
        (
            SELECT
                DATEPART(YEAR, ws.created_at) AS Year,
                DATEPART(MONTH, ws.created_at) AS Month,
                COUNT(DISTINCT ws.website_session_id) AS OrganicSessions
            FROM
                website_sessions ws
            WHERE
                ws.utm_source NOT IN  ('gsearch', 'bsearch', 'socialbook') 
                AND ws.http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com')
            GROUP BY
                DATEPART(YEAR, ws.created_at),
                DATEPART(MONTH, ws.created_at)
        ) o
    JOIN 
        (
            SELECT
                DATEPART(YEAR, ws.created_at) AS Year,
                DATEPART(MONTH, ws.created_at) AS Month,
                COUNT(DISTINCT ws.website_session_id) AS DirectTypeInSessions
            FROM
                website_sessions ws
            WHERE
                ws.utm_source NOT IN  ('gsearch', 'bsearch', 'socialbook') 
                AND ws.http_referer NOT IN ('https://www.gsearch.com', 'https://www.bsearch.com')
            GROUP BY
                DATEPART(YEAR, ws.created_at),
                DATEPART(MONTH, ws.created_at)
        ) d ON o.Year = d.Year AND o.Month = d.Month
    JOIN 
        (
            SELECT
                DATEPART(YEAR, ws.created_at) AS Year,
                DATEPART(MONTH, ws.created_at) AS Month,
                COUNT(DISTINCT ws.website_session_id) AS PaidBrandSessions
            FROM
                website_sessions ws
            WHERE
                ws.utm_source IN ('gsearch', 'bsearch')
                AND ws.utm_campaign = 'brand'
            GROUP BY
                DATEPART(YEAR, ws.created_at),
                DATEPART(MONTH, ws.created_at)
        ) pb ON o.Year = pb.Year AND o.Month = pb.Month
    JOIN 
        (
            SELECT
                DATEPART(YEAR, ws.created_at) AS Year,
                DATEPART(MONTH, ws.created_at) AS Month,
                COUNT(DISTINCT ws.website_session_id) AS PaidNonbrandSessions
            FROM
                website_sessions ws
            WHERE
                ws.utm_source IN ('gsearch', 'bsearch')
                AND ws.utm_campaign = 'nonbrand'
            GROUP BY
                DATEPART(YEAR, ws.created_at),
                DATEPART(MONTH, ws.created_at)
        ) pn ON o.Year = pn.Year AND o.Month = pn.Month
    JOIN 
        (
            SELECT
                DATEPART(YEAR, ws.created_at) AS Year,
                DATEPART(MONTH, ws.created_at) AS Month,
                COUNT(DISTINCT ws.website_session_id) AS SocialbookSessions
            FROM
                website_sessions ws
            WHERE
                ws.utm_source = 'socialbook'
            GROUP BY
                DATEPART(YEAR, ws.created_at),
                DATEPART(MONTH, ws.created_at)
        ) s ON o.Year = s.Year AND o.Month = s.Month
)
SELECT
    TotalOrganicSessions,
    TotalDirectTypeInSessions,
    TotalPaidBrandSessions,
    TotalPaidNonbrandSessions,
    TotalSocialbookSessions,
    (TotalOrganicSessions * 100.0 / TotalPaidNonbrandSessions) AS OrganicToPaidNonbrandPercent,
    (TotalDirectTypeInSessions * 100.0 / TotalPaidNonbrandSessions) AS DirectTypeInToPaidNonbrandPercent,
    (TotalOrganicSessions + TotalDirectTypeInSessions) AS TotalFreeSessions,
    ((TotalOrganicSessions + TotalDirectTypeInSessions) * 100.0 / TotalPaidNonbrandSessions) AS FreeToPaidNonbrandPercent,
    ((TotalOrganicSessions + TotalDirectTypeInSessions) * 100.0 / TotalPaidBrandSessions) AS FreeToPaidBrandPercent,
    (TotalPaidBrandSessions * 100.0 / TotalPaidNonbrandSessions) AS PaidBrandToPaidNonbrandPercent,
    (TotalSocialbookSessions * 100.0 / TotalPaidNonbrandSessions) AS SocialbookToPaidNonbrandPercent
FROM
    OverallSessions;


/******Analyzing Channel Portfolios*******/

--1.Traffic Channel Mix: Understanding the distribution of traffic across various channels.
WITH TrafficData AS (
    SELECT
        utm_source,
        COUNT(DISTINCT ws.website_session_id) AS sessions,
        COUNT(DISTINCT order_id) AS orders,
        SUM(price_usd) AS revenue
	FROM
		website_sessions ws
	LEFT JOIN
		Orders o ON ws.website_session_id = o.website_session_id
    GROUP BY
        utm_source
)
SELECT
    utm_source,
    sessions,
    orders,
    revenue,
    CASE 
        WHEN utm_source IN ('gsearch', 'bsearch', 'socialbook') THEN 'Paid'
        ELSE 'Free'
    END AS traffic_type
FROM
    TrafficData
ORDER BY
    traffic_type, sessions DESC;

--2.Paid vs. Free Traffic: Differentiating between paid channels (e.g., PPC, socialbook campaigns) and free channels (e.g., organic search, direct type-in).
WITH TrafficData AS (
    SELECT
        utm_source,
        COUNT(DISTINCT ws.website_session_id) AS sessions,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(o.price_usd) AS revenue
    FROM
        website_sessions ws
    LEFT JOIN
        Orders o ON ws.website_session_id = o.website_session_id
    GROUP BY
        utm_source
)
SELECT
    traffic_type,
    SUM(sessions) AS sessions,
    SUM(orders) AS orders,
    SUM(revenue) AS revenue
FROM (
    SELECT
        utm_source,
        sessions,
        orders,
        revenue,
        CASE 
            WHEN utm_source IN ('gsearch', 'bsearch', 'socialbook') THEN 'Paid'
            ELSE 'Free'
        END AS traffic_type
    FROM
        TrafficData
) AS categorized_data
GROUP BY
    traffic_type
ORDER BY
    traffic_type, sessions DESC;


--3.Mobile vs. Desktop Performance: Comparing user behavior and conversion rates between mobile and desktop users.
SELECT
    ws.device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(o.price_usd) AS revenue,
    COUNT(DISTINCT o.order_id) * 100.0 / COUNT(DISTINCT ws.website_session_id) AS conversion_rate
FROM
    website_sessions ws
LEFT JOIN
    Orders o ON ws.website_session_id = o.website_session_id
GROUP BY
    ws.device_type
ORDER BY
    sessions DESC;


--4.Time-Series Analysis: Identifying trends and seasonality in traffic and conversion rates.


/***************************Comparing Channel Characteristics***********************************/
WITH ChannelData AS (
    SELECT
        ws.utm_source,
        ws.device_type,
        COUNT(DISTINCT ws.website_session_id) AS sessions,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(o.price_usd) AS revenue,
        SUM(o.price_usd - o.cogs_usd) AS profit,
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
        COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions
    FROM
        website_sessions ws
    LEFT JOIN
        Orders o ON ws.website_session_id = o.website_session_id
   -- WHERE
       -- ws.utm_campaign = 'nonbrand'
    GROUP BY
        ws.utm_source, ws.device_type
)
SELECT
    utm_source,
    SUM(sessions) AS total_sessions,
    SUM(orders) AS total_orders,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(mobile_sessions) AS total_mobile_sessions,
    SUM(desktop_sessions) AS total_desktop_sessions,
    (SUM(mobile_sessions) * 100.0 / SUM(sessions)) AS pct_mobile_sessions,
    (SUM(desktop_sessions) * 100.0 / SUM(sessions)) AS pct_desktop_sessions,
    (SUM(orders) * 100.0 / SUM(sessions)) AS conversion_rate
FROM
    ChannelData
GROUP BY
    utm_source
ORDER BY
    total_sessions DESC;

WITH ChannelData AS (
    SELECT
        ws.utm_source,
		ws.utm_campaign,
        ws.utm_content,
        ws.device_type,
        COUNT(DISTINCT ws.website_session_id) AS sessions,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(o.price_usd) AS revenue,
        SUM(o.price_usd - o.cogs_usd) AS profit,
        COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
        COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions
    FROM
        website_sessions ws
    LEFT JOIN
        Orders o ON ws.website_session_id = o.website_session_id
  /*  WHERE
        ws.utm_campaign = 'nonbrand'  */
    GROUP BY
        ws.utm_source, ws.utm_content, ws.device_type, ws.utm_campaign
)
SELECT
    utm_source,
	utm_campaign,
    utm_content,
    SUM(sessions) AS total_sessions,
    SUM(orders) AS total_orders,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(mobile_sessions) AS total_mobile_sessions,
    SUM(desktop_sessions) AS total_desktop_sessions,
    (SUM(mobile_sessions) * 100.0 / SUM(sessions)) AS pct_mobile_sessions,
    (SUM(desktop_sessions) * 100.0 / SUM(sessions)) AS pct_desktop_sessions,
    (SUM(orders) * 100.0 / SUM(sessions)) AS conversion_rate
FROM
    ChannelData
GROUP BY
    utm_source, utm_content, utm_campaign
ORDER BY
    total_sessions DESC, utm_source, utm_content;



/**********************Cross-Channel Bid Optimization Analysis**************************/

WITH ChannelContentPerformance AS (
    SELECT
        ws.utm_source AS Channel,
        ws.utm_content AS Content,
        COUNT(DISTINCT ws.website_session_id) AS Sessions,
        COUNT(DISTINCT o.order_id) AS Orders,
        SUM(o.price_usd) AS Revenue,
        SUM(o.price_usd - o.cogs_usd) AS Profit
    FROM
        website_sessions ws
    LEFT JOIN
        Orders o ON ws.website_session_id = o.website_session_id
    WHERE
        ws.utm_source IS NOT NULL
        AND ws.utm_content IS NOT NULL
    GROUP BY
        ws.utm_source, ws.utm_content
)
SELECT
    Channel,
    Content,
    Sessions,
    Orders,
    Revenue,
    Profit,
    CASE 
        WHEN Orders > 0 THEN Revenue / Orders
        ELSE 0
    END AS AverageOrderValue,
    CASE 
        WHEN Sessions > 0 THEN Orders / Sessions
        ELSE 0
    END AS ConversionRate
FROM
    ChannelContentPerformance
ORDER BY
    Revenue DESC;

WITH ChannelContentPerformance AS (
    SELECT
        ws.utm_source AS Channel,
        ws.utm_content AS Content,
        COUNT(DISTINCT ws.website_session_id) AS Sessions,
        COUNT(DISTINCT o.order_id) AS Orders,
        SUM(o.price_usd) AS Revenue,
        SUM(o.price_usd - o.cogs_usd) AS Profit
    FROM
        website_sessions ws
    LEFT JOIN
        Orders o ON ws.website_session_id = o.website_session_id
    WHERE
        ws.utm_source IS NOT NULL
        AND ws.utm_content IS NOT NULL
    GROUP BY
        ws.utm_source, ws.utm_content
)
SELECT
    Channel,
    Content,
    Sessions,
    Orders,
    Revenue,
    Profit,
    CASE 
        WHEN Orders > 0 THEN Revenue / Orders
        ELSE 0
    END AS AverageOrderValue,
    CASE 
        WHEN Sessions > 0 THEN CAST(Orders AS FLOAT) / CAST(Sessions AS FLOAT)
        ELSE 0
    END AS ConversionRate
FROM
    ChannelContentPerformance
ORDER BY
    Revenue DESC;


