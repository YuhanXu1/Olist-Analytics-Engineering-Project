with 

source as (
    select * from {{source('olist_raw', 'raw_sellers')}}
),

cleaned as (
    select
        trim(seller_id) as seller_id,
        lpad(cast(seller_zip_code_prefix as text), 5, '0') as seller_zip_code_prefix,
        trim(seller_city) as seller_city,
        trim(seller_state) as seller_state
    from source
)

select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
from cleaned