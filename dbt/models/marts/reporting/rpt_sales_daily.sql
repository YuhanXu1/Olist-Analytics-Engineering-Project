with

orders as (
    select * from {{ref('fct_orders')}}
),

dates as (
    select * from {{ref('dim_date')}}
),

order_items as (
    select * from {{ref('fct_order_items')}}
),

final as (
    select
        orders.order_purchase_datetime::date as order_purchase_date, 

        dates.is_weekend, 
        dates.is_holiday, 

        sum(order_items.price) as delivered_product_revenue, 
        sum(order_items.freight_value) as delivered_freight_fee, 
        count(distinct orders.order_id) as delivered_order_count, 
        count(distinct (orders.order_id, order_items.order_item_id)) as delivered_order_item_count
    
    from orders 

    join dates
        on orders.order_purchase_datetime::date = dates.full_date

    left join order_items 
        on orders.order_id = order_items.order_id

    where orders.order_status = 'delivered'
        and dates.year >= 2017 /*dates.year >= extract(year from current_date)-1*/

    group by 1,2,3
)

select * from final