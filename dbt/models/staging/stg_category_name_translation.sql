with

raw_translation as (
    select * from {{source('olist_raw', 'raw_category_name_translation')}}
),

translation_overrides as (
    select * from {{ref('category_name_translation_overrides')}}
),

cleaned_raw_translation as (
    select
        trim(product_category_name) as product_category_name,
        trim(product_category_name_english) as product_category_name_english
    from raw_translation
),

final as (
    (select * from cleaned_raw_translation)

    union
    
    (select * from translation_overrides)
)

select 
    product_category_name,
    product_category_name_english
from final