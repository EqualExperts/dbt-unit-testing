{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call test_should_fail('model_b_references_a', 'more rows expected') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'a' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
    UNION ALL
    select 2 as a, 'c' as b
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call test_should_fail('model_b_references_a', 'different row expected') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 2 as a, 'b' as b
  {% endcall %}
{% endcall %}

UNION ALL

{% call test_should_fail('model_b_references_a', 'less rows expected') %}
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

{% call test_should_fail('model_b_references_a', 'duplicated entries on source') %}
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

{% call test_should_fail('model_b_references_a', 'duplicated entries on expectation') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
    UNION ALL
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}

UNION ALL

{% call test_should_fail('model_b_references_a', 'rows are different despite being equal when using distinct') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a
    UNION ALL
    select 1 as a
    UNION ALL
    select 2 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
    UNION ALL
    select 2 as a
    UNION ALL
    select 2 as a
  {% endcall %}
{% endcall %}
 
