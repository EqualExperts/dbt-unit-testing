{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call test_should_fail('model_b_references_a', 'sample test failing, more rows expected') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 0 as a, 'a' as b
    UNION ALL
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
    UNION ALL
    select 2 as a, 'c' as b
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call test_should_fail('model_b_references_a', 'sample test failing, different row expected') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 2 as a, 'b' as b
  {% endcall %}
{% endcall %}

UNION ALL

{% call test_should_fail('model_b_references_a', 'sample test failing, less rows expected') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
    UNION ALL
    select 2 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}

UNION ALL

{% call test_should_fail('model_b_references_a', 'sample test failing, duplicated entries on source') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
    UNION ALL
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}

UNION ALL

{% call test_should_fail('model_b_references_a', 'sample test failing, duplicated entries on expectation') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
    UNION ALL
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}