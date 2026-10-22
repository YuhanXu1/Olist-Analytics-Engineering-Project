with

orders as (
    select * from {{ref('fct_orders')}}
),

dates as (
    select * from {{ref('dim_date')}}
),

final as (
    select
        orders.order_id,
        orders.order_purchase_datetime::date as order_purchase_date,

        (
            orders.order_estimated_delivery_datetime::date
            < orders.order_delivered_customer_datetime::date
        ) as is_delay_flag,

        case
            when orders.order_purchase_datetime
                <= orders.order_approved_datetime
            then round(
                (
                    extract(
                        epoch from (
                            orders.order_approved_datetime
                            - orders.order_purchase_datetime
                        )
                    ) / 86400
                )::numeric,
                2
            )
        end as order_approve_days,

        case
            when orders.order_approved_datetime
                <= orders.order_delivered_carrier_datetime
            then round(
                (
                    extract(
                        epoch from (
                            orders.order_delivered_carrier_datetime
                            - orders.order_approved_datetime
                        )
                    ) / 86400
                )::numeric,
                2
            )
        end as order_seller_to_carrier_days,

        case
            when orders.order_delivered_carrier_datetime
                <= orders.order_delivered_customer_datetime
            then round(
                (
                    extract(
                        epoch from (
                            orders.order_delivered_customer_datetime
                            - orders.order_delivered_carrier_datetime
                        )
                    ) / 86400
                )::numeric,
                2
            )
        end as order_carrier_to_customer_days,

        case
            when orders.order_estimated_delivery_datetime::date
                < orders.order_delivered_customer_datetime::date
            then round(
                (
                    extract(
                        epoch from (
                            orders.order_delivered_customer_datetime
                            - orders.order_estimated_delivery_datetime
                        )
                    ) / 86400
                )::numeric,
                2
            )
        end as order_delivery_delay_days

    from orders

    join dates
        on orders.order_purchase_datetime::date = dates.full_date

    where orders.order_status = 'delivered'
        and dates.year >= 2017
)

select * from final