{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_stats'
    )
}}

{% call test ('covid19_stats', 'descr') %}
  {% call mock_ref ('covid19_cases_per_day') %}
     select cast('2021-05-05' as Date) as day, 10 as cases, 'uk' as country_id
  {% endcall %}
 
  {% call mock_source('covid19_stg', 'covid19_country_stg') %}
    select 'uk' as country_id, 'United Kingdom' as country_name
  {% endcall %}

  {% call expect() %}
    select  cast('2021-05-05' as Date) as day, 10 as cases,  'United Kingdom' as country_name    
  {% endcall %}

{% endcall %}
 