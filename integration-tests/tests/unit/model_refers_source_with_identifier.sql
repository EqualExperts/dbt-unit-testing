{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_refers_source_with_identifier', 'Can refer to source that has an identifier') %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing', 'sample_source_name') %}
    select 1 as example
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as example
  {% endcall %}
{% endcall %}