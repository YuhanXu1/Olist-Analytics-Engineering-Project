with

customers as (
    select * from {{ref('stg_customers')}}
),

orders as (
    select * from {{ref('fct_orders')}}
),

customer_latest_address as (
    select * from {{ref('int_customer_latest_address')}}
),

customers_metrics as (
    select
        customers.customer_unique_id,
        min(orders.order_purchase_datetime) as first_purchase_date,
        max(orders.order_purchase_datetime) as last_purchase_date,

        sum(orders.total_order_revenue) as lifetime_revenue,
        count(distinct orders.order_id) as lifetime_order_count

    from customers

    left join orders
        on customers.customer_unique_id = orders.customer_unique_id

    group by 1
),

final as (
    select
        customer_latest_address.customer_unique_id,
        customer_latest_address.latest_customer_zip_code_prefix as customer_zip_code_prefix,
        customer_latest_address.latest_customer_city as customer_city,
        customer_latest_address.latest_customer_state as customer_state,

        customers_metrics.first_purchase_date,
        customers_metrics.last_purchase_date,
        customers_metrics.lifetime_revenue,
        customers_metrics.lifetime_order_count

    from customer_latest_address

    left join customers_metrics
        on customer_latest_address.customer_unique_id = customers_metrics.customer_unique_id
)

select * from final