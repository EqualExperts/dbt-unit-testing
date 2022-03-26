{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_with_existing_source', 'sample test') %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing','sample_source_without_columns_declared') %}
    select 0 as existing_source_a, 'a' as existing_source_b
    UNION ALL
    select 1 as existing_source_a, 'b' as existing_source_b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as existing_source_a, 'b' as existing_source_b
  {% endcall %}
{% endcall %}
 
 UNION ALL

{% call dbt_unit_testing.test('model_with_existing_source', 'sample test with partial mocking') %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing','sample_source_without_columns_declared') %}
    select 1 as existing_source_a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as existing_source_a
  {% endcall %}
{% endcall %}