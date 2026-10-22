with

logistic_summary as (
    select * from {{ref('rpt_logistic_per_order_daily')}}
),

orders as (
    select * from {{ref('fct_orders')}}
),

order_items as (
    select * from {{ref('fct_order_items')}}
),

customers as (
    select * from {{ref('dim_customers')}}
),

sellers as (
    select * from {{ref('dim_sellers')}}
),

logistic_per_route_summary as 
(
    select 
        customers.customer_state, 
        sellers.seller_state, 
        orders.order_id,

        count(distinct order_items.order_item_id) as order_item_count,

        count(
            distinct case
                when order_items.shipping_limit_datetime::date
                    < orders.order_delivered_carrier_datetime::date
                then order_items.order_item_id
            end
        ) as seller_delay_order_item_count,

        sum(
            case
                when order_items.shipping_limit_datetime::date
                    < orders.order_delivered_carrier_datetime::date
                then round(
                    (
                        extract(
                            epoch from (
                                orders.order_delivered_carrier_datetime
                                - order_items.shipping_limit_datetime
                            )
                        ) / 86400
                    )::numeric,
                    2
                )
            end
        ) as total_seller_delay_days,

        sum(order_items.shipping_distance_km) as total_shipping_distance_km
        
        from orders
        
        left join order_items 
            on orders.order_id = order_items.order_id
        
        left join customers 
            on orders.customer_unique_id = customers.customer_unique_id
        
        left join sellers
            on order_items.seller_id = sellers.seller_id
        
        where orders.order_status = 'delivered' 

        group by 1,2,3
),

final as (
    select 
        logistic_summary.order_purchase_date, 
        logistic_per_route_summary.customer_state, 
        logistic_per_route_summary.seller_state, 

        count(distinct logistic_summary.order_id) as order_count,
        count(distinct case when logistic_summary.is_delay_flag then logistic_summary.order_id end) as delay_order_count,
        sum(logistic_summary.order_approve_days) as total_order_approve_days,
        sum(logistic_summary.order_seller_to_carrier_days) as total_order_seller_to_carrier_days,
        sum(logistic_summary.order_carrier_to_customer_days) as total_order_carrier_to_customer_days,
        sum(logistic_summary.order_delivery_delay_days) as total_order_delivery_delay_days,
        
        sum(logistic_per_route_summary.order_item_count) as total_order_item_count,
        sum(logistic_per_route_summary.seller_delay_order_item_count) as total_seller_delay_order_item_count,
        sum(logistic_per_route_summary.total_shipping_distance_km) as total_shipping_distance_km,
        sum(logistic_per_route_summary.total_seller_delay_days) as total_seller_delay_days
    
    from logistic_summary 

    left join logistic_per_route_summary 
        on logistic_summary.order_id = logistic_per_route_summary.order_id

    group by 1,2,3
)

select * from final