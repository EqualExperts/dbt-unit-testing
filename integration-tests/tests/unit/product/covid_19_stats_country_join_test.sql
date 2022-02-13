{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test ('covid19_stats') %}
  {% call dbt_unit_testing.mock_ref ('covid19_cases_per_day') %}
     select cast('2021-05-05' as Date) as day, 10 as cases, 'uk' as country_id
  {% endcall %}
 
  {% call dbt_unit_testing.mock_source('dbt_unit_testing_staging', 'covid19_country_stg') %}
    select 'uk' as country_id, 'United Kingdom' as country_name
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select  cast('2021-05-05' as Date) as day, 10 as cases,  'United Kingdom' as country_name    
  {% endcall %}

{% endcall %}
 