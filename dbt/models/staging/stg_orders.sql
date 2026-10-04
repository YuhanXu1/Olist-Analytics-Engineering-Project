with 

source as (
    select * from {{source('olist_raw', 'raw_orders')}}
),

cleaned as (
    select
        trim(order_id) as order_id,
        trim(customer_id) as customer_id,        
        lower(trim(order_status)) as order_status,
        cast(order_purchase_timestamp as timestamp) as order_purchase_datetime,
        cast(order_approved_at as timestamp) as order_approved_datetime,
        cast(order_delivered_carrier_date as timestamp) as order_delivered_carrier_datetime,
        cast(order_delivered_customer_date as timestamp) as order_delivered_customer_datetime,
        cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_datetime
    from source
)

select
    order_id,
    customer_id,
    order_status,
    order_purchase_datetime,
    order_approved_datetime,
    order_delivered_carrier_datetime,
    order_delivered_customer_datetime,
    order_estimated_delivery_datetime
from cleaned