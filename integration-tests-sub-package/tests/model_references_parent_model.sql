{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'subpack']
    )
}}

{% call dbt_unit_testing.test('model_references_parent_model', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}
 