with 

source as (
    select * from {{source('olist_raw', 'raw_order_items')}}
),

cleaned as (
    select
        trim(order_id) as order_id,
        order_item_id,
        trim(product_id) as product_id,
        trim(seller_id) as seller_id,
        cast(shipping_limit_date as timestamp) as shipping_limit_datetime,
        cast(price as numeric(12,2)) as price,
        cast(freight_value as numeric(12,2)) as freight_value
    from source
)

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_datetime,
    price,
    freight_value
from cleaned