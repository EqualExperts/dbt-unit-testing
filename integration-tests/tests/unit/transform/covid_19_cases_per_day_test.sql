{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test('covid19_cases_per_day', 'empty payload') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing', 'covid19_stg') %}
    select CAST('2021-05-05' as date) as day, '[{}]' as payload
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select cast('2021-05-05' as Date) as day, 0 as cases
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call dbt_unit_testing.test('covid19_cases_per_day', 'extracting cases from payload') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing', 'covid19_stg') %}
    select CAST('2021-05-06' as date) as day, '[{"newCases": 20}]' as payload
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select cast('2021-05-07' as Date) as day, 20 as cases
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call dbt_unit_testing.test('covid19_cases_per_day', 'extracting country id') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing', 'covid19_stg') %}
    select null as day, '' as payload, 'uk' as country_id
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 'uk' as country_id
  {% endcall %}
{% endcall %}
 

