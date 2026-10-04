with

customers as (
    select * from {{ref('stg_customers')}}
),

orders as (
    select * from {{ref('stg_orders')}}
),

customer_address_ranked as (
    select
        customers.customer_unique_id,
        customers.customer_zip_code_prefix,
        customers.customer_city,
        customers.customer_state,

        row_number() over (
            partition by customers.customer_unique_id
            order by orders.order_purchase_datetime desc NULLS LAST,
                     orders.customer_id desc) as latest_address_rank
    
    from customers

    left join orders
        on customers.customer_id = orders.customer_id
),

final as (
    select 
        customer_address_ranked.customer_unique_id,
        customer_address_ranked.customer_zip_code_prefix as latest_customer_zip_code_prefix,
        customer_address_ranked.customer_city as latest_customer_city,
        customer_address_ranked.customer_state as latest_customer_state
    
    from customer_address_ranked

    where latest_address_rank = 1
)

select * from final