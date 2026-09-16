# Copyright 2026 Google. This software is provided as-is, without warranty or
# representation for any use or purpose. Your use of it is subject to your
# agreement with Google.

with orders as (
    select
        safe_cast(order_id as int64) as order_id,
        safe_cast(customer_id as int64) as customer_id,
        safe_cast(order_date as date) as order_date,
        safe_cast(order_status as string) as order_status,
        safe_cast(order_amount_usd as numeric) as order_amount_usd,
        safe_cast(last_updated_at as timestamp) as last_updated_at
    from {{ ref('stg_orders') }}
),

aggregated as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(distinct order_id) as total_lifetime_orders,
        sum(case
            when order_status = 'COMPLETED' then order_amount_usd
            else 0
        end) as total_lifetime_spend_usd
    from orders
    group by customer_id
)

select * from aggregated
