-- depends_on: {{ ref('model_a') }}
{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'db-dependency']
    )
}}

{% call dbt_unit_testing.test('model_b_references_a_with_builtin_ref', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 0 as a, 'a' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 0 as a, 'a' as b
  {% endcall %}
{% endcall %}
 