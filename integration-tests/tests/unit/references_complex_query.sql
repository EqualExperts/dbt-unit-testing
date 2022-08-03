{{
    config(
        tags=['unit-test', 'bigquery']
    )
}}

{% call dbt_unit_testing.test('model_references_complex_query', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('model_with_complex_query') %}
    select 1 as complex_1
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
  {% endcall %}
{% endcall %}
 