{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test('covid19_stats_with_array', 'array test') %}
  {% call dbt_unit_testing.mock_ref ('covid19_cases_per_day') %}
     select 20 as cases, 'UK' as country_id
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
  {% if target.type == 'postgres' %}
    select  'UK' as country_id, '{20}'::bigint[] as cases
  {% elif target.type in ('bigquery') %}
    select  'UK' as country_id, [20] as cases
  {% elif target.type in ('snowflake') %}
    select  'UK' as country_id, array_construct(20) as cases
  {% else %}
    {{ exceptions.raise_compiler_error(target.type ~" not supported in this project") }}
  {% endif %}
  {% endcall %}
{% endcall %}
 