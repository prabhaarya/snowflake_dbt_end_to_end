with orders as (
    select * from {{ ref('stg_orders') }}
),

aggregated as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(distinct order_id) as total_lifetime_orders,
        sum(case when order_status = 'COMPLETED' then order_amount_usd else 0 end) as total_lifetime_spend_usd
    from orders
    group by customer_id
)

select * from aggregated
