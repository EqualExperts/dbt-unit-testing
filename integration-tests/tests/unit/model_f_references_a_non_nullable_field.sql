{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_f_references_a_non_nullable_field', 'sample test passes without a pure mock') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 0 as a
    UNION ALL
    select 1 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_f_references_a_non_nullable_field', 'sample test passes with PURE mock by defining the extra field, it wont compile otherwise') %}
  {% call dbt_unit_testing.mock_ref ('model_a', {"mocking_strategy": "PURE"}) %}
    select 0 as a, '' as b
    UNION ALL
    select 1 as a, '' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
  {% endcall %}
{% endcall %}
 