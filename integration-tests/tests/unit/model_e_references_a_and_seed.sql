{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_e_references_a_and_seed', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('seed') %}
    select 1 as value
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b, 1 as value
  {% endcall %}
{% endcall %}
 