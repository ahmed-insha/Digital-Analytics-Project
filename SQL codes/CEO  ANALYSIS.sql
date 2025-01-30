use digital_analytics

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

select *
from
website_sessions as WS
left join orders as O on O.website_session_id = WS.website_session_id

--no of sessions converted for every 1000 sessions
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


select
year,quarter,no_of_sessions,no_of_purchases,device_type,round(cast(no_of_purchases as float)/no_of_sessions*1000,2) as purchase_per_1000_sessions
from
(select DATEPART(YEAR, WS.created_at) AS Year, DATEPART(QUARTER, WS.created_at) AS Quarter,device_type,count(WS.website_session_id) as no_of_sessions,count(o.website_session_id) as no_of_purchases
from
website_sessions as WS
left join orders as O on O.website_session_id = WS.website_session_id
group by DATEPART(YEAR, WS.created_at),DATEPART(QUARTER, WS.created_at),device_type) as tbl
order by year,Quarter


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








	---kpi and analysis
SELECT COUNT(DISTINCT website_session_id) AS unique_session_count
FROM website_sessions;


select
count(distinct(website_session_id)) as website_session_distribution,
utm_source,
COUNT(DISTINCT website_session_id) * 100.0 / (select count(distinct(website_session_id))from website_sessions) AS percentage
from
website_sessions
group by utm_source
order by website_session_distribution


--Average Sessions by Day of Week
SELECT 
    DATENAME(WEEKDAY, created_at) AS day_of_week,
    COUNT(DISTINCT website_session_id) AS session_count
FROM 
    website_sessions
GROUP BY 
DATENAME(WEEKDAY, created_at),
DATEPART(WEEKDAY, created_at)
order by
DATEPART(WEEKDAY, created_at)


--Monthly Visits
SELECT 
    FORMAT(created_at, 'yyyy-MM') AS month,
    COUNT(DISTINCT website_session_id) AS visit_count
FROM 
    website_sessions
GROUP BY 
    FORMAT(created_at, 'yyyy-MM')
ORDER BY 
    month;


--Monthly Revenue (year, quarter)
SELECT 
    FORMAT(created_at, 'yyyy-qq') AS month,
    SUM(price_usd) AS total_revenue
FROM 
    orders
GROUP BY 
    FORMAT(created_at, 'yyyy-qq')
ORDER BY 
    month;








--Top Selling Products
SELECT 
p.product_name,
    SUM(o.items_purchased) AS total_sales_volume
FROM 
    orders o
JOIN 
    products p ON o.primary_product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    total_sales_volume DESC;




	-- Query to get sum of items purchased for each product within first 3 months from their launch date
SELECT 
    p.product_name,
    count(o.product_id) AS total_sales_volume
FROM 
    order_items o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.created_at BETWEEN p.created_at AND DATEADD(MONTH, 3, p.created_at)
GROUP BY 
    p.product_name
ORDER BY 
    total_sales_volume DESC;



	--refund rate by product
	SELECT 
    p.product_id,
    SUM(r.refund_amount_usd)*100 / SUM(o.price_usd) AS refund_rate
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    products p ON oi.product_id = p.product_id
LEFT JOIN 
    order_item_refunds r ON oi.order_item_id = r.order_item_id
GROUP BY 
    p.product_id
ORDER BY 
    refund_rate DESC;




	--revenue by product
	SELECT 
    p.product_id,
    round(SUM(oi.price_usd),2) AS total_revenue
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
GROUP BY 
    p.product_id
ORDER BY 
    total_revenue DESC;




--cross selling
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

