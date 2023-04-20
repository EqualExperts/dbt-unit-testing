-- depends_on: {{ ref('model_in_database') }}
{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'db-dependency']
    )
}}

{% call dbt_unit_testing.test('model_b_references_model_with_builtin_ref', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_in_database') %}
    select 10 as a, 20 as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 10 as a, 20 as b
  {% endcall %}
{% endcall %}
 