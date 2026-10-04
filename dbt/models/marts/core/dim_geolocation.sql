with

geolocation as (
    select * from {{ref('int_geolocation')}}
),

final as (
    select
        geolocation_zip_code_prefix,
        geolocation_latitude,
        geolocation_longitude,
        geolocation_city,
        geolocation_state

    from geolocation
)

select * from final