with

orders as (
    select * from {{ref('stg_orders')}}
),

order_items as (
    select * from {{ref('fct_order_items')}}
),

customers as (
    select * from {{ref('stg_customers')}}
),

payments as (
    select * from {{ref('stg_payments')}}
),

reviews as (
    select * from {{ref('stg_reviews')}}
),

payment_summary as (
    select
        order_id,
        payment_type,
        sum(payment_value) as payment_value,
        sum(payment_installments) as payment_installments
    from payments
    group by 1,2
),

payment_summary_ranked as (
    select
        order_id,
        payment_type,
        payment_value,
        payment_installments,
        row_number() over (
            partition by order_id 
            order by payment_value desc, payment_type) as payment_rank
    from payment_summary
),

order_primary_payment as (
    select
        order_id,
        payment_type as primary_payment_method
    from payment_summary_ranked
    where payment_rank = 1
),

order_payment_summary as (
    select
        order_id,
        sum(payment_value) as payment_amount,
        sum(case when payment_summary.payment_type = 'credit_card'
                 then payment_summary.payment_installments end) as num_payment_installments
    from payment_summary
    group by 1
),

order_revenue_summary as (
    select
        order_id,
        sum(price) as product_revenue,
        sum(freight_value) as freight_fee,
        sum(gross_item_revenue) as total_order_revenue
    from order_items
    group by 1
),

order_review as (
    select
        order_id,
        avg(review_score) as review_score
    from reviews
    group by 1
),

final as (
    select
        orders.order_id,
        customers.customer_unique_id,
        orders.order_status,
        orders.order_purchase_datetime,
        orders.order_approved_datetime,
        orders.order_delivered_carrier_datetime,
        orders.order_delivered_customer_datetime,
        orders.order_estimated_delivery_datetime,

        order_primary_payment.primary_payment_method,
        order_payment_summary.payment_amount,
        order_payment_summary.num_payment_installments,
        
        order_revenue_summary.product_revenue,
        order_revenue_summary.freight_fee,
        order_revenue_summary.total_order_revenue,

        order_review.review_score

    from orders

    left join order_revenue_summary 
        on orders.order_id = order_revenue_summary.order_id

    left join customers
        on orders.customer_id = customers.customer_id

    left join order_payment_summary
        on orders.order_id = order_payment_summary.order_id

    left join order_primary_payment
        on orders.order_id = order_primary_payment.order_id

    left join order_review
        on orders.order_id = order_review.order_id
)

select * from final