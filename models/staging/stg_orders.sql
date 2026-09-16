with source as (
    select * from {{ source('raw_ecommerce', 'raw_orders') }}
),

renamed as (
    select
        id::integer as order_id,
        customer_id::integer as customer_id,
        order_date::date as order_date,
        status::varchar(50) as order_status,
        round(amount::numeric(10, 2), 2) as order_amount_usd,
        updated_at::timestamp_ntz as last_updated_at
    from source
)

select * from renamed
