{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_f_references_a_non_nullable_field', 'sample test passes without the need for extra columns') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 0 as a, '' as b
    UNION ALL
    select 1 as a, '' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call dbt_unit_testing.test('model_f_references_a_non_nullable_field', 'sample test passes if we include extra columns') %}
  {% call dbt_unit_testing.mock_ref ('model_a', options={"include_missing_columns": true}) %}
    select 0 as a
    UNION ALL
    select 1 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
  {% endcall %}
{% endcall %}
