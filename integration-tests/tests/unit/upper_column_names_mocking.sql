{{
    config(
        tags=['unit-test', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_references_model_with_upper_column_name', 'should work') %}
  {% call dbt_unit_testing.mock_ref ('model_with_upper_column_name') %}
    select 1 as a, 'b' as b, 1 as "UPPER_CASE_COLUMN"
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b, 1 as "UPPER_CASE_COLUMN"
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_references_model_with_upper_column_name', 'should work case insensitive') %}
  {% call dbt_unit_testing.mock_ref ('model_with_upper_column_name') %}
    select 1 as a, 'b' as b, 1 as upper_case_column
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b, 1 as upper_case_column
  {% endcall %}
{% endcall %}
 