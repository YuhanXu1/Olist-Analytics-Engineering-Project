with 

source as (
    select * from {{source('olist_raw', 'raw_reviews')}}
),

cleaned as (
    select
        trim(review_id) as review_id,
        trim(order_id) as order_id,
        review_score,
        nullif(trim(review_comment_title),'') as review_comment_title,
        nullif(trim(review_comment_message),'') as review_comment_message,
        cast(review_creation_date as timestamp) as review_creation_date,
        cast(review_answer_timestamp as timestamp) as review_answered_datetime
    from source
)

select
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answered_datetime
from cleaned