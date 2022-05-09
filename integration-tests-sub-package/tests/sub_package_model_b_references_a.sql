{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'subpack']
    )
}}

{% call dbt_unit_testing.test('sub_package_model_b_references_a', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('sub_package_model_a') %}
    select 0 as a, 'a' as b
    UNION ALL
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing', 'sub_package_sample_source') %}
    select 2 as a, 'c' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
    UNION ALL
    select 2 as a, 'c' as b
  {% endcall %}
{% endcall %}
 