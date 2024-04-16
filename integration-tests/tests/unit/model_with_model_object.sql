{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_with_model_object', 'sample test') %}
  {% call dbt_unit_testing.expect() %}
    select 'model' as resource_type
  {% endcall %}
{% endcall %}
