{{
    config(
        tags=['unit-test']
    )
}}

{% call test('covid19_cases_per_day', 'empty payload') %}
  {% call mock_source('covid19_stg', 'covid19_stg') %}
    select CAST('2021-05-05' as date) as day, '[{}]' as payload
  {% endcall %}

  {% call expect() %}
    select cast('2021-05-05' as Date) as day, 0 as cases
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call test('covid19_cases_per_day', 'extracting cases from payload') %}
  {% call mock_source('covid19_stg', 'covid19_stg') %}
    select CAST('2021-05-06' as date) as day, '[{"newCases": 20}]' as payload
  {% endcall %}

  {% call expect() %}
    select cast('2021-05-06' as Date) as day, 20 as cases
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call test('covid19_cases_per_day', 'extracting country id') %}
  {% call mock_source('covid19_stg', 'covid19_stg') %}
    select null as day, '' as payload, 'uk' as country_id
  {% endcall %}

  {% call expect() %}
    select 'uk' as country_id
  {% endcall %}
{% endcall %}
 

