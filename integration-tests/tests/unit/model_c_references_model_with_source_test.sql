{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_c_references_model_with_source', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_with_source') %}
    select 1 as source_a, 'b' as source_b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as source_a, 'b' as source_b
  {% endcall %}
{% endcall %}
 