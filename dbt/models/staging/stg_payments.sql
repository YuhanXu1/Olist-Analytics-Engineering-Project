with 

source as (
    select * from {{source('olist_raw', 'raw_payments')}}
),

cleaned as (
    select
        trim(order_id) as order_id,
        payment_sequential as payment_sequential_id,
        lower(trim(payment_type)) as payment_type,
        payment_installments,
        payment_value
    from source
)

select
    order_id,
    payment_sequential_id,
    payment_type,
    payment_installments,
    payment_value
from cleaned