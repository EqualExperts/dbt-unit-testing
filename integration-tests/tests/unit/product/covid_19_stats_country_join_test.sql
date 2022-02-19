{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test ('covid19_stats') %}
  {% call dbt_unit_testing.mock_ref ('covid19_cases_per_day') %}
     select cast('2021-05-05' as Date) as day, 10 as cases, 'uk' as country_id
  {% endcall %}
 
  {% call dbt_unit_testing.mock_source('dbt_unit_testing', 'covid19_country_stg') %}
    select 'uk' as country_id, 'United Kingdom' as country_name
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select  cast('2021-05-05' as Date) as day, 10 as cases,  'United Kingdom' as country_name    
  {% endcall %}

{% endcall %}

UNION ALL

{% call dbt_unit_testing.test ('covid19_stats', 'test csv format') %}
  {% call dbt_unit_testing.mock_ref ('covid19_cases_per_day', {"input_format": "csv"}) %}

    day::Date, cases, country_id
    '2021-05-05', 10, 'uk' 

  {% endcall %}
 
  {% call dbt_unit_testing.mock_source('dbt_unit_testing', 'covid19_country_stg', {"input_format": "csv"}) %}

    country_id, country_name
    'uk', 'United Kingdom'
    
  {% endcall %}

  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}

    day::Date, cases, country_name
    '2021-05-05', 10, 'United Kingdom'

  {% endcall %}

{% endcall %}
  