{{
    config(
        materialized='incremental',
        unique_key='sales_date',
        cluster_by=['sales_date']
    )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
    {% if is_incremental() %}
        where last_updated_at >= dateadd('day', -3, (select max(sales_date) from {{ this }}))
    {% endif %}
),

daily_aggregates as (
    select
        order_date as sales_date,
        count(distinct order_id) as total_orders,
        count(distinct customer_id) as unique_customers,
        sum(case when order_status = 'COMPLETED' then order_amount_usd else 0 end) as gross_revenue_usd,
        current_timestamp() as dbt_updated_at
    from orders
    group by order_date
)

select * from daily_aggregates
