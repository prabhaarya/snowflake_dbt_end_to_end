with source as (
    select * from {{ source('raw_ecommerce', 'raw_customers') }}
),

renamed as (
    select
        id::integer as customer_id,
        trim(first_name)::varchar(100) as first_name,
        trim(last_name)::varchar(100) as last_name,
        lower(email)::varchar(255) as email_address,
        created_at::timestamp_ntz as registered_at
    from source
)

select * from renamed
