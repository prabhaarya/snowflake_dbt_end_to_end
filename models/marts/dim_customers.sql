{{
    config(
        materialized='table',
        cluster_by=['customer_id']
    )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select * from {{ ref('int_customer_orders_summary') }}
),

final as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email_address,
        c.registered_at,
        coalesce(co.first_order_date, null) as first_order_date,
        coalesce(co.most_recent_order_date, null) as most_recent_order_date,
        coalesce(co.total_lifetime_orders, 0) as total_lifetime_orders,
        coalesce(co.total_lifetime_spend_usd, 0.00) as total_lifetime_spend_usd,
        case
            when co.total_lifetime_orders > 0 then true
            else false
        end as is_active_buyer
    from customers c
    left join customer_orders co
        on c.customer_id = co.customer_id
)

select * from final
