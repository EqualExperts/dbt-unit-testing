{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_union_multi_schema', 'sample test') %}
  {% call dbt_unit_testing.mock_source('source_from_schema_1','multi_schema') %}
    select 'ONE' as name
  {% endcall %}

  {% call dbt_unit_testing.mock_source('source_from_schema_2','multi_schema') %}
    select 'TWO' as name
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 'schema_1' as from_schema, 'ONE' as name
    union all
    select 'schema_2' as from_schema, 'TWO' as name
  {% endcall %}
{% endcall %}
