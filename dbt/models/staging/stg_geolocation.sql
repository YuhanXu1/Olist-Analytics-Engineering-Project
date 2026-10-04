with 

source as (
    select * from {{source('olist_raw', 'raw_geolocation')}}
),

cleaned as (
    select
        lpad(cast(geolocation_zip_code_prefix as text), 5, '0') as geolocation_zip_code_prefix,
        geolocation_lat as geolocation_latitude,
        geolocation_lng as geolocation_longitude,
        trim(geolocation_city) as geolocation_city,
        trim(geolocation_state) as geolocation_state
    from source
)

select distinct
    geolocation_zip_code_prefix,
    geolocation_latitude,
    geolocation_longitude,
    geolocation_city,
    geolocation_state
from cleaned