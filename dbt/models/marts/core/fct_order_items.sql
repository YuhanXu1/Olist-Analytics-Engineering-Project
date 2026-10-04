with

order_items as (
    select * from {{ref('stg_order_items')}}
),

orders as (
    select * from {{ref('stg_orders')}}
),

customers as (
    select * from {{ref('stg_customers')}}
),

sellers as (
    select * from {{ref('stg_sellers')}}
),

geolocation as (
    select * from {{ref('int_geolocation')}}
),

final as (
    select 
        order_items.order_item_id,
        order_items.order_id,
        customers.customer_unique_id,
        order_items.product_id,
        order_items.seller_id,

        order_items.shipping_limit_datetime,

        order_items.price,
        order_items.freight_value,
        order_items.price + order_items.freight_value as gross_item_revenue,

        6371 * acos(
            sin(radians(customer_geolocation.geolocation_latitude)) * sin(radians(seller_geolocation.geolocation_latitude)) + 
            cos(radians(customer_geolocation.geolocation_latitude)) * cos(radians(seller_geolocation.geolocation_latitude)) * 
            cos(radians(seller_geolocation.geolocation_longitude) - radians(customer_geolocation.geolocation_longitude))
        ) as shipping_distance_km

    from order_items

    left join orders
        on order_items.order_id = orders.order_id

    left join customers
        on orders.customer_id = customers.customer_id
    left join geolocation as customer_geolocation
        on customers.customer_zip_code_prefix = customer_geolocation.geolocation_zip_code_prefix

    left join sellers
        on order_items.seller_id = sellers.seller_id
    left join geolocation as seller_geolocation
        on sellers.seller_zip_code_prefix = seller_geolocation.geolocation_zip_code_prefix
)

select * from final