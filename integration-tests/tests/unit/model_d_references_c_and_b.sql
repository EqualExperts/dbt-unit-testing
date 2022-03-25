{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_d_references_c_and_b', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_c_references_model_with_source') %}
    select 1 as source_a, 'b' as source_b
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('model_b_references_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as source_a, 'b' as source_b, 1 as a, 'b' as b
  {% endcall %}
{% endcall %}
 