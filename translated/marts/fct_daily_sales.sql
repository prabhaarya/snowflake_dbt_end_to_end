# Copyright 2026 Google. This software is provided as-is, without warranty or
# representation for any use or purpose. Your use of it is subject to your
# agreement with Google.

{{ config(
    materialized='incremental',
    unique_key='sales_date',
    cluster_by=['sales_date']
) }}

with orders as (
    select
        safe_cast(order_id as int64) as order_id,
        safe_cast(customer_id as int64) as customer_id,
        safe_cast(order_date as date) as order_date,
        safe_cast(order_status as string) as order_status,
        safe_cast(order_amount_usd as numeric) as order_amount_usd,
        safe_cast(last_updated_at as timestamp) as last_updated_at
    from {{ ref('stg_orders') }}
    {% if is_incremental() %}
    where last_updated_at >= timestamp_sub(cast((select max(sales_date) from {{ this }}) as timestamp), interval 3 day)
    {% endif %}
),

daily_aggregates as (
    select
        order_date as sales_date,
        count(distinct order_id) as total_orders,
        count(distinct customer_id) as unique_customers,
        sum(case
            when order_status = 'COMPLETED' then order_amount_usd
            else 0
        end) as gross_revenue_usd,
        current_timestamp() as dbt_updated_at
    from orders
    group by order_date
)

select * from daily_aggregates
