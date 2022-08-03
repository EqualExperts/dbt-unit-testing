{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_with_comment', 'sample test') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing','sample_source') %}
    select 0 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 0 as a
  {% endcall %}
{% endcall %}
 