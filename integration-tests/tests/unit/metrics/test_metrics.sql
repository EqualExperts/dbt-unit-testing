-- depends on: {{ ref(var('dbt_metrics_calendar_model', 'dbt_metrics_default_calendar')) }}
{{
    config(
        tags=['unit-test', 'metrics-test']
    )
}}


{% call dbt_unit_testing.test('metrics_mart_customers', 'customers table should yield expected result') %}
  
  {% call dbt_unit_testing.mock_ref ('metrics_model_stg_customer') %}
    select 1 as customer_id, 'first_name' as first_name, 'last_name' as last_name
  {% endcall %}

  {% call dbt_unit_testing.mock_ref ('metrics_model_stg_orders') %}
    select 1 as customer_id, 1 as order_id, 0.3 as order_amount, '2023-02-01'::Timestamp as order_date union all
    select 1 as customer_id, 2 as order_id, 0.5 as order_amount, '2023-02-01'::Timestamp as order_date union all
    select 2 as customer_id, 3 as order_id, 0.2 as order_amount, '2023-02-01'::Timestamp as order_date
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 1 as customer_id, 'first_name' as first_name, 'last_name' last_name, '2023-02-01'::Timestamp as first_order, '2023-02-01'::Timestamp as most_recent_order, 2 as number_of_orders, 0.8 as total_amount
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('metrics_customers', 'metrics table should yield expected result') %}
  
  {% call dbt_unit_testing.mock_ref ('metrics_model_stg_customer') %}
    select 1 as customer_id, 'first_name' as first_name, 'last_name' as last_name
  {% endcall %}

  {% call dbt_unit_testing.mock_ref ('metrics_model_stg_orders') %}
    select 1 as customer_id, 1 as order_id, 0.3 as order_amount, '2023-02-01'::Timestamp as order_date union all
    select 1 as customer_id, 2 as order_id, 0.5 as order_amount, '2023-02-01'::Timestamp as order_date union all
    select 2 as customer_id, 3 as order_id, 0.2 as order_amount, '2023-02-01'::Timestamp as order_date
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select '2023-02-01'::Timestamp as metric_start_date, '2023-02-01'::Timestamp as metric_end_date, 0.8 as average_order_amount, 0.8 as total_order_amount, 3 as generic_sum
  {% endcall %}
{% endcall %}
