with customers as (
    select * from {{ dbt_unit_testing.ref('metrics_model_stg_customer') }}
),


orders as (
    select * from {{ dbt_unit_testing.ref('metrics_model_stg_orders') }}
),


customer_orders as (
        select
        customer_id,
        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders,
        sum(order_amount) as total_amount
    from orders
    group by customer_id
),


final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order,
        customer_orders.most_recent_order,
        customer_orders.number_of_orders,
        customer_orders.total_amount as total_amount
    from customers
    left join customer_orders
        on customers.customer_id = customer_orders.customer_id
)

select * from final
