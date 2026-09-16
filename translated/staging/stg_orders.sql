# Copyright 2026 Google. This software is provided as-is, without warranty or
# representation for any use or purpose. Your use of it is subject to your
# agreement with Google.

with source as (
    select
        safe_cast(id as int64) as id,
        safe_cast(customer_id as int64) as customer_id,
        safe_cast(order_date as date) as order_date,
        safe_cast(status as string) as status,
        safe_cast(amount as numeric) as amount,
        safe_cast(updated_at as timestamp) as updated_at
    from {{ source('raw_ecommerce', 'raw_orders') }}
),

renamed as (
    select
        source.id as order_id,
        source.customer_id as customer_id,
        source.order_date as order_date,
        substr(source.status, 1, 50) as order_status,
        round(source.amount, 2) as order_amount_usd,
        source.updated_at as last_updated_at
    from source
)

select * from renamed
