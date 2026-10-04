#configure the database connection
import os

def get_database_config():
    """configure the database connection variables
    
    Returns:
        db_user: str, database username
        db_password: str, database password
        db_host: str, database host name
        db_port: str, database port
        db_name: str, database name
    """
    db_host = os.getenv("DATABASE_HOST")
    db_name =  os.getenv("DATABASE_NAME")
    db_user = os.getenv("DATABASE_USER")
    db_password =  os.getenv("DATABASE_PASSWORD")
    db_port = os.getenv("DATABASE_PORT")

    return db_user, db_password, db_host, db_port, db_name

#map the file names to table names in the database
table_mapping = {
    "olist_customers_dataset.csv": {
        "table_name": "raw_customers",
        "expected_columns": [
            "customer_id",
            "customer_unique_id",
            "customer_zip_code_prefix",
            "customer_city",
            "customer_state",
        ],
    },
    "olist_geolocation_dataset.csv": {
        "table_name": "raw_geolocation",
        "expected_columns": [
            "geolocation_zip_code_prefix",
            "geolocation_lat",
            "geolocation_lng",
            "geolocation_city",
            "geolocation_state",
        ],
    },
    "olist_order_items_dataset.csv": {
        "table_name": "raw_order_items",
        "expected_columns": [
            "order_id",
            "order_item_id",
            "product_id",
            "seller_id",
            "shipping_limit_date",
            "price",
            "freight_value",
        ],
    },
    "olist_order_payments_dataset.csv": {
        "table_name": "raw_payments",
        "expected_columns": [
            "order_id",
            "payment_sequential",
            "payment_type",
            "payment_installments",
            "payment_value",
        ],
    },
    "olist_order_reviews_dataset.csv": {
        "table_name": "raw_reviews",
        "expected_columns": [
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message",
            "review_creation_date",
            "review_answer_timestamp",
        ],
    },
    "olist_orders_dataset.csv": {
        "table_name": "raw_orders",
        "expected_columns": [
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
    },
    "olist_products_dataset.csv": {
        "table_name": "raw_products",
        "expected_columns": [
            "product_id",
            "product_category_name",
            "product_name_lenght",
            "product_description_lenght",
            "product_photos_qty",
            "product_weight_g",
            "product_length_cm",
            "product_height_cm",
            "product_width_cm",
        ],
    },
    "olist_sellers_dataset.csv": {
        "table_name": "raw_sellers",
        "expected_columns": [
            "seller_id",
            "seller_zip_code_prefix",
            "seller_city",
            "seller_state",
        ],
    },
    "product_category_name_translation.csv": {
        "table_name": "raw_category_name_translation",
        "expected_columns": [
            "product_category_name",
            "product_category_name_english",
        ],
    },
}

#kaggle dataset name
dataset_name = 'olistbr/brazilian-ecommerce'

#database schema name
db_schema_name = 'olist_raw'