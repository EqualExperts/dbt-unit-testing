{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_b_references_a', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 0 as a, 'a' as b
    UNION ALL
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}

UNION ALL

{% call test_condition_on_model_query('model_b_references_a', "should quote CTE", {}, 
                                       assert_should_contain, dbt_unit_testing.quote_identifier("DBT_CTE__model_a")) %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as id
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}
