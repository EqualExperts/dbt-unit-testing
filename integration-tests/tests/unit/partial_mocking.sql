{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_b_references_a', 'mock just the used column') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
  {% endcall %}
{% endcall %}
 