{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_b_references_subpackage', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('dbt_unit_testing_sub_package', 'sub_package_model_a') %}
    select 0 as a, 'a' as b
    UNION ALL
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}
 