# Copyright 2026 Google. This software is provided as-is, without warranty or
# representation for any use or purpose. Your use of it is subject to your
# agreement with Google.

{{ config(
    materialized='table',
    cluster_by=['customer_id']
) }}

with customers as (
    select
        safe_cast(customer_id as int64) as customer_id,
        safe_cast(first_name as string) as first_name,
        safe_cast(last_name as string) as last_name,
        safe_cast(email_address as string) as email_address,
        safe_cast(registered_at as timestamp) as registered_at
    from {{ ref('stg_customers') }}
),

customer_orders as (
    select
        safe_cast(customer_id as int64) as customer_id,
        safe_cast(first_order_date as date) as first_order_date,
        safe_cast(most_recent_order_date as date) as most_recent_order_date,
        safe_cast(total_lifetime_orders as int64) as total_lifetime_orders,
        safe_cast(total_lifetime_spend_usd as numeric) as total_lifetime_spend_usd
    from {{ ref('int_customer_orders_summary') }}
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
    from customers as c
    left outer join customer_orders as co
        on safe_cast(c.customer_id as string) = safe_cast(co.customer_id as string)
)

select * from final
