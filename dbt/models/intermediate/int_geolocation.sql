with

geolocation as (
    select * from {{ref('stg_geolocation')}}
),

final as (
    select
        geolocation.geolocation_zip_code_prefix, 
        min(geolocation.geolocation_city) as geolocation_city, 
        min(geolocation.geolocation_state) as geolocation_state,
        avg(geolocation.geolocation_latitude) as geolocation_latitude,
        avg(geolocation.geolocation_longitude) as geolocation_longitude
    from geolocation
    group by 1
)

select * from final