SELECT order_id,
	   order_date, 
	   category, 
	   subcategory,
	   ROUND(
	   CAST(
	   (
	   SUM(sales) OVER (
			ORDER BY order_date DESC
			RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))
		*100 as numeric)
		,0) as cumulative_percent
FROM orders
LIMIT 10;

with percent_sales as (
	SELECT order_id,
	   order_date, 
	   category, 
	   subcategory,
	   ROUND(CAST((ct.cat_total/st.sales_total)*100 as numeric),0) as cumulative_percent
	FROM cat_totals as ct NATURAL JOIN sales_totals as st
	ORDER BY order_date,
	   ROUND(CAST((ct.cat_total/st.sales_total)*100 as numeric),0)
)