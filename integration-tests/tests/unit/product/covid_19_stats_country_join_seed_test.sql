{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test ('covid19_stats_using_seed') %}
  {% call dbt_unit_testing.mock_ref ('covid19_cases_per_day') %}
     select cast('2021-05-05' as Date) as day, 10 as cases, 'uk' as country_id
  {% endcall %}
 
  {% call dbt_unit_testing.mock_ref('country_codes') %}
    select 'uk' as country_code, 'United Kingdom' as country_name
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select  cast('2021-05-05' as Date) as day, 10 as cases,  'United Kingdom' as country_name    
  {% endcall %}

{% endcall %}