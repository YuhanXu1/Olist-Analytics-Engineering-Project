with

logistic_summary as (
    select * from {{ref('rpt_logistic_per_order_daily')}}
),

final as (
    select logistic_summary.order_purchase_date,
    count(distinct logistic_summary.order_id) as order_count, 
    count(
            distinct case
                when logistic_summary.is_delay_flag
                then logistic_summary.order_id
            end
        ) as delay_order_count,
    sum(logistic_summary.order_approve_days) as total_order_approve_days,
    sum(logistic_summary.order_seller_to_carrier_days) as total_order_seller_to_carrier_days,
    sum(logistic_summary.order_carrier_to_customer_days) as total_order_carrier_to_customer_days,
    sum(logistic_summary.order_delivery_delay_days) as total_order_delivery_delay_days
    
    from logistic_summary

    group by 1
)

select * from final