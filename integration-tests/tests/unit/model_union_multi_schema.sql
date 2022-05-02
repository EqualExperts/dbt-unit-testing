{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_union_multi_schema', 'sample test') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing','multi_schema') %}
    select 'ONE' as name
  {% endcall %}

  {% call dbt_unit_testing.mock_source('dbt_unit_testing_2','multi_schema') %}
    select 'TWO' as name
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 'dbt_unit_testing' as from_schema, 'ONE' as name
    union all
    select 'dbt_unit_testing_2' as from_schema, 'TWO' as name
  {% endcall %}
{% endcall %}
