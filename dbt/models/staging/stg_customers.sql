with 

source as (
    select * from {{source('olist_raw', 'raw_customers')}}
),

cleaned as (
    select
        trim(customer_id) as customer_id,
        trim(customer_unique_id) as customer_unique_id,
        lpad(cast(customer_zip_code_prefix as text), 5, '0') as customer_zip_code_prefix,
        trim(customer_city) as customer_city,
        trim(customer_state) as customer_state
    from source
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
from cleaned