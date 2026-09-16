# Copyright 2026 Google. This software is provided as-is, without warranty or
# representation for any use or purpose. Your use of it is subject to your
# agreement with Google.

with source as (
    select
        safe_cast(id as int64) as id,
        safe_cast(first_name as string) as first_name,
        safe_cast(last_name as string) as last_name,
        safe_cast(email as string) as email,
        safe_cast(created_at as timestamp) as created_at
    from {{ source('raw_ecommerce', 'raw_customers') }}
),

renamed as (
    select
        source.id as customer_id,
        substr(trim(source.first_name), 1, 100) as first_name,
        substr(trim(source.last_name), 1, 100) as last_name,
        substr(lower(source.email), 1, 255) as email_address,
        source.created_at as registered_at
    from source
)

select * from renamed
