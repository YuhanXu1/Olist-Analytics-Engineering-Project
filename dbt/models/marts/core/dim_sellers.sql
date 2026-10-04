with

sellers as (
    select * from {{ref('stg_sellers')}}
),

final as (
    select
        sellers.seller_id,
        sellers.seller_zip_code_prefix,
        sellers.seller_city,
        sellers.seller_state

    from sellers
)

select * from final