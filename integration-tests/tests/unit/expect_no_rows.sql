{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_b_references_a', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 0 as a, 'a' as b
  {% endcall %}
  {% call dbt_unit_testing.expect_no_rows() %}
  {% endcall %}
{% endcall %}
